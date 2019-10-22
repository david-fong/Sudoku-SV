
# Sudoku written in SystemVerilog

### contents:

- how sudoku works
- using brute force
- hardware tricks


## how sudoku works:

sudoku is a popular puzzle game where the goal is to re-construct a grid of highly structured numbers. the grid is defined by its size _s_, which typically has the value three. the grid has dimensions _l_ equals to _s^2_, and area _a_ equals to _l^2_. I will refer to each atomic square in the grid as a _tile_. it has three types of groups: those aligned to columns, to rows, and to blocks. for each group type, there are _l_ of those groups each enclosing _l_ tiles with no overlap between groups of the same type. blocks are squares with dimensions _s_, aligned to the grid borders. a standard solution to a sudoku puzzle has the following properties: each group of each group type (ie. each row, each column, and each block) contains one of each number from 1 to _l_ inclusive.

a puzzle is a solution with information previously removed in such a way that there is guaranteed to only be one possible solution. the process of generating a solution involves creating a solution (which by definition must follow the above rules), which necessitates some amount of brute force, and then incrementally removing information from tiles to create a puzzle (which must also follow the previous rules according to its definition), which also necessitates some brute force.

perhaps surprising is the fact that the procedure to generate a solution by brute force can be used to solve a puzzle after it is created, and also to verify that a puzzle has a single solution during the puzzle generation process. once a puzzle is generated, it is difficult to quantify whether or not it will be difficult for a person to solve, but this is outside the scope of this project and discussion.

this project will focus particularly on the solution-generation process, and even use some tricks for this that will cause its design not to be directly usable for puzzle solving.



## using brute force:

in solution generation, brute force is necessary. this may sound like a bad thing (at least- it feels that way to me): brute force can possibly spend a lot of effort on something that eventually will not work. there are two things I think of to ease my mind on this: for one, I see no other way. the only way I see to create a solution without brute force is to directly copy another existing solution (although I also keep in mind the times I have been wrong about things I once felt quite sure of something). 

* worst case time complexity. some discussion on NP-complete problems.
* notes on randomness



## here's the plan:

* discussion on using tiles with individual statemachines- a decentralized approach.



