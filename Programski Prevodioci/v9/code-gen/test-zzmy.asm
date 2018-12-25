
main:
			PUSH	%14
			MOV 	%15,%14
			SUBS	%15,$8,%15
@main_body:
			MOV 	$0,-4(%14)
@for_init0:
			MOV 	$0,-8(%14)
@for_condition0:
			CMPS 	-8(%14),$5
			JLTS	@for_statement0
			JMP		@for_exit0
@for_statement0:
			ADDS	-4(%14),$2,%0
			MOV 	%0,-4(%14)
			ADDS	-8(%14),$1,-8(%14)
			JMP		@for_condition0
@for_exit0:
			MOV 	-4(%14),%13
			JMP 	@main_exit
@main_exit:
			MOV 	%14,%15
			POP 	%14
			RET