`timescale 1ns/1ps

module axi_gpio #(
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 32,
  parameter int GPIO_WIDTH = 32
)(  
  //Global sys signals 
  input  logic                             S_AXI_ACLK,
  input  logic                             S_AXI_ARESETN,

  //Axi write address channel
  input  logic [AXI_ADDR_WIDTH-1:0]        S_AXI_AWADDR_I,
  input  logic                             S_AXI_AWVALID_I,
  output logic                             S_AXI_AWREADY_O,

  //Axi write data channel
  input  logic [AXI_DATA_WIDTH-1:0]        S_AXI_WDATA_I,
  input  logic [AXI_DATA_WIDTH/8-1:0]      S_AXI_WSTB_I,
  input  logic                             S_AXI_WVALID_I,
  output logic                             S_AXI_WREADY_O,

  //Axi write response channel
  output logic [1:0]                       S_AXI_BRESP_O,
  output logic                             S_AXI_BVALID_O,
  input  logic                             S_AXI_BREADY_I,

  //Axi read address channel
  input  logic [AXI_ADDR_WIDTH-1:0]        S_AXI_ARADDR_I,
  input  logic                             S_AXI_ARVALID_I,
  output logic                             S_AXI_ARREADY_O,
  
  //Axi read data channel
  output logic [AXI_DATA_WIDTH-1:0]        S_AXI_RDATA_O,
  output logic [1:0]                       S_AXI_RRESP_O,
  output logic                             S_AXI_RVALID_O,
  input  logic                             S_AXI_RREADY_I,

  //GPIO interface signals
  output logic                             DATA_RECEIVED_O,
  output logic [AXI_ADDR_WIDTH-1:0]        AW_DATA_REG_O,
  output logic [AXI_DATA_WIDTH-1:0]        W_DATA_REG_O,
  output logic [AXI_DATA_WIDTH/8-1:0]      W_STROBE_O,
  output logic [AXI_ADDR_WIDTH-1:0]        READ_ADDR_O,
  input  logic [AXI_DATA_WIDTH-1:0]        GPIO_DATA_I                    
);
  //AW
  logic                             axi_awready;
  
  //assign outputs to top level signals
  assign S_AXI_AWREADY_O = axi_awready;
  
  //W
  logic                             axi_wready;
  assign S_AXI_WREADY_O = axi_wready;

  //B
  logic [1:0]                       axi_bresp;
  logic                             axi_bvalid;
  assign S_AXI_BRESP_O = axi_bresp;
  assign S_AXI_BVALID_O = axi_bvalid;

  //AR
  logic                             axi_arready;
  assign S_AXI_ARREADY_O = axi_arready;
  
  //R
  logic [AXI_DATA_WIDTH-1:0]        axi_rdata;
  logic [1:0]                       axi_rresp;
  logic                             axi_rvalid;
  assign S_AXI_RDATA_O = axi_rdata;
  assign S_AXI_RRESP_O = axi_rresp;
  assign S_AXI_RVALID_O = axi_rvalid;

  //GPIO interface
  logic                             data_received;
  logic [AXI_ADDR_WIDTH-1:0]        aw_data_reg;
  logic [AXI_DATA_WIDTH-1:0]        w_data_reg;
  logic [AXI_DATA_WIDTH/8-1:0]      w_strobe;
  logic [AXI_ADDR_WIDTH-1:0]        read_addr;
  
  assign DATA_RECEIVED_O = data_received;
  assign AW_DATA_REG_O = aw_data_reg;
  assign W_DATA_REG_O = w_data_reg;
  assign W_STROBE_O = w_strobe;
  assign READ_ADDR_O = read_addr;
  
  // internal signals
  logic aw_done;
  logic w_done;
  logic aw_shake;
  logic w_shake;
  
  assign aw_shake = S_AXI_AWVALID_I && axi_awready;
  assign w_shake = S_AXI_WVALID_I && axi_wready;

  // ======================================
  // AXI WRITE
  // ======================================
  //AW handshake
  always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : AW_handshake
    if(!S_AXI_ARESETN) begin
      axi_awready <= 1'b1;
      aw_data_reg <= '0;
    end else begin
      if(S_AXI_AWVALID_I && axi_awready) begin
        axi_awready <= 1'b0;
        aw_data_reg <= S_AXI_AWADDR_I;
      end else if (axi_bvalid && S_AXI_BREADY_I) begin
        axi_awready <= 1'b1;
      end
    end
  end

  //W handshake
  always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : W_handshake
    if(!S_AXI_ARESETN) begin
      axi_wready <= 1'b1;
      w_data_reg <= '0;
      w_strobe <= '0;
      data_received <= 1'b0;
    end else begin
      if(S_AXI_WVALID_I && axi_wready) begin
        axi_wready <= 1'b0;
        w_data_reg <= S_AXI_WDATA_I;
        w_strobe <= S_AXI_WSTB_I;
        data_received <= 1'b1;
      end else if (axi_bvalid && S_AXI_BREADY_I) begin
        axi_wready <= 1'b1;
        data_received <= 1'b0;
      end
    end
  end
  
  // B response
  always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : B_response
    if(!S_AXI_ARESETN) begin
      aw_done <= 1'b0;
      w_done <= 1'b0;
      axi_bvalid <= 1'b0;
      axi_bresp <= 2'b00;
    end else begin
      if(aw_shake) begin
        aw_done <= 1'b1;
      end

      if(w_shake) begin
        w_done <= 1'b1;
      end

      if((aw_done || aw_shake) && (w_done || w_shake) && !axi_bvalid) begin
        axi_bvalid <= 1'b1;
        axi_bresp <= 2'b00;
      end else if(axi_bvalid && S_AXI_BREADY_I) begin
        axi_bvalid <= 1'b0;
        aw_done <= 1'b0;
        w_done <= 1'b0;
      end
    end
  end
  // ======================================
  
  // ======================================
  // AXI READ
  // ======================================

  always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : AR_handshake
    if(!S_AXI_ARESETN) begin
      axi_arready <= 1'b1;
      read_addr <= '0;
    end else begin
      if(axi_arready && S_AXI_ARVALID_I) begin
        axi_arready <= 1'b0;
        read_addr <=  S_AXI_ARADDR_I;
      end else if(axi_rvalid && S_AXI_RREADY_I) begin
        axi_arready <= 1'b1;
      end
    end
  end

  always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : R_handshake
    if(!S_AXI_ARESETN) begin
      axi_rvalid <= 1'b0;
      //axi_rdata <= '0;
      axi_rresp <= 2'b00;
    end else begin
      if(axi_arready && S_AXI_ARVALID_I) begin
        axi_rvalid <= 1'b1;
        //axi_rdata <= GPIO_DATA_I;
        axi_rresp <= 2'b00;
      end else if(axi_rvalid && S_AXI_RREADY_I) begin
        axi_rvalid <= 1'b0;
      end
    end
  end
  assign axi_rdata = GPIO_DATA_I;
endmodule

  // typedef enum logic [1:0] {
  //   RD_ADDR,
  //   RD_DATA
  // } read_state_t;
  
  // read_state_t rd_state;
  // read_state_t rd_state_next;
  
  // // State register
  // always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : fsm_read_state_reg
  //   if(!S_AXI_ARESETN) begin
  //     rd_state <= RD_ADDR;
  //   end else begin
  //     rd_state <= rd_state_next;
  //   end
  // end

  // // Next-state logic
  // always_comb begin : fsm_read_next_state_logic
  //   rd_state_next = 2'bx;

  //   case (rd_state)
  //     RD_ADDR: begin
  //       if(axi_arready && S_AXI_ARVALID_I) begin
  //         rd_state_next = RD_DATA;
  //       end else begin
  //         rd_state_next = RD_ADDR;
  //       end
  //     end

  //     RD_DATA: begin
  //       if(axi_rvalid && S_AXI_RREADY_I) begin
  //         rd_state_next = RD_ADDR;
  //       end else begin
  //         rd_state_next = RD_DATA;
  //       end
  //     end

  //     default: rd_state_next = RD_ADDR;
  //   endcase
  // end

  // output logic [AXI_ADDR_WIDTH-1:0]        READ_ADDR_O
  // input  logic [AXI_DATA_WIDTH-1:0]        GPIO_DATA_I
  // logic [AXI_ADDR_WIDTH-1:0]        read_addr;
  // assign READ_ADDR_O = read_addr;
  // // Output register
  // always_ff @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin : fsm_out_reg
  //   if(!S_AXI_ARESETN) begin
  //     axi_arready <= 1'b1;
  //     axi_rdata <= '0;
  //     axi_rresp <= 2'b00;
  //     axi_rvalid <= 1'b0;
  //     read_addr <= '0;
  //   end else begin

  //     case (rd_state_next)
  //       RD_ADDR: begin
  //         axi_arready <= 1'b1;
  //         if(axi_arready && S_AXI_ARVALID_I) begin
  //           read_addr <= S_AXI_ARADDR_I;
  //         end
  //         if(axi_rvalid && S_AXI_RREADY_I) begin
  //           axi_rvalid <= 1'b0;
  //         end
  //       end

  //       RD_DATA: begin
          
  //       end
      
  //       default: rd_state_next = RD_ADDR; 
  //     endcase
  //   end
  // end
  // // ======================================

