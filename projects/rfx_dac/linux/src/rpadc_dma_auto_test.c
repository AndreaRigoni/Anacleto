#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "rpadc_dma_auto.h"
#include "axi_reg.h"

#define BUF_SIZE 10240

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#define DEC_REG_ADDR 0x60000000
#define DMA_STREAMING_SAMPLES 1024

#define PRE_SAMPLES 0
#define POST_SAMPLES 30
enum rpadc_mode {
  STREAMING,
  EVENT_STREAMING
};


struct rpadc_configuration
{
    enum rpadc_mode mode;   		//STREAMING or EVENT_STREAMING
    unsigned short trig_threshold;		//Signal level for trigger
    char trig_above_threshold;  //If true, trigger when above threshold, below threshold otherwise
    char trig_from_chana;	//If true, the trigger is derived from channel A
    unsigned char trig_samples;          //Number of samples above/below threshol for validating trigger
    unsigned short pre_samples;		//Number of pre-trigger samples
    unsigned short post_samples;         //Number of post-trigger samples
    unsigned int decimation;		//Decimation factor (base frequency: 125MHz)
};



static void writeConfig(int fd, struct rpadc_configuration *config)
{
    int status;
    struct rpadc_dma_auto_registers regs;
    memset(&regs, 0, sizeof(regs));
    unsigned int currVal = 0;
    unsigned int dmaBufSize = 0;
    if(config->mode == STREAMING)
	currVal |= 0x00000001;
    if(config->trig_from_chana)
	currVal |= 0x00000002;
    if(config->trig_above_threshold)
	currVal |= 0x00000004;
	
    currVal |= ((config->trig_samples << 8) & 0x0000FF00);
    currVal |= ((config->trig_threshold << 16) & 0xFFFF0000);
    regs.mode_register_enable = 1;
    regs.mode_register = currVal;
    
    regs.pre_register_enable = 1;
    regs.pre_register = config->pre_samples;
    regs.post_register_enable = 1;
    regs.post_register = config->post_samples;
    
    regs.decimator_register_enable = 1;
    regs.decimator_register = config->decimation - 1;

    status = ioctl(fd, RPADC_DMA_AUTO_SET_REGISTERS, &regs);

    if(config->mode == STREAMING)
	dmaBufSize = DMA_STREAMING_SAMPLES * sizeof(unsigned int); 
    else
      dmaBufSize = (config->post_samples + config->pre_samples) * sizeof(unsigned int);

    status = ioctl(fd, RPADC_DMA_AUTO_ARM_DMA, &dmaBufSize);
    
    currVal = 1;
    status = ioctl(fd, RPADC_DMA_AUTO_SET_PACKETIZER, &currVal);
    
}


static void readConfig(int fd, struct rpadc_configuration *config)
{
    int status;
    unsigned int currVal;
    struct rpadc_dma_auto_registers regs;    
    status = ioctl(fd,  RPADC_DMA_AUTO_GET_REGISTERS, &regs);
       
    currVal = regs.mode_register;
    if(currVal & 0x00000001)
	config->mode = STREAMING;
    else
	config->mode = EVENT_STREAMING;
       
    if(currVal &  0x00000002)
	config->trig_from_chana = 1;
    else
	config->trig_from_chana = 0;
       
    if(currVal &  0x00000004)
	config->trig_above_threshold = 1;
    else
	config->trig_above_threshold = 0;
	 
    config->trig_samples = ((currVal >> 8) & 0x000000FF);
    config->trig_threshold = ((currVal >> 16) & 0x0000FFFF);
	
    config->post_samples = regs.post_register;
    config->pre_samples = regs.pre_register;
    config->decimation = regs.decimator_register + 1;
}
  
  

// #define PKT_REG_ADDR 0x43c30000

void plot_ascii_a(u_int32_t data, FILE *f) {
    int j;
    int range_hlf = 0x2FFFF;
    int displ_max = 80;
    int range_max = range_hlf << 1;

    fprintf(f,"[0x%8x] [",data);
    data = data & 0xFFFF + range_hlf;
    for(j=0; j<displ_max; j++) {
        if ( j == data * displ_max / range_max ) fprintf(f,"+");
        else if ( j == range_hlf * displ_max / range_max ) fprintf(f,"^");
        else fprintf(f," ");
    }
    fprintf(f,"]\n");
}

