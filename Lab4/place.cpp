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
#include <math.h>

#include "place.h"

#define INITIAL_TEMPERATURE 10000
#define COOLING_RATE 0.9999
#define STOP_THRESHOLD 001

int nodes, num_rows, num_cols;
std::vector<int> x_pos;	// x_pos[n] = x coord for node n
std::vector<int> y_pos;	// y_pox[n] = y coord for node n
std::vector<std::vector<bool>> edges; // 2D vector for edge graph

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
	std::cout << "Placing Nodes" << std::endl;
	placeNodes(&x_pos,&y_pos);

	// Print Node locations
	std::cout << "Printing Nodes" << std::endl;
	printNodes(x_pos, y_pos);

        // By this point, we have two int vectors with node coords, and an edge map
        //  We can now begin the annealing process		
	anneal(&x_pos[0], &y_pos[0]);
	
	// Print results to console and table

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

void placeNodes(std::vector<int> *x_pos, std::vector<int> *y_pos) {
	for(int i=0; i<nodes; i++) {
		x_pos->push_back(i);
		y_pos->push_back(i);
	}
}

void printNodes(std::vector<int> x_pos, std::vector<int> y_pos) {
	printf("TEST: %d\n", x_pos[0]);
	for(int i=0; i<nodes; i++) {
		printf("Node %d placed at (%d, %d)\n",i, x_pos[i], y_pos[i]);
	}
}

void anneal(int *current_x_pos, int *current_y_pos){
	double temperature = INITIAL_TEMPERATURE;
	int current_val, next_val, i;
	std::vector<int> next_x_pos;
	std::vector<int> next_y_pos;
	
	current_val = evaluate(&current_x_pos[0], &current_y_pos[0]);
	printf("\nInitial score: %d\n", current_val);
	
	while (temperature > STOP_THRESHOLD)
	{
		std::cout << "Starting Copy" << std::endl;
		copy(current_x_pos, current_y_pos, &next_x_pos[0], &next_y_pos[0]);
		//std::cout << "Finished copy" << std::endl;
	/*	
		alter(&next_x_pos[0], &next_y_pos[0]);
		std::cout << "Finished alter" << std::endl;
		
		next_val = evaluate(&next_x_pos[0], &next_y_pos[0]);
		std::cout << "Finished evaluate" << std::endl;
		
		accept(&current_val, next_val, current_x_pos, current_y_pos,
			   &next_x_pos[0], &next_y_pos[0], temperature);
		std::cout << "Finished accept" << std::endl;
	*/	
		temperature = cooling();
		std::cout << "Finished cooling" << std::endl;
		
		i++;
	}
//	printf("\nExplored %d solutions\n", i);
//	printf("Final score: %d\n", current_val);
	std::cout << "Finished" << std::endl;	
	
}

double cooling()
{
	static double temperature = INITIAL_TEMPERATURE;
	temperature *= COOLING_RATE;
	return temperature;
}

void copy(int *current_x_pos, int *current_y_pos, int *next_x_pos, int *next_y_pos)
{
	int i;
	printf("current_x_pos[0]: %d", current_x_pos[0]);
	for (i = 0; i < nodes; i++){
		next_x_pos[i] = current_x_pos[i];
		next_y_pos[i] = current_y_pos[i];
	}
}

void alter(int *next_x_pos, int *next_y_pos)
{
	int a, b, temp;
	
	do{
		a = rand() % nodes;
		b = rand() % nodes;
	}
	while (a == b);
	temp = next_x_pos[a];
	next_x_pos[a] = next_x_pos[b];
	next_x_pos[b] = temp;
	
	temp = next_y_pos[a];
	next_y_pos[a] = next_y_pos[b];
	next_y_pos[b] = temp;
}

int evaluate (int *next_x_pos, int *next_y_pos)
{
	int distance, i, j;
	
	distance = 0;
	for (i = 0; i < num_rows; i++){
		for(j = 0; j < num_cols; j++){
			if (edges[i][j]){
				distance += abs(next_x_pos[i] - next_x_pos[j]) +
							abs(next_y_pos[i] - next_y_pos[j]);
			}
		}
	}
	return distance;
}

void accept(int *current_val, int next_val, int *current_x_pos, int *current_y_pos, int *next_x_pos, int *next_y_pos, int temperature)
{
	int delta_e, i;
	double p, r;
	
	delta_e = next_val - *current_val;
	if (delta_e <= 0){
		for (i = 0; i < nodes; i++){
			current_x_pos[i] = next_x_pos[i];
			current_y_pos[i] = next_y_pos[i];
		}
		*current_val = next_val;
	}
	else{
		p = exp(-((double)delta_e)/temperature);
		r = (double)rand() / RAND_MAX;
		if (r < p){
			for (i = 0; i < nodes; i++){
				current_x_pos[i] = next_x_pos[i];
				current_y_pos[i] = next_y_pos[i];

			}
			*current_val = next_val;
		}
	}
}
