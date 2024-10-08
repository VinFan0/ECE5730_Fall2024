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
void anneal(int *current);
void copy(int *current, int *next);
void alter(int *next);
int evaluate(int *next);
void accept(int *current_val, int next_val, int *current, int *next, float temperature);
float cooling();

#endif
