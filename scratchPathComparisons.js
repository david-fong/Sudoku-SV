/**
 * This is a quick mostly-by-hand comparison of gen paths for grids
 * of order 3. I may write something more formal in the future,
 * especially to see if rankings change with respect to grid order.
 *
 * These are arrays where each entry is the pessimistic number of
 * possible values a tile could take on, where the entries are in
 * the order of their corresponding tile's traversal-path-index.
 *
 * Computing the product of the entries gives an upper bound on the
 * number of possible permutations (including invalid sudoku solutions)
 * according to such a genpath. It is preferable when this value is
 * smaller than those of other genpaths.
 *
 * A comparative measure of how efficient the genpath is can be
 * calculated according to the sum after mapping each entry to (the
 * reciprocal of its value times its index), where lower results are
 * more preferable. This is according to the logic that a tile with
 * fewer possible options as a result of the genpath are more likely
 * to cause impossibilities the farther in the genpath order they are.
 *
 * NOTE: I'm not sure about the below assertions I made...
 *
 * If when making minute decisions on traversal path and some decision
 * will create more options and improve the result of the efficiency
 * calculation, choose the path that _does not_ create more options.
 * Ie. The efficiency calculation is not always an accurate measure-
 * especially when considered in isolation.
 *
 * In general, it's bad to see lots of ones at the end of the path.
 */
const GENPATHS = [
    {
        name: "rowmajor",
        pathOpts: [
            9,8,7, 6,5,4, 3,2,1,
            6,5,4, 6,5,4, 3,2,1,
            3,2,1, 3,2,1, 3,2,1,
            6,6,6, 6,5,4, 3,2,1,
            5,5,4, 5,5,4, 3,2,1,
            3,2,1, 3,2,1, 3,2,1,
            3,3,3, 3,3,3, 3,2,1,
            2,2,2, 2,2,2, 2,2,1,
            1,1,1, 1,1,1, 1,1,1,
        ],
    }, {
        name: "blockcol",
        pathOpts: [
            // 9,8,7, 6,5,4, 3,2,1,
            // 6,5,4, 6,5,4, 3,2,1,
            // 3,2,1, 3,2,1, 3,2,1,
            // 6,6,6, 6,5,4, 3,2,1,
            // 6,5,4, 5,5,4, 3,2,1,
            // 3,2,1, 3,2,1, 3,2,1,
            // 3,3,3, 3,3,3, 3,2,1,
            // 2,2,2, 2,2,2, 2,2,1,
            // 1,1,1, 1,1,1, 1,1,1,
            9,8,7,6,5,4,3,2,1,6,6,6,6,5,4,3,2,1,3,3,3,2,2,2,1,1,1,
            6,5,4,6,5,4,3,2,1,6,5,4,5,5,4,3,2,1,3,3,3,2,2,2,1,1,1,
            3,2,1,3,2,1,3,2,1,3,2,1,3,2,1,3,2,1,3,2,1,2,2,1,1,1,1,
        ],
    }, {
        // iterate over blocks in row-major fashion
        // (row,col): 0,0  0,3  0,6  3,0  3,3  3,6  6,0  6,3  6,6  0,1....
        name: "spread_rowmajor",
        pathOpts: [
            // 9,6,3,  8,5,2,  7,4,1,
            // 6,5,3,  6,5,2,  6,4,1,
            // 3,2,1,  3,2,1,  3,2,1,

            // 8,6,3,  8,5,2,  7,4,1,
            // 5,5,3,  5,5,2,  5,4,1,
            // 2,2,1,  2,2,1,  2,2,1,

            // 7,6,3,  7,5,2,  7,4,1,
            // 4,4,3,  4,4,2,  4,4,1,
            // 1,1,1,  1,1,1,  1,1,1,
            9,8,7,8,8,7,7,7,7,6,5,4,6,5,4,6,5,4,3,2,1,3,2,1,3,2,1,
            6,6,6,5,5,5,4,4,4,5,5,4,5,5,4,4,4,4,3,2,1,3,2,1,3,2,1,
            3,3,3,2,2,2,1,1,1,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,
        ],
    }, {
        name: "spread_triangle",
        pathOpts: [
            // Note: prefer middle of anti-diagonal within a block to
            // be visited last since the edges tend not to depend on it.
            // ex row1,col4 and row4,col4.

            // 9,6,3,  8,5,2,  7,4,1,
            // 6,4,3,  7,4,2,  7,4,1,
            // 3,2,1,  3,2,1,  3,2,1,

            // 8,7,3,  8,6,5,  7,5,1,
            // 5,4,2,  6,4,2,  7,4,1,
            // 2,2,1,  5,2,1,  2,2,1,

            // 7,7,3,  7,7,2,  7,7,1,
            // 4,4,2,  5,4,2,  7,4,1,
            // 1,1,1,  1,1,1,  1,1,1,
            9,8,8,7,7,8,7,7,7,
            6,6,5,5,7,7,4,4,7,7,6,6,5,5,7,7,7,7,
            3,3,4,2,2,3,3,4,4,1,1,3,3,4,4,5,5,4,1,1,2,2,3,3,1,1,4,
            3,2,2,2,2,2,1,1,2,2,2,2,1,1,2,2,1,1,
            1,1,1,1,1,1,1,1,1,
        ],
    }
];

console.log("efficiencyInverse 1 and 2 use difference inverting functions.");
console.table(GENPATHS.map((genpath) => {
    console.log("\n", genpath.name);
    genpath.pathOpts.forEach((numOpts) => {
        console.log("O".repeat(numOpts));
    });
    return {
        name: genpath.name,
        weakMaxNumPermutations: genpath.pathOpts
            .reduce((prev, next) => prev * next, 1),
        efficiencyInverse1: genpath.pathOpts
            .map((numOpts, index) => index / numOpts)
            .reduce((prev, next) => prev + next, 0),
        efficiencyInverse2: genpath.pathOpts
            .map((numOpts, index) => index * ((9 - numOpts + 1)/9))
            .reduce((prev, next) => prev + next, 0),
        averageOptsPerTile: genpath.pathOpts
            .reduce((prev, next) => prev + next, 0) / 81,
    };
}));