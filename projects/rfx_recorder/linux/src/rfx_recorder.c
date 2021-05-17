#define HAS_FIFO_INTERRUPT
#define HAS_DMA

#include <linux/module.h>
#include <linux/version.h>
#include <linux/kernel.h>
#include <linux/mm.h>
#include <linux/vmalloc.h>

#include <linux/io.h>
#include <linux/ptrace.h>

#include <asm/uaccess.h>  // put_user
#include <asm/pgtable.h>

#include <linux/fs.h>

#include <linux/platform_device.h>

#include <linux/interrupt.h>
#include <linux/poll.h>

#include "rfx_recorder.h"

#include <linux/dmaengine.h>         // dma api
#include <linux/dma/xilinx_dma.h>   // axi dma driver


#include <asm/io.h>
#include <linux/semaphore.h>
#include <linux/spinlock.h>
#include <linux/slab.h>
#include <linux/cdev.h>
#include <linux/delay.h>

#define SUCCESS 0
#define FIFO_LEN 16384

//static struct platform_device *s_pdev = 0;
// static int s_device_open = 0;
static int device_open(struct inode *, struct file *);
static int device_release(struct inode *, struct file *);
static ssize_t device_read(struct file *, char *, size_t, loff_t *);
static ssize_t device_write(struct file *, const char *, size_t, loff_t *);
static int device_mmap(struct file *filp, struct vm_area_struct *vma);
static loff_t memory_lseek(struct file *file, loff_t offset, int orig);
static long device_ioctl(struct file *file, unsigned int cmd, unsigned long arg);
static unsigned int device_poll(struct file *file, struct poll_table_struct *p);

static int deviceAllocated = 0;

static struct file_operations fops = {
    .read = device_read,
    .write = device_write,
    .open = device_open,
    .release = device_release,
    .mmap = device_mmap,
    .llseek = memory_lseek,
    .unlocked_ioctl = device_ioctl,
    .poll = device_poll,
};

#define MAX_DMA_BUFFERS 80
#define DMA_BUFSIZE 1600000

struct rfx_recorder_dev {
    struct platform_device *pdev;
    struct cdev cdev;
    int busy;
    int irq;
    
    	void * iomap_command_register;
	void * iomap_decimator_register;
	void * iomap_dma_size_register;
	void * iomap_event_code_register;
	void * iomap_mode_register;
	void * iomap_pts_register;
	void * iomap_stream_decimator_register;
	void * iomap_counter_register;
	void * iomap_status_register;
	void * iomap_stream_fifo;
	void * iomap1_stream_fifo;

    
    struct semaphore sem;     /* mutual exclusion semaphore     */
    spinlock_t spinLock;     /* spinlock     */
    spinlock_t checkSpinLock;     /* spinlock     */
    u32 *fifoBuffer;
    u32 bufSize;
    u32 rIdx, wIdx, bufCount;
    wait_queue_head_t readq;  /* read queue */
    int dma_started;
    int started;
#ifdef HAS_DMA
    int dma_align;
    struct dma_chan *dma_chan;
    dma_addr_t dma_handles[MAX_DMA_BUFFERS];
    char *dma_buffers[MAX_DMA_BUFFERS];
    u32 dma_buf_sizes[MAX_DMA_BUFFERS];
    u32 num_dma_buffers;
    u32 dma_tot_size;
    u32 dma_allocated;
    struct scatterlist dma_sg[MAX_DMA_BUFFERS];
    dma_cookie_t dma_cookie;
    struct completion dma_cmp;
#endif
#ifdef HAS_FIFO_INTERRUPT
    int fifoHalfInterrupt;
    int fifoOverflow;
#endif

};

////////////////////////////////////////////////////////////////////////////////
//  FIFO IO  ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void writeFifo(void *addr, enum AxiStreamFifo_Register op, u32 data ) {
    *(u32 *)(addr+op) = data;
}

u32 readFifo(void *addr, enum AxiStreamFifo_Register op ) {
    return *(u32 *)(addr+op);
}

static void clearFifo(void *dev, void *dev1)
{
   u32 occ, i;
   writeFifo(dev,ISR,0xFFFFFFFF);
   writeFifo(dev,RDFR,0xa5);
   writeFifo(dev,IER,0x04000000);
//   occ = readFifo(dev,RDFO); 
//   for(i = 0; i < occ; i++)
//       readFifo(dev,RDFD4);
}


