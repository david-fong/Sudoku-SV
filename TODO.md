
# Things To Do

- Edit traversal paths to zig-zag where possible instead of making big jumps
  - Rationale: may help shorten hardware logic paths and improve timing.
- Check out RTL diagrams of synthesized logic to see if the hardware blocks are being generated as intended
  - Rowbias 1-hot arbiter selection of valtotry
- Change dimension definitions usages to params (length and area should be `localparam`s)
- optimization: make tile go back immediately if any later tile cannot be anything.
  - Nuance: Only use these "alert" signals from tiles that can only ever have up to 1 or 2 possible options,
    - Only ever send these alerts to the group of tiles preceding (in terms of genpath) the group described above.

## Other Related Work

- https://dlbeer.co.nz/articles/sudoku.html
- https://github.com/t-dillon/tdoku