void plot_ascii_ab(u_int32_t data, FILE *f) {
    int j;
    int range_hlf = 0x2000;
    int displ_max = 80;
    int range_max = range_hlf << 1;

    int16_t d0 = data & 0xFFFF;
    int16_t d1 = data >> 16;
    fprintf(f,"[0x%8x,0x%8x] [",d0,d1);
    for(j=0; j<displ_max; j++) {
        if ( j == (d0 + range_hlf) * displ_max / range_max ) fprintf(f,"+");
        else if ( j == (d1 + range_hlf)   * displ_max / range_max ) printf("x");
        else if ( j == range_hlf * displ_max / range_max ) fprintf(f,"^");
        else fprintf(f," ");
    }
    fprintf(f,"]\n");
}

#pragma pack(push, 1)
struct decimator_reg_t { int dec; };
struct packetsize_reg_t { int size; };
#pragma pack(pop)


static void printConfig(struct rpadc_configuration *config)
{
    printf("CONFIG:\n");
    if(config->mode == STREAMING)
	printf("\tmode: STREAMING\n");
    else
 	printf("\tmode: EVENT_STREAMING\n");
     
    if(config->trig_above_threshold)
	printf("\ttrig_above_threshold: true\n");
    else
 	printf("\ttrig_above_threshold: false\n");

    if(config->trig_from_chana)
	printf("\ttrig_from_chana: true\n");
    else
 	printf("\ttrig_from_chana: false\n");
    
    printf("\ttrig_samples: %d\n", config->trig_samples);
    printf("\ttrig_threshold: %d\n", config->trig_threshold);
    printf("\tpre_samples: %d\n", config->pre_samples);
    printf("\tpost_samples: %d\n", config->post_samples);
    printf("\tdecimation: %d\n", config->decimation);
}



