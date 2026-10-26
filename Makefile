# Local flow for the GF180 PRISM tile (what the Tiny Tapeout GDS action does).
#
# Tools: the LibreLane nix shell (NIX_SHELL), the Tiny Tapeout support tools
# checked out in tt/ (git-ignored) with their own venv (.venv-tt, git-ignored),
# and PDK_ROOT holding gf180mcuD.
#     git clone -b ttgf26c https://github.com/TinyTapeout/tt-support-tools tt
#     make venv
#     make harden
NIX_SHELL ?= ../../DFFRAM.librelane/shell.nix
PDK_ROOT  ?= $(HOME)/projects/fossi
PYTHON    ?= python3.12
ifeq ($(IN_NIX_SHELL),)
RUN = nix-shell $(NIX_SHELL) --run
else
RUN = sh -c
endif
# tt_tool.py uses gitpython, which must find a native git (the nix one), and
# shells out to yowasp-yosys from its venv.
TT_PY = export GIT_PYTHON_GIT_EXECUTABLE=$$(which git); PATH=$$PATH:$(CURDIR)/.venv-tt/bin .venv-tt/bin/python

.PHONY: venv config harden test gl gui klayout clean

venv:
	$(PYTHON) -m venv .venv-tt
	.venv-tt/bin/python -m pip install --quiet --upgrade pip
	.venv-tt/bin/python -m pip install --quiet -r tt/requirements.txt

# info.yaml + src/config.json -> src/user_config.json + src/config_merged.json
config:
	$(RUN) "$(TT_PY) tt/tt_tool.py --create-user-config --gf"

harden: config
	rm -rf runs/wokwi && mkdir -p runs/wokwi
	$(RUN) "export PDK_ROOT=$(PDK_ROOT); python -m librelane --pdk-root $(PDK_ROOT) --pdk gf180mcuD --run-tag wokwi --force-run-dir runs/wokwi src/config_merged.json" 2>&1 | tee harden.log

# RTL simulation (cocotb + Icarus, not from the nix shell)
test:
	$(MAKE) -C test

# Gate-level simulation of the hardened netlist
gl:
	cp runs/wokwi/final/pnl/*.pnl.v test/gate_level_netlist.v
	PDK_ROOT=$(PDK_ROOT) GATES=yes $(MAKE) -C test

gui:
	$(RUN) "openroad -gui -no_init -db $(firstword $(wildcard runs/wokwi/final/odb/*.odb))"

klayout:
	$(RUN) "klayout $(firstword $(wildcard runs/wokwi/final/gds/*.gds))"

clean:
	rm -rf test/sim_build test/results.xml test/*.vcd test/*.fst
