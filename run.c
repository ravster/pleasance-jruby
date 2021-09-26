// gcc -g -Wall -o stats run.c -lm

// To run,
// ./stats
// This will read a file named sp500_1y.csv that is in the same directory as the 'stats' program.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

float *opens, *highs, *lows, *closes;
float *trs, *atr10s, *hh100s, *ll100s;
int *docs;
char** dates;

void load_arrs(char* line, int i) {
  line = strtok(line, ",");
  dates[i] = strdup(line);

  line = strtok(NULL, ",");
  float f = atof(line);
  opens[i] = f;

  line = strtok(NULL, ",");
  f = atof(line);
  highs[i] = f;

  line = strtok(NULL, ",");
  f = atof(line);
  lows[i] = f;

  line = strtok(NULL, ",");
  f = atof(line);
  closes[i] = f;
}

void reverse_float_array(float* arr, int n) {
  float temp;
   for(int i=0; i<n/2; i++)
    {
        temp = arr[i];
        arr[i] = arr[n-i-1];
        arr[n-1-i] = temp;
    }
}
void reverse_string_array(char** arr, int n) {
  char* temp;
   for(int i=0; i<n/2; i++)
    {
        temp = arr[i];
        arr[i] = arr[n-i-1];
        arr[n-1-i] = temp;
    }
}
int load_ohlc() {
  FILE* stream = fopen("DBA.csv", "r");
  char line[70];
  int i = 0;
  while (fgets(line, 70, stream))
    {
        char* tmp = strdup(line);
	load_arrs(tmp, i);
        free(tmp); // NOTE strtok clobbers tmp
	i++;
    }
  fclose(stream);

  // We want the newest entries later in the datasets.
  /* reverse_float_array(opens, i); */
  /* reverse_float_array(closes, i); */
  /* reverse_float_array(highs, i); */
  /* reverse_float_array(lows, i); */
  /* reverse_string_array(dates, i); */

  return i;
}

/* n is num_rows */
void calc_true_range(int n) {
  trs = (float*)calloc(n, sizeof(float));
  // We start from index 1 instead of index 0 because we can't calc TR for the first datapoint.
  for(int i = 1; i < n; i++) {
    float pr_close = closes[i-1];
    float h = highs[i];
    float l = lows[i];
    float a = fabs(h - l);
    float b = fabs(h - pr_close);
    float c = fabs(pr_close - l);

    trs[i] = fmax(a, fmax(b, c));
  }
}

void calc_atr_10(int n) {
  atr10s = (float*)malloc(n * sizeof(float));
  // We start from index 10 instead of index 0 because we can't calc TR for the first 10 datapoints.
  for(int i = 10; i < n; i++) {
    float sum = 0;
    for(int j = -10; j <= 0; j++) {
      sum += trs[i+j];
    }
    atr10s[i] = sum / 10;
  }
}

/*
1 means yesterday's close was greater than from 5 days ago,
else 0
 */
void calc_direction_of_change(int n) {
  docs = (int*)malloc(n * sizeof(int));
  for(int i = 5; i < n; i++) {
    float a, b;
    a = closes[i-5];
    b = closes[i-1];
    if (b > a){
      docs[i] = 1;
    }
    else {
      docs[i] = 0;
    }
  }
}

// Record highest high in the last 100 ticks.
void calc_hh100(int n) {
  hh100s = (float*)calloc(n, sizeof(float));
  ll100s = (float*)calloc(n, sizeof(float));
  for(int i = 100; i < n; i++) {
    float max = -1;
    float min = 10000;
    for(int j = i-100; j< i; j++) {
      max = fmax(max, highs[j]);
      min = fmin(min, lows[j]);
    }
    hh100s[i] = max;
    ll100s[i] = min;
  }
}

float avg(int i) {
  return (highs[i] + lows[i]) / 2;
}

/* When TR[-1] > ATR10[-1], and DOC[-1] is 1, I hope that H[+5]
   (high of 5d from now) - O[0] (open today) is a nice big positive number.  If DOC[-1] is 0, we sell instead.
   if TR does not break out of ATR10, we do not enter a position.

   Let's test this.

   This is a volatility breakout strategy.*/
void t1(int n) {
  // THIS LOSES MONEY
  FILE* f = fopen("t1.csv", "w");
  for(int i = 11; i < n-5; i++) {
    float tr = trs[i-1];
    float atr10 = atr10s[i-1];
    int doc = docs[i-1];
    float a = avg(i+5) - opens[i]; // positive if profit
    float b = avg(i+5) - opens[i]; // negative if profit

    if (tr > atr10) {
      if (doc > 0) { //buy
	fprintf(f, "%s, 1, %f\n", dates[i], a);
      } else { // sell
	fprintf(f, "%s, -1, %f\n", dates[i], b);
      }
    }
  }
  fclose(f);
}