#ifdef HAS_DMA
static dma_cookie_t dma_prep_buffer(struct rfx_recorder_dev *dev, struct dma_chan *chan, dma_addr_t *handles, size_t *lens, 
                                    struct scatterlist *sg, u32 num_dma_buffers, enum dma_transfer_direction dir) ;
static void dma_start_transfer(struct dma_chan *chan, struct completion *cmp, dma_cookie_t cookie);
#endif //HAS_DMA

int writeBuf(struct rfx_recorder_dev *dev, u32 sample)
{
    spin_lock_irq(&dev->spinLock);
    if(dev->bufCount >= dev->bufSize)
    {
        printk(KERN_DEBUG "ADC FIFO BUFFER OVERFLOW!\n");
	spin_unlock_irq(&dev->spinLock);
	return -1;
    }
    else
    {
        dev->fifoBuffer[dev->wIdx] = sample;
        dev->wIdx = (dev->wIdx + 1) % dev->bufSize;
        dev->bufCount++;
    }
    spin_unlock_irq(&dev->spinLock);
    return 0;
} 

int writeBufSet(struct rfx_recorder_dev *dev, u32 *buf, int nSamples, int check)
{
    int i;
    spin_lock_irq(&dev->spinLock);
    for(i = 0; i < nSamples; i++)
    {
      if(check && (dev->bufCount >= dev->bufSize))
	{
	    printk(KERN_DEBUG "ADC FIFO BUFFER OVERFLOW  %d    %d!\n", dev->bufCount, dev->bufSize);
	    spin_unlock_irq(&dev->spinLock);
	    return -1;
	}
	else
	{
	    dev->fifoBuffer[dev->wIdx] = buf[i];
	    dev->wIdx = (dev->wIdx + 1) % dev->bufSize;
	    dev->bufCount++;
	}
    }
    spin_unlock_irq(&dev->spinLock);
    return 0;
} 

u32 readBuf(struct rfx_recorder_dev *dev)
{
    u32 data;
    spin_lock_irq(&dev->spinLock);
    if(dev->bufCount <= 0)
    {
        printk(KERN_DEBUG "ADC FIFO BUFFER UNDERFLOW!\n");  //Should never happen
        data = 0;
    }
    else
    {
        data = dev->fifoBuffer[dev->rIdx];
        dev->rIdx = (dev->rIdx+1) % dev->bufSize;
        dev->bufCount--;
    }
    spin_unlock_irq(&dev->spinLock);
    return data;
}




////////////////////////////////////////////////////////////////////////////////
//  DMA Management  /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


#ifdef HAS_DMA

/* Handle a callback called when the DMA transfer is complete 
*/
static int dma_sync_callback(struct rfx_recorder_dev *dev)
{
    int status, i;
    struct task_struct *ts;
    dma_cookie_t lastCookie;
    printk("DMA SYNC CALLBACK %d \n", dev->num_dma_buffers);

    status = dma_async_is_tx_complete(dev->dma_chan,  dev->dma_cookie, &lastCookie, NULL); 
    if (status != DMA_COMPLETE) {
                        printk(KERN_ERR "DMA returned completion callback status of: %s\n",
                               status == DMA_ERROR ? "error" : "in progress"); }
    if(lastCookie != dev->dma_cookie)
    {
        printk("DMA NOT TERMINATED FOR THIS COOKIE %d  %d\n", lastCookie, dev->dma_cookie);
        dmaengine_terminate_all(dev->dma_chan);
        return 0;
    }
     //Start a new DMA round if device still armed
    printk("STATUS REGISTER: %d\n", *((u32 *)dev->iomap_status_register));
    if(*((u32 *)dev->iomap_status_register) == 0) //Always is!!
    {
        dev->dma_started = 0;
        printk("DMA TERMINATED\n");
        return 0;
    }
    return 0;
}

/* Prepare a DMA buffer to be used in a DMA transaction, submit it to the DMA engine 
 * to queued and return a cookie that can be used to track that status of the 
 * transaction
 */
