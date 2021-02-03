# The LocTag USB Bootloader (based on the TinyFPGA USB Bootloader)

## 依赖的软件包 (Ubuntu)：
1. Python (建议使用Python3，Python2也可)

    ```bash
    apt-get install python3-dev python3-pip
    pip3 install -U setuptools wheel
    pip3 install -U pyrsistent spacy
    ```

2. 适用于iCE40系列FPGA的开源开发套件
    ```bash
    pip install apio==0.4.0b5
    apio install system scons icestorm iverilog
    apio drivers --serial-enable
    ```

## 构建LocTag USB Bootloader

目录中已经放置了Makefile文件，克隆代码后直接使用make即可（推荐在Linux下进行）,make命令的输出中包含了FPGA资源使用情况和关键信号的时序信息。
```bash
git clone git@github.com:holyens/TinyFPGA-Bootloader.git
cd TinyFPGA-Bootloader/boards/LocTag_v3.1/ 
make H_VER=3.1.2
# save output to file: 
# make H_VER=3.1.2 > build_3_1_2.log 2>&1 
```

make成功后将生成可烧写的FPGA镜像文件，其中bootloader.bin为USB引导，loctag_test.bin为测试loctag板子的FPGA配置镜像（即用户镜像），loctag_3_1_2_firmware.bin同时包含bootloader.bin和loctag_test.bin的多配置镜像，因此烧写时只需要loctag_3_1_2_firmware.bin文件即可。

loctag上电后将加载内含的bootloader.bin，如果拨码开关4处于off，则bootloader利用ice40UP5K的WARM BOOT功能直接从bootloader跳转到用户镜像(严格地说是重新配置)；否则如果开关4处于on状态，则bootloader.bin在一段超时时间内检测板子是否通过USB连接了PC主机，如果连接了则停留在bootloader，否则的话将跳转到用户镜像,此后再想进入bootLoader需要将开关4拨至on状态然后重新插拔电源或按板子上的复位键。

## LocTag实验板程序烧写

### FLASH芯片初次烧写
FLASH芯片初次编程时需要使用专门的FLASH烧写工具，最好在将FLASH芯片焊到板子之前就进行烧写：
1. 准备W25Q64FV FLASH芯片（SOIC-8封装）和FLASH编程器（这里使用在淘宝购买的“USB土豪金编程器”）及编程器附带的烧录软件。
2. 将W25Q64FV FLASH芯片放置在编程器背面的SOIC位，注意引脚顺序。对准引脚后推荐用透明胶带将芯片固定在编程器上，在需要操作时用手按紧即可。
3. 将编程器插入电脑，打开烧录软件，选择芯片型号，然后打开生成的loctag_3_1_2_firmware.bin。
4. 依次执行擦除、烧写、校验。
5. 全部成功后取下芯片，将芯片焊到板子上。

### 使用板载USB接口烧写

1. 查询信息/读取测试
    ```bash
    sudo tinyprog -l       # 列出所有连接的设备
    sudo tinyprog -m       # 读取security pages的meta数据和FLASH芯片的JEDEC ID
    sudo tinyprog -r 0-10  # 读取[0x00,0x10)地址范围内的数据并打印
    ```
2. 烧录meta文件
    
    W25Q64FV FLASH提供了少量独立的存储空间，可利用它们存储板子的meta信息，这些meta信息包含板子相关的、tinyprog执行时需要的一些参数，所以在使用tinyprog烧写镜像之前，最好先烧录meta文件。

    tinyprog使用的meta文件有两个：bootmeta.json和boardmeta.json，对于每个板子，boardmeta.json中的uuid必须不同（为了使tinyprog能够区分不同的设备），其它可根据需要修改。需要注意的是，由于单个security page的大小256字节，所以meta文件的大小不能超过256字节！
    ```bash
    sudo tinyprog --security ../boards/LocTag_v3_1/boardmeta.json -a 1
    sudo tinyprog --security ../boards/LocTag_v3_1/bootmeta.json -a 2
    ```

