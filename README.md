
# Sudoku written in SystemVerilog

### contents:

- preface
- how sudoku works
- using brute force
- hardware tricks



## preface:

I like to feel smart. but trying to feel smart has not helped me in the past to learn new things (the same is true for the opposite extreme of accepting the things about myself I would like to improve). so, I feel obliged to say that this project is not special because it was undertaken by an expert in mathematics, or a master of hardware design, or even by someone good at playing sudoku. _this_ project of all sudoku projects is only special because it is special to me- because I am interested in it and like to spend some of my free time thinking about it. I embrace that. I will talk about my thoughts and feelings, and about the things I have learned from past stabs at solving this problem well. I will try to keep this short without sacrificing those things.



## how sudoku works:

sudoku is a popular puzzle game where the goal is to re-construct a grid of highly structured numbers. the grid is defined by its size _s_, which typically has the value three. the grid has dimensions _l_ equal to _s^2_, and area _a_ equal to _l^2_. I will refer to each atomic square in the grid as a _tile_. the grid has three types of groups: those aligned to columns, to rows, and to blocks. for each group type, there are _l_ of those groups each enclosing _l_ tiles with no overlap between groups of the same type. blocks are square-shaped with dimensions _s_, aligned to the grid borders. a standard solution to a sudoku puzzle has the following properties: each group of each group type (ie. each row, each column, and each block) contains exactly one of each number from 1 to _l_ inclusive. in other words, each tile must contain one of the numbers from 1 to _l_ inclusive, and no group may contain two tiles with the same value.

a puzzle is a solution with information previously removed in such a way that there is guaranteed to only be one possible solution. the process of generating a solution involves creating a solution (which by definition must follow the above rules), which necessitates some amount of brute force, and then incrementally removing information from tiles to create a puzzle (which must also follow the previous rules according to its definition), which also necessitates some brute force.

perhaps surprising is the fact that the procedure to generate a solution by brute force can be used to solve a puzzle after it is created, and also to verify that a puzzle has a single solution during the puzzle generation process. once a puzzle is generated, it is difficult to quantify whether or not it will be difficult for a person to solve, but this is outside the scope of this project and discussion. this project will focus particularly on the solution-generation process, but keep in mind that it is at the same time usable in generating puzzles and in solving them.



## using brute force:

in solution generation, brute force is necessary. this may sound like a bad thing. at least- it feels that way to me. brute force can possibly spend a lot of effort on something that eventually will not work out. there are two things I think of to ease my mind on this:
- on uncertainty: for one thing, I see no other way. (although I also keep in mind the times I felt quite sure of something and found out I was wrong). going down some wrong paths is inevitable. you cannot be sure how bad they may be, but you can be certain that they will happen. perhaps this bothers me about sudoku because it also bothers me about life, for which I am trying to convince my mind of the same thing.
- on elegance: another thing that I've been thinking about is the line that separates brute force and what in my mind is "intelligent" or "elegant" thinking. I dislike brute force because it feel inelegant. when I come to a point where I don't know how to continue without trying something that might not work, I wonder if I'm just missing some clever logical deduction, and that's the point when I give up and try a different puzzle. however, I don't believe that all sudoku puzzles can be solved with logical deductions. so for the sake of my sanity, I now believe that elegance is not in doing everything logically, but in being aware of what can be done logically, and having grit, faith, and a healthy amount of optimism for the rest that requires it. I include faith- because the solution is there. it's just that it requires searching for.

enough talk and feelings :) how is brute force solution generation done?

* worst case time complexity. some discussion on NP-complete problems.
* notes on randomness



## here's the plan:

* discussion on using tiles with individual statemachines- a decentralized approach.



