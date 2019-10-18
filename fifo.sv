module fifo
#(
    parameter ADDR_SIZE = 10,
    parameter WORD_SIZE = 8
)
(
    input  logic clk,
    input  logic rstn,

    input  logic fwft,

    output logic full,
    input  logic we,
    input  logic [WORD_SIZE-1:0] wdata,

    output logic empty,
    input  logic re,
    output logic [WORD_SIZE-1:0] rdata
);
logic [ADDR_SIZE:0]   pointer_we, pointer_re; // + 1 бит
logic [WORD_SIZE-1:0] data_ram;
logic [ADDR_SIZE-1:0] addr_read;

ram
    #(
        .ADDR_SIZE  (ADDR_SIZE),
        .WORD_SIZE  (WORD_SIZE)
    )
ram_i1
    (
        .clk    (clk),

        .w_addr (pointer_we[ADDR_SIZE-1:0]),
        .w_data (wdata),
        .we     (~full),

        .r_addr (addr_read),
        .r_data (data_ram)  
    );

always_ff @(negedge rstn, posedge clk)
    if(~rstn)
        pointer_we <= 0;
    else if(fwft)
        pointer_we <= 0;
    else if(~full && we)
        pointer_we <= pointer_we + 1;

always_ff @(negedge rstn, posedge clk)
    if(~rstn) begin
        pointer_re[ADDR_SIZE]     <= 1;
        pointer_re[ADDR_SIZE-1:0] <= 0;
    end
    else if(fwft)begin
        pointer_re[ADDR_SIZE]     <= 1;
        pointer_re[ADDR_SIZE-1:0] <= 0;
    end        
    else if(~empty && re)
        pointer_re <= pointer_re + 1;


always_comb
    if( pointer_re[ADDR_SIZE-1:0] == pointer_we[ADDR_SIZE-1:0] &&  
        pointer_re[ADDR_SIZE]     != pointer_we[ADDR_SIZE])
            empty = 1;
    else 
            empty = 0;

always_comb
    if( pointer_re[ADDR_SIZE-1:0] == pointer_we[ADDR_SIZE-1:0] &&  
        pointer_re[ADDR_SIZE]     == pointer_we[ADDR_SIZE])
            full = 1;
    else 
            full = 0;

assign addr_read = pointer_re[ADDR_SIZE-1:0] + (re && ~empty);

always_ff @(negedge rstn, posedge clk)
    if(~rstn)
        rdata <= 0;
    else if(fwft && we)
        rdata <= wdata;
    else if(~empty && re)
        rdata <= data_ram;


endmodule 

//модуль ram прилагался к заданию 
module ram #(parameter ADDR_SIZE = 10, parameter WORD_SIZE = 8)(
  input clk,

  input [ADDR_SIZE - 1 : 0] w_addr,
  input [WORD_SIZE - 1 : 0] w_data,
  input we,


  input [ADDR_SIZE - 1 : 0] r_addr,
  output [WORD_SIZE - 1 : 0] r_data
);


// -----------------------------------------------------------------------------
reg [WORD_SIZE - 1 : 0] mem [0 : 2 ** ADDR_SIZE - 1];
reg [ADDR_SIZE - 1 : 0] r_addr_reg;


// -----------------------------------------------------------------------------
always @(posedge clk) begin
  r_addr_reg <= r_addr;
end
assign r_data = mem[r_addr_reg];


// -----------------------------------------------------------------------------
always @(posedge clk) begin
  if (we == 1'b1) begin
    mem[w_addr] <= w_data;
  end
end
endmodule
