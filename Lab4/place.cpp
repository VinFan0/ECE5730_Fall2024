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

#define INITIAL_TEMPERATURE 100000
#define COOLING_RATE 0.99999
#define STOP_THRESHOLD 0.001

int nodes, num_rows, num_cols;

std::vector<std::vector<bool>> edges; // 2D vector for edge graph

int main(int argc, char *argv[]) {
	srand(time(NULL));
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
				std::cout << "nodes: " << nodes << std::endl << std::endl;
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
	
	std::vector<int> current_x_pos; // current_x_pos[n] = x coord for node n
	std::vector<int> current_y_pos; // current_y_pos[n] = y coord for node n

	// Populate x and y pos vectors with initial positions
	std::cout << "Placing Nodes" << std::endl;
	placeNodes(current_x_pos,current_y_pos);

	// Print Node locations
	std::cout << "Initial Node Locations" << std::endl;
	printNodes(current_x_pos, current_y_pos);

	// By this point, we have two int vectors with node coords and an edge map
	// We can now begin the annealing process		
	anneal(current_x_pos, current_y_pos);
	
	// Print results to console and table
	FILE* outputFile = fopen("output.txt", "w");
	
	for(int i=0; i<nodes; i++) {
		printf("Node %d placed at (%d, %d)\n",i, current_x_pos[i], current_y_pos[i]);
		fprintf(outputFile, "Node %d placed at (%d, %d)\n",i, current_x_pos[i], current_y_pos[i]);
	}
	
	int distance, n1, n2;
	
	for (n1 = 0; n1 < nodes; n1++){
		for(n2 = 0; n2 < nodes; n2++){
			if (edges[n1][n2]){
				distance = abs(current_x_pos[n1] - current_x_pos[n2]) + abs(current_y_pos[n1] - current_y_pos[n2]);
				printf("Edge from %d to %d has length %d\n", n1, n2, distance);
				fprintf(outputFile, "Edge from %d to %d has length %d\n", n1, n2, distance);
			}
		}
	}

	fclose(outputFile);
	return 0;
}

/****************************
* Simulated Annealing Functions
****************************/

void anneal(std::vector<int> &current_x_pos, std::vector<int> &current_y_pos)
{
	double temperature = INITIAL_TEMPERATURE;
	int current_val, next_val, i;
	std::vector<int> next_x_pos;
	std::vector<int> next_y_pos;
		
	current_val = evaluate(current_x_pos, current_y_pos);
	printf("\nInitial score: %d\n", current_val);
	
	while (temperature > STOP_THRESHOLD)
	{
		copy(current_x_pos, current_y_pos, next_x_pos, next_y_pos);
		//std::cout << "Finished copy" << std::endl;
		
		alter(next_x_pos, next_y_pos);
		//std::cout << "Finished alter" << std::endl;
		
		next_val = evaluate(next_x_pos, next_y_pos);
		//std::cout << "Finished evaluate" << std::endl;
		
		accept(current_val, next_val, current_x_pos, current_y_pos,
			   next_x_pos, next_y_pos, temperature);
		//std::cout << "Finished accept" << std::endl;

		temperature = cooling();
		i++;
	}
	printf("\nExplored %d solutions\n", i);
	printf("Final score: %d\n\n", current_val);
}

void copy(std::vector<int> &current_x_pos, std::vector<int> &current_y_pos,
		  std::vector<int> &next_x_pos,    std::vector<int> &next_y_pos)
{
	int i;
	for (i = 0; i < nodes; i++){
		next_x_pos.push_back(current_x_pos[i]);
		next_y_pos.push_back(current_y_pos[i]);
	}
}

void alter(std::vector<int> &next_x_pos, std::vector<int> &next_y_pos)
{	
	int n, new_x_pos, new_y_pos;
	// Repeat until move is on the graph
	do
	{
		// Pick random directions to move node
		do
		{
			n = rand() % nodes;
			new_x_pos = rand() % 3;
			new_y_pos = rand() % 3;
			
			
			if(new_x_pos == 2) new_x_pos = -1;
			if(new_y_pos == 2) new_y_pos = -1;
			
		}
		while(!((new_x_pos == 0 && new_y_pos != 0) || (new_x_pos != 0 && new_y_pos == 0)));
	}
	while(!((next_x_pos[n] + new_x_pos >= 0) && (next_x_pos[n] + new_x_pos < num_cols) && (next_y_pos[n] + new_y_pos >= 0) && (next_y_pos[n] + new_y_pos < num_cols)));
	
	//printf("Old coords: (%d,%d)\tNew coords: (%d,%d)\n", next_x_pos[n], next_y_pos[n], new_x_pos, new_y_pos);
	next_x_pos[n] = next_x_pos[n] + new_x_pos;
	next_y_pos[n] = next_y_pos[n] + new_y_pos;
}

