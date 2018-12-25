
main:
			PUSH	%14
			MOV 	%15,%14
			SUBS	%15,$4,%15
@main_body:
			MOV 	$30,-4(%14)
			ADDS	-4(%14),$12,%0
			MOV 	%0,%13
			JMP 	@main_exit
@main_exit:
			MOV 	%14,%15
			POP 	%14
			RET