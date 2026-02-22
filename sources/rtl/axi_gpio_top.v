`timescale 1ns/1ps

module axi_gpio_top #(
  parameter integer AXI_ADDR_WIDTH = 32,
  parameter integer AXI_DATA_WIDTH = 32,
  parameter integer GPIO_WIDTH     = 32
)(
  // ======================================
  // AXI-Lite Interface
  // ======================================
  input  wire                         s_axi_aclk_i,
  input  wire                         s_axi_areset_n,

  // Write address channel
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_awaddr_i,
  input  wire                         s_axi_awvalid_i,
  output wire                         s_axi_awready_o,

  // Write data channel
  input  wire [AXI_DATA_WIDTH-1:0]    s_axi_wdata_i,
  input  wire [AXI_DATA_WIDTH/8-1:0]  s_axi_wstb_i,
  input  wire                         s_axi_wvalid_i,
  output wire                         s_axi_wready_o,

  // Write response channel
  output wire [1:0]                   s_axi_bresp_o,
  output wire                         s_axi_bvalid_o,
  input  wire                         s_axi_bready_i,

  // Read address channel
  input  wire [AXI_ADDR_WIDTH-1:0]    s_axi_araddr_i,
  input  wire                         s_axi_arvalid_i,
  output wire                         s_axi_arready_o,

  // Read data channel
  output wire [AXI_DATA_WIDTH-1:0]    s_axi_rdata_o,
  output wire [1:0]                   s_axi_rresp_o,
  output wire                         s_axi_rvalid_o,
  input  wire                         s_axi_rready_i,

  // ======================================
  // GPIO pins
  // ======================================
  inout  wire [GPIO_WIDTH-1:0]        gpio_io
);

  // ======================================
  // Internal interconnect signals
  // ======================================

  // Write side
  wire [AXI_ADDR_WIDTH-1:0]   wr_addr;
  wire [AXI_DATA_WIDTH-1:0]   wr_data;
  wire [AXI_DATA_WIDTH/8-1:0] wr_strb;
  wire                        wr_en;

  // Read side
  wire                        rd_en;
  wire [AXI_ADDR_WIDTH-1:0]   rd_addr;
  wire                        rd_done;
  wire [AXI_DATA_WIDTH-1:0]   rd_data;
  wire [1:0]                  rd_err;

  // ======================================
  // AXI GPIO Slave
  // ======================================

  axi_gpio #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .GPIO_WIDTH     (GPIO_WIDTH)
  ) u_axi_gpio (
    // AXI
    .s_axi_aclk_i     (s_axi_aclk_i),
    .s_axi_areset_n   (s_axi_areset_n),

    .s_axi_awaddr_i   (s_axi_awaddr_i),
    .s_axi_awvalid_i  (s_axi_awvalid_i),
    .s_axi_awready_o  (s_axi_awready_o),

    .s_axi_wdata_i    (s_axi_wdata_i),
    .s_axi_wstb_i     (s_axi_wstb_i),
    .s_axi_wvalid_i   (s_axi_wvalid_i),
    .s_axi_wready_o   (s_axi_wready_o),

    .s_axi_bresp_o    (s_axi_bresp_o),
    .s_axi_bvalid_o   (s_axi_bvalid_o),
    .s_axi_bready_i   (s_axi_bready_i),

    .s_axi_araddr_i   (s_axi_araddr_i),
    .s_axi_arvalid_i  (s_axi_arvalid_i),
    .s_axi_arready_o  (s_axi_arready_o),

    .s_axi_rdata_o    (s_axi_rdata_o),
    .s_axi_rresp_o    (s_axi_rresp_o),
    .s_axi_rvalid_o   (s_axi_rvalid_o),
    .s_axi_rready_i   (s_axi_rready_i),

    // Write interface to core
    .wr_addr_o        (wr_addr),
    .wr_data_o        (wr_data),
    .wr_strb_o        (wr_strb),
    .wr_en_o          (wr_en),

    // Read interface to core
    .rd_done_i        (rd_done),
    .rd_data_i        (rd_data),
    .rd_err_i         (rd_err),
    .rd_en_o          (rd_en),
    .rd_addr_o        (rd_addr)
  );

  // ======================================
  // GPIO Core
  // ======================================

  gpio_core #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
    .GPIO_WIDTH     (GPIO_WIDTH)
  ) u_gpio_core (
    .clk_i           (s_axi_aclk_i),
    .reset_n         (s_axi_areset_n),

    // Write interface
    .wr_en_i         (wr_en),
    .wr_addr_i       (wr_addr),
    .wr_strb_i       (wr_strb),
    .wr_data_i       (wr_data),

    // Read interface
    .rd_done_o       (rd_done),
    .rd_data_o       (rd_data),
    .rd_err_o        (rd_err),
    .rd_en_i         (rd_en),
    .rd_addr_i       (rd_addr),

    // GPIO pins
    .gpio_io         (gpio_io)
  );

endmodule