static dma_cookie_t dma_prep_buffer(struct rfx_recorder_dev *dev, struct dma_chan *chan, dma_addr_t *handles, size_t *lens, 
                                    struct scatterlist *sg, u32 num_dma_buffers, enum dma_transfer_direction dir) 
{
    int i;
    //enum dma_ctrl_flags flags = DMA_CTRL_ACK |  DMA_PREP_INTERRUPT;
    enum dma_ctrl_flags flags = DMA_CTRL_ACK;// |  DMA_PREP_INTERRUPT;
    struct dma_async_tx_descriptor *chan_desc;
    dma_cookie_t cookie;
    set_user_nice(current, 10);
    sg_init_table(sg, num_dma_buffers);
    for(i = 0; i < num_dma_buffers; i++)
    {
        sg_dma_address(&sg[i]) = handles[i];
        sg_dma_len(&sg[i]) = lens[i];
    }
//    chan_desc = dev->dma_chan->device->device_prep_slave_sg(chan, sg, num_dma_buffers, dir, flags, NULL);
    chan_desc = dmaengine_prep_slave_sg(chan, sg, num_dma_buffers, dir, flags);
    if (!chan_desc) 
    {
        printk(KERN_ERR "dmaengine_prep_slave_single error\n");
        cookie = -EBUSY;
    } else 
    {
        //chan_desc->callback = dma_sync_callback;
        //chan_desc->callback_param = dev;
        cookie = dmaengine_submit(chan_desc);  
        printk("SUBMIT DMA  cookie: %x\n", cookie);
    }
    return cookie;
}

/* Start a DMA transfer that was previously submitted to the DMA engine and then
 * wait for it complete, timeout or have an error
 */
static void dma_start_transfer(struct dma_chan *chan, struct completion *cmp, 
                                        dma_cookie_t cookie)
{
        unsigned long timeout = msecs_to_jiffies(10000);
        enum dma_status status;

        init_completion(cmp);
        dma_async_issue_pending(chan);
    
}
#endif  //HAS_DMA

#ifdef HAS_FIFO_INTERRUPT
////////////////////////////////////////////////////////////////////////////////
//  Interrupt Management for FIFO //////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static void Write(void *addr, enum AxiStreamFifo_Register op, u32 data ) {
    *(u32 *)(addr+op) = data;
}

static u32 Read(void *addr, enum AxiStreamFifo_Register op ) {
    return *(u32 *)(addr+op);
}

// interrupt handler //
irqreturn_t IRQ_cb(int irq, void *dev_id, struct pt_regs *regs) {
    struct rfx_recorder_dev *dev =  dev_id;
    //struct rpadc_fifo_dev *rpadc = dev_id;
    static int isFirst = 1;
    //Check whether he cause of interrupt has been reveive overrun
    Write(dev->iomap_stream_fifo,ISR,0xFFFFFFFF);
    //Write(dev->iomap_stream_fifo,IER,0x00000000);

    void* fifo  = dev->iomap_stream_fifo;
    void* fifo1 = dev->iomap1_stream_fifo;

    static u32 prev1, prev2;

    u32 occ = Read(fifo,RDFO);
    {
        isFirst = 0;
    }

//printk("--INTERRUPT: Available samples: %d\n", occ);    
    
    
    if(occ >= FIFO_LEN)
    {
        dev->fifoOverflow = 1;
        wake_up(&dev->readq);
        //When oveflow is detected, disable interrupts
    }

    int i;
    for(i = 0; i < occ; i++)
    {
        u32 currSample = Read(fifo1,RDFD4);
        if(writeBuf(dev, currSample) < 0) //In case of ADC FIFO overflow, abort data readout from FPGA
	{
	  Write(dev->iomap_stream_fifo,IER,0x00000000);
	  return IRQ_HANDLED;
	}
     }
    wake_up(&dev->readq);
/*
    if(dev->fifoHalfInterrupt)
        Write(dev->iomap_stream_fifo,IER,0x00100000);
    else
        Write(dev->iomap_stream_fifo,IER,0x04000000);
*/
//printk("--INTERRUPT: Done\n");    
    return IRQ_HANDLED;
}


#endif //HAS_FIFO_INTERRUPT




