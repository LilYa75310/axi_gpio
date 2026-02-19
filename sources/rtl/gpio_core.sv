`timescale 1ns/1ps

module axi_gpio #(
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 32,
  parameter int GPIO_WIDTH = 32
)(  

//   //GPIO interface signals
//   //Channel 1
//   input  logic [GPIO_WIDTH-1:0]            GPIO_IO_I,
//   output logic [GPIO_WIDTH-1:0]            GPIO_IO_O,
//   output logic [GPIO_WIDTH-1:0]            GPIO_IO_T,
//   //Channel 2
//   input  logic [GPIO_WIDTH-1:0]            GPIO2_IO_I,
//   output logic [GPIO_WIDTH-1:0]            GPIO2_IO_O,
//   output logic [GPIO_WIDTH-1:0]            GPIO2_IO_T,

  //GPIO inout pins
  //Channel 1
  inout logic [GPIO_WIDTH-1:0]             GPIO_IO,
  //Channel 2
  inout logic [GPIO_WIDTH-1:0]             GPIO2_IO
);

  // //GPIO interface signals
  // logic [GPIO_WIDTH-1:0]            read_reg_in;
  // //Channel 1
  // logic [GPIO_WIDTH-1:0]            gpio_tri;
  // logic [GPIO_WIDTH-1:0]            gpio_data;
  // //Channel 2
  // logic [GPIO_WIDTH-1:0]            gpio2_tri;
  // logic [GPIO_WIDTH-1:0]            gpio2_data;

endmodule