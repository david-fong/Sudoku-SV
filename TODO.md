
# Things To Do

- Edit traversal paths to zig-zag where possible instead of making big jumps
  - Rationale: may help shorten hardware logic paths and improve timing.
- Check out RTL diagrams of synthesized logic to see if the hardware blocks are being generated as intended
  - Rowbias 1-hot arbiter selection of valtotry
- Change dimension definitions usages to params (length and area should be `localparam`s)
- optimization: make tile go back immediately if any later tile cannot be anything.

## Other Related Work

- https://dlbeer.co.nz/articles/sudoku.html
- https://github.com/t-dillon/tdoku