// OPEN //
static int device_open(struct inode *inode, struct file *file)
{    
    if(!file->private_data) {
        u32 off;

        struct rfx_recorder_dev *privateInfo = container_of(inode->i_cdev, struct rfx_recorder_dev, cdev);

        printk(KERN_DEBUG "OPEN: privateInfo = %0x \n",privateInfo);
        //struct resource *r_mem =  platform_get_resource(s_pdev, IORESOURCE_MEM, 0);
        file->private_data = privateInfo;

        privateInfo->busy = 0;
        privateInfo->wIdx = 0;
        privateInfo->rIdx = 0;
        privateInfo->bufCount = 0;
	if(privateInfo->bufSize > 0)
	     kfree(privateInfo->fifoBuffer);
	privateInfo->bufSize = FIFO_LEN;
	privateInfo->fifoBuffer = (u32 *)kmalloc(privateInfo->bufSize * sizeof(u32), GFP_KERNEL);
	privateInfo->dma_started = 0;
#ifdef HAS_FIFO_INTERRUPT
	privateInfo->fifoOverflow = 0;
	privateInfo->fifoHalfInterrupt = 0;
#endif
    }
    struct rfx_recorder_dev *privateInfo = (struct rfx_recorder_dev *)file->private_data;
    if(!privateInfo) return -EFAULT;
    else if (privateInfo->busy) return -EBUSY;
    else privateInfo->busy++;
    privateInfo->started = 0;
    return capable(CAP_SYS_RAWIO) ? 0 : -EPERM;
}

// CLOSE //
static int device_release(struct inode *inode, struct file *file)
{
    struct rfx_recorder_dev *dev = file->private_data;
    if(!dev) return -EFAULT;
     if(--dev->busy == 0)
    {
        printk(KERN_DEBUG "CLOSE\n");
        wake_up(&dev->readq);
    }
    return 0;
}

static int checkFifo(struct rfx_recorder_dev *dev)
{
    void* fifo  = dev->iomap_stream_fifo;
    void* fifo1 = dev->iomap1_stream_fifo;

    spin_lock_irq(&dev->checkSpinLock);
    u32 occ = Read(fifo,RDFO);
    int i;
    for(i = 0; i < occ; i++)
    {
        u32 currSample = Read(fifo1,RDFD4);
        if(writeBuf(dev, currSample) < 0) //In case of ADC FIFO overflow, abort data readout from FPGA
        {
          dev->fifoOverflow = 1;
          spin_unlock_irq(&dev->checkSpinLock);
          return 0;
        }
     }
    spin_unlock_irq(&dev->checkSpinLock);
    return occ;
}




static ssize_t device_read(struct file *filp, char *buffer, size_t length,
                           loff_t *offset)
{    
    u32 i = 0;
    struct rfx_recorder_dev *dev = (struct rfx_recorder_dev *)filp->private_data;
    u32 *b32 = (u32*)buffer;
#ifdef HAS_FIFO_INTERRUPT
    if(dev->fifoOverflow)
        return -1;
#endif
    checkFifo(dev);
    while(dev->bufCount == 0)
    {
        if(filp->f_flags & O_NONBLOCK)
            return -EAGAIN;
        if(wait_event_interruptible(dev->readq, (dev->bufCount > 0 || dev->started == 0)))
	    return -ERESTARTSYS;
	if(!dev->started)
	    return 0;
   }

    u32 occ = dev->bufCount;
    for(i=0; i < min(length/sizeof(u32), occ); ++i) {
        u32 curr = readBuf(dev);
	put_user(curr, b32++);
    }
    return i*sizeof(u32);
}


// WRITE //
static ssize_t device_write(struct file *filp, const char *buff, size_t len,
                            loff_t *off)
{
    printk ("<1>Sorry, this operation isn't supported yet.\n");
    return -EINVAL;
}




// MMAP //
static int device_mmap(struct file *filp, struct vm_area_struct *vma)
{
    printk ("<1>Sorry, this operation isn't supported.\n");
    return -EINVAL;
}

// LSEEK //
static loff_t memory_lseek(struct file *file, loff_t offset, int orig)
{
     printk ("<1>Sorry, this operation isn't supported.\n");
    return -EINVAL;
}

