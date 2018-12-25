
xyz:
			WORD	1
main:
			PUSH	%14
			MOV 	%15,%14
			SUBS	%15,$4,%15
@main_body:
			MOV 	$3,xyz
			ADDS	xyz,$1,xyz
			ADDS	xyz,$5,%0
			MOV 	%0,-4(%14)
			MOV 	-4(%14),%13
			JMP 	@main_exit
@main_exit:
			MOV 	%14,%15
			POP 	%14
			RET