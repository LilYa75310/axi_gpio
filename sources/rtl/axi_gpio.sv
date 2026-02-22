`timescale 1ns/1ps

module axi_gpio #(
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 32,
  parameter int GPIO_WIDTH = 32
)(  
  //Global sys signals 
  input  logic                             s_axi_aclk_i,
  input  logic                             s_axi_areset_n,

  //Axi write address channel
  input  logic [AXI_ADDR_WIDTH-1:0]        s_axi_awaddr_i,
  input  logic                             s_axi_awvalid_i,
  output logic                             s_axi_awready_o,
  //Axi write data channel
  input  logic [AXI_DATA_WIDTH-1:0]        s_axi_wdata_i,
  input  logic [AXI_DATA_WIDTH/8-1:0]      s_axi_wstb_i,
  input  logic                             s_axi_wvalid_i,
  output logic                             s_axi_wready_o,
  //Axi write response channel
  output logic [1:0]                       s_axi_bresp_o,
  output logic                             s_axi_bvalid_o,
  input  logic                             s_axi_bready_i,
  //Axi read address channel
  input  logic [AXI_ADDR_WIDTH-1:0]        s_axi_araddr_i,
  input  logic                             s_axi_arvalid_i,
  output logic                             s_axi_arready_o,
  //Axi read data channel
  output logic [AXI_DATA_WIDTH-1:0]        s_axi_rdata_o,
  output logic [1:0]                       s_axi_rresp_o,
  output logic                             s_axi_rvalid_o,
  input  logic                             s_axi_rready_i,
  //GPIO write interface signals
  output logic [AXI_ADDR_WIDTH-1:0]        wr_addr_o,
  output logic [AXI_DATA_WIDTH-1:0]        wr_data_o,
  output logic [AXI_DATA_WIDTH/8-1:0]      wr_strb_o,
  output logic                             wr_en_o,
  //GPIO read interface signals
  input  logic                             rd_done_i,
  input  logic [AXI_DATA_WIDTH-1:0]        rd_data_i,
  input  logic [1:0]                       rd_err_i,
  output logic                             rd_en_o,
  output logic [AXI_ADDR_WIDTH-1:0]        rd_addr_o
);
  
  // internal signals
  logic aw_shake_q;
  logic w_shake_q;
  logic aw_shake;
  logic w_shake;
  
  assign aw_shake = s_axi_awvalid_i && s_axi_awready_o;
  assign w_shake = s_axi_wvalid_i && s_axi_wready_o;


  // ======================================
  // AXI WRITE
  // ======================================
  //AW handshake
  always_ff @(posedge s_axi_aclk_i or negedge s_axi_areset_n) begin : AW_handshake
    if(!s_axi_areset_n) begin
      s_axi_awready_o <= 1'b1;
      wr_addr_o <= '0;
    end else begin
      if(aw_shake) begin
        s_axi_awready_o <= 1'b0;
        wr_addr_o <= s_axi_awaddr_i;
      end else if (s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_awready_o <= 1'b1;
      end
    end
  end

  //W handshake
  always_ff @(posedge s_axi_aclk_i or negedge s_axi_areset_n) begin : W_handshake
    if(!s_axi_areset_n) begin
      s_axi_wready_o <= 1'b1;
      wr_data_o <= '0;
      wr_strb_o <= '0;
    end else begin
      if(w_shake) begin
        s_axi_wready_o <= 1'b0;
        wr_data_o <= s_axi_wdata_i;
        wr_strb_o <= s_axi_wstb_i;
      end else if (s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_wready_o <= 1'b1;
      end
    end
  end
  
  // B response
  always_ff @(posedge s_axi_aclk_i or negedge s_axi_areset_n) begin : B_response
    if(!s_axi_areset_n) begin
      aw_shake_q <= 1'b0;
      w_shake_q <= 1'b0;
      s_axi_bvalid_o <= 1'b0;
      s_axi_bresp_o <= 2'b00;
      wr_en_o <= 1'b0;
    end else begin
      if(aw_shake) begin
        aw_shake_q <= 1'b1;
      end

      if(w_shake) begin
        w_shake_q <= 1'b1;
      end

      if((aw_shake_q || aw_shake) && (w_shake_q || w_shake) && !s_axi_bvalid_o) begin
        s_axi_bvalid_o <= 1'b1;
        s_axi_bresp_o <= 2'b00;
        wr_en_o <= 1'b1;
      end else if(s_axi_bvalid_o && s_axi_bready_i) begin
        s_axi_bvalid_o <= 1'b0;
        aw_shake_q <= 1'b0;
        w_shake_q <= 1'b0;
        wr_en_o <= 1'b0;
      end
    end
  end
  // ======================================
  
  // ======================================
  // AXI READ
  // ======================================

  typedef enum logic [1:0] {
    RD_IDLE,
    RD_ADDR,
    RD_WAIT_DONE,
    RD_WRITE_AXI_SIG
  } read_state_t;
  
  read_state_t rd_state;
  read_state_t rd_state_next;
  
  // State register
  always_ff @(posedge s_axi_aclk_i or negedge s_axi_areset_n) begin : fsm_read_state_reg
    if(!s_axi_areset_n) begin
      rd_state <= RD_IDLE;
    end else begin
      rd_state <= rd_state_next;
    end
  end

  // Next-state logic
  always_comb begin : fsm_read_next_state_logic
    //rd_state_next = 2'bx;

    case (rd_state)
      RD_IDLE: begin
        if(s_axi_arvalid_i) begin
          rd_state_next = RD_ADDR;
        end else begin
          rd_state_next = RD_IDLE;
        end
      end

      RD_ADDR: begin
        rd_state_next = RD_WAIT_DONE;
      end

      RD_WAIT_DONE: begin
        if(rd_done_i) begin
          rd_state_next = RD_WRITE_AXI_SIG;
        end else begin
          rd_state_next = RD_WAIT_DONE;
        end
      end

      RD_WRITE_AXI_SIG: begin
        if(s_axi_rready_i) begin
          rd_state_next = RD_IDLE;
        end else begin
          rd_state_next = RD_WRITE_AXI_SIG;
        end
      end

      default: rd_state_next = RD_IDLE;
    endcase
  end

  // Output register
  always_ff @(posedge s_axi_aclk_i or negedge s_axi_areset_n) begin : fsm_out_reg
    if(!s_axi_areset_n) begin
      rd_en_o <= 1'b0;
      rd_addr_o <= '0;
      s_axi_rdata_o <= '0;
      s_axi_rresp_o <= 2'b00;
      s_axi_rvalid_o <= 1'b0;
    end else begin
      case (rd_state_next)
        RD_IDLE: begin
          rd_en_o <= 1'b0;
          rd_addr_o <= '0;
          s_axi_rdata_o <= '0;
          s_axi_rresp_o <= 2'b00;
          s_axi_rvalid_o <= 1'b0;
        end

        RD_ADDR: begin
          rd_en_o <= 1'b1;
          rd_addr_o <= s_axi_araddr_i;
        end

        RD_WAIT_DONE: begin
          rd_en_o <= 1'b0;
        end

        RD_WRITE_AXI_SIG: begin
          s_axi_rvalid_o <= 1'b1;
          s_axi_rresp_o <= rd_err_i;
          s_axi_rdata_o <= rd_data_i;
        end
      
      endcase
    end
  end

  assign s_axi_arready_o = rd_done_i;

endmodule
