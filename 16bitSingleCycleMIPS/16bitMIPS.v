`timescale 1ns/100ps


module CPU(ROUT, clk,reset);
	output [15:0] ROUT;
	input clk, reset;

	wire [15:0] AluOut, PCout, WDATA, RDATA;
	wire [31:0] Inst;
	MIPS M(AluOut, PCout, ROUT, DataWrite, WDATA, RDATA, Inst, clk, reset);
	InnstructionMem I(Inst, PCout);
	DataMem D(RDATA, AluOut, WDATA,  DataWrite, clk);

endmodule

module MIPS(AluOut, PCout, ROUT, DataWrite, WDATA, RDATA, Inst, clk, reset);
	output [15:0] AluOut, PCout, ROUT;
	output [15:0] WDATA;
	output DataWrite;
	input clk, reset;
	input [15:0] RDATA;
	input [31:0] Inst;

	wire [2:0] AluCont;

	Controller C0(DataToReg, DataWrite, Branch, AluMux, 
					RegAddress, RegWrite, AluCont, Jump,
					Inst[31:26], Inst[5:0], Zero);

	DataPath D0(Zero, PCout, ROUT, AluOut, WDATA, DataToReg, Branch, 
				AluMux, RegAddress, RegWrite, AluCont, Jump, Inst, RDATA, clk, reset);


endmodule



module Controller(DataToReg, DataWrite, Branch, AluMux, 
					RegAddress, RegWrite, AluCont, Jump,
					OpCode, Function, Zero);

	output DataToReg, DataWrite, Branch, AluMux, RegAddress, RegWrite, Jump;
	output [2:0] AluCont;
	input [5:0] OpCode, Function;
	input Zero;

	wire [1:0] AluOp;
	OpDecoder D0(DataToReg, DataWrite, Branch, AluMux, 
						RegAddress, RegWrite, Jump, AluOp, OpCode, Zero);
	FuncDecoder D1(AluCont, Function, AluOp);

endmodule


module OpDecoder(DataToReg, DataWrite, Branch, 
				AluMux, RegAddress, RegWrite, Jump, AluOp, OpCode, Zero);

		output  DataToReg, DataWrite, AluMux, RegAddress, RegWrite, Jump, Branch;
		output [1:0] AluOp;
		input [5:0] OpCode;
		input Zero;
		wire  Branch0;

		reg [8:0] controlsig;
		assign {RegWrite, RegAddress, AluMux, Branch0, DataWrite, DataToReg, Jump, AluOp} = controlsig;
		always @* begin
			case (OpCode)
				6'b0: controlsig = 9'b110000010; //R-type inst
				6'b100011: controlsig = 9'b101001000; //LW
				6'b101011: controlsig = 9'b001010000; //SW
				6'b001000: controlsig = 9'b000100001; //Beq
				6'b010000: controlsig = 9'b101000000; //Addi
				6'b000010: controlsig = 9'b000000100; //Jump
				default: controlsig = 9'bxxxxxxxxx;
			endcase
		end

		assign Branch = (Branch0 & Zero);
endmodule 

module FuncDecoder(AluCont, Function, AluOp);
	output reg[2:0] AluCont;
	input [5:0] Function;
	input [1:0] AluOp;

	always @* begin 
		case(AluOp)
			2'b0: AluCont = 3'b010; //Add;
			2'b01: AluCont = 3'b110; //Sub;
			2'b10: begin 
					case(Function) 
			 			 6'b100000: AluCont = 3'b010;//Add
			 			 6'b100010: AluCont = 3'b110;//Sub
			 			 6'b100100: AluCont = 3'b000; //And
			 			 6'b100101: AluCont = 3'b001;//Or
			 			 6'b101010: AluCont = 3'b111;//SLT
			 			 default: AluCont = 3'bxxx;
					endcase
					end
			default: AluCont = 3'bxxx;
		endcase
	end

endmodule 


module DataPath(Zero, PCout, ROUT, AluOut, WDATA, DataToReg, Branch, 
				AluMux, RegAddress, RegWrite, AluCont, Jump, Inst, RDATA, clk, reset);

	output Zero;
	output [15:0] PCout, ROUT;//ROUT used only for debugging 
	output [15:0] AluOut, WDATA;
	input DataToReg, Branch, AluMux, RegAddress, RegWrite, Jump, clk, reset;
	input[2:0] AluCont;
	input[15:0] RDATA; //Data from Data memory;
	input[31:0] Inst; //Instruction From Instruction memory;
	wire[15:0] W1,W2,WD3,D1,D2,RD1,RD2;
	wire[3:0] A1,A2,A3;

	assign WDATA = RD2;
	assign A1 = Inst[24:21];
	assign A2 = Inst[19:16];
	Mux M0(A3, Inst[19:16], Inst[14:11], RegAddress);
	Mux #16 M1 (WD3, AluOut, RDATA, DataToReg); //mux before RegFile
 	Mux #16 M2(W1, PCout+16'b1, PCout+Inst[15:0]+16'b1, Branch); //mux before counter
 	Mux #16 M3(W2, W1, Inst[15:0], Jump);
 	Mux #16 M4(D2, RD2, Inst[15:0], AluMux); //mux before ALU

	RegFile regf(RD1, RD2, ROUT, A1, A2, A3, WD3, RegWrite, clk);
	ALU Alu(AluOut, Zero, RD1, D2, AluCont);
	ProgramCounter PC(PCout, W2, clk, reset);

endmodule 

module Mux(Q, D0,D1, s);
	parameter bits = 4;
	output [bits-1:0] Q;
	input [bits-1:0] D0,D1;
	input s;

	assign Q = (s==0) ? D0 : D1;
endmodule 

module ALU(AluOut, Zero, RD1, RD2, AluCont);
	output Zero;
	output reg[15:0] AluOut;
	input [15:0] RD1, RD2;
	input [2:0] AluCont;

	assign Zero = (RD1==RD2);
	always @* begin 
		case (AluCont)
			3'b010: AluOut = RD1+RD2; 
			3'b110: AluOut = RD1-RD2;
			3'b000: AluOut = RD1&RD2;
			3'b001: AluOut = RD1|RD2;
			3'b111: if (RD1 < RD2) AluOut = 16'b1111_1111_1111_1111; else AluOut = 16'b0;
			default: AluOut = 16'bxxxx_xxxx_xxxx_xxxx;
		endcase
	end

endmodule 


module ProgramCounter(PCout, D, clk, reset);
	output reg [15:0] PCout;
	input [15:0] D;
	input clk, reset;	

	always @(posedge clk, posedge reset)
		if (reset) PCout <= 0;
		else PCout <= D;

endmodule

module RegFile(RD1, RD2, ROUT, A1, A2, A3, WD3, WE,clk);
	output [15:0] RD1,RD2,ROUT;
	input [3:0] A1,A2,A3;
	input [15:0] WD3;
	input WE, clk;

	reg [16:0] rf[16:0];

	assign ROUT = rf[15];
	assign RD1 = (A1!=0) ? rf[A1] : 0;
	assign RD2 = (A2!=0) ? rf[A2] : 0;
	//register 0 is used for holding 0, however it is up to user
	//It is usefull to use one of 16 registers to hold zero temporary.

	always @(posedge clk)
		if (WE) rf[A3] <= WD3;

endmodule

module InnstructionMem(Inst, Address);
	output reg [31:0] Inst;
	input [15:0] Address;

	reg[31:0] ROM[10:0];
	
	initial
		$readmemh("instruction.txt", ROM); //gcd(32,28) program

	always @*
		Inst = ROM[Address];

endmodule


module DataMem(RDATA, Address, WDATA, WE, clk);
	output reg[15:0] RDATA;
	input [15:0] Address, WDATA;
	input WE, clk;

	reg [15:0] RAM[15:0];
	always @(posedge clk)
		if (WE) RAM[Address]<=WDATA;

	always @*
		if (!WE) RDATA = RAM[Address]; 

endmodule







module test;
	reg clk, reset;

	wire [15:0] ROUT;
	CPU MAIN(ROUT, clk,reset);

	initial #800 $finish;

	initial begin clk=0; forever #5 clk=~clk; end

	initial fork
		reset = 1;
		#10 reset =0;
	join


	initial begin
		$dumpfile("MIPS.vcd");
		$dumpvars(0,test);
	end

endmodule






