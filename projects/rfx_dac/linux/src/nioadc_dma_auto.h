#ifndef $$DEVICE_NAME_U$$_H
#define $$DEVICE_NAME_U$$_H


#include <linux/types.h>
#include <asm/ioctl.h>



#ifdef __cplusplus
extern "C" {
#endif

#define DEVICE_NAME "$$DEVICE_NAME_L$$"  /* Dev name as it appears in /proc/devices */
#define MODULE_NAME "$$DEVICE_NAME_L$$"

//Generic IOCTL commands  

#define $$DEVICE_NAME_U$$_IOCTL_BASE	'W'
#define $$DEVICE_NAME_U$$_ARM_DMA    			_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 1)
#define $$DEVICE_NAME_U$$_START_DMA     		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 2)
#define $$DEVICE_NAME_U$$_STOP_DMA     		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 3)
#define $$DEVICE_NAME_U$$_SET_DMA_BUFLEN     		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 4)
#define $$DEVICE_NAME_U$$_GET_DMA_BUFLEN     		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 5)
#define $$DEVICE_NAME_U$$_SET_DRIVER_BUFLEN     	_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 6)
#define $$DEVICE_NAME_U$$_GET_DRIVER_BUFLEN     	_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 7)
#define $$DEVICE_NAME_U$$_GET_CONFIGURATION		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 8)
#define $$DEVICE_NAME_U$$_SET_CONFIGURATION		_IO($$DEVICE_NAME_U$$_IOCTL_BASE, 9)
#define NIOADC_DMA_AUTO_GET_COMMAND_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 10)
#define NIOADC_DMA_AUTO_SET_COMMAND_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 11)
#define NIOADC_DMA_AUTO_GET_DECIMATOR_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 12)
#define NIOADC_DMA_AUTO_SET_DECIMATOR_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 13)
#define NIOADC_DMA_AUTO_GET_MODE_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 14)
#define NIOADC_DMA_AUTO_SET_MODE_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 15)
#define NIOADC_DMA_AUTO_GET_PACKETIZER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 16)
#define NIOADC_DMA_AUTO_SET_PACKETIZER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 17)
#define NIOADC_DMA_AUTO_GET_PRE_POST_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 18)
#define NIOADC_DMA_AUTO_SET_PRE_POST_REGISTER		_IO(NIOADC_DMA_AUTO_IOCTL_BASE, 19)
  


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

struct $$DEVICE_NAME_L$$_conf
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

#endif // $$DEVICE_NAME_U$$_H