// IOCTL //
static long device_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{    
    int i;
    int status = 0;
    struct rfx_recorder_dev *dev = file->private_data;

    switch (cmd) {
#ifdef HAS_DMA
    case RFX_RECORDER_ARM_DMA:
      {
        if(!dev->dma_allocated)
        {
            int i;
            dma_addr_t currHandle;
            for(i = 0; i < dev->num_dma_buffers; i++)
            {
   printk("ALLOC COHERENT %d\n", dev->dma_buf_sizes[i]);
               dev->dma_buffers[i] = dma_alloc_coherent(dev->dma_chan->device->dev,dev->dma_buf_sizes[i],&dev->dma_handles[i],GFP_KERNEL);
   printk("ALLOCATED COHERENT %p\n", dev->dma_buffers[i]);
   printk("MAPPED %d\n", dev->dma_handles[i]);
            }
            dev->dma_allocated = 1;
        }
        return 0;
      }
      case RFX_RECORDER_START_DMA:
      {
//Start DMA if DMA buffer previusly allocated
        if(!dev->dma_allocated)
            return -1;
        for(i = 0; i < dev->num_dma_buffers; i++)
        {
            memset(dev->dma_buffers[i], 0, dev->dma_buf_sizes[i]);
        }
        dev->dma_cookie = dma_prep_buffer(dev, dev->dma_chan, dev->dma_handles, dev->dma_buf_sizes, dev->dma_sg, 
                                          dev->num_dma_buffers, DMA_DEV_TO_MEM);
        if (dma_submit_error(dev->dma_cookie) ) {
            printk(KERN_ERR "dma_prep_buffer error\n");
            return -EIO;
        }
        printk(KERN_INFO "Starting DMA transfers. num dma buffers %d\n", dev->num_dma_buffers);
        dma_start_transfer(dev->dma_chan, &dev->dma_cmp, dev->dma_cookie);
        dev->dma_started = 1;
        return 0;
      }
      case RFX_RECORDER_STOP_DMA:
      {
          int status = dma_async_is_tx_complete(dev->dma_chan, dev->dma_cookie,
                                                        NULL, NULL);
          if(status != DMA_COMPLETE)
           printk("DMA ENGINE NOT STOPPED!!!!!!\n");
          dmaengine_terminate_all(dev->dma_chan);
          dev->dma_started = 0;
          return 0;
      }
      case RFX_RECORDER_IS_DMA_RUNNING:
      {
          copy_to_user ((void __user *)arg, &dev->dma_started, sizeof(u32));    
          return 0;
      }
      case RFX_RECORDER_GET_DMA_BUFLEN:
      {
          copy_to_user ((void __user *)arg, &dev->dma_tot_size, sizeof(u32));   
          return 0;
      }
      case RFX_RECORDER_SET_DMA_BUFLEN:
      {
          u32 numDmaBuffers;
          u32 dmaBuflen;
          int i;
          copy_from_user (&dmaBuflen, (void __user *)arg, sizeof(u32)); 
          if(dmaBuflen <= 0 || dmaBuflen > MAX_DMA_BUFFERS * DMA_BUFSIZE)
              return -1;
          if(dev->dma_tot_size != dmaBuflen)
          {
              if(dev->dma_allocated > 0)
              {
                  for(i = 0; i < dev->num_dma_buffers; i++)
                  {
                      dma_free_coherent(dev->dma_chan->device->dev,dev->dma_buf_sizes[i],dev->dma_buffers[i],dev->dma_handles[i]);
                  }
                  dev->dma_allocated = 0;
              }
          }
          dev->num_dma_buffers = dmaBuflen / DMA_BUFSIZE;
          for(i = 0; i < dev->num_dma_buffers; i++)
              dev->dma_buf_sizes[i] = DMA_BUFSIZE;
          if(dmaBuflen % DMA_BUFSIZE)
          {
              dev->dma_buf_sizes[dev->num_dma_buffers] = dmaBuflen % DMA_BUFSIZE;
              dev->num_dma_buffers++;
              printk("LAST DMA SIZE: %d\n", dmaBuflen % DMA_BUFSIZE);
          }
          dev->dma_tot_size = dmaBuflen;
          printk("NUM DMA BUFFERS: %d\n", dev->num_dma_buffers);
          return 0;
      }
      case RFX_RECORDER_GET_DMA_DATA:
      {
          int i;
          if(!dev->dma_allocated)
              return -1;
          char *currPtr = (void __user *)arg;
          for(i = 0; i < dev->num_dma_buffers; i++)
          {
              printk("COPYING %d  %d\n", i,  dev->dma_buf_sizes[i]);
              copy_to_user ((void __user *)currPtr, dev->dma_buffers[i], dev->dma_buf_sizes[i]);
              currPtr += dev->dma_buf_sizes[i];
          }
          return 0;
      }
#endif //HAS_DMA      
      
      case RFX_RECORDER_SET_DRIVER_BUFLEN:
      {
	  if(dev->dma_started)
	      return 0;
	  dev->wIdx = 0;
	  dev->rIdx = 0;
          dev->bufCount = 0;
	  if(dev->bufSize > 0)
	      kfree(dev->fifoBuffer);
	  copy_from_user (&dev->bufSize, (void __user *)arg, sizeof(u32));
	  dev->fifoBuffer = (u32 *)kmalloc(dev->bufSize * sizeof(u32), GFP_KERNEL);
	  return 0;
      }
      case RFX_RECORDER_GET_DRIVER_BUFLEN:
      {
	  copy_to_user ((void __user *)arg, &dev->bufSize, sizeof(u32));	
	  return 0;
      }
      
    	case RFX_RECORDER_GET_COMMAND_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_command_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_COMMAND_REGISTER:
	{
		copy_from_user (dev->iomap_command_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_DECIMATOR_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_decimator_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_DECIMATOR_REGISTER:
	{
		copy_from_user (dev->iomap_decimator_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_DMA_SIZE_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_dma_size_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_DMA_SIZE_REGISTER:
	{
		copy_from_user (dev->iomap_dma_size_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_EVENT_CODE_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_event_code_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_EVENT_CODE_REGISTER:
	{
		copy_from_user (dev->iomap_event_code_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_MODE_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_mode_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_MODE_REGISTER:
	{
		copy_from_user (dev->iomap_mode_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_PTS_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_pts_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_PTS_REGISTER:
	{
		copy_from_user (dev->iomap_pts_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_STREAM_DECIMATOR_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_stream_decimator_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_STREAM_DECIMATOR_REGISTER:
	{
		copy_from_user (dev->iomap_stream_decimator_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_COUNTER_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_counter_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_COUNTER_REGISTER:
	{
		copy_from_user (dev->iomap_counter_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_STATUS_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_status_register, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_SET_STATUS_REGISTER:
	{
		copy_from_user (dev->iomap_status_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_STREAM_FIFO_LEN:
	{
		u32 val = readFifo(dev->iomap_stream_fifo,RDFO);
		copy_to_user ((void __user *)arg, &val, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_GET_STREAM_FIFO_VAL:
	{
		u32 val = readFifo(dev->iomap1_stream_fifo,RDFD4);
		copy_to_user ((void __user *)arg, &val, sizeof(u32));
		return 0;
	}
	case RFX_RECORDER_CLEAR_STREAM_FIFO:
	{
		clearFifo(dev->iomap_stream_fifo,dev->iomap1_stream_fifo);
		return 0;
	}
	case RFX_RECORDER_GET_REGISTERS:
	{
		struct rfx_recorder_registers currConf;
		memset(&currConf, 0, sizeof(currConf));
		currConf.command_register = *((u32 *)dev->iomap_command_register);
		currConf.decimator_register = *((u32 *)dev->iomap_decimator_register);
		currConf.dma_size_register = *((u32 *)dev->iomap_dma_size_register);
		currConf.event_code_register = *((u32 *)dev->iomap_event_code_register);
		currConf.mode_register = *((u32 *)dev->iomap_mode_register);
		currConf.pts_register = *((u32 *)dev->iomap_pts_register);
		currConf.stream_decimator_register = *((u32 *)dev->iomap_stream_decimator_register);
		currConf.counter_register = *((u32 *)dev->iomap_counter_register);
		currConf.status_register = *((u32 *)dev->iomap_status_register);
		copy_to_user ((void __user *)arg, &currConf, sizeof(currConf));
	}
	case RFX_RECORDER_SET_REGISTERS:
	{
		struct rfx_recorder_registers currConf;
		copy_from_user (&currConf, (void __user *)arg, sizeof(currConf));
		if(currConf.command_register_enable)
			*((u32 *)dev->iomap_command_register) = currConf.command_register;
		if(currConf.decimator_register_enable)
			*((u32 *)dev->iomap_decimator_register) = currConf.decimator_register;
		if(currConf.dma_size_register_enable)
			*((u32 *)dev->iomap_dma_size_register) = currConf.dma_size_register;
		if(currConf.event_code_register_enable)
			*((u32 *)dev->iomap_event_code_register) = currConf.event_code_register;
		if(currConf.mode_register_enable)
			*((u32 *)dev->iomap_mode_register) = currConf.mode_register;
		if(currConf.pts_register_enable)
			*((u32 *)dev->iomap_pts_register) = currConf.pts_register;
		if(currConf.stream_decimator_register_enable)
			*((u32 *)dev->iomap_stream_decimator_register) = currConf.stream_decimator_register;
		if(currConf.counter_register_enable)
			*((u32 *)dev->iomap_counter_register) = currConf.counter_register;
		if(currConf.status_register_enable)
			*((u32 *)dev->iomap_status_register) = currConf.status_register;
	}

 
 #ifdef HAS_FIFO_INTERRUPT
 
     case RFX_RECORDER_FIFO_INT_HALF_SIZE:
        dev->fifoHalfInterrupt = 1;
        //Write(dev->iomap_data_fifo,IER,0x00100000);
        return 0;
    case RFX_RECORDER_FIFO_INT_FIRST_SAMPLE:
        dev->fifoHalfInterrupt = 0;
        //Write(dev->iomap_data_fifo,IER,0x04000000);
        return 0;
    case RFX_RECORDER_FIFO_FLUSH:
	  IRQ_cb(0, dev, 0);
      //  Write(dev->iomap_data_fifo,IER,0x04000000);
    case RFX_RECORDER_START_READ:
	  dev->started = 1;
        return 0;
    case RFX_RECORDER_STOP_READ:
	  dev->started = 0;
	  IRQ_cb(0, dev, 0);
        return 0;

 
 #endif
 
    default:
        return -EAGAIN;
        break;
    }
    return status;
}


static unsigned int device_poll(struct file *file, struct poll_table_struct *p) 
{
    unsigned int mask=0;
    struct rfx_recorder_dev *dev =  (struct rfx_recorder_dev *)file->private_data;

    down(&dev->sem);
    poll_wait(file,&dev->readq,p);
    if(dev->bufCount > 0)
        mask |= POLLIN | POLLRDNORM;
    up(&dev->sem);
    return mask;
}




////////////////////////////////////////////////////////////////////////////////
//  PROBE  MANAGEMENT///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static int id_major;
static struct class *rfx_recorder_class;
static struct rfx_recorder_dev staticPrivateInfo;

#ifdef HAS_FIFO_INTERRUPT
static void setIrq(struct platform_device *pdev)
{
     staticPrivateInfo.irq = platform_get_irq(pdev,0);
     printk(KERN_DEBUG "IRQ: %x\n",staticPrivateInfo.irq);
     int res = request_irq(staticPrivateInfo.irq, IRQ_cb, IRQF_TRIGGER_RISING ,"rfx_recorder",&staticPrivateInfo);
     if(res) 
	printk(KERN_INFO "rfx_recorder: can't get IRQ %d assigned\n",staticPrivateInfo.irq);
     else 
	printk(KERN_INFO "rfx_recorder: got IRQ %d assigned\n",staticPrivateInfo.irq);
}
#endif






static int rfx_recorder_probe(struct platform_device *pdev)
{
    int i;
    u32 off;
    static int memIdx;
    struct resource *r_mem;
    struct device *dev = &pdev->dev;

    //s_pdev = pdev;
    printk("rfx_recorder_probe  %s\n", pdev->name);

    // CHAR DEV //
    if(!deviceAllocated)
    {
        deviceAllocated = 1;
	memIdx = 0;
        printk("registering char dev %s ...\n",pdev->name);
        printk("PLATFORM DEVICE PROBE...%x\n", &staticPrivateInfo);

        int err, devno;
        dev_t newDev;
        err = alloc_chrdev_region(&newDev, 0, 1, DEVICE_NAME);
        id_major = MAJOR(newDev);
        printk("MAJOR ID...%d\n", id_major);
        if(err < 0)
        {
            printk ("alloc_chrdev_region failed\n");
            return err;
        }
        cdev_init(&staticPrivateInfo.cdev, &fops);
        staticPrivateInfo.cdev.owner = THIS_MODULE;
        staticPrivateInfo.cdev.ops = &fops;
        devno = MKDEV(id_major, 0); //Minor Id is 0
        err = cdev_add(&staticPrivateInfo.cdev, devno, 1);
        if(err < 0)
        {
            printk ("cdev_add failed\n");
            return err;
        }
        staticPrivateInfo.pdev = pdev;

        printk(KERN_NOTICE "mknod /dev/%s c %d 0\n", DEVICE_NAME, id_major);

        rfx_recorder_class = class_create(THIS_MODULE, DEVICE_NAME);
        if (IS_ERR(rfx_recorder_class))
            return PTR_ERR(rfx_recorder_class);

        device_create(rfx_recorder_class, NULL, MKDEV(id_major, 0),
                  NULL, DEVICE_NAME);


      // Initialize semaphores and queues
      sema_init(&staticPrivateInfo.sem, 1);
      spin_lock_init(&staticPrivateInfo.spinLock);
      spin_lock_init(&staticPrivateInfo.checkSpinLock);
      init_waitqueue_head(&staticPrivateInfo.readq);
      staticPrivateInfo.bufCount = 0;
      staticPrivateInfo.rIdx = 0;
      staticPrivateInfo.wIdx = 0;
      staticPrivateInfo.bufSize = 0;
#ifdef HAS_DMA      
      staticPrivateInfo.dma_tot_size = 0;
      staticPrivateInfo.dma_allocated = 0;
      staticPrivateInfo.dma_chan = NULL;
      //Declare DMA Channel
      printk("REQUEST DMA\n");
      staticPrivateInfo.dma_chan = dma_request_slave_channel(&pdev->dev, "dma0");
      if (IS_ERR(staticPrivateInfo.dma_chan)) {
	  pr_err("xilinx_dmatest: No Tx channel\n");
	  dma_release_channel(staticPrivateInfo.dma_chan);
	  return -EFAULT;
      }
      printk("GOT DMA %p\n", staticPrivateInfo.dma_chan);
#endif //HAS_DMA
      

    }
    else //Further calls for memory resources
    {
      printk("FOLLOWING CALL TO rfx_rfx_recorder_probe: %s, memIdx: %d\n", pdev->name, memIdx);	
//      r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
//      off = r_mem->start & ~PAGE_MASK;
       switch(memIdx) {
	 
	 	case 1:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_stream_fifo = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap1_stream_fifo = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);
		setIrq(pdev);
	break;
	case 2:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_command_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 3:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_counter_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 4:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_decimator_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 5:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_dma_size_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 6:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_event_code_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 7:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_mode_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 8:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_pts_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 9:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_status_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 10:
		r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
		off = r_mem->start & ~PAGE_MASK;
		staticPrivateInfo.iomap_stream_decimator_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;


	 default: printk("ERROR: Unexpected rfx_recorder_probe call\n");
        } 
    }
    memIdx++;
    printk(KERN_DEBUG"mem start: %x\n",r_mem->start);
    printk(KERN_DEBUG"mem end: %x\n",r_mem->end);
    printk(KERN_DEBUG"mem offset: %x\n",r_mem->start & ~PAGE_MASK);
    return 0;
}

static int rfx_recorder_remove(struct platform_device *pdev)
{
    printk("PLATFORM DEVICE REMOVE...\n");
    if(rfx_recorder_class) {
        device_destroy(rfx_recorder_class,MKDEV(id_major, 0));
        class_destroy(rfx_recorder_class);
    }
#ifdef HAS_DMA    
    printk("PLATFORM DEVICE REMOVE dma_release_channel...%x  \n",staticPrivateInfo.dma_chan);
    if(staticPrivateInfo.dma_chan)
        dma_release_channel(staticPrivateInfo.dma_chan);
#endif //HAS_DMA
    cdev_del(&staticPrivateInfo.cdev);
    return 0;
}

static const struct of_device_id rfx_recorder_of_ids[] = {
{ .compatible = "xlnx,axi-dma-test-1.00.a",},
{ .compatible = "xlnx,axi-cfg-register-1.0",},
{ .compatible = "xlnx,axi-sts-register-1.0",},
{ .compatible = "xlnx,axi-fifo-mm-s-4.1",},
{}
};

static struct platform_driver rfx_recorder_driver = {
   .driver = {
        .name  = MODULE_NAME,
        .owner = THIS_MODULE,
        .of_match_table = rfx_recorder_of_ids,
     },
    .probe = rfx_recorder_probe,
    .remove = rfx_recorder_remove,
};

static int __init rfx_recorder_init(void)
{
    printk(KERN_INFO "inizializing AXI module ...\n");
    deviceAllocated = 0;
    return platform_driver_register(&rfx_recorder_driver);
}

static void __exit rfx_recorder_exit(void)
{
    printk(KERN_INFO "exiting AXI module ...\n");
    platform_driver_unregister(&rfx_recorder_driver);
}

module_init(rfx_recorder_init);
module_exit(rfx_recorder_exit);
MODULE_LICENSE("GPL");
