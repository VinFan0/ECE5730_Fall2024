#ifndef PLACE_H
#define PLACE_H

void anneal(int *current);
void copy(int *current, int *next);
void alter(int *next);
int evaluate(int *next);
void accept(int *current_val, int next_val, int *current, int *next, float temperature);
float adjust_temperature();

#endif