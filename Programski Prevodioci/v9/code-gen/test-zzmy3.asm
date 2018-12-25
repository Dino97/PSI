
main:
			PUSH	%14
			MOV 	%15,%14
			SUBS	%15,$8,%15
@main_body:
			MOV 	$20,-4(%14)
			JMP		@jumps_switch0		# jump to comparing first
@switch0_case10:
			MOV 	$1,-8(%14)
			JMP		@exit_switch0		#break
@switch0_case20:
			MOV 	$2,-8(%14)
			JMP		@exit_switch0		# last case statement, jump to exit
@default_switch0:
			MOV 	$0,-8(%14)
			JMP		@exit_switch0
@jumps_switch0:
			CMPS 	-4(%14),$10
			JEQ		@switch0_case10
			CMPS 	-4(%14),$20
			JEQ		@switch0_case20
			JMP		@default_switch0
@exit_switch0:
			JMP		@jumps_switch1		# jump to comparing first
@switch1_case10:
			MOV 	$5,-8(%14)
			JMP		@exit_switch1		#break
@switch1_case20:
			MOV 	$30,-8(%14)
@switch1_case30:
			MOV 	$20,-8(%14)
			JMP		@exit_switch1		# last case statement, jump to exit
@jumps_switch1:
			CMPS 	-4(%14),$10
			JEQ		@switch1_case10
			CMPS 	-4(%14),$20
			JEQ		@switch1_case20
			CMPS 	-4(%14),$30
			JEQ		@switch1_case30
@exit_switch1:
			MOV 	-8(%14),%13
			JMP 	@main_exit
@main_exit:
			MOV 	%14,%15
			POP 	%14
			RET