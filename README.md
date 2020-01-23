
# Sudoku written in SystemVerilog

### Table of Contents:

- preface
- how sudoku works
- using brute force
- hardware tricks

## Sudoku in a Nutshell

Sudoku is a common puzzle game often found in newspapers where the goal is to re-construct a square grid of symbols according to simple conflict rules. The grid is defined by a size argument _S_ which is typically three. The grid is composed of _S^4_ atomic containers that can carry one of the same _S^2_ unique symbols (typically the numbers one through _S^2_). The only rule is that no row, column, or block can contain duplicate symbols. In other words, each row, column, and block must contain one of each symbol.

Puzzles are computer-generated in such a way that there is at least enough starting information for there to be only one solution (ie. There are no two ways to complete the grid that produce the same arrangements of symbols). This can be done by brute-forcing the creation of a full solution, and then incrementally erasing symbols at random until any further erasure would allow for multiple valid completions of the grid.

The systematic processes of solving a puzzle and of generating a solution using backtracing (brute force) are actually the same. The defining differences are in how they start and end. When generating a solution, there is no starting information, and a very large (but computable and finite) number of possible completions. When solving a puzzle, there is at least enough starting information such that there is only one possible completion.

## Solution Space

The number of possible completions (symbol arrangements filling the grid that do not have to abide by conflict rules) is _(S^2)^(s^4)_, where the base is the number of symbols, and the exponent is the area of the grid.

The number of solutions (symbol arrangements filling the grid that abide by conflict rules) is much less than this.

Many solutions in the solutions space are symbolically or relationally equivalent. Swapping the symbolic identity of any two symbols in a solution produces another solution. To discount symbolic equivalence in the solution space, divide by the number of ways to symbolically permutate some solution, which is _(S^2)!_. Relational equivalence has to do with how a symbol positionally relates to other symbols in a solution. Two symbols are positionally related if they are in the same row, column, or block. Certain operations do not change symbol relatedness: Swapping columns or rows of blocks, swapping columns or rows within block boundaries, and rotating the entire grid. The number of ways to symbolically permutate some solution is _(S!)^4 \* 4_.

## Time Complexity




