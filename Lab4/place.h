#ifndef PLACE_H
#define PLACE_H

/*****************************************
* Graph management functions
******************************************/
void printEdges(std::vector<std::vector<bool>> * graph); // Prints edges of provided graph(1 for edge, 0 no edge)
void printNodes(std::vector<int> x_pos, std::vector<int> y_pos); // Prints (x,y) coords of each node 
void placeNodes(std::vector<int> *x_pos, std::vector<int> *y_pos); // Place nodes in initial locations


/*****************************************
* Annealing functions
******************************************/
void anneal(int *current_x_pos, int *current_y_pos);
void copy(int *current_x_pos, int *current_y_pos, int *next_x_pos, int *next_y_pos);
void alter(int *next_x_pos, int *next_y_pos);
int evaluate (int *next_x_pos, int *next_y_pos);
void accept(int *current_val, int next_val, int *current_x_pos, int *current_y_pos, int *next_x_pos, int *next_y_pos, int temperature);
double cooling();

#endif
