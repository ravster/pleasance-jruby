// gcc -o stats -I/usr/include/x86_64-linux-gnu -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include run.c -lglib-2.0 -lm

// To run,
// ./stats
// This will read a file named sp500_1y.csv that is in the same directory as the 'stats' program.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <glib.h>

float *opens, *highs, *lows, *closes;
float *trs, *atr10s;

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
  FILE* stream = fopen("sp500_1y.csv", "r");
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
    printf("%f, ", atr10s[i]);
  }
}

int main () {
  int num_rows = 512;
  opens = (float*) malloc(num_rows * sizeof(float));
  highs = (float*) malloc(num_rows * sizeof(float));
  lows = (float*) malloc(num_rows * sizeof(float));
  closes = (float*) malloc(num_rows * sizeof(float));
  num_rows = load_ohlc();
  calc_true_range(num_rows);
  calc_atr_10(num_rows);
}
