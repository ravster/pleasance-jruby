// gcc -g -Wall -o stats run.c -lm

// To run,
// ./stats
// This will read a file named sp500_1y.csv that is in the same directory as the 'stats' program.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

float *opens, *highs, *lows, *closes;
float *trs, *atr10s;
int *docs;

void load_arrs(char* line, int i) {
  line = strtok(line, ",");
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

int load_ohlc() {
  FILE* stream = fopen("sp500_5y.csv", "r");
  char line[40];
  int i = 0;
  while (fgets(line, 40, stream))
    {
        char* tmp = strdup(line);
	load_arrs(tmp, i);
        free(tmp); // NOTE strtok clobbers tmp
	i++;
    }
  printf("Finished loading data, rows=%d\n", i - 1);
  free(stream);
  return i;
}

/* n is num_rows */
void calc_true_range(int n) {
  trs = (float*)malloc(n * sizeof(float));
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

/* When TR[-1] > ATR10[-1], and DOC[-1] is 1, I hope that H[+5]
   (high of 5d from now) - O[0] (open today) is a nice big positive number.  If DOC[-1] is 0, we sell instead.
   if TR does not break out of ATR10, we do not enter a position.

   Let's test this.

   This is a volatility breakout strategy.*/
void t1(int n) {
  for(int i = 11; i < n-5; i++) {
    float tr = trs[i-1];
    float atr10 = atr10s[i-1];
    int doc = docs[i-1];
    float a = highs[i+5] - opens[i]; // positive if profit
    float b = lows[i+5] - opens[i]; // negative if profit

    if (tr > atr10) {
      if (doc > 0) { //buy
	printf("1, %f\n", a);
      } else { // sell
	printf("-1, %f\n", b);
      }
    }
  }
}

int main () {
  int num_rows = 1300; // Max rows we want to consider.
  opens = (float*) malloc(num_rows * sizeof(float));
  highs = (float*) malloc(num_rows * sizeof(float));
  lows = (float*) malloc(num_rows * sizeof(float));
  closes = (float*) malloc(num_rows * sizeof(float));
  num_rows = load_ohlc();
  calc_true_range(num_rows);
  calc_atr_10(num_rows);
  calc_direction_of_change(num_rows);

  t1(num_rows);
}
