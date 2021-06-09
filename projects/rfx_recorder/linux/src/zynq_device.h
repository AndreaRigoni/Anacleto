#ifndef ZYNQ_DEVICE_H
#define ZYNQ_DEVICE_H


#include <linux/types.h>
#include <asm/ioctl.h>



#ifdef __cplusplus
extern "C" {
#endif

#define DEVICE_NAME "zynq_device"  /* Dev name as it appears in /proc/devices */
#define MODULE_NAME "zynq_device"

//Generic IOCTL commands  

#define ZYNQ_DEVICE_IOCTL_BASE	'W'
#define ZYNQ_DEVICE_ARM_DMA    			_IO(ZYNQ_DEVICE_IOCTL_BASE, 1)
#define ZYNQ_DEVICE_START_DMA     		_IO(ZYNQ_DEVICE_IOCTL_BASE, 2)
#define ZYNQ_DEVICE_STOP_DMA     		_IO(ZYNQ_DEVICE_IOCTL_BASE, 3)
#define ZYNQ_DEVICE_SET_DMA_BUFLEN     		_IO(ZYNQ_DEVICE_IOCTL_BASE, 4)
#define ZYNQ_DEVICE_GET_DMA_BUFLEN     		_IO(ZYNQ_DEVICE_IOCTL_BASE, 5)
#define ZYNQ_DEVICE_SET_DRIVER_BUFLEN     	_IO(ZYNQ_DEVICE_IOCTL_BASE, 6)
#define ZYNQ_DEVICE_GET_DRIVER_BUFLEN     	_IO(ZYNQ_DEVICE_IOCTL_BASE, 7)
#define ZYNQ_DEVICE_GET_CONFIGURATION		_IO(ZYNQ_DEVICE_IOCTL_BASE, 8)
#define ZYNQ_DEVICE_SET_CONFIGURATION		_IO(ZYNQ_DEVICE_IOCTL_BASE, 9)
#define ZYNQ_DEVICE_GET_COMMAND_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 10)
#define ZYNQ_DEVICE_SET_COMMAND_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 11)
#define ZYNQ_DEVICE_GET_DECIMATOR_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 12)
#define ZYNQ_DEVICE_SET_DECIMATOR_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 13)
#define ZYNQ_DEVICE_GET_MODE_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 14)
#define ZYNQ_DEVICE_SET_MODE_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 15)
#define ZYNQ_DEVICE_GET_PACKETIZER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 16)
#define ZYNQ_DEVICE_SET_PACKETIZER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 17)
#define ZYNQ_DEVICE_GET_PRE_POST_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 18)
#define ZYNQ_DEVICE_SET_PRE_POST_REGISTER		_IO(ZYNQ_DEVICE_IOCTL_BASE, 19)
  


enum AxiStreamFifo_Register {
    ISR   = 0x00,   ///< Interrupt Status Register (ISR)
    IER   = 0x04,   ///< Interrupt Enable Register (IER)
    TDFR  = 0x08,   ///< Transmit Data FIFO Reset (TDFR)
    TDFV  = 0x0c,   ///< Transmit Data FIFO Vacancy (TDFV)
    TDFD  = 0x10,   ///< Transmit Data FIFO 32-bit Wide Data Write Port
    TDFD4 = 0x1000, ///< Transmit Data FIFO for AXI4 Data Write Port
    TLR   = 0x14,   ///< Transmit Length Register (TLR)
    RDFR  = 0x18,   ///< Receive Data FIFO reset (RDFR)
    RDFO  = 0x1c,   ///< Receive Data FIFO Occupancy (RDFO)
    RDFD  = 0x20,   ///< Receive Data FIFO 32-bit Wide Data Read Port (RDFD)
    RDFD4 = 0x1000, ///< Receive Data FIFO for AXI4 Data Read Port (RDFD)
    RLR   = 0x24,   ///< Receive Length Register (RLR)
    SRR   = 0x28,   ///< AXI4-Stream Reset (SRR)
    TDR   = 0x2c,   ///< Transmit Destination Register (TDR)
    RDR   = 0x30,   ///< Receive Destination Register (RDR)
    /// not supported yet .. ///
    TID   = 0x34,   ///< Transmit ID Register
    TUSER = 0x38,   ///< Transmit USER Register
    RID   = 0x3c,   ///< Receive ID Register
    RUSER = 0x40    ///< Receive USER Register
};

enum AxiStreamFifo_ISREnum {
    ISR_RFPE = 1 << 19,  ///< Receive FIFO Programmable Empty
    ISR_RFPF = 1 << 20,  ///< Receive FIFO Programmable Full
    ISR_TFPE = 1 << 21,  ///< Transmit FIFO Programmable Empty
    ISR_TFPF = 1 << 22,  ///< Transmit FIFO Programmable Full
    ISR_RRC = 1 << 23,   ///< Receive Reset Complete
    ISR_TRC = 1 << 24,   ///< Transmit Reset Complete
    ISR_TSE = 1 << 25,   ///< Transmit Size Error
    ISR_RC = 1 << 26,    ///< Receive Complete
    ISR_TC = 1 << 27,    ///< Transmit Complete
    ISR_TPOE = 1 << 28,  ///< Transmit Packet Overrun Error
    ISR_RPUE = 1 << 29,  ///< Receive Packet Underrun Error
    ISR_RPORE = 1 << 30, ///< Receive Packet Overrun Read Error
    ISR_RPURE = 1 << 31, ///< Receive Packet Underrun Read Error
};

enum RegisterIdx {
    FIFO_00_IDX = 0,
    FIFO_01_IDX = 1,
    FIFO_10_IDX = 2,
    FIFO11_IDX = 3,
    COMMAND_REG_IDX = 4,
    PRE_POST_REG_IDX = 5,
    DEC_REG_IDX = 6,
    MODE_REG_IDX = 8
};


#pragma pack(1)

struct zynq_device_conf
{
    u32 bufSize;
    u32 dmaBufSize;
    	char command_register_enable;
	u32 command_register;
	char decimator_register_enable;
	u32 decimator_register;
	char mode_register_enable;
	u32 mode_register;
	char packetizer_enable;
	u32 packetizer;
	char pre_post_register_enable;
	u32 pre_post_register;

};



#ifdef __cplusplus
}
#endif

#endif // ZYNQ_DEVICE_H
