
# Things To Do

- Find out why BLOCK_COL genpath seems to not be working.
- Get closer to meeting timing requirements by spacing out initialization in rowbias module.
  - Add signals to waveform viewer and debug from there.
- Edit traversal paths to zig-zag where possible instead of making big jumps
  - Rationale: may help shorten hardware logic paths and improve timing.
  - See if this is actually helping... The logic is complex so the fitter is having a hard time.
- Remove inferred divider/modulo blocks from rowbias module
  - Rationale: They are costing a lot of ALUT's
- Check out RTL diagrams of synthesized logic to see if the hardware blocks are being generated as intended
  - Rowbias 1-hot arbiter selection of valtotry
- Change dimension definitions usages to params (length and area should be `localparam`s)
- optimization: make tile go back immediately if any later tile cannot be anything.
  - Nuance: Only use these "alert" signals from tiles that can only ever have up to 1 or 2 possible options,
    - Only ever send these alerts to the group of tiles preceding (in terms of genpath) the group described above.

## Other Related Work

- https://dlbeer.co.nz/articles/sudoku.html
- https://github.com/t-dillon/tdoku
