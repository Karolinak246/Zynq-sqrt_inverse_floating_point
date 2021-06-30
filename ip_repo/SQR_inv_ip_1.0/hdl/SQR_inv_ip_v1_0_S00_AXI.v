
`timescale 1 ns / 1 ps

	module SQR_inv_ip_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      //slv_reg2 <= 0;
	      //slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                //slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                //slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      //slv_reg2 <= slv_reg2;
	                      //slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
//We create acive-high reset signal for cordic_ip module
wire ARESET;
assign ARESET = ~S_AXI_ARESETN;
//Code to transfer output data from cordic processor to output registers
wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire2;
wire [C_S_AXI_DATA_WIDTH-1:0] slv_wire3;
always @( posedge S_AXI_ACLK )
begin
 slv_reg2 <= slv_wire2;
 slv_reg3 <= slv_wire3;
end
//Assign zeros to unused bits
//assign slv_wire2[31:1] = 31'b0;
assign slv_wire2[31:1] = 4'b0;
assign slv_wire3[31:27] = 4'b0;
SQR_inv SQR_inv_inst( S_AXI_ACLK, //clock,
ARESET, //reset,
 slv_reg0[0], //start
 slv_wire2[0],//ready_out
 slv_reg1[22:0], //x_in ,
 slv_wire3[26:0]//y_out
 );
	// User logic ends

	endmodule
	
	
	
	
	module SQR_inv(clock, reset, start, ready_out, x_in , y_out);

//Input, outputs
input clock, reset, start;
input [22:0] x_in;
output reg ready_out;
output reg [26:0] y_out;

// LUT containing coefficients
// currently only one member of this table exists


// States
parameter S1 = 4'h00, S2 = 4'h01, S3 = 4'h02, S4 = 4'h03, S5 = 4'h04, S6 = 4'h05, S7 = 4'h06, S8 = 4'h07, S9 = 4'h08, S10 = 4'h09, S11 = 4'h0A, S12 = 4'h0B;
reg [3:0] state;

// Temporary variables
// temp_bin_to_754 - this variable holds on 32 bits regular binary converted into IEEE 754 standard
// temp_i - this variable holds on 32 bits the temp_bin_to_754 shifted by one position to the right
// temp_y - this variable holds on 32 bits result of substraction between "magic" variable stored in coeffs LUT and temp_i
// temp_754_exponent - this variable holds on 8 bits an exponent part of IEEE 754 standard number
// temp_exponent - this variable holds on 8 bits number 0'd127 required for creation exponent part of IEEE 754 number
// temp_sign - single bit representing sign bit in IEEE 754, always equal to zero in this example, placed in project for clarity and standard compliance
// temp_x - holds on 23 bits the input and result of loop iterations
// temp_754_to_bin - requires 27 bits and stores all operations required to achieve proper conversion from IEEE 754 to binary
// temp_cnt - 4 bit counter
// temp_cnt - additional 0'd127 constant 
reg signed [31:0] coeffs; //magic number
reg signed [31:0] temp_i, temp_bin_to_754;
reg signed [7:0] temp_exponent, temp_754_exponent;
reg signed [0:0] temp_sign;
reg signed [22:0] temp_x;
reg signed [26:0] temp_754_to_bin;
reg [3:0] temp_cnt;
reg [7:0] temp_127;

always @ (posedge clock)
begin
    if(reset==1'b1)
    begin
        ready_out <= 1'b0;
        state <= S1;
    end
    else
    begin
    case(state)
        S1: begin // If start the start :) 
            if(start == 1'b1) state <= S2; else state <= S1;
           end
        S2: begin // Init all vars
            coeffs <= 32'h5f3759df; //magic number
            temp_sign <= 0; //bit znaku zmienic temp - nie potrzebne
            temp_x <= x_in; //x2 wejœcie pozwalaj¹ce obliczyæ mantyse, operujemy na liczbach po przecinku 
            temp_i <= 0; //i - na tej zmiennej obliczenia
            y_out <= 0; //result
            temp_127 <= 0'd127; // potrzebna do konwersji powrotnej z iee754 na bin - niezmienne
            temp_exponent <= 0'd127; //eksponenta (zwi¹zane z E - 127) - zmienne
            temp_754_exponent <= 0; //wyciête z temp_y, eksponentw w standardzie
            temp_bin_to_754 <= 0; //z bin na 754 - konwesja z bin na standard IEE 754
            temp_754_to_bin <= 0'b000100000000000000000000000; //jest w bin, wynik z konw z 754 na bin zapis
            temp_cnt <= 0; //counter, do pêtli
            ready_out <= 0; //flaga, urz¹dzenie przesta³o dzia³aæ
            state <= S3;
        end
        S3: begin // If MSB of temp_x is equal to zero move shift to the right <-- basically while loop
            //$display("temp_x = %b", temp_x);
           if(temp_x[22] == 0)  //dopóki napotykamy 0 - przesuwamy
           begin
           temp_x <= temp_x <<< 1; // przesuwamy o 1 do czasu a¿ 1 - najstarszy bit
           temp_cnt <= temp_cnt + 1; // inkrementacja countera
           state <= S3;
           end
           else
           state <= S4;
        end
        S4:begin //One more shift
            temp_x <= temp_x <<< 1; // z nieznanych przyczyn robimy 1 raz ponowne przesuniêcie
            temp_cnt <= temp_cnt + 1;
            //$display("temp_x = %b", temp_x);
            state <= S5;
        end
        S5: begin //Determine exponent by substraction: 127 - counter
            temp_exponent <= temp_exponent - temp_cnt; // wartoœæ eksponenty = max - il wykonanych pêtli
            state <= S6;
        end
        S6:begin // Create IEEE 754 var by "concatenation": sign bit + exponent + mantissa 
            //$display("temp_exponent = %b", temp_exponent);
            temp_bin_to_754[31] <= temp_sign;// najstarszy bit - bit znaku
            temp_bin_to_754[30:23] <= temp_exponent; // 8 bbitów eksponenta
            temp_bin_to_754[22:0] <= temp_x; // mantysa
            //$display("temp_x = %b", temp_x);
           state <= S7;
        end
        S7: begin // Shift an IEEE 754 (an "x" in wikipedia) by one position to the right
            //start algorytmu
            temp_i <= temp_bin_to_754 >> 1; // podzielenie przez 2, przesuniêcie w prawo i = (i>>1)
            state <= S8;
        end
        S8:begin //"Magic happens" as stated in wikipedia 
            temp_i <= coeffs - temp_i; //i = magic - i
            state <= S9;
            //$display("temp_i = %b", temp_i);
        end
        S9: begin // Place fraction of IEEE 754 var into 23 LSB's of binary number, and place exponent of IEEE 754 to temp var 
        //tutaj by³oby mno¿enie
            //$display("temp_754_to_bin = %b", temp_754_to_bin);
            temp_754_to_bin[22:0] <= temp_i[22:0]; //temp_... "y" konwersja z 754 na bin, przenoszona sama mantysa - bo na niej obliczenia
            temp_754_exponent <= temp_i[30:23]; //sama eksponenta
            state <= S10;
        end
        S10:begin // If temp temp_754_to_bin is bigger than 127 shift by their difference to left else shift to right
           //$display("temp_754_to_bin = %b", temp_754_to_bin);
           if(temp_754_exponent - temp_127 > 0) // je¿eli wyk³adnik jest dodatni mno¿ymy 2^k - czyli przesuniêcie bitowe w lewo
           begin
                temp_754_to_bin <= temp_754_to_bin << (temp_754_exponent - temp_127);
           end
           else // je¿eli wyk³adnik jest inny mno¿ymy 2^k - czyli przesuniêcie bitowe w prawo
           begin
                temp_754_to_bin <= temp_754_to_bin >> (temp_754_exponent - temp_127);
           end
           state <= S11;
        end
        S11:begin // Write to an output
           $display("output = %b", temp_754_to_bin);
           y_out <= temp_754_to_bin;
           ready_out <= 1;
           state <= S12;
        end
        S12: begin // Wait for new input
            //$display("temp_754_to_bin = %b", temp_754_to_bin);
            if(start == 1'b0) state <= S12; else state <= S1;
        end
    endcase
    end
end

endmodule
