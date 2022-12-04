module f_axil #
    (
        // Width of data bus in bits
        parameter DATA_WIDTH = 32,
        // Width of address bus in bits
        parameter ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter STRB_WIDTH = (DATA_WIDTH/8)
    )
    (
        input  wire                   clk,
        input  wire                   rst,
    
        input  wire [ADDR_WIDTH-1:0]  s_axil_awaddr,
        input  wire [2:0]             s_axil_awprot,
        input  wire                   s_axil_awvalid,
        input wire                   s_axil_awready,

        input  wire [DATA_WIDTH-1:0]  s_axil_wdata,
        input  wire [STRB_WIDTH-1:0]  s_axil_wstrb,
        input  wire                   s_axil_wvalid,
        input wire                   s_axil_wready,

        input wire [1:0]             s_axil_bresp,
        input wire                   s_axil_bvalid,
        input  wire                   s_axil_bready,

        input  wire [ADDR_WIDTH-1:0]  s_axil_araddr,
        input  wire [2:0]             s_axil_arprot,
        input  wire                   s_axil_arvalid,
        input wire                   s_axil_arready,

        input wire [DATA_WIDTH-1:0]  s_axil_rdata,
        input wire [1:0]             s_axil_rresp,
        input wire                   s_axil_rvalid,
        input  wire                   s_axil_rready
    );

    // awaddr must remain stable, once the valid signal is asserted and must remain so untill ready becomes high
    // As long as valid is high, and ready is low then the data must remain stable until ready goes high
    property ar_stable;
        @(posedge clk) disable iff(rst)
            (s_axil_arvalid && !s_axil_arready) |-> $stable(s_axil_araddr);
    endproperty
    property ar_stable_2;
        @(posedge clk) disable iff(rst) 
            s_axil_arvalid |=> $stable(s_axil_araddr) ;
    endproperty

    // Once valid is asserted it must remain asserted till ready is high -> handshake completion 
    property val_rose;
        @(posedge clk) disable iff(rst) $rose(s_axil_arvalid);
    endproperty


    property val_rdy_stability(valid,ready);
        @(posedge clk) $rose(valid) |=> (valid)[*0:$] ##1  (valid && ready) ##1 !valid;
    endproperty
  //a1: assert property ( val_rose |-> s_axil_awvalid s_until_with s_axil_awready);
    asrt_val_rdy_aw: assert property  (val_rdy_stability(s_axil_awvalid, s_axil_awready));
   aSrt_val_rdy_w: assert property   (val_rdy_stability(s_axil_wvalid, s_axil_wready));
   asrt_val_rdy_r: assert property   (val_rdy_stability(s_axil_rvalid,s_axil_rready));
   asrt_val_rdy_ar: assert property  (val_rdy_stability(s_axil_arvalid,s_axil_arready));
   asrt_val_rdy_b: assert property   (val_rdy_stability(s_axil_bvalid,s_axil_bready));

/* 4
   As with the read address channel, while S_AXI_RVALID is true and the master has yet to raise S_AXI_RREADY,
    both S_AXI_RDATA and S_AXI_RRESP must remain constant.
    
    */

    property stable_packet(valid,ready,packet);
        @(posedge clk) disable iff(rst) (valid && !ready) |=> $stable(packet);
    endproperty
    asrt_r_stable_data: assert property (stable_packet(s_axil_rvalid,s_axil_rready,s_axil_rdata));
    asrt_b_stable_resp: assert property(stable_packet(s_axil_bvalid, s_axil_bready, s_axil_bresp));
   
    // These donot hold - reason : these are from A -> B valid: input ready -> output
    //asrt_ar_stable_addr: assert property (stable_packet(s_axil_arvalid,s_axil_arready,s_axil_araddr));
    //asrt_w_stable_data: assert property(stable_packet(s_axil_wvalid, s_axil_wready,s_axil_wdata));
    //asrt_aw_stable_addr: assert property(stable_packet(s_axil_awvalid, s_axil_awready, s_axil_awaddr));
    //asrt_aw_stable_prot: assert property(stable_packet(s_axil_awvalid, s_axil_awready, s_axil_awprot));
  
    



    //asrt_ar_stable: assert property (ar_stable);
    //asr_aw_handshake: assert property (aw_stable);
    property handshake(valid,ready);
        @(posedge clk) disable iff(rst)
            valid && ready;
    endproperty

    c_hs_r: cover property (handshake(s_axil_rready,s_axil_rvalid));
    c_hs_b: cover property (handshake(s_axil_bready,s_axil_bvalid));
    c_hs_w: cover property (handshake(s_axil_wready,s_axil_wvalid));
    c_hs_aw: cover property (handshake(s_axil_awready,s_axil_awvalid));
    c_hs_ar: cover property (handshake(s_axil_arready,s_axil_arvalid));

        /* 5
    For every request with S_AXI_ARVALID && S_AXI_ARREADY, 
    there must follow one clock period sometime later where S_AXI_RVALID && S_AXI_RREADY.
    
    */

    //read channel dependency
    // Once the awread handshake is done and addressis sent then the read data must become valid eventually
    property rd_depend;
        @(posedge clk) disable iff(rst) 
            (s_axil_arvalid && s_axil_arready) |-> ##[0:$] s_axil_rvalid;
    endproperty

    rd_dependency: assert property (rd_depend);


    // wr channel dependency
    // Once we write the data there must eventually be a response
    property wr_depend;
        @(posedge clk) disable iff(rst)
            (s_axil_wready && s_axil_wvalid) |-> ##[0:$] s_axil_bvalid;
    endproperty

    wr_dependency: assert property (wr_depend);

    /*
    A slave must not take BVALID High until after the write address is handshake is complete.
    
    -This fails -Xilinx condition
    */

    property bvalid_after_awhandshake;
        @(posedge clk) disable iff (rst) 
            (s_axil_awaddr && s_axil_awready) |=> !s_axil_bvalid;
    endproperty

    asrt_bvalid_after_awhandshake: assert property (bvalid_after_awhandshake);

    //
    /*
    Valid signals (output from slave) must go low first cycle after reset
    */

    property rst_valid (rst,valid);
        @(posedge clk) rst |=> !valid;
    endproperty
    asrt_rst_vaild_1: assert property (rst_valid(rst,s_axil_rvalid));
    asrt_rst_valid_2: assert property (rst_valid(rst,s_axil_bvalid));
endmodule