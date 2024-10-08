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

#define INITIAL_TEMPERATURE 10000
#define COOLING_RATE 0.9999
#define STOP_THRESHOLD 001

int nodes;

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
	int rows; // Height of grid
	int cols; // Width of grid
	
	// Iterate through lines vector
	for (const auto& l : lines) {
		// Grab first char of line
		ch = l[0];

		switch(ch) {
			// If initializing grid
			case 'g': {
				rows = l[2];
				cols = l[4];
				break;
			}
			// Determine node count
			case 'v': {
				nodes = l[2]-48;
				std::cout << "nodes: " << nodes << std::endl;
				break;
			}
			// Create edges
			case 'e': {
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

	// X coord array (x_pos[n] = x coord of node n)
	std::vector<int> x_pos;
	// X coord array (x_pos[n] = x coord of node n)
	std::vector<int> y_pos;
	// Populate x and y pos vectors with initial positions
	for (int i=0; i<nodes; i++) {
		x_pos.push_back(i);
		y_pos.push_back(i);
	}

	for(int i=0;i<sizeof(x_pos);i++) {
		std::cout << i << std::endl;
	}

	return 0;
}


