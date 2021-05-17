import sys
if len(sys.argv) < 3:
  print('Usage: python get_device_tree_info <device name> <device tree path> [synch_fifo]')
  sys.exit(0)

if len(sys.argv) > 3:
  isSynchFifo = True
  SYNCH_FIFO = sys.argv[3]
else:
  isSynchFifo = False
  
  
DEVICE_NAME = sys.argv[1]
DEVICE_TREE = sys.argv[2]

import re
f = open(DEVICE_TREE, 'r')
t = f.read()
isDma = False;
if len(re.findall('dma@',t)) > 0:
  isDma = True
  print ('IS DMA!')
  
  

  
  
regexp = '[\s]*[a-zA-Z0-9\-_]+:\saxi_cfg_register@[0-9]+'
rl = re.findall(regexp, t)
registers = []
for r in rl:
#  print(r)
  registers.append(r.split()[0][:-1])

regexp = '[\s]*[a-zA-Z0-9\-_]+:\saxi_sts_register@[0-9]+'
rl = re.findall(regexp, t)
for r in rl:
#  print(r)
  registers.append(r.split()[0][:-1])

regexpr = '[\s]*[a-zA-Z0-9\-_]+:\saxi_fifo_mm_s@[0-9]+'
fl = re.findall(regexpr, t)
fifos = []
for f in fl:
#  print(f)
  fifos.append(f.split()[0][:-1])

regexpr = '[\s]*[a-zA-Z0-9\-_]+:\saxi_[a-zA-Z0-9\-_]+@[0-9]+'
fl = re.findall(regexpr, t)
fifosRegs = []
isRegs = []
for f in fl:
#  print(f)
  fifosRegs.append(f.split()[0][:-1])
  isRegs.append('axi_cfg_register' in f or 'axi_sts_register' in f)

print(fifosRegs)

regConf = ''
baseId = 20
for reg in registers:
  regConf += ('#define '+DEVICE_NAME.upper()+'_GET_'+reg.upper()+'\t\t'+'_IO('+DEVICE_NAME.upper()+'_IOCTL_BASE, '+str(baseId)+')\n')
  baseId = baseId + 1 
  regConf += ('#define '+DEVICE_NAME.upper()+'_SET_'+reg.upper()+'\t\t'+'_IO('+DEVICE_NAME.upper()+'_IOCTL_BASE, '+str(baseId)+')\n')
  baseId = baseId + 1 

for fifo in fifos:
  regConf += ('#define '+DEVICE_NAME.upper()+'_GET_'+fifo.upper()+'_LEN\t\t'+'_IO('+DEVICE_NAME.upper()+'_IOCTL_BASE, '+str(baseId)+')\n')
  baseId = baseId + 1 
  regConf += ('#define '+DEVICE_NAME.upper()+'_GET_'+fifo.upper()+'_VAL\t\t'+'_IO('+DEVICE_NAME.upper()+'_IOCTL_BASE, '+str(baseId)+')\n')
  baseId = baseId + 1 
  regConf += ('#define '+DEVICE_NAME.upper()+'_CLEAR_'+fifo.upper()+'\t\t'+'_IO('+DEVICE_NAME.upper()+'_IOCTL_BASE, '+str(baseId)+')\n')
  baseId = baseId + 1 
  
regStruct = ''
for reg in registers:
  regStruct += ('\tchar '+reg+'_enable;\n')
  regStruct += ('\tunsigned int '+reg+';\n')

include = open('zynq_device.h.template', 'r').read()
include = include.replace('$$DEFINE_REGISTER_CODES$$', regConf)
include = include.replace('$$DEFINE_REGISTER_STRUCT$$', regStruct)
include = include.replace('$$DEVICE_NAME_U$$', DEVICE_NAME.upper())
include = include.replace('$$DEVICE_NAME_L$$', DEVICE_NAME.lower())

outF = open(DEVICE_NAME.lower()+'.h','w')
outF.write(include)
outF.close()

source = open('zynq_device.c.template', 'r').read()

declReg = ''
for reg in registers:
  declReg += '\tvoid * iomap_'+reg.lower()+';\n';
for fifo in fifos:
  declReg += '\tvoid * iomap_'+fifo.lower()+';\n';
  declReg += '\tvoid * iomap1_'+fifo.lower()+';\n';

source = source.replace('$$DECLARE_REGISTERS_IN_STRUCT$$', declReg)

iomapReg = ''
for reg in registers:
  iomapReg += '\tcase '+DEVICE_NAME.upper()+'_GET_'+reg.upper()+':\n'
  iomapReg += '\t{\n'
  iomapReg += '\t\tcopy_to_user ((void __user *)arg, dev->iomap_'+reg+', sizeof(u32));\n'
  iomapReg += '\t\treturn 0;\n'
  iomapReg += '\t}\n'
  iomapReg += '\tcase '+DEVICE_NAME.upper()+'_SET_'+reg.upper()+':\n'
  iomapReg += '\t{\n'
  iomapReg += '\t\tcopy_from_user (dev->iomap_'+reg+', (void __user *)arg, sizeof(u32));\n'
  iomapReg += '\t\treturn 0;\n'
  iomapReg += '\t}\n'
  
