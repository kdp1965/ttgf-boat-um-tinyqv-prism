![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# PRISM programmable FSM on GF180 (Tiny Tapeout BOAT)

- [Read the documentation for project](docs/info.md)

## What this is

PRISM (Programmable Reconfigurable Indexed State Machine) is a runtime-programmable
Mealy state machine with an 8-state execution table, a 24-bit counter / shifter, an
8-bit counter, a communication shift register, a small FIFO, interrupts and a
debugger.  An FSM written in Verilog is compiled into a configuration bitstream
("chroma") by a [Yosys fork](https://github.com/kdp1965/yosys-prism) and loaded
at run time.

The design is the TinyQV peripheral that went to the ttsky25a shuttle
(peripheral index 8, source in
[tinyqv-prism-lite](https://github.com/kdp1965/tinyqv-prism-lite)).  Here it is
hardened on its own on the GF180 "Best Of All Time" shuttle, driven through the
TinyQV peripheral test harness: a 32-bit SPI register interface on the `uio` pins
replaces the RISC-V bus.  The port to GF180 changed only the instantiated cells:

| sky130 cell | GF180 (`gf180mcu_fd_sc_mcu7t5v0`) cell | where |
|---|---|---|
| `dlxtp_1` latch | `latq_1` | configuration shift register, latch registers |
| `and2_1`, `or2_1/2/4` | `and2_1`, `or2_1/2/4` | latch enable / gate logic |
| `dlclkp_4` clock gate | `icgtp_4` | divide-by-2 clock (compiled out) |

## Layout

- `src/` RTL: `prism.v` (the state machine), `prism_periph.v` (registers,
  counters, shifter, FIFO, debugger), the latch-based configuration storage
  (`latch_shift_reg.v`, `latch_loader.v`, `prism_latch_reg.v`, `prism_*_sit.v`),
  `tt_wrapper.v` + `test_harness/` (the SPI register harness).
- `chromas/` example FSMs (rotary encoder, WS2812 driver, 24-bit GPIO expander,
  SPI slave) and the Makefile that compiles them with yosys-prism.
- `test/` cocotb test bench (`make` for RTL, `GATES=yes make` for the gate-level
  netlist); the Python classes in `tqv.py` / `tqv_reg.py` drive the SPI harness.
- `docs/info.md` the datasheet.

## Pins

`ui_in[6:0]` are the seven FSM inputs, `ui_in[7]` is a host-readable input,
`uo_out[7:1]` are the seven FSM outputs (`uo_out[0]` is unused).  `uio[4]` CS_n,
`uio[5]` SCK, `uio[6]` MOSI and `uio[3]` MISO form the SPI register port,
`uio[1]` is the SPI data-ready flag and `uio[0]` the interrupt output.

## Local hardening

The GDS action does this on push.  Locally, with the Tiny Tapeout tools in `tt/`
and a LibreLane install on the PATH:

    python tt/tt_tool.py --create-user-config --gf
    python -m librelane --pdk-root $PDK_ROOT --pdk gf180mcuD \
        --run-tag wokwi --force-run-dir runs/wokwi src/config_merged.json

## License

Apache-2.0, see [LICENSE](LICENSE).
