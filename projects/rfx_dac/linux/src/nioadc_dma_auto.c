

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

#include "$$DEVICE_NAME_L$$.h"

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

#define DMA_STREAMING_SAMPLES 1024
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

#define BUFSIZE 65536

struct $$DEVICE_NAME_L$$_dev {
    struct platform_device *pdev;
    struct cdev cdev;
    int busy;
    int irq;
    
    	void * iomap_command_register;
	void * iomap_decimator_register;
	void * iomap_mode_register;
	void * iomap_packetizer;
	void * iomap_pre_post_register;

    
/*    void * iomap_cmd_reg;	//Command register
    void * iomap_mode_reg;	//Mode register
    void * iomap_pre_post_reg;	//Pre/Post register
    void * iomap_pack_reg;	//Packetizer register
    void * iomap_dec_reg;	//Decimator register
*/    
    struct semaphore sem;     /* mutual exclusion semaphore     */
    spinlock_t spinLock;     /* spinlock     */
    u32 *fifoBuffer;
    u32 bufSize;
    u32 rIdx, wIdx, bufCount;
    wait_queue_head_t readq;  /* read queue */
    int dma_started;
    
    struct dma_chan *dma_chan;
    dma_addr_t dma_handle;
    dma_addr_t rx_dma_handle;
    char *dma_buffer;
    u32 dma_buf_size;
    dma_cookie_t dma_cookie;
    struct completion dma_cmp;

};


// FOPS FWDDECL //
static dma_cookie_t dma_prep_buffer(struct $$DEVICE_NAME_L$$_dev *dev, struct dma_chan *chan, dma_addr_t buf, size_t len, 
					enum dma_transfer_direction dir, struct completion *cmp);
static void dma_start_transfer(struct dma_chan *chan, struct completion *cmp, dma_cookie_t cookie, int wait);

int writeBuf(struct $$DEVICE_NAME_L$$_dev *dev, u32 sample)
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