int evaluate(std::vector<int> &next_x_pos, std::vector<int> &next_y_pos)
{
	int distance, n1, n2;
	bool penalty = false;
	
	distance = 0;
	for (n1 = 0; n1 < nodes; n1++){
		for(n2 = 0; n2 < nodes; n2++){
			if(n1 != n2) {
				if (edges[n1][n2]){
					distance += abs(next_x_pos[n1] - next_x_pos[n2]) +
								abs(next_y_pos[n1] - next_y_pos[n2]);
					//printf("Node1: %d\t Node2: %d\t N1(%d,%d)\t N2(%d,%d)\nDistance: %d\n", i,j,next_x_pos[i],next_y_pos[i],next_x_pos[j],next_y_pos[j], abs(next_x_pos[i] - next_x_pos[j]) +abs(next_y_pos[i] - next_y_pos[j]));
				}
				// If invalid nodes exist (nodes in same place) add penalty (3 times the max distance of the grid)
				if((next_x_pos[n1] == next_x_pos[n2]) && (next_y_pos[n1] == next_y_pos[n2])) {
					distance += 1*(num_rows + num_cols);
					penalty = true;
					//printf("Penalty Applied\t");
				}
				//printf("N1(%d,%d)\tN2(%d,%d)\n", next_x_pos[n1],next_y_pos[n1],next_x_pos[n2],next_y_pos[n2]);
			}
		}
	}
	/*
	if(penalty) 
		printf("Penalty applied to this solution\n"); 
	else 
		printf("Penalty not applied\n");
	*/
	return distance;
}

void accept(int &current_val, int next_val, std::vector<int> &current_x_pos, 
			std::vector<int> &current_y_pos, std::vector<int> &next_x_pos, 
			std::vector<int> &next_y_pos, int temperature)
{
	int delta_e, i;
	double p, r;
	
	delta_e = next_val - current_val;
	// If new result is better
	if (delta_e <= 0){
		for (i = 0; i < nodes; i++){
			current_x_pos[i] = next_x_pos[i];
			current_y_pos[i] = next_y_pos[i];
		}
		current_val = next_val;
	}
	// Have a chance to take worse result
	else{
		//printf("Current val: %d\t Next val: %d\n", current_val, next_val);
		p = exp(-((double)delta_e)/temperature);
		r = (double)rand() / RAND_MAX;
		if (r < p){
			for (i = 0; i < nodes; i++){
				current_x_pos[i] = next_x_pos[i];
				current_y_pos[i] = next_y_pos[i];
			}			
			current_val = next_val;
		}
	}
}

double cooling()
{
	static double temperature = INITIAL_TEMPERATURE;
	temperature *= COOLING_RATE;
	return temperature;
}

/****************************
* Graph Management Functions
****************************/

void printEdges(std::vector<std::vector<bool>> * graph) {
	printf("Edges of provided graph\n   ");
	for(int i=0; i<nodes; i++)
		printf("%d ", i);
	printf("\n");
	
	for(int i=0; i<nodes; i++) {
		printf("%d: ",i);
		for(int j=0; j<nodes; j++) {
			std::cout << edges[i][j] << " ";
		}
		std::cout << std::endl;
	}
	std::cout << std::endl;
}

void placeNodes(std::vector<int> &x_pos, std::vector<int> &y_pos) {
	int node_x, node_y;
	
	// Loop for all nodes
	for(int n=0; n<nodes;) {
		
		bool duplicate = false;
		
		// Select random coords
		node_x = rand() % num_rows;
		node_y = rand() % num_cols;
		// Place first node
		if(n == 0) {
			x_pos.push_back(node_x);
			y_pos.push_back(node_y);
			n++;
		}
		else {
			// Loop through existing nodes
			for(int existingNode = 0; existingNode<n; existingNode++) {
				// If existing node coords do match new coords
				if(x_pos[existingNode] == node_x && y_pos[existingNode] == node_y) {
					// Break from loop without incrementing n count
					duplicate = true;
					break;
				}
				//printf("New node %d (%d,%d)\t Existing at %d (%d,%d)\n",n,node_x,node_y,existingNode, x_pos[existingNode], y_pos[existingNode]);
			}
			if(!duplicate) {
				// Place node
				x_pos.push_back(node_x);
				y_pos.push_back(node_y);
				// Increment n count
				n++;
			}
		}
	}
	std::cout << std::endl;;
}

void printNodes(std::vector<int> x_pos, std::vector<int> y_pos) {
	for(int i=0; i<nodes; i++) {
		printf("Node %d placed at (%d, %d)\n",i, x_pos[i], y_pos[i]);
	}
}
