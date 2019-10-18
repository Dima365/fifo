module test_fifo 
#(
    parameter ADDR_SIZE = 10,
    parameter WORD_SIZE = 8
)
();
logic clk;
logic rstn;

logic fwft;

logic full;
logic we;
logic [WORD_SIZE-1:0] wdata;

logic empty;
logic re;
logic [WORD_SIZE-1:0] rdata;


logic fwft_en;
logic [WORD_SIZE-1:0] queue_fifo[$];
logic [WORD_SIZE-1:0] wdata_delay;
fifo 
    #(
        .ADDR_SIZE (ADDR_SIZE),
        .WORD_SIZE (WORD_SIZE)
    )
DUT
    (
        .*
    );

always
    #10 clk = ~clk;
    
always @(posedge clk)
    if(we && ~full && ~fwft)
        queue_fifo.push_front(wdata);
        
always @(posedge clk)
    if(re && ~empty && ~fwft) begin 
        #1
        if(queue_fifo.pop_back != rdata)begin
            $display ("time: %t", $time);
            #100 $stop;     
        end
    end
    else if(fwft && we) begin
        wdata_delay = wdata;
        #1
        if(wdata_delay != rdata)begin
            $display ("time: %t", $time);
            #100 $stop;
        end            
    end
    
always @(posedge clk)
    if(fwft)
        queue_fifo.delete();
    
initial begin
    clk   = 0;
    rstn  = 1;
    fwft  = 0;
    we    = 0;
    wdata = 0;
    re    = 0;
    #33 rstn = 0;
    #33 rstn = 1;

    fwft_en  = 0;
    around_full();
    around_empty();
    midle();

    fwft_en  = 1;
    around_full();
    around_empty();
    midle();
 
    #100
    $stop;
end

task around_full;
    while (~full)begin
        @(posedge clk); #1;
        we    = 1;
        wdata = $urandom;
    end
    we    = 0;
    wdata = 0;
    repeat(11)begin
        @(posedge clk); #1;
        re = $urandom_range(0,1);
        we = $urandom_range(0,1);
        if(we)
            wdata = $urandom;
        else 
            wdata = 0;
        if(fwft_en)
            if($urandom_range(0,1))
                fwft = 1;
            else 
                fwft = 0;
    end
    re    = 0;
    we    = 0;
    wdata = 0;
    fwft  = 0;
endtask

task around_empty;
    while (~empty)begin
        @(posedge clk); #1;
        re = 1;
    end
    re    = 0;
    repeat(11)begin
        @(posedge clk); #1;
        re = $urandom_range(0,1);
        we = $urandom_range(0,1);
        if(we)
            wdata = $urandom;
        else 
            wdata = 0;
        if(fwft_en)
            if($urandom_range(0,1))
                fwft = 1;
            else 
                fwft = 0;
    end
    re    = 0;
    we    = 0;
    wdata = 0;
    fwft  = 0;
endtask

task midle;
    while(DUT.pointer_we[ADDR_SIZE-1:0] < 2**(ADDR_SIZE-1))begin
        @(posedge clk); #1;
        we    = 1;
        wdata = $urandom;
    end
    we    = 0;
    wdata = 0;
    while(DUT.pointer_we[ADDR_SIZE-1:0] > 2**(ADDR_SIZE-1))begin
        @(posedge clk); #1;
        re    = 1;        
    end
    re = 0;
    repeat(11)begin
        @(posedge clk); #1;
        re = $urandom_range(0,1);
        we = $urandom_range(0,1);
        if(we)
            wdata = $urandom;
        else 
            wdata = 0;
        if(fwft_en)
            if($urandom_range(0,1))
                fwft = 1;
            else 
                fwft = 0;
    end
    re    = 0;
    we    = 0;
    wdata = 0;
    fwft  = 0;    
endtask



endmodule 