int writeBufSet(struct $$DEVICE_NAME_L$$_dev *dev, u32 *buf, int nSamples)
{
    int i;
    spin_lock_irq(&dev->spinLock);
    for(i = 0; i < nSamples; i++)
    {
      if(dev->bufCount >= dev->bufSize)
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

u32 readBuf(struct $$DEVICE_NAME_L$$_dev *dev)
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


static void dma_buffer2fifo_buffer(struct $$DEVICE_NAME_L$$_dev *dev)
{
    int i;
    int dmaSamples = dev->dma_buf_size/sizeof(u32);
    writeBufSet(dev, dev->dma_buffer, dmaSamples);
    wake_up(&dev->readq);
}


////////////////////////////////////////////////////////////////////////////////
//  DMA Management  /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/* Handle a callback called when the DMA transfer is complete to another
 * thread of control
 */
static int dma_sync_callback(struct $$DEVICE_NAME_L$$_dev *dev)
{
    int status, i;
    dma_cookie_t lastCookie;
    printk("DMA SYNC CALLBACK\n");
    status = dma_async_is_tx_complete(dev->dma_chan,  dev->dma_cookie, &lastCookie, NULL); 
    if (status != DMA_COMPLETE) {
			printk(KERN_ERR "DMA returned completion callback status of: %s\n",
			       status == DMA_ERROR ? "error" : "in progress"); }
    if(lastCookie != dev->dma_cookie)
    {
	printk("DMA NOT TERMINATED FOR THIS COOKIE %d  %d\n", lastCookie, dev->dma_cookie);
	dmaengine_terminate_all(dev->dma_chan);
//	return 0;
    }
    else
    {
         dma_buffer2fifo_buffer(dev);
    }
    //Start a new DMA round if device still armed
    if(!dev->dma_started)
        return 0;
    for(i = 0; i < dev->dma_buf_size/sizeof(u32); i++)
      ((u32 *)dev->dma_buffer)[i] = 0xffffffff;
 
    dev->dma_cookie = dma_prep_buffer(dev, dev->dma_chan, dev->dma_handle, dev->dma_buf_size, DMA_DEV_TO_MEM,  &dev->dma_cmp);
    if (dma_submit_error(dev->dma_cookie)) {
	printk(KERN_ERR "dma_prep_buffer error\n");
	return -EIO;
    }
    printk(KERN_INFO "Starting NEW DMA transfers\n");
    dma_start_transfer(dev->dma_chan, &dev->dma_cmp, dev->dma_cookie, 0);
    return 0;
}

/* Prepare a DMA buffer to be used in a DMA transaction, submit it to the DMA engine 
 * to queued and return a cookie that can be used to track that status of the 
 * transaction
 */
static dma_cookie_t dma_prep_buffer(struct $$DEVICE_NAME_L$$_dev *dev, struct dma_chan *chan, dma_addr_t buf, size_t len, 
					enum dma_transfer_direction dir, struct completion *cmp) 
{
	enum dma_ctrl_flags flags = /*DMA_CTRL_ACK | */ DMA_PREP_INTERRUPT;
	struct dma_async_tx_descriptor *chan_desc;
	dma_cookie_t cookie;

	chan_desc = dmaengine_prep_slave_single(chan, buf, len, dir, flags);
	if (!chan_desc) {
		printk(KERN_ERR "dmaengine_prep_slave_single error\n");
		cookie = -EBUSY;
	} else {
		chan_desc->callback = dma_sync_callback;
		chan_desc->callback_param = dev;
		printk("SUBMIT DMA \n");
		cookie = dmaengine_submit(chan_desc);	
		printk("SUBMIT DMA  cookie: %x\n", cookie);
	}
	return cookie;
}

/* Start a DMA transfer that was previously submitted to the DMA engine and then
 * wait for it complete, timeout or have an error
 */
static void dma_start_transfer(struct dma_chan *chan, struct completion *cmp, 
					dma_cookie_t cookie, int wait)
{
	unsigned long timeout = msecs_to_jiffies(10000);
	enum dma_status status;

	init_completion(cmp);
	dma_async_issue_pending(chan);
    
	if (wait) 
	{
		timeout = wait_for_completion_timeout(cmp, timeout);
		status = dma_async_is_tx_complete(chan, cookie, NULL, NULL);
		if (timeout == 0)  
		{
		    printk(KERN_ERR "DMA timed out\n");
		} 
		else if (status != DMA_COMPLETE) 
		{
		    printk(KERN_ERR "DMA returned completion callback status of: %s\n",
		    status == DMA_ERROR ? "error" : "in progress");
		}
	}
}


// OPEN //
static int device_open(struct inode *inode, struct file *file)
{    
    if(!file->private_data) {
        u32 off;

        struct $$DEVICE_NAME_L$$_dev *privateInfo = container_of(inode->i_cdev, struct $$DEVICE_NAME_L$$_dev, cdev);

        printk(KERN_DEBUG "OPEN: privateInfo = %0x \n",privateInfo);
        //struct resource *r_mem =  platform_get_resource(s_pdev, IORESOURCE_MEM, 0);
        file->private_data = privateInfo;

        privateInfo->busy = 0;
        privateInfo->wIdx = 0;
        privateInfo->rIdx = 0;
        privateInfo->bufCount = 0;
	if(privateInfo->bufSize > 0)
	     kfree(privateInfo->fifoBuffer);
	privateInfo->bufSize = BUFSIZE;
	privateInfo->fifoBuffer = (u32 *)kmalloc(privateInfo->bufSize * sizeof(u32), GFP_KERNEL);
	privateInfo->dma_started = 0;
    }
    struct $$DEVICE_NAME_L$$_dev *privateInfo = (struct $$DEVICE_NAME_L$$_dev *)file->private_data;
    if(!privateInfo) return -EFAULT;
    else if (privateInfo->busy) return -EBUSY;
    else privateInfo->busy++;
    
    return capable(CAP_SYS_RAWIO) ? 0 : -EPERM;
}

// CLOSE //
static int device_release(struct inode *inode, struct file *file)
{
    struct $$DEVICE_NAME_L$$_dev *dev = file->private_data;
    if(!dev) return -EFAULT;
     if(--dev->busy == 0)
    {
        printk(KERN_DEBUG "CLOSE\n");
        wake_up(&dev->readq);
    }
    return 0;
}




static ssize_t device_read(struct file *filp, char *buffer, size_t length,
                           loff_t *offset)
{    
    u32 i = 0;
    struct $$DEVICE_NAME_L$$_dev *dev = (struct $$DEVICE_NAME_L$$_dev *)filp->private_data;
    u32 *b32 = (u32*)buffer;

    while(dev->bufCount == 0)
    {
        if(filp->f_flags & O_NONBLOCK)
            return -EAGAIN;
        if(wait_event_interruptible(dev->readq, dev->bufCount > 0))
            return -ERESTARTSYS;
	if(!dev->dma_started)
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
    struct $$DEVICE_NAME_L$$_dev *dev = file->private_data;

    switch (cmd) {
      case $$DEVICE_NAME_U$$_ARM_DMA:
      {
	u32 newDmaBufSize;
	if(!arg)
	{
	  if(dev->dma_buf_size > 0)
	    newDmaBufSize = dev->dma_buf_size;
	  else
	    newDmaBufSize = DMA_STREAMING_SAMPLES * sizeof(u32);
	}
	else
	{  
	    copy_from_user (&newDmaBufSize, (void __user *)arg, sizeof(u32));
	}
 	if(dev->dma_buf_size > 0 && dev->dma_buf_size  != newDmaBufSize)
	{
	   dma_free_coherent(dev->dma_chan->device->dev,dev->dma_buf_size,dev->dma_buffer,dev->dma_handle);
	}
	if(newDmaBufSize != dev->dma_buf_size)
	{
	    dev->dma_buf_size = newDmaBufSize;
	    dev->dma_buffer = dma_alloc_coherent(dev->dma_chan->device->dev,dev->dma_buf_size,&dev->dma_handle,GFP_KERNEL);
	}
	for(i = 0; i < 300; i++)  //Just test
	  ((u32 *)dev->dma_buffer)[i] = 0xFFFFFFFF;
	
	printk("DMA BUFFER ADDRESS: %x\n", dev->dma_buffer);
	dev->rx_dma_handle = dma_map_single(dev->dma_chan->device->dev, dev->dma_buffer, dev->dma_buf_size, DMA_FROM_DEVICE);	
	return 0;
      }
      case $$DEVICE_NAME_U$$_START_DMA:
      {
//Start DMA if DMA buffer previusly allocated
	if(dev->dma_buf_size > 0)
	{
	    dev->dma_cookie = dma_prep_buffer(dev, dev->dma_chan, dev->dma_handle, dev->dma_buf_size, DMA_DEV_TO_MEM,  &dev->dma_cmp);
	    if (dma_submit_error(dev->dma_cookie) ) {
		printk(KERN_ERR "dma_prep_buffer error\n");
		return -EIO;
	    }
	    printk(KERN_INFO "Starting DMA transfers. DMA Buf size = %d\n", dev->dma_buf_size);
            dma_start_transfer(dev->dma_chan, &dev->dma_cmp, dev->dma_cookie, 0);
	    dev->dma_started = 1;
	}
	return 0;
      }
      case $$DEVICE_NAME_U$$_STOP_DMA:
      {
	  dev->dma_started = 0;
	  return 0;
      }
      case $$DEVICE_NAME_U$$_GET_DMA_BUFLEN:
      {
	  copy_to_user ((void __user *)arg, &dev->dma_buf_size, sizeof(u32));	
	  return 0;
      }
      case $$DEVICE_NAME_U$$_SET_DRIVER_BUFLEN:
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
      case $$DEVICE_NAME_U$$_GET_DRIVER_BUFLEN:
      {
	  copy_to_user ((void __user *)arg, &dev->bufSize, sizeof(u32));	
	  return 0;
      }
      
    	case NIOADC_DMA_AUTO_GET_COMMAND_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_command_register, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_SET_COMMAND_REGISTER:
	{
		copy_from_user (dev->iomap_command_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_GET_DECIMATOR_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_decimator_register, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_SET_DECIMATOR_REGISTER:
	{
		copy_from_user (dev->iomap_decimator_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_GET_MODE_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_mode_register, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_SET_MODE_REGISTER:
	{
		copy_from_user (dev->iomap_mode_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_GET_PACKETIZER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_packetizer, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_SET_PACKETIZER:
	{
		copy_from_user (dev->iomap_packetizer, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_GET_PRE_POST_REGISTER:
	{
		copy_to_user ((void __user *)arg, dev->iomap_pre_post_register, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_SET_PRE_POST_REGISTER:
	{
		copy_from_user (dev->iomap_pre_post_register, (void __user *)arg, sizeof(u32));
		return 0;
	}
	case NIOADC_DMA_AUTO_GET_CONFIGURATION:
	{
		struct nioadc_dma_auto_conf currConf;
		memset(&currConf, 0, sizeof(currConf));
		currConf.command_register = *((u32 *)dev->iomap_command_register);
		currConf.decimator_register = *((u32 *)dev->iomap_decimator_register);
		currConf.mode_register = *((u32 *)dev->iomap_mode_register);
		currConf.packetizer = *((u32 *)dev->iomap_packetizer);
		currConf.pre_post_register = *((u32 *)dev->iomap_pre_post_register);
		copy_to_user ((void __user *)arg, &currConf, sizeof(currConf));
	}
	case NIOADC_DMA_AUTO_SET_CONFIGURATION:
	{
		struct nioadc_dma_auto_conf currConf;
		copy_from_user (&currConf, (void __user *)arg, sizeof(currConf));
		if(currConf.command_register_enable)
			*((u32 *)dev->iomap_command_register) = currConf.command_register;
		if(currConf.decimator_register_enable)
			*((u32 *)dev->iomap_decimator_register) = currConf.decimator_register;
		if(currConf.mode_register_enable)
			*((u32 *)dev->iomap_mode_register) = currConf.mode_register;
		if(currConf.packetizer_enable)
			*((u32 *)dev->iomap_packetizer) = currConf.packetizer;
		if(currConf.pre_post_register_enable)
			*((u32 *)dev->iomap_pre_post_register) = currConf.pre_post_register;
	}

 
    default:
        return -EAGAIN;
        break;
    }
    return status;
}


static unsigned int device_poll(struct file *file, struct poll_table_struct *p) 
{
    unsigned int mask=0;
    struct $$DEVICE_NAME_L$$_dev *dev =  (struct $$DEVICE_NAME_L$$_dev *)file->private_data;

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
static struct class *$$DEVICE_NAME_L$$_class;
static struct $$DEVICE_NAME_L$$_dev staticPrivateInfo;
static int $$DEVICE_NAME_L$$_dma_probe(struct platform_device *pdev)
{
    int i;
    u32 off;
    static int memIdx;
    struct resource *r_mem;
    struct device *dev = &pdev->dev;

    //s_pdev = pdev;
    printk("$$DEVICE_NAME_L$$_dma_probe  %x\n", pdev->name);

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

        $$DEVICE_NAME_L$$_class = class_create(THIS_MODULE, DEVICE_NAME);
        printk("CHIAMATO CLASS CREATE %d\n",  $$DEVICE_NAME_L$$_class);
        if (IS_ERR($$DEVICE_NAME_L$$_class))
            return PTR_ERR($$DEVICE_NAME_L$$_class);

        printk("DEVICE CREATE...\n");
        device_create($$DEVICE_NAME_L$$_class, NULL, MKDEV(id_major, 0),
                  NULL, DEVICE_NAME);


      // Initialize semaphores and queues
      sema_init(&staticPrivateInfo.sem, 1);
      spin_lock_init(&staticPrivateInfo.spinLock);
      init_waitqueue_head(&staticPrivateInfo.readq);
      staticPrivateInfo.bufCount = 0;
      staticPrivateInfo.rIdx = 0;
      staticPrivateInfo.wIdx = 0;
      staticPrivateInfo.bufSize = 0;
      staticPrivateInfo.dma_buf_size = 0;
      staticPrivateInfo.dma_chan = NULL;
      //Declare DMA Channel
      staticPrivateInfo.dma_chan = dma_request_slave_channel(&pdev->dev, "dma0");
      printk("CHIAMATO dma_request_slave_channel: %x\n", staticPrivateInfo.dma_chan);
      if (IS_ERR(staticPrivateInfo.dma_chan)) {
	  pr_err("xilinx_dmatest: No Tx channel\n");
	  dma_release_channel(staticPrivateInfo.dma_chan);
	  return -EFAULT;
      }
    }
    else //Further calls for memory resources
    {
      printk("SUCCESSIVA CHIAMATA A rfx_$$DEVICE_NAME_L$$_dma_probe: %s, memIdx: %d\n", pdev->name, memIdx);	
      r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
      off = r_mem->start & ~PAGE_MASK;
       switch(memIdx) {
	 
	 	case 0:  staticPrivateInfo.iomap_command_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 1:  staticPrivateInfo.iomap_decimator_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 2:  staticPrivateInfo.iomap_mode_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 3:  staticPrivateInfo.iomap_packetizer = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 4:  staticPrivateInfo.iomap_pre_post_register = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;

/*	 
	case 0:  staticPrivateInfo.iomap_cmd_reg = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 1:  staticPrivateInfo.iomap_dec_reg = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 2:  staticPrivateInfo.iomap_mode_reg = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 3:  staticPrivateInfo.iomap_pack_reg = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
	case 4:  staticPrivateInfo.iomap_pre_post_reg = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;
*/	default: printk("ERROR: Unexcpected $$DEVICE_NAME_L$$_dma_probe call\n");
      }
      memIdx++;
      printk(KERN_DEBUG"mem start: %x\n",r_mem->start);
      printk(KERN_DEBUG"mem end: %x\n",r_mem->end);
      printk(KERN_DEBUG"mem offset: %x\n",r_mem->start & ~PAGE_MASK);
    }
    return 0;
}

static int $$DEVICE_NAME_L$$_dma_remove(struct platform_device *pdev)
{
    printk("PLATFORM DEVICE REMOVE...\n");
    if($$DEVICE_NAME_L$$_class) {
        device_destroy($$DEVICE_NAME_L$$_class,MKDEV(id_major, 0));
        class_destroy($$DEVICE_NAME_L$$_class);
    }
    printk("PLATFORM DEVICE REMOVE dma_release_channel...%x  \n",staticPrivateInfo.dma_chan);
    if(staticPrivateInfo.dma_chan)
      dma_release_channel(staticPrivateInfo.dma_chan);
    //Gabriele Dec 2017
    cdev_del(&staticPrivateInfo.cdev);
    return 0;
}

static const struct of_device_id $$DEVICE_NAME_L$$_dma_of_ids[] = {
{ .compatible = "xlnx,axi-dma-test-1.00.a",},
{ .compatible = "xlnx,axi-cfg-register-1.0",},
{}
};

static struct platform_driver $$DEVICE_NAME_L$$_dma_driver = {
   .driver = {
        .name  = MODULE_NAME,
        .owner = THIS_MODULE,
        .of_match_table = $$DEVICE_NAME_L$$_dma_of_ids,
     },
    .probe = $$DEVICE_NAME_L$$_dma_probe,
    .remove = $$DEVICE_NAME_L$$_dma_remove,
};

static int __init $$DEVICE_NAME_L$$_dma_init(void)
{
    printk(KERN_INFO "inizializing AXI module ...\n");
    deviceAllocated = 0;
    return platform_driver_register(&$$DEVICE_NAME_L$$_dma_driver);
}

static void __exit $$DEVICE_NAME_L$$_dma_exit(void)
{
    printk(KERN_INFO "exiting AXI module ...\n");
    platform_driver_unregister(&$$DEVICE_NAME_L$$_dma_driver);
}

module_init($$DEVICE_NAME_L$$_dma_init);
module_exit($$DEVICE_NAME_L$$_dma_exit);
MODULE_LICENSE("GPL");
