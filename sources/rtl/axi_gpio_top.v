`timescale 1ns/1ps

module axi_gpio_top #(
  parameter integer AXI_ADDR_WIDTH = 32,
  parameter integer AXI_DATA_WIDTH = 32,
  parameter integer GPIO_WIDTH     = 1
)(
  // ======================================
  // AXI-Lite Interface
  // ======================================
  input  wire                         s_axi_aclk,
  input  wire                         s_axi_aresetn,

  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
  input  wire                         s_axi_awvalid,
  output wire                         s_axi_awready,

  input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata,
  input  wire [AXI_DATA_WIDTH/8-1:0]  s_axi_wstrb,
  input  wire                         s_axi_wvalid,
  output wire                         s_axi_wready,

  output wire [1:0]                   s_axi_bresp,
  output wire                         s_axi_bvalid,
  input  wire                         s_axi_bready,

  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
  input  wire                         s_axi_arvalid,
  output wire                         s_axi_arready,

  output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  output wire [1:0]                   s_axi_rresp,
  output wire                         s_axi_rvalid,
  input  wire                         s_axi_rready,

  //inout  wire [GPIO_WIDTH-1:0]        gpio_io
  output wire [GPIO_WIDTH-1:0] gpio_data,
  output wire [GPIO_WIDTH-1:0] gpio_tri,
  input  wire [GPIO_WIDTH-1:0] gpio_data_in
);

  

  // assign gpio_io = gpio_tri ? gpio_data : {GPIO_WIDTH{1'bz}};
  // assign gpio_data_in = gpio_io;

  // ======================================
  // AXI → core signals
  // ======================================

  wire [AXI_ADDR_WIDTH-1:0]   wr_addr;
  wire [AXI_DATA_WIDTH-1:0]   wr_data;
  wire [AXI_DATA_WIDTH/8-1:0] wr_strb;
  wire                        wr_en;

  wire                        rd_en;
  wire [AXI_ADDR_WIDTH-1:0]   rd_addr;
  wire                        rd_done;
  wire [AXI_DATA_WIDTH-1:0]   rd_data;
  wire [1:0]                  rd_err;

  // ======================================
  // AXI Slave
  // ======================================

  axi_gpio u_axi_gpio (
    .s_axi_aclk_i     (s_axi_aclk),
    .s_axi_areset_n   (s_axi_aresetn),

    .s_axi_awaddr_i   (s_axi_awaddr),
    .s_axi_awvalid_i  (s_axi_awvalid),
    .s_axi_awready_o  (s_axi_awready),

    .s_axi_wdata_i    (s_axi_wdata),
    .s_axi_wstb_i     (s_axi_wstrb),
    .s_axi_wvalid_i   (s_axi_wvalid),
    .s_axi_wready_o   (s_axi_wready),

    .s_axi_bresp_o    (s_axi_bresp),
    .s_axi_bvalid_o   (s_axi_bvalid),
    .s_axi_bready_i   (s_axi_bready),

    .s_axi_araddr_i   (s_axi_araddr),
    .s_axi_arvalid_i  (s_axi_arvalid),
    .s_axi_arready_o  (s_axi_arready),

    .s_axi_rdata_o    (s_axi_rdata),
    .s_axi_rresp_o    (s_axi_rresp),
    .s_axi_rvalid_o   (s_axi_rvalid),
    .s_axi_rready_i   (s_axi_rready),

    .wr_addr_o        (wr_addr),
    .wr_data_o        (wr_data),
    .wr_strb_o        (wr_strb),
    .wr_en_o          (wr_en),

    .rd_done_i        (rd_done),
    .rd_data_i        (rd_data),
    .rd_err_i         (rd_err),
    .rd_en_o          (rd_en),
    .rd_addr_o        (rd_addr)
  );

  // ======================================
  // GPIO Core
  // ======================================

  gpio_core u_gpio_core (
    .clk_i            (s_axi_aclk),
    .reset_n          (s_axi_aresetn),

    .wr_en_i          (wr_en),
    .wr_addr_i        (wr_addr),
    .wr_strb_i        (wr_strb),
    .wr_data_i        (wr_data),

    .rd_done_o        (rd_done),
    .rd_data_o        (rd_data),
    .rd_err_o         (rd_err),
    .rd_en_i          (rd_en),
    .rd_addr_i        (rd_addr),

    .gpio_tri_o       (gpio_tri),
    .gpio_data_o      (gpio_data),
    .gpio_data_in_i   (gpio_data_in)
  );



endmodule