3. 烧录用户镜像
    
    烧写用户镜像不会覆盖bootloader，默认tinyprog将读取flash存储器安全页中的bootmeta.json的地址配置，作为用户镜像的烧写地址。
    ```bash
    tinyprog -i 312.01 -p loctag.bin # 312.01为板子的uuid
    ```

4. 烧写bootloader

    **！！！谨慎操作！！！**
    ```bash
    sudo tinyprog -a 0x00 -p ./loctag_3_1_2_firmware.bin
    ```
    警告！！！如果烧写了不正确bootloader镜像，将导致bootloader的USB烧写功能失效，此时板子将无法再通过USB接口烧写镜像。这种情况下必须重新使用FLASH编程器对板子上的FLASH芯片进行编程，方法有二：（1）取下芯片后使用FLASH编程器烧写，步骤与前面所讲的初次烧写bootloader程序的步骤相同；（2）将FLASH编程器连接到板子上预留的FLASH SPI接口进行烧写。

    使用方法（2）必须满足以下条件：
    - 板子上电
    - 由于FLASH SPI接口也连接到了FPGA的SPI相关引脚，所以需要FPGA相关引脚处于高阻状态（输入或未使用状态，不能是输出状态），否则不仅不能烧写，还有可能损坏芯片。
      
    经验证，方法（2）无法使用前述的“USB土豪金编程器”烧写程序，但是可以使用另一块未焊接flash芯片、烧录了usb bootloader的loctag板子进行烧写。大致流程是先使用排线将烧写有bootloader的flash芯片接到未焊接flash芯片的loctag板子的SPI预留接口，等待该板子加载bootloader并被主机USB识别后，拔掉flash芯片，并将用排线将该板子与待烧写的板子的SPI预留接口对接，然后使用上述命令烧写无问题的bootloader。可知，无论哪种方法都比较麻烦，所以如无必要，请勿烧写和覆盖FLASH芯片bootloader部分的数据。

5. 从bootloader进入用户配置
  ```bash
  tinyprog -b
  ```

### loctag_test硬件测试程序
key_x is high when key_x is on.
```v
reg [22:0] t_counter;
assign {mio_4, mio_3, mio_2, mio_1} = {key_4, key_3, key_2, key_1};
assign ctrl_1 = (key_1 & clk_50mhz) | key_2;
assign lt5534_en = key_3;
assign mio_7 = trig ^ key_4;
assign mio_8 = adc_cs;
assign mio_9 = adc_so; 
assign mio_10 = ctrl_1;

assign adc_clk = clk_16mhz;
assign adc_cs = t_counter[5] | (~key_3);
assign led = t_counter[21];

always @(posedge clk_16mhz) begin
  t_counter <= t_counter + 1;
end
```

--------------------------------------- 分割线 -------------------------------------------

# The TinyFPGA USB Bootloader
The TinyFPGA USB Bootloader is an open source IP for programming FPGAs without extra USB interface chips.  It implements a USB virtual serial port to SPI flash bridge on the FPGA fabric itself.  For FPGAs that support loading multiple configurations it is possible for the bootloader to be completely unloaded from the FPGA before the user configuration is loaded in.  

From the host computer's perspective, the bootloader looks like a serial port.  This method was chosen because programming with serial ports is generally easier to understand than other USB-specific protocols.  Commands to boot into the user configuration or access the SPI flash are all transfered over this interface.  Using this serial interface, a programmer application on the host computer can issue commands to the SPI flash directly through the bootloader.  All of the details about programming the SPI flash are handled by the programmer application.

## Hardware Requirements
In order to implement the TinyFPGA USB Bootloader, an FPGA system...
1. **MUST** have USB_P and USB_N lines with 3.3v signalling for the USB interface.
2. **MUST** have an oscillator and PLL capable of generating an accurate and stable 48MHz in the FPGA fabric.
3. **MUST** have FPGA configuration stored on external SPI flash, loaded by FPGA on boot.
4. **MUST** have a 1.5k pull-up resistor on the USB_P line and **SHOULD** connect the 1.5K pull-up resistor to the `usb_pu` signal from the bootloader.
5. **SHOULD** support booting from multiple images stored in SPI flash.  The bootloader in the primary image, and the user configuration in a secondary image.  
6. **SHOULD** use SPI flash that is large enough for a multi-boot image with at least two FPGA configurations as well as any user data that may be stored there.  Use the appropriate tools for your FPGA to determine the size of the mult-boot image before selecting the SPI flash size.
7. **SHOULD** use SPI flash that supports programmable security register pages accessed with opcodes 0x44, 0x42, 0x48.  These register places are a useful location to store metadata for the board that the programmer application needs to properly program user configurations and data.