int main(int argc, char **argv) {
    unsigned int command;
    struct decimator_reg_t *dec_reg;
    struct packetsize_reg_t *pkt_reg;
    struct rpadc_configuration inConfig, outConfig;
    printf("rpadc test \n");
    const char *file_out_name = "rpadc_data";
    fd_set readset;

    if(argc<3) {
        printf("usage: %s dev dec samples \n",argv[0]);
        return 1;
    }


    int status = 0, result;
//    int fd = open(argv[1], O_RDWR | O_SYNC | O_NONBLOCK);
    int fd = open(argv[1], O_RDWR | O_SYNC);
    if(fd < 0) {
        printf(" ERROR: failed to open device file %s error: %d\n",argv[1],fd);
        return 1;
    }

     printf("aperto \n");

    command = 0x00000002;
    status = ioctl(fd, RPADC_DMA_AUTO_SET_COMMAND_REGISTER, &command);
    sleep(1);
    status = ioctl(fd, RPADC_DMA_AUTO_STOP_DMA, 0);
    sleep(1);

    inConfig.mode = EVENT_STREAMING;
//    inConfig.mode = STREAMING;
    inConfig.trig_samples = 2;
    inConfig.trig_above_threshold = 1;
    inConfig.trig_from_chana = 1;
//    inConfig.trig_threshold = -6500;
    inConfig.trig_threshold = 5000;
//    inConfig.trig_threshold = 0;
    inConfig.pre_samples = PRE_SAMPLES;
    inConfig.post_samples = POST_SAMPLES;
    inConfig.decimation = atoi(argv[2]);
    printConfig(&inConfig);
    writeConfig(fd, &inConfig);
    //status = ioctl(fd, RFX_RPADC_SET_CONFIG, &inConfig);
    memset(&outConfig, 0, sizeof(outConfig));
    printf("configurato \n");
     
     //status = ioctl(fd, RFX_RPADC_GET_CONFIG, &outConfig);
    readConfig(fd, &outConfig);
    printf("letto \n");
    printConfig(&outConfig);
    status = ioctl(fd, RPADC_DMA_AUTO_CLEAR_TIME_FIFO, 0);
    sleep(1);
    int cyclic = 1;
    status = ioctl(fd, RPADC_DMA_AUTO_START_DMA, &cyclic);
    sleep(1);
    command = 0x00000001;
    status = ioctl(fd, RPADC_DMA_AUTO_SET_COMMAND_REGISTER, &command);
    sleep(1);
    printf("TRIGGER!\n");
    command = 0x00000004;
    status = ioctl(fd, RPADC_DMA_AUTO_SET_COMMAND_REGISTER, &command);

    
    int i, j, size = atoi(argv[3]);
    size = MIN((size)*sizeof(u_int32_t),BUF_SIZE);
    if (size <= 0) { return size; }

    char *data = malloc(sizeof(u_int32_t) * size);
    if (!data) { perror("malloc\n"); exit (1); }


//Test FIFO overflow
//    for(i = 0; i < 10; i++)
//    {
//	sleep(1);
//	printf("FIFO Overflow: %d\n",   ioctl(fd, RFX_RPADC_OVERFLOW, 0));
//    }

    int frameCount = 0;
    int currTime = 0;
    //sleep(3);
    for(i=0;i<size;) {
/*	do {
	    FD_ZERO(&readset);
	    FD_SET(fd, &readset);
	    result = select( fd+1, &readset, NULL, NULL, NULL);
	} while(result == -1 & errno == EINTR);
*/
        int rb = read(fd,&data[0], size );
	if(rb < 0)
	{
	    printf("ERROR IN READ!!\n");
	    break;
	}
        for(int j=0; j<rb; j+=sizeof(u_int32_t)) {
            plot_ascii_ab(*((u_int32_t *)&data[j]),stdout);
	    i++;
	    if(i%(PRE_SAMPLES+POST_SAMPLES) == 0)
	    {	
		unsigned long timeL;
		unsigned int time1, time2;
		unsigned int timeLen = 0;
		ioctl(fd, RPADC_DMA_AUTO_GET_TIME_FIFO_LEN, &timeLen);
		ioctl(fd, RPADC_DMA_AUTO_GET_TIME_FIFO_VAL, &time1);
		ioctl(fd, RPADC_DMA_AUTO_GET_TIME_FIFO_VAL, &time2);
		

		printf("FIFO len: %d, time1: %d, time2: %d\n", timeLen, time1, time2);
		for (j = 0; j < timeLen - 2; j++) 
		    ioctl(fd, RPADC_DMA_AUTO_GET_TIME_FIFO_VAL, &time1);
	    }
        }
    }


    // PLOT TO FILE //
    //
    //    u_int32_t *data = malloc(sizeof(u_int32_t) * size);
    //    if (!data) { perror("malloc\n"); exit (1); }
    //    for(i=0;i<size;) {
    //        int rb = read(fd,&data[i],BUF_SIZE);
    //        i += rb/sizeof(u_int32_t);
    //    }
    //
    //    char name[256];
    //    FILE *file_out = fopen(strcat(strcpy(name,file_out_name),".out"),"w");
    //    FILE *file_plt = fopen(strcat(strcpy(name,file_out_name),".plt"),"w");
    //    FILE *file_py = fopen(strcat(strcpy(name,file_out_name),".py"),"w");
    //    fwrite(data,sizeof(u_int32_t),size,file_out);
    //
    //    fprintf(file_py,
    //            "\ndef get_data():\n"
    //            "\timport struct\n"
    //            "\tf = open(\"%s.out\", \"rb\")\n"
    //            "\ta=[]\n"
    //            "\tfor i in range(%d):\n"
    //            "\t\ta.append(struct.unpack('i', f.read(4))[0])\n"
    //            "\treturn a"
    //            ,
    //            file_out_name,
    //            size
    //            );
    //
    //    fprintf(file_py,
    //            "\ndef plot_data():\n"
    //            "\timport matplotlib.pyplot as plt\n"
    //            "\ta=get_data();"
    //            "\tplt.plot(a)\n"
    //            "\tplt.show()\n"
    //            );
    //
    //    fprintf(file_plt,"plot \"scc52460_data.out\" binary format=\"%int32\" u 1 w lp");
    //
    //    fclose(file_out);
    //    fclose(file_plt);
    //    fclose(file_py);
    //    free(data);

    command = 0x00000002;
    status = ioctl(fd, RPADC_DMA_AUTO_SET_COMMAND_REGISTER, &command);
    sleep(1);
    status = ioctl(fd, RPADC_DMA_AUTO_STOP_DMA, 0);

    sleep(1);

    // CLOSE FILE //
    close(fd);

    // AXI REG RELEASE //
    axi_reg_Release();

    return 0;
}