/* How often does close-open go in the same direction for consecutive days, and how long does that trend usually last? */
void t2(int n) {
  int up = 0;
  int down = 0;
  FILE* f = fopen("t2.csv", "w");
  fprintf(f, "date, consecutive up days, consecutive down days\n");

  for(int i = 2; i < n; i++) {
    if (closes[i] > closes[i-1]) {
      up++;
      if (up > 3) {
	// printf("%f\n", avg(i+1) - opens[i]);
	/* If it's gone up consecutively for 3 days (~10% of the time), and you
	   buy on the open of day 4, then sell on day-5,
	   num-wins/num-loss = 70/27, and
	   avgwin = 14points,
	   avgloss = 8points */
      }
      if (down != 0) {
	fprintf(f, "%s, 0, %d\n", dates[i], down);
	down = 0;
      }
    } else if (closes[i] < closes[i-1]) {
      down++;
      if (down > 2) {
	printf("%f\n", opens[i] - closes[i+1]);
	/* If you sell after 3 consecutive down days (~10% chance of this),
	   count win = 58
	   countloss = 31
	   avg-win = 39.42
	   avg-loss = -25.43 */
      }
      if (up != 0) {
	fprintf(f, "%s, %d, 0\n", dates[i], up);
	up = 0;
      }
    }
  }
  fclose(f);
}

/* When TR[-1] > ATR10[-1] && TR[-2] < ATR10[-2], and DOC[-1] is 1, I hope that H[+5]
   (high of 5d from now) - O[0] (open today) is a nice big positive number.  If DOC[-1] is 0, we sell instead.
   if TR does not break out of ATR10, we do not enter a position.

   Let's test this.

   This is a volatility breakout strategy.*/
void t3(int n) {
  FILE* f = fopen("a.csv", "w");
  for(int i = 11; i < n-5; i++) {
    float tr = trs[i-1];
    float atr10 = atr10s[i-1];
    int doc = docs[i-1];
    float a = (highs[i+5] + lows[i+5])/2 - opens[i]; // positive if profit
    float b = (lows[i+5] + highs[i+5])/2 - opens[i]; // negative if profit

    if ((trs[i-2] < atr10s[i-2]) && (tr > atr10)) {
      if (doc > 0) { //buy
	fprintf(f, "%s, 1, %f, %f, %f\n", dates[i], a, tr, atr10);
      } else { // sell
	fprintf(f, "%s, -1, %f, %f, %f\n", dates[i], b, tr, atr10);
      }
    }
  }
  fclose(f);
}

/* I'm interested in the spikes.  This is when the tick-chart shows a long wick either
   above or below the candle.  I want to know the stats around this.
   It appears we should just buy everytime a spike happens, when the spike is greater
   than the median ATR-10.
 */
void t4(int n) {
  FILE* f = fopen("candle_wicks.csv", "w");
  fprintf(f, "Date, 1, h/atr10, l/atr10, atr10, h+2, l+2\n");
  for(int i = 11; i < n; i++) {
    float atr10 = atr10s[i-1];
    float h = highs[i-1] - fmax(opens[i-1], closes[i-1]);
    float l = fmin(opens[i-1], closes[i-1]) - lows[i-1];
    float h_2 = 0;
    float l_2 = 0;

    // Magic numbers are the median
    if (h/atr10 > 0.11) { // spike on top
      h_2 = avg(i+2) - opens[i]; // positive is good
    }
    if ((l/atr10 > 0.14) && h_2 == 0) { // spike on bottom
      // buy
      l_2 = avg(i+2) - opens[i]; // positive is good
    }

    fprintf(f, "%s, 1, %f, %f, %f, %f, %f\n", dates[i], h/atr10, l/atr10, atr10, h_2, l_2);
  }
  fclose(f);
}

/* Stats on the HH100s */
void t5(int n) {
  FILE* f = fopen("hh100s.csv", "w");
  FILE* g = fopen("ll100s.csv", "w");
  fprintf(f, "Date, high, hh100[-1], [+1], [+3], [+5], [+10]\n");
  fprintf(g, "Date, low, ll100[-1], [+1], [+3], [+5], [+10]\n");
  for(int i = 101; i < n; i++) {
    if (highs[i] > hh100s[i-1]) {
      fprintf(f, "%s, %f, %f, %f, %f, %f, %f\n", dates[i], highs[i], hh100s[i-1],
	      highs[i+1] / closes[i],
	      highs[i+3] / closes[i],
	      highs[i+5] / closes[i],
	      highs[i+10] / closes[i]
	      );
    } else if (lows[i] < ll100s[i-1]) {
      fprintf(g, "%s, %f, %f, %f, %f, %f, %f\n", dates[i], lows[i], ll100s[i-1],
	      lows[i+1] / closes[i],
	      lows[i+3] / closes[i],
	      lows[i+5] / closes[i],
	      lows[i+10] / closes[i]
	      );
    }
  }
  fclose(f);
  fclose(g);
}

int main () {
  int num_rows = 5000; // Max rows we want to consider.
  opens = (float*) malloc(num_rows * sizeof(float));
  highs = (float*) malloc(num_rows * sizeof(float));
  lows = (float*) malloc(num_rows * sizeof(float));
  closes = (float*) malloc(num_rows * sizeof(float));
  dates = malloc(num_rows * sizeof(char*));
  num_rows = load_ohlc();

  calc_true_range(num_rows);
  calc_atr_10(num_rows);
  calc_direction_of_change(num_rows);
  calc_hh100(num_rows);

  /* printf("start\n"); */
  //t1(num_rows);
  /* printf("t1 done\n"); */
  // t2(num_rows);
  /* printf("t2 done\n"); */
  // t3(num_rows);
  // t4(num_rows);
  t5(num_rows);
}
