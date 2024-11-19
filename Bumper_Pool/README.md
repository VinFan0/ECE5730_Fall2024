# Bumper Pool FPGA Project
Jared Bronson, Ryan Beck\
ECE 5730 / Fall 2024

### FPGA
Terasic MAX DE10-Lite

### Game Board

### Ball Movement
- Track X,Y Coords for current ball position
- Track velocity vector for direction and magnitude
  - X component and Y component
- Update next_<movement value> to move ball
- 
### Collision Detection
- If next_<movement value> would intersect a wall, adjust velocity and position accordingly
