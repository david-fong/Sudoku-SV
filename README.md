
# Sudoku written in SystemVerilog

### contents:

- preface
- how sudoku works
- using brute force
- hardware tricks





## preface:

I like to feel smart. but trying to feel smart has not helped me in the past to learn new things (the same is true for the opposite extreme of accepting the things about myself I would like to improve). so, I feel obliged to say that this project is not special because it was undertaken by an expert in mathematics, or a master of hardware design, or even by someone good at playing sudoku. _this_ project of all sudoku projects is only special because it is special to me- because I am interested in it and like to spend some of my free time thinking about it. I embrace that. I will talk about my thoughts and feelings, and about the things I have learned from past stabs at solving this problem well. I will try to keep this short without sacrificing those things.





## how sudoku works:

sudoku is a popular puzzle game where the goal is to re-construct a grid of highly structured numbers. the grid is defined by its "size" / "order" _o_, which typically has the value three. the grid has dimensions _l_ equal to _o_ ^ 2, and area _a_ equal to _l_ ^ 2. I will refer to each atomic square in the grid as a _tile_. the grid has three types of groups: those aligned to columns, to rows, and to blocks. for each group type, there are _l_ of those groups each enclosing _l_ tiles with no overlap between groups of the same type. blocks are square-shaped with dimensions _o_, aligned to the grid borders. a standard solution to a sudoku puzzle has the following properties: each group of each group type (ie. each row, each column, and each block) contains exactly one of each number from 1 to _l_ inclusive. in other words, each tile must contain one of the numbers from 1 to _l_ inclusive, and no group may contain two tiles with the same value.

a puzzle is a solution with information previously removed in such a way that there is guaranteed to only be one possible solution. the process of generating a solution involves creating a solution (which by definition must follow the above rules), which necessitates some amount of brute force, and then incrementally removing information from tiles to create a puzzle (which must also follow the previous rules according to its definition), which also necessitates some brute force.

perhaps surprising is the fact that the procedure to generate a solution by brute force can be used to solve a puzzle after it is created, and also to verify that a puzzle has a single solution during the puzzle generation process. once a puzzle is generated, it is difficult to quantify whether or not it will be difficult for a person to solve, but this is outside the scope of this project and discussion. this project will focus particularly on the solution-generation process, but keep in mind that it is at the same time usable in generating puzzles and in solving them.





## using brute force:

#### some thoughts:

in solution generation, brute force is necessary. this may sound like a bad thing. at least- it feels that way to me. brute force can possibly spend a lot of effort on something that eventually will not work out. there are two things I think of to ease my mind on this:
- on uncertainty: for one thing, I see no other way. (although I also keep in mind the times I felt quite sure of something and found out I was wrong). going down some wrong paths is inevitable. you cannot be sure how bad they may be, but you can be certain that they will happen. perhaps this bothers me about sudoku because it also bothers me about life, for which I am trying to convince my mind of the same thing.
- on elegance: another thing that I've been thinking about is the line that separates brute force and what in my mind is "intelligent" or "elegant" thinking. I dislike brute force because it feel inelegant. when I come to a point where I don't know how to continue without trying something that might not work, I wonder if I'm just missing some clever logical deduction, and that's the point when I give up and try a different puzzle. however, I don't believe that all sudoku puzzles can be solved with logical deductions. so for the sake of my sanity, I now believe that elegance is not in doing everything logically, but in being aware of what can be done logically, and having grit, faith, and a healthy amount of optimism for the rest that requires it. I include faith- because the solution is there. it's just that it requires searching for.


### how it's done:

enough talk and feelings :) how is brute force solution generation done? the basic procedure is quite simple. I haven't done much reading on this subject so I can only speak from the things I have found out from practice.


#### initialization steps:

1. start with an empty grid. ie. here, each tile has _l_ + 1 possible values: the integers between 1 and _l_ inclusive, and the special value, "empty".
1. decide on a tile traversal-order. the order can be arbitrary, but must remain constant throughout the whole process. in software, following row-major order is convenient and performs well (compared to other orders, including random orders).
1. decide on each tile's value-order. that is- in what order will it try on each value (excluding the special "empty" value). in a naive implementation, all tiles choose sequential order. the problem with this is that the generated solutions are 100% predictable, and also follows a pattern that make it less interesting for a player who notices that pattern to solve. giving a random value-order to each tile produces solutions with no apparant pattern, which is highly desireable, but also incurs significant space overhead. I have found sharing a value-order between groups of a chosen group-type to be an effective balance. we can leverage some nice properties later if the chosen group-type aligns to the traversal-order chosen in the previous step.
1. optionally seed some times with random values. I say random, but if this step is to be done, it must be done carefully. you must be absolutely certain that the seeds will not create a situation where no solution exists, and your seeds must still follow the rules on what makes a valid solution. a safe example, is to seed all tiles in blocks along the main diagonal. this means that for all unseeded tiles, there is an optimistic worst-case number of remaining value candidates equal to _l_ - 2 * _o_, which, for _o_ > 2, is always greater than zero. I say optimistic because there is no guarantee that any remaining solutions exist, and because I haven't tried to prove whether or not remaing solutions are guaranteeed. but in practice, I have always found there to be more than enough remaining options (even at _o_ equals three) to find a solution. in fact, I have measured performance with seeding to be slightly better than without, but I suspect that those benefits are trivial and become harder to reap as _o_ increases. this is something worthy of further work! it currently is not the focus of my interest.


#### traversal steps:

1. 


#### remarks:

- only one tile is "active" (trying values) at a time. any attempt at parallelization without using separate grids will result in skipped outcomes.


#### time complexity:

if we continue with the assumption that it takes constant time to check whether a value can be tried for a tile, and treat each trying of a value in a tile as a single unit of time, then we can calculate and bound the absolute-worst-case time complexity as so:

each tile can have _l_ values, and there are _a_ tiles. this means there are _l_ ^ _a_ permutations (most of which will not be followed to the end due to how we short circuit on a non-working value). this equals (_o_ ^ 2) ^ (_o_ ^ 4), which simplifies to (_o_ ^ (2 * _o_ ^ 4)). that is, the absolute-worst-case time complexity can be bounded by (_o_ ^ (2 * _o_ ^ 4)).

the limitation of software is that a single tile cannot find a a value that is not guaranteed to fail in a constant amount of time. in other words, with some book-keeping, it can check if a value is guaranteed to fail in a constant amount of time, but it doesn't have high-level support for arbiting bits, which would allow it to find a value that to try that will succeed without instruction-level iteration.

but we don't have that limitation with hardware! let's now imagine that we traverse by rows, that tiles in the same row share the same value-order, and that with hardware, we can instantaneously avoid testing for values that are already in the row. then the number of test operations we perform is bounded by the product of the number of tests that will be performed per row. that is, ((_o_ ^ 2)!) ^ (_o_ ^ 2).

* some discussion on NP-complete problems.





## here's the plan:

* discussion on using tiles with individual statemachines- a decentralized approach.



