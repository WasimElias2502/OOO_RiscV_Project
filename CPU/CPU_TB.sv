/*------------------------------------------------------------------------------
 * File          : CPU_TB.sv
 * Project       : RTL
 * Author        : epwebq
 * Creation date : Nov 15, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module CPU_TB #() ();

	//reset & clk
	logic 										clk , reset							;
	ARCH_REG_READ_IF							ARCH_REG_READ_if()					;
	MEM_IF										MEM_if()							;
	logic										finish								;
	
	
	// ==================================================== CPU ============================================== // 
	
	CPU cpu(
		.clk				(clk),
		.reset				(reset),
		.ARCH_REG_READ_if	(ARCH_REG_READ_if.slave), 
		.MEM_if				(MEM_if.CPU),
		.finish				(finish)
	
	);
	
	// ================================================ D_MEMORY ============================================== //
	
	D_MEMORY_WRAPPER data_memory(
		.clk				(clk),
		.reset				(reset),
		.mem_if				(MEM_if.MEM)
	);
	
	// ========================================== Clk and Reset assigns ======================================= // 
	initial begin
		clk = 1'b0; // Ensure clk is explicitly 0 at time 0
	end
	always #20 clk = ~clk ;
		
	
	//reset
	initial
		begin
			reset = 1'b1;
			#35 reset = 1'b0;
			#15000 reset = 1'b1;
		end
	
	
	// ========================================== Register Read Tasks =+====================================== // 
	
	//Read Arch register
	task automatic read_register(
			input  logic [`ARCH_REG_NUM_WIDTH-1:0] 	reg_idx,
			output logic [`REG_VAL_WIDTH-1:0] 		data
	);
			
		@(posedge clk);
		ARCH_REG_READ_if.rd_en 					<= 1'b1		;
		ARCH_REG_READ_if.read_red_addr_req 		<= reg_idx	;
		
		@(posedge clk);
		while(!ARCH_REG_READ_if.read_valid) begin
			@(posedge clk);
		end
		
		data = ARCH_REG_READ_if.read_value					;
		
		
		ARCH_REG_READ_if.rd_en 					<= 1'b0		;
	
	endtask
	
	//Dump Regfile
	task automatic dump_regfile();
		
		logic [`REG_VAL_WIDTH-1:0] 		data;
		
		//go over all regs
		for (int reg_idx=0 ; reg_idx<`ARCH_REG_NUM ; reg_idx++) begin
			read_register( reg_idx , data);
			$display("[CPU_DEBUG] READ REG[%0d] = %0h\n" , reg_idx , data);
		end
		
	endtask
	
	// ============================================ Stimuli ===================================================== //
	initial begin
		
		
		ARCH_REG_READ_if.rd_en 				= 1'b0;
		ARCH_REG_READ_if.read_red_addr_req 	= '0;
		
		//Monitor FINISH indication of code
		@(posedge finish);
		$display("[CPU_DEBUG] Finish code at time: %t\n" , $time );
		
		dump_regfile();

	end
	
	
	//Setting Up waveform
	initial
		begin
			$fsdbDumpfile("CPU_TB_wave.vcd");
			$fsdbDumpvars(0,CPU_TB);
		end
	
	//end test after 500ns 
	initial 
		#20000 $finish;


endmodule