for fifo in fifos:
  iomapReg += '\tcase '+DEVICE_NAME.upper()+'_GET_'+fifo.upper()+'_LEN:\n'
  iomapReg += '\t{\n'
  iomapReg += '\t\tu32 val = readFifo(dev->iomap_'+fifo.lower()+',RDFO);\n'
  iomapReg += '\t\tcopy_to_user ((void __user *)arg, &val, sizeof(u32));\n'
  iomapReg += '\t\treturn 0;\n'
  iomapReg += '\t}\n'
  iomapReg += '\tcase '+DEVICE_NAME.upper()+'_GET_'+fifo.upper()+'_VAL:\n'
  iomapReg += '\t{\n'
  iomapReg += '\t\tu32 val = readFifo(dev->iomap1_'+fifo.lower()+',RDFD4);\n'
  iomapReg += '\t\tcopy_to_user ((void __user *)arg, &val, sizeof(u32));\n'
  iomapReg += '\t\treturn 0;\n'
  iomapReg += '\t}\n'
  iomapReg += '\tcase '+DEVICE_NAME.upper()+'_CLEAR_'+fifo.upper()+':\n'
  iomapReg += '\t{\n'
  iomapReg += '\t\tclearFifo(dev->iomap_'+fifo.lower()+',dev->iomap1_'+fifo.lower()+');\n'
  iomapReg += '\t\treturn 0;\n'
  iomapReg += '\t}\n'
  
iomapReg += '\tcase '+DEVICE_NAME.upper()+'_GET_REGISTERS:\n'
iomapReg += '\t{\n'
iomapReg += '\t\tstruct '+DEVICE_NAME.lower()+'_registers currConf;\n'
iomapReg += '\t\tmemset(&currConf, 0, sizeof(currConf));\n'
for reg in registers:
  iomapReg += '\t\tcurrConf.'+reg+' = *((u32 *)dev->iomap_'+reg+');\n'
iomapReg += '\t\tcopy_to_user ((void __user *)arg, &currConf, sizeof(currConf));\n'
iomapReg += '\t}\n'

iomapReg += '\tcase '+DEVICE_NAME.upper()+'_SET_REGISTERS:\n'
iomapReg += '\t{\n'
iomapReg += '\t\tstruct '+DEVICE_NAME.lower()+'_registers currConf;\n'
iomapReg += '\t\tcopy_from_user (&currConf, (void __user *)arg, sizeof(currConf));\n'
for reg in registers:
  iomapReg += '\t\tif(currConf.'+reg+'_enable)\n'
  iomapReg += '\t\t\t*((u32 *)dev->iomap_'+reg+') = currConf.'+reg+';\n'
iomapReg += '\t}\n'
source = source.replace('$$MAP_IOCTL$$', iomapReg)

mapFirstReg = ''

if isRegs[0]:
  mapFirstReg += '\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
  mapFirstReg += '\toff = r_mem->start & ~PAGE_MASK;\n'
  mapFirstReg += '\tstaticPrivateInfo.iomap_'+fifosRegs[0]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
else:
  mapFirstReg += '\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
  mapFirstReg += '\toff = r_mem->start & ~PAGE_MASK;\n'
  mapFirstReg += '\tstaticPrivateInfo.iomap_'+fifosRegs[0]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
  mapFirstReg += '\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);\n'
  mapFirstReg += '\toff = r_mem->start & ~PAGE_MASK;\n'
  mapFirstReg += '\tstaticPrivateInfo.iomap1_'+fifosRegs[0]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
  if fifosRegs[0] == SYNCH_FIFO:
    mapFirstReg+= '\tsetIrq(pdev);\n'



mapReg = ''
idx = 0


if isDma:
  for i in range(0, len(fifosRegs)):
    if isRegs[i]:
      mapReg += '\tcase '+str(i+1)+':\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;\n'
    else:
      mapReg += '\tcase '+str(i+1)+':\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap1_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
      if fifosRegs[i] == SYNCH_FIFO:
        mapReg+= '\t\tsetIrq(pdev);\n'
      mapReg += '\tbreak;\n'  

else:
  for i in range(1, len(fifosRegs)):
    if isRegs[i]:
      mapReg += '\tcase '+str(i)+':\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff); break;\n'
    else:
      mapReg += '\tcase '+str(i)+':\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
      mapReg += '\t\tr_mem = platform_get_resource(pdev, IORESOURCE_MEM, 1);\n'
      mapReg += '\t\toff = r_mem->start & ~PAGE_MASK;\n'
      mapReg += '\t\tstaticPrivateInfo.iomap1_'+fifosRegs[i]+' = devm_ioremap(&pdev->dev,r_mem->start+off,0xffff);\n'
      if fifosRegs[i] == SYNCH_FIFO:
        mapReg+= '\t\tsetIrq(pdev);\n'
      mapReg += '\tbreak;\n'  
  idx = idx+1
  
  
if isDma:  
  source = source.replace('$$MAP_FIRST_REGISTER$$', '')
else: 
  source = source.replace('$$MAP_FIRST_REGISTER$$', mapFirstReg)
source = source.replace('$$MAP_REGISTERS$$', mapReg)
source = source.replace('$$DEVICE_NAME_U$$', DEVICE_NAME.upper())
source = source.replace('$$DEVICE_NAME_L$$', DEVICE_NAME.lower())
if isDma:
  source = source.replace('$$SET_DEVICE_DMA_MODE$$', '#define HAS_DMA')
else:
  source = source.replace('$$SET_DEVICE_DMA_MODE$$', '')
  
if isSynchFifo:
  source = source.replace('$$SET_DEVICE_FIFO_MODE$$', '#define HAS_FIFO_INTERRUPT')
  source = source.replace('$$SYNCH_FIFO$$', SYNCH_FIFO)
else:
  source = source.replace('$$SET_DEVICE_FIFO_MODE$$', '')
  

outF = open(DEVICE_NAME.lower()+'.c','w')
outF.write(source)
outF.close()






