/*
 * ECE 5730
 * Lab4 - Simulated Annealing
 * 10/10/24
 * Ryan Beck, Jared Bronson
 *
 */
#include <iostream>
#include <vector>
#include <fstream>
#include <cstdlib>
#include <ctime>
#include "place.h"

#define INITIAL_TEMPERATURE 10000
#define COOLING_RATE 0.9999
#define STOP_THRESHOLD 001

void printEdges(std::vector<std::vector<bool>> * graph);	// Prints edges of provided graph(1 for edge, 0 no edge)

int nodes;
std::vector<int> x_pos;			// x_pos[n] = x coord for node n
std::vector<int> y_pos;			// y_pox[n] = y coord for node n
std::vector<std::vector<bool>> edges;	// 2D vector for edge graph

int main(int argc, char *argv[]) {
	/*************************************
	 * READ INPUT CONTENTS
	 *************************************/
	// Open file
	std::ifstream file(argv[1]);
	if (!file.is_open()) {
		std::cerr << "Failed to open the file.\n";
		return 1;
	}

	// Variables for input parsing
	std::vector<std::string> lines;
	std::string line;

	// Enter each line as string into lines vector
	while (std::getline(file,line)) {
		lines.push_back(line);
	}

	// Close file
	file.close();

	char ch; // For switching on first char of line
	int num_rows; // Height of grid
	int num_cols; // Width of grid
	int row;      // tracking row for edge graph
	int col;      // tracking col for edge graph
	
	// Iterate through lines vector
	for (const auto& l : lines) {
		// Grab first char of line
		ch = l[0];

		switch(ch) {
			// If initializing grid
			case 'g': {
				num_rows = l[2]-48;
				num_cols = l[4]-48;
				break;
			}
			// Determine node count
			case 'v': {
				nodes = l[2]-48;
				std::cout << "nodes: " << nodes << std::endl;
				for(int i=0; i<nodes; i++) {
					edges.push_back(std::vector<bool>(nodes,false));
				}
				break;
			}
			// Create edges
			case 'e': {
				// Select edge in graph
				row = l[2]-48;
				col = l[4]-48;

				// Set edge
				edges[row][col] = true;
				break;
			}
			default: {
				std::cout << "Invalid line! ch: " << ch << std::endl;
				std::cout << "--> " << l << std::endl;
				break;
			}
		}
	}
	// END READ INPUT CONTENTS
	printEdges(&edges);

	// Populate x and y pos vectors with initial positions
	for (int i=0; i<nodes; i++) {
		x_pos.push_back(i);
		y_pos.push_back(i);
	}

	return 0;
}

void printEdges(std::vector<std::vector<bool>> * graph) {
	printf("Edges of provided graph\n");
	for(int i=0; i<nodes; i++) {
		for(int j=0; j<nodes; j++) {
			std::cout << edges[i][j] << " ";
		}
		std::cout << std::endl;
	}
}
/*
void anneal(int *current)
{
	float temperature;
	int current_val, next_val;
	//int next[NUM_CITIES];
	int i=0;
	
	temperature = INITIAL_TEMPERATURE;
	current_val = evaluate(current);
	printf("\nInitial score: %d\n", current_val);
	while (temperature > STOP_THRESHOLD)
	{
		//copy(current, next);
		//alter(next);
		//next_val = evaluate(next);
		//accept(&current_val, next_val, current, next, temperature);
		//temperature = adjustTemperature();
		i++;
	}
	printf("\nExplored %d solutions\n", i);
	printf("Final score: %d\n", current_val);
}

void copy(int *current, int *next)
{
	int i;
	//for (i=0; i<NUM_CITIES; i++)
	//{
	//	next[i] = current[i];
	//}
}

void alter(int *next)
{
	int a, b, temp;
	do
	{
	//	a = rand() % NUM_CITIES;
	//	b = rand() % NUM_CITIES;
	}
	while (a == b);
	temp = next[a];
	next[a] = next[b];
	next[b] = temp;
}

int evaluate (int *next)
{
	// x_pos[n] = x coord for node n
	//const int x_pos[NUM_CITIES] = {27, 32, 91, 60, 36, 64, 32, 9, 7, 64, 2, 28, 41, 4, 38, 33, 79, 65, 45, 57};
	// y_pos[n] = y coord for node n
	//const int y_pos[NUM_CITIES] = {20, 17, 98, 83, 35, 77, 41, 61, 0, 55, 17, 70, 4, 92, 25, 59, 16, 66, 39, 73};
	int distance, i;
	
	distance = 0;
	//for (i=0; i<NUM_CITIES-1; i++)
	//{
	//	distance += abs(x_pos[next[i]] - x_pos[next[i+1]]) +
	//				abs(y_pos[next[i]] - y_pos[next[i+1]]);
	//}
	
	return distance;
}

void accept(int *current_val, int next_val, int *current, int *next, float temperature)
{
	int delta_e, i;
	float p, r;

	delta_e = next_val - *current_val;
	if (delta_e <= 0)
	{
		//for (i=0; i<NUM_CITIES; i++)
		//{
		//	current[i] = next[i];
		//}
		*current_val = next_val;
	}
	else
	{
		//p = exp(-((float)delta_e)/temperature);
		r = (float)rand() / RAND_MAX;
		if (r < p)
		{
			//for (i=0; i<NUM_CITIES; i++)
			//{
			//	current[i] = next[i];
			//}
			*current_val = next_val;
		}
	}
}

float cooling()
{
	static float temperature = INITIAL_TEMPERATURE;
	temperature *= COOLING_RATE;
	return temperature;
}*/
