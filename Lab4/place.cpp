/*
 * ECE 5730
 * Lab4 - Simulated Annealing
 * 10/10/24
 * Ryan Beck, Jared Bronson
 *
 */
#include <iostream>
#include <vector>

class Grid {
	private:
	    int rows;
	    int cols;
	    std::vector<std::vector<char>> grid;
	public:
	    Grid(int rows, int cols) : rows(rows), cols(cols), grid(rows,std::vector<char>(cols,'-')) {}


	    void setValue(int i, int j, char value) {
	        if (i >= 0 && i < rows && j >= 0 && j < cols) 
		    grid[i][j] = value;
		else
		    std::cout << "Index out of bounds!" << std::endl;
	    }

	    int getValue(int i, int j) const {
	        if (i >= 0 && i < rows && j >= 0 && j < cols) {
		    return grid[i][j];
		} else {
		    std::cout << "Index out fo bounds!" << std::endl;
		    return -1;
		}
	    }

	    void printGrid() {
		for(int i=0; i<rows; ++i) {
		    for(int j=0; j<cols; ++j) {
		        std::cout << grid[i][j] << " " ;
		    }
		    std::cout << std::endl;
		}
		std::cout << std::endl;
	    }
};

int main(int argc, char *argv[]) {
	int rows = 5;
	int cols  = 5;
	int nodes = 5;
	if(argc > 1) {
	    std::cout << "Updating node count to " << argv[1] << std::endl;
	    nodes = atoi(argv[1]);
	}
	else {
	    std::cout << "Placing 5 nodes" << std::endl;
	}
	Grid myGrid(rows,cols);
	myGrid.printGrid();
	
	int row,col,val;
	
	for(int count=0;count<nodes;++count) {
	    std::cout << "What row? ";
	    std::cin >> row;
	    std::cout << "What col? ";
	    std::cin >> col;
	    myGrid.setValue(row-1,col-1, char(count+48));
	    myGrid.printGrid();
	}

	return 0;
}