## FPGA Board Metadata
Each FPGA board implementing the TinyFPGA USB Bootloader may have different locations for the bootloader image, user image, user data, and other information.  These differences are driven by the FPGA's multi-boot capabilities/requirements and the size of the FPGA configuration image.

In order for a common bootloader and programmer application to program user images and user data to the correct locations, the programmer must know where these locations are in the SPI flash.  It is also useful to identify the board with a name and unique serial number.  This information along with other required and optional metadata is stored in the non-volatile security register pages of the SPI flash and optionally in the main SPI flash memory.

The programmer application will search security register pages 0-3 for valid metadata.  The metadata is stored in JSON format.  JSON was choosen because it is compact enough, is well understood, and easier to read and understand than a binary format. 

Below is an example of how the metadata may be structured and formatted for the TinyFPGA BX board:

#### SPI Flash Security Register Page 1 (write-protected)
One of the SPI flash security register pages contains fixed data about the board that does not change.  This is the name of the board, the hardware revision of the board, and serial number unique to the board name.  This security register page should be write protected as it should never be changed.  If the rest of the SPI flash is erased, this minimal amount of information will help the user to find recovery instructions.

```javascript
{"boardmeta":{
  "name": "TinyFPGA BX",
  "fpga": "ice40lp8k-cm81",
  "hver": "1.0.0",
  "serial": 10034
}}
```

#### SPI Flash Security Register Page 2 (not write-protected)
A seperate SPI flash security register page should contain or point to information that can change.  This includes the bootloader version number, update URL for new bootloader releases for this board, and an address map for the SPI flash that describes where the bootloader, user image, and user data belong.  Using this information the programmer application is able to discover where to put new user images and data without any input from the user or built-in knowledge about the board.  It makes the board plug-and-play.

Optionally, an additional `desc.tgz` file may be included in the SPI flash itself, or on the update page.  This `desc.gz` file contains the information necessary to develop with the board.  At a minimum it describes the FPGA name, package, and a mapping from FPGA pins to board IOs and peripherals.

```javascript
{"bootmeta": "@0xFF000+445"}
```

#### SPI Flash Memory Address 0xFF000
```javascript
{
  "bootloader": "TinyFPGA USB Bootloader",
  "bver": "2.0.0",
  "update": "https://tinyfpga.com/update/tinyfpga-bx",
  "addrmap": {
    "bootloader": "0x00000-0x2FFFF",
    "userimage":  "0x30000-0x4FFFF",
    "userdata":   "0x50000-0xFBFFF",
    "desc.tgz":   "0xFC000-0xFFFFF"
  }
}
```

A detailed explanation of the metadata structure will be added here.

## Protocol
The protocol on top of the USB virtual serial port takes the form of requests and responses.  Only the host computer is able to initiate requests.  The bootloader on the FPGA can only respond to requests.

### Boot Command
```
Length: 1 byte

+=====================+
|    Request Data     |
+=====+========+======+
| Byte| Field  |Value |
+=====+========+======+
|  0  | Opcode | 0x00 |
+-----+--------+------+
```

The `Boot` command forces the TinyFPGA B-series board to exit the bootloader and configure the FPGA with the user design from SPI flash.  Once the user design is loaded onto the FPGA, the bootloader is no longer present and the user design has full control over the FPGA, including the USB interface.   

