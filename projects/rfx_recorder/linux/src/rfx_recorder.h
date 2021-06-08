#ifndef RFX_RECORDER_H
#define RFX_RECORDER_H


#include <linux/types.h>
#include <asm/ioctl.h>



#ifdef __cplusplus
extern "C" {
#endif

//Temporaneo
#define DMA_SOURCE 1
////////////////


#define DEVICE_NAME "rfx_recorder"  /* Dev name as it appears in /proc/devices */
#define MODULE_NAME "rfx_recorder"

//Generic IOCTL commands  

#define RFX_RECORDER_IOCTL_BASE	'W'
#define RFX_RECORDER_ARM_DMA    			_IO(RFX_RECORDER_IOCTL_BASE, 1)
#define RFX_RECORDER_START_DMA     		_IO(RFX_RECORDER_IOCTL_BASE, 2)
#define RFX_RECORDER_STOP_DMA     			_IO(RFX_RECORDER_IOCTL_BASE, 3)
#define RFX_RECORDER_SET_DMA_BUFLEN     		_IO(RFX_RECORDER_IOCTL_BASE, 4)
#define RFX_RECORDER_GET_DMA_BUFLEN     		_IO(RFX_RECORDER_IOCTL_BASE, 5)
#define RFX_RECORDER_IS_DMA_RUNNING     		_IO(RFX_RECORDER_IOCTL_BASE, 6)
#define RFX_RECORDER_GET_DMA_DATA     		_IO(RFX_RECORDER_IOCTL_BASE, 7)
#define RFX_RECORDER_SET_DRIVER_BUFLEN     	_IO(RFX_RECORDER_IOCTL_BASE, 8)
#define RFX_RECORDER_GET_DRIVER_BUFLEN     	_IO(RFX_RECORDER_IOCTL_BASE, 9)
#define RFX_RECORDER_GET_REGISTERS			_IO(RFX_RECORDER_IOCTL_BASE, 10)
#define RFX_RECORDER_SET_REGISTERS			_IO(RFX_RECORDER_IOCTL_BASE, 11)
#define RFX_RECORDER_FIFO_INT_HALF_SIZE		_IO(RFX_RECORDER_IOCTL_BASE, 12)
#define RFX_RECORDER_FIFO_INT_FIRST_SAMPLE		_IO(RFX_RECORDER_IOCTL_BASE, 13)
#define RFX_RECORDER_FIFO_FLUSH			_IO(RFX_RECORDER_IOCTL_BASE, 14)
#define RFX_RECORDER_START_READ			_IO(RFX_RECORDER_IOCTL_BASE, 15)
#define RFX_RECORDER_STOP_READ			_IO(RFX_RECORDER_IOCTL_BASE, 16)
#define RFX_RECORDER_GET_AUTOZERO_MUL_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 20)
#define RFX_RECORDER_SET_AUTOZERO_MUL_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 21)
#define RFX_RECORDER_GET_AUTOZERO_SMP_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 22)
#define RFX_RECORDER_SET_AUTOZERO_SMP_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 23)
#define RFX_RECORDER_GET_COMMAND_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 24)
#define RFX_RECORDER_SET_COMMAND_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 25)
#define RFX_RECORDER_GET_DECIMATOR_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 26)
#define RFX_RECORDER_SET_DECIMATOR_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 27)
#define RFX_RECORDER_GET_DMA_SIZE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 28)
#define RFX_RECORDER_SET_DMA_SIZE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 29)
#define RFX_RECORDER_GET_EVENT_CODE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 30)
#define RFX_RECORDER_SET_EVENT_CODE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 31)
#define RFX_RECORDER_GET_MODE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 32)
#define RFX_RECORDER_SET_MODE_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 33)
#define RFX_RECORDER_GET_PTS_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 34)
#define RFX_RECORDER_SET_PTS_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 35)
#define RFX_RECORDER_GET_STREAM_DECIMATOR_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 36)
#define RFX_RECORDER_SET_STREAM_DECIMATOR_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 37)
#define RFX_RECORDER_GET_AUTOZERO_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 38)
#define RFX_RECORDER_SET_AUTOZERO_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 39)
#define RFX_RECORDER_GET_COUNTER_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 40)
#define RFX_RECORDER_SET_COUNTER_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 41)
#define RFX_RECORDER_GET_STATUS_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 42)
#define RFX_RECORDER_SET_STATUS_REGISTER		_IO(RFX_RECORDER_IOCTL_BASE, 43)
#define RFX_RECORDER_GET_STREAM_FIFO_LEN		_IO(RFX_RECORDER_IOCTL_BASE, 44)
#define RFX_RECORDER_GET_STREAM_FIFO_VAL		_IO(RFX_RECORDER_IOCTL_BASE, 45)
#define RFX_RECORDER_CLEAR_STREAM_FIFO		_IO(RFX_RECORDER_IOCTL_BASE, 46)
  

#ifndef AXI_ENUMS_DEFINED
#define AXI_ENUMS_DEFINED
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
#endif

#pragma pack(1)

struct rfx_recorder_registers
{
    	char autozero_mul_register_enable;
	unsigned int autozero_mul_register;
	char autozero_smp_register_enable;
	unsigned int autozero_smp_register;
	char command_register_enable;
	unsigned int command_register;
	char decimator_register_enable;
	unsigned int decimator_register;
	char dma_size_register_enable;
	unsigned int dma_size_register;
	char event_code_register_enable;
	unsigned int event_code_register;
	char mode_register_enable;
	unsigned int mode_register;
	char pts_register_enable;
	unsigned int pts_register;
	char stream_decimator_register_enable;
	unsigned int stream_decimator_register;
	char autozero_register_enable;
	unsigned int autozero_register;
	char counter_register_enable;
	unsigned int counter_register;
	char status_register_enable;
	unsigned int status_register;

};



#ifdef __cplusplus
}
#endif

#endif // RFX_RECORDER_H
