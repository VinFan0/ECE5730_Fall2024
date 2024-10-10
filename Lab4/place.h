#ifndef PLACE_H
#define PLACE_H

/*****************************************
* Graph management functions
******************************************/
void printEdges(std::vector<std::vector<bool>> * graph); // Prints edges of provided graph(1 for edge, 0 no edge)
void printNodes(std::vector<int> x_pos, std::vector<int> y_pos); // Prints (x,y) coords of each node 
void placeNodes(std::vector<int> &x_pos, std::vector<int> &y_pos); // Place nodes in initial locations


/*****************************************
* Annealing functions
******************************************/
void anneal(std::vector<int> &current_x_pos, std::vector<int> &current_y_pos)

void copy(std::vector<int> &current_x_pos, std::vector<int> &current_y_pos,
		  std::vector<int> &next_x_pos,    std::vector<int> &next_y_pos);
		  
void alter(std::vector<int> &next_x_pos, std::vector<int> &next_y_pos);

int evaluate(std::vector<int> &next_x_pos, std::vector<int> &next_y_pos);

void accept(int &current_val, int next_val, std::vector<int> &current_x_pos, 
			std::vector<int> &current_y_pos, std::vector<int> &next_x_pos, 
			std::vector<int> &next_y_pos, int temperature);

double cooling();

#endif
