`timescale 1ns/1ps

module gpio_core #(
  parameter int AXI_ADDR_WIDTH = 32,
  parameter int AXI_DATA_WIDTH = 32,
  parameter int GPIO_WIDTH = 1
)(  
  //Global sys signals 
  input  logic                             clk_i,
  input  logic                             reset_n,
  //GPIO write interface signals
  input  logic                             wr_en_i,
  input  logic [AXI_ADDR_WIDTH-1:0]        wr_addr_i,
  input  logic [AXI_DATA_WIDTH/8-1:0]      wr_strb_i,
  input  logic [AXI_DATA_WIDTH-1:0]        wr_data_i,
  //GPIO read interface signals
  output logic                             rd_done_o,
  output logic [AXI_DATA_WIDTH-1:0]        rd_data_o,
  output logic [1:0]                       rd_err_o,
  input  logic                             rd_en_i,
  input  logic [AXI_ADDR_WIDTH-1:0]        rd_addr_i,
  
  output logic [GPIO_WIDTH-1:0]            gpio_tri_o,
  output logic [GPIO_WIDTH-1:0]            gpio_data_o,
  input  logic [GPIO_WIDTH-1:0]            gpio_data_in_i

  //GPIO inout pins
  //Channel 1
  //inout  logic [GPIO_WIDTH-1:0]            gpio_io
  //Channel 2
  //inout  logic [GPIO_WIDTH-1:0]            gpio2_io
);
  
  // //Channel 1
  logic [GPIO_WIDTH-1:0]            gpio_tri;
  logic [GPIO_WIDTH-1:0]            gpio_data;
  logic [GPIO_WIDTH-1:0]            gpio_data_in;
  logic [AXI_ADDR_WIDTH-1:0]        rd_addr_q;
  logic [GPIO_WIDTH-1:0]            wr_data_masked;
  // //Channel 2
  // logic [GPIO_WIDTH-1:0]            gpio2_tri;
  // logic [GPIO_WIDTH-1:0]            gpio2_data;

  //assign gpio_io = gpio_tri ? gpio_data : 'z;
  //assign gpio_io = gpio_tri ? gpio_data : {GPIO_WIDTH{1'bz}};

  assign gpio_tri_o = gpio_tri;
  assign gpio_data_o = gpio_data;
  assign gpio_data_in = gpio_data_in_i;

  // genvar i;
  // generate
  //   for (i = 0; i < GPIO_WIDTH; i++) begin
  //     assign gpio_io[i] = gpio_tri[i] ? gpio_data[i] : 1'bz;
  //   end
  // endgenerate

  //assign gpio_data_in = gpio_io;
  
   assign wr_data_masked = wr_data_i[GPIO_WIDTH-1:0];

  always_ff @(posedge clk_i or negedge reset_n) begin : write_logic
    if(!reset_n) begin
      gpio_data <= '0;
      gpio_tri <= '1;
    end else begin
      if(wr_en_i) begin
        case(wr_addr_i[3:0])
          4'h0: begin
            for (int i = 0; i < GPIO_WIDTH; i++) begin
              if(wr_strb_i[i/8]) begin // or i>>3
                gpio_data[i] <= wr_data_masked[i];
              end
            end
          end

          4'h4: begin
            for (int i = 0; i < GPIO_WIDTH; i++) begin
              if(wr_strb_i[i/8]) begin // or i>>3
                gpio_tri[i] <= wr_data_masked[i];
              end
            end
          end

          default: ;
        endcase
      end
    end
  end

  //read interface
  typedef enum logic [1:0] {
    RD_IDLE,
    RD_BUSY,
    RD_DONE
  } read_state_t;
  
  read_state_t rd_state;
  read_state_t rd_state_next;

  logic [1:0] counter;
  
  // State register
  always_ff @(posedge clk_i or negedge reset_n) begin : fsm_read_state_reg
    if(!reset_n) begin
      rd_state <= RD_IDLE;
    end else begin
      rd_state <= rd_state_next;
    end
  end
  
  // Counter
  always_ff @(posedge clk_i or negedge reset_n) begin : fsm_counter_delay
    if(!reset_n) begin
      counter <= '0;
    end else begin
      if(rd_state == RD_BUSY) begin
        if(counter == 2'd1) begin
          counter <= 2'd0;
        end else begin
          counter <= counter + 1'b1;
        end
      end else begin
        counter <= '0;
      end
    end
  end
  
  always_ff @(posedge clk_i or negedge reset_n) begin
    if(!reset_n)
      rd_addr_q <= '0;
    else if(rd_state == RD_IDLE && rd_en_i)
      rd_addr_q <= rd_addr_i;
  end

  // Next-state logic
  always_comb begin : fsm_read_next_state_logic
    //rd_state_next = 2'bx;

    case (rd_state)
      RD_IDLE: begin
        if(rd_en_i) begin
          rd_state_next = RD_BUSY;
        end else begin
          rd_state_next = RD_IDLE;
        end
      end

      RD_BUSY: begin
        if(counter == 2'd1) begin
          rd_state_next = RD_DONE;
        end else begin
          rd_state_next = RD_BUSY;
        end
      end

      RD_DONE: begin
        rd_state_next = RD_IDLE;
      end

      default: rd_state_next = RD_IDLE;
    endcase
  end

  // Output register
  always_ff @(posedge clk_i or negedge reset_n) begin : fsm_out_reg
    if(!reset_n) begin
      rd_data_o <= '0;
      rd_done_o <= '0;
      rd_err_o <= '0;
    end else begin
      rd_done_o <= '0;
      rd_data_o <= 1'b0;
      rd_err_o <= 2'b00;

      case (rd_state_next)
        RD_IDLE: ;

        RD_BUSY: ;

        RD_DONE: begin
          rd_done_o <= 1'b1;
          //case (rd_addr_i[3:0])
          case (rd_addr_q[3:0])
            4'h0: begin
              //rd_data_o <= gpio_data_in;
              rd_data_o <= {{(AXI_DATA_WIDTH-GPIO_WIDTH){1'b0}}, gpio_data_in};
            end

            4'h4: begin
              //rd_data_o <= gpio_tri;
              rd_data_o <= {{(AXI_DATA_WIDTH-GPIO_WIDTH){1'b1}}, gpio_tri};
            end

            default: begin
              rd_data_o <= '0;
              rd_err_o <= 2'b10;
            end
          endcase
        end
      endcase
    end
  end


endmodule