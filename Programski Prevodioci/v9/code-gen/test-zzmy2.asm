
main:
			PUSH	%14
			MOV 	%15,%14
			SUBS	%15,$12,%15
@main_body:
			MOV 	$0,-4(%14)
@for_init0:
			MOV 	$0,-8(%14)
@for_condition0:
			CMPS 	-8(%14),$5
			JLTS	@for_statement0
			JMP		@for_exit0
@for_statement0:
@for_init1:
			MOV 	$0,-12(%14)
@for_condition1:
			CMPS 	-12(%14),$5
			JLTS	@for_statement1
			JMP		@for_exit1
@for_statement1:
			ADDS	-4(%14),$1,%0
			MOV 	%0,-4(%14)
			ADDS	-12(%14),$1,-12(%14)
			JMP		@for_condition1
@for_exit1:
			ADDS	-8(%14),$1,-8(%14)
			JMP		@for_condition0
@for_exit0:
			MOV 	-4(%14),%13
			JMP 	@main_exit
@main_exit:
			MOV 	%14,%15
			POP 	%14
			RET