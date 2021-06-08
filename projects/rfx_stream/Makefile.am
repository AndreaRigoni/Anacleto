include $(top_srcdir)/Common.mk
include $(top_srcdir)/fpga/Common.mk

FPGA_REPO_DIR   += $(top_builddir)/fpga/lib/red-pitaya-notes
FPGA_REPO_DIR   += $(top_builddir)/fpga/lib/rfx

VENDOR = rfx

## PROJECTS ##


export DEVICE_BOOT_DIR = /root/rfx_stream
export DEVICE_MODULES_DIR = /root/rfx_stream

vivado_PROJECTS = stream_10 stream 

stream_SOURCES = red_pitaya.xdc \
                 src/trarec.vhdl \
                 src/trarec_tb.vhdl \
		 src/resampler.vhdl \
		 src/timing_highway.vhdl

stream_10_SOURCES = red_pitaya_10.xdc \
                 src/trarec.vhdl \
                 src/trarec_tb.vhdl \
                 src/resampler.vhdl \
                 src/timing_highway.vhdl

patch: ##@hsi fix the system-top.dts for usb support on redpitaya (must be triggered before dts)
patch:
	patch  -u -b edit/red_pitaya/rfx_stream_0.1.sdk/dts/system-top.dts -i prj/red_pitaya/patches/system-top.patch
	patch  -u -b edit/red_pitaya/rfx_stream_10.sdk/dts/system-top.dts -i prj/red_pitaya/patches/system-top.patch

.PHONY: linux
linux:
	$(MAKE) $(AM_MAKEFLAGS) -C linux/src clean all

shell:
	ssh $(DEVICE_USER)@$(DEVICE_IP)

all: dtb linux
