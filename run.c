// gcc -o stats -I/usr/include/x86_64-linux-gnu -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include run.c -lglib-2.0

// To run,
// ./stats
// This will read a file named sp500_1y.csv that is in the same directory as the 'stats' program.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <glib.h>

float *opens, *highs, *lows, *closes;

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

void load_ohlc() {
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
}

int main () {
  int num_rows = 512
  opens = (float*) malloc(num_rows * sizeof(float));
  highs = (float*) malloc(num_rows * sizeof(float));
  lows = (float*) malloc(num_rows * sizeof(float));
  closes = (float*) malloc(num_rows * sizeof(float));

  load_ohlc();
}
