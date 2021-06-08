include $(top_srcdir)/Common.mk
include $(top_srcdir)/fpga/Common.mk

FPGA_REPO_DIR   += $(top_builddir)/fpga/lib/red-pitaya-notes
FPGA_REPO_DIR   += $(top_builddir)/fpga/lib/rfx

VENDOR = rfx

## PROJECTS ##

export DEVICE_BOOT_DIR = /root/rfx_recorder
export DEVICE_MODULES_DIR = /root/rfx_recorder

vivado_PROJECTS = recorder

recorder_SOURCES = red_pitaya.xdc \
                 src/trarec.vhdl \
                 src/trarec_tb.vhdl \
                 src/recorder.vhdl \
		 src/resampler.vhdl \
		 src/timing_highway.vhdl



.PHONY: linux
linux:
	$(MAKE) $(AM_MAKEFLAGS) -C linux/src clean all

shell:
	ssh $(DEVICE_USER)@$(DEVICE_IP)

all: dtb linux
