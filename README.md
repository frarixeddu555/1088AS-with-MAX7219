# 1088AS-with-MAX7219
We control a 1088AS matrices module with MAX7219 driver with an FPGA.

# Tools and devices
- FPGA Spartan-3 XCS400-4FT256 (50 MHz)
- LED RGB WS2812
- Oscilloscope Tektronix TDS1001B
- ISE Xilinx

# Overall description
This code realizes the controlling of a module of 16 1088AS LED matrices equipped with a MAX7219 driver.
Instead of controlling directly the matrices, we interface with MAX7219 driver using the SPI protocol.
We use a memory in order to realize a stream of sequences that realize the sight of a defined stream images: after initializing the registers, the subsequent istruction realize the display of various arrows that move from left to right through the module.