### Access SPI Command
```
Length: Variable

+================================+
|          Request Data          |
+=====+===================+======+
| Byte|       Field       | Value|
+=====+===================+======+
|  0  |       Opcode      | 0x01 |
+-----+-------------------+------+
|  1  |  Write Length Lo  | 0xWW |
+-----+-------------------+------+
|  2  |  Write Length Hi  | 0xWW |
+-----+-------------------+------+
|  3  |   Read Length Lo  | 0xRR |
+-----+-------------------+------+
|  4  |   Read Length Hi  | 0xRR |
+-----+-------------------+------+
|  5  | Write Data Byte 0 | 0xDD |
+-----+-------------------+------+
+-----+-------------------+------+
| n+5 | Write Data Byte n | 0xDD |
+-----+-------------------+------+

+================================+
|         Response Data          |
+=====+===================+======+
| Byte|       Field       | Value|
+=====+===================+======+
|  0  |  Read Data Byte 0 | 0xDD |
+-----+-------------------+------+
+-----+-------------------+------+
|  n  |  Read Data Byte n | 0xDD |
+-----+-------------------+------+
```

The `Access SPI` command executes a transfer with the SPI flash.  SPI flash commands can have two phases:
1. Write phase.  Command opcode, address, and potentially data are shifted out the SPI master to the SPI flash.
2. Read phase.  Data is shifted from the SPI flash to the SPI master.

The `Write Length` and `Read Length` in the `Access SPI` command refer to these two phases.  In order to fully understand how to interact with the SPI flash you need to read the [datasheet for the SPI flash chip](http://datasheet.octopart.com/AT25SF041-SSHD-B-Adesto-Technologies-datasheet-62342976.pdf).  The datasheet contains a table that lists the commands the SPI flash chip supports.  

Here's a summary of the commands used to properly erase, program, and verify bitstreams on the SPI flash:

| Command               | Opcode      | Address Bytes | Dummy Bytes | Data Bytes | Datasheet Section |
|-----------------------|:-----------:|:-------------:|:-----------:|:----------:|:-----------------:|
| Resume                |     0xAB    |       0       |      0      |      0     |        11.4       |
| Read Man. and Dev. ID |     0x9F    |       0       |      0      |      0     |        11.1       |
| Read Status Reg 1     |     0x05    |       0       |      0      |      1     |        10.1       |
| Block Erase 4 KBytes  |     0x20    |       3       |      0      |      0     |         7.2       |
| Block Erase 32 KBytes |     0x52    |       3       |      0      |      0     |         7.2       |
| Block Erase 64 KBytes |     0xD8    |       3       |      0      |      0     |         7.2       |
| Write Enable          |     0x06    |       0       |      0      |      0     |         8.1       |
| Byte/Page Program     |     0x02    |       3       |      0      |     1+     |         7.1       |
| Read Array            |     0x0B    |       3       |      1      |     1+     |         6.1       |     

## SPI Flash Programming Flow

The SPI flash needs to be accessed in a specific order to successfully program the bitstream.  The following pseudocode illustrates how the `tinyprog` programmer programs user FPGA bitstreams into the SPI flash:

```
// SPI flash will be in deep sleep, we need to wake it up
issue resume command     

// read FPGA board metadata
for each SPI flash security register page 0-3:
    read the security register page and metadata JSON
    recursively read any other locations in SPI flash referenced by the metadata
 
 userimage_addr = metadata["bootmeta"]["addrmap"]["userimage"]

// erase user flash area
for each 4k block from (userimage_addr) to (userimage_addr + length(bitstream)):
    issue write enable command
    issue block erase 4 KBytes at current block address
    poll status reg 1 until bit 0 is cleared

// program new user bitstream into user flash area
for each 256 bytes from (userimage_addr) to (userimage_addr + length(bitstream)):
    issue write enable command
    write 256 bytes of of the bitstream and increment write offset by 256 bytes
    poll status reg 1 until bit 0 is cleared
    
// verify bitstream data is correct
read length(bitstream) bytes of of the bitstream, compare to bitstream file

if verify is successful then issue boot command to the bootloader
```

For exact details, see the [`tinyprog/__init__.py`](https://github.com/tinyfpga/TinyFPGA-Bootloader/blob/master/programmer/tinyprog/__init__.py) Python module in this repo.

