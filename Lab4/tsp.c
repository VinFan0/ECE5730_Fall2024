#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define NUM_CITIES 20
#define INITIAL_TEMPERATURE 1000000
#define COOLING_RATE 0.99999
#define STOP_THRESHOLD 0.001

void anneal(int *current);
void copy(int *current, int *next);
void alter(int *next);
int evaluate(int *next);
void accept(int *current_val, int next_val, int *current, int *next, float temperature);
float adjustTemperature();

int main()
{
	// Initial order
	static int current[NUM_CITIES] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19};
	int i;
	
	printf("Initial order:\n");
	for (i=0; i<NUM_CITIES; i++)
	{
		printf("%d ", current[i]);
	}
		
	srand(time(NULL));
	// Find optimal order
	anneal(current);
	
	printf("Final order: ");
	for (i=0; i<NUM_CITIES; i++)
	{
		printf("%d ", current[i]);
	}
	
	return 0;
}

void anneal(int *current)
{
	float temperature;
	int current_val, next_val;
	int next[NUM_CITIES];
	int i=0;
	
	temperature = INITIAL_TEMPERATURE;
	current_val = evaluate(current);
	printf("\nInitial score: %d\n", current_val);
	while (temperature > STOP_THRESHOLD)
	{
		copy(current, next);
		alter(next);
		next_val = evaluate(next);
		accept(&current_val, next_val, current, next, temperature);
		temperature = adjustTemperature();
		i++;
	}
	printf("\nExplored %d solutions\n", i);
	printf("Final score: %d\n", current_val);
}

void copy(int *current, int *next)
{
	int i;
	for (i=0; i<NUM_CITIES; i++)
	{
		next[i] = current[i];
	}
}

void alter(int *next)
{
	int a, b, temp;
	do
	{
		a = rand() % NUM_CITIES;
		b = rand() % NUM_CITIES;
	}
	while (a == b);
	temp = next[a];
	next[a] = next[b];
	next[b] = temp;
}

int evaluate (int *next)
{
	// x_pos[n] = x coord for node n
	const int x_pos[NUM_CITIES] = {27, 32, 91, 60, 36, 64, 32, 9, 7, 64, 2, 28, 41, 4, 38, 33, 79, 65, 45, 57};
	// y_pos[n] = y coord for node n
	const int y_pos[NUM_CITIES] = {20, 17, 98, 83, 35, 77, 41, 61, 0, 55, 17, 70, 4, 92, 25, 59, 16, 66, 39, 73};
	int distance, i;
	
	distance = 0;
	for (i=0; i<NUM_CITIES-1; i++)
	{
		distance += abs(x_pos[next[i]] - x_pos[next[i+1]]) +
					abs(y_pos[next[i]] - y_pos[next[i+1]]);
	}
	
	return distance;
}

void accept(int *current_val, int next_val, int *current, int *next, float temperature)
{
	int delta_e, i;
	float p, r;

	delta_e = next_val - *current_val;
	if (delta_e <= 0)
	{
		for (i=0; i<NUM_CITIES; i++)
		{
			current[i] = next[i];
		}
		*current_val = next_val;
	}
	else
	{
		p = exp(-((float)delta_e)/temperature);
		r = (float)rand() / RAND_MAX;
		if (r < p)
		{
			for (i=0; i<NUM_CITIES; i++)
			{
				current[i] = next[i];
			}
			*current_val = next_val;
		}
	}
}

float adjustTemperature()
{
	static float temperature = INITIAL_TEMPERATURE;
	temperature *= COOLING_RATE;
	return temperature;
}
