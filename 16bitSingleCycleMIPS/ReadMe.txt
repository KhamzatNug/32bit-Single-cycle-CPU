Single-cycle 16 bit CPU
(instruction set will be expanded later[last update: andi,ori,sll,slr] , multy-cycle and pipelined version will come later(logisim + verilog))  

Program Counter(16 bit register):
	Word-addressable(it is usefull to use one of these registers to hold "zero" temporary, but it is up to you.)

Instruction Memory(16X32)

Data Memory(16X16)

Register File(16x32): 
	16 registers, the first one $0(contains 0)

Instruction encoding:
	R-type
              32 bits = op(6)-rs(5)-rt(5)-rd(5)-shamt(5)-funct(6)
	in our case rs[5]=rt[5]=rd[5]=0(we have only 16 registers, not 32)
	
	I-type
	      32 bits = op(6)-rs(5)-rt(5)-imm(16);
	There is no need to extend "imm" up to 32 as in regular 32bit MIPS
	
	J-type
	      32 bits = op(6)-imm(26)
	in our case imm[25:16]=0, cause we are using 16bit address

Instructions:
R-type (op=0)
1)add rs,rt,rd ([rd]<=[rs]+[rt]), funct = 100000
2)sub rs,rt,rd ([rd]<=[rs]-[rt]), funct = 100010
3)and rs,rt,rd ([rd]<=[rs]and[rt]), funct = 100100
4)or rs,rt,rd  ([rd]<=[rs]or[rt]), funct = 100101
5)slt rs,rt,rd ([rd]=1 if [rs]<[rt], 0 otherwise) funct = 101011
6)sll rt,rd,shamp ([rd] <= [rs]<<shamp) funct = 000000
7)slr rt,rd,shamp ([rd] <= [rs]>>shamp) funct = 000001

I-type
1)lw rs,rt,imm ([rt]<=datamem[[rs]+imm]), op = 100011
2)sw rs,rt,imm ([datamem[[rs]+imm]<=[rt]), op = 100100
3)beq rs,rt,imm (if [rs]==[rt] then branch to pc+imm address),
	op = 001000
4)addi rs,rt,imm ([rt]<=[rs]+imm), op = 010000
5)andi rs,rt,imm ([rt]<=[rs]and(imm)), op = 101000
6)ori rs,rt,imm ([rt]<=[rs]or(imm)), op = 001101

J-type
1)j target (jump to target address), op=000010


Example Program:
	calculates the gcd of two numbers(might not be the most efficient program)
	this program is already stored in instruction memory 
	
	addi $1,$0,32   
	addi $2,$0,48
	while:
		beg $1,$2,target
		slt $3,$1,$2
		beq $3,$0,else
		sub $2,$2,$1
		j while
   		else: sub $1,$1,$2
		j while
	target:
		addi $15,$1,$0