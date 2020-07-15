########################################################################
# COMP1521 20T2 --- assignment 1: a cellular automaton renderer
#
# Written by <<Hayley Gayfer>>, July 2020.


# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	=    0
MAX_RULE	=  255

# Characters used to print alive/dead cells.

ALIVE_CHAR	= '#'
DEAD_CHAR	= '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

	.data

# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

cells:	.space MAX_CELLS_BYTES


# Some strings you'll need to use:

prompt_world_size:	.asciiz "Enter world size: "
error_world_size:	.asciiz "Invalid world size\n"
prompt_rule:		.asciiz "Enter rule: "
error_rule:		.asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"
alive_char:			.asciiz "#"
dead_char:			.asciiz "."

	.text

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `main', AND THE PURPOSES THEY ARE ARE USED FOR
	# $a1 => world_size
	# $a2 => rule
	# $s0 => n_generations
	# $s1 => reverse
	# $a3 => g
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	#

main:
	#
	# REPLACE THIS COMMENT WITH YOUR CODE FOR `main'.
	#

	sub $sp, $sp, 4     # move stack pointer down to make room
    sw $ra, 0($sp)      # save $ra on $stack

	# RETRIEVE WORLD SIZE VALUE
	la  $a0, prompt_world_size  # printf("Enter word size: ");
    li  $v0, 4
    syscall

	li $v0, 5           		#   scanf("%d", &world_size);
    syscall             		#

	move $a1, $v0               # 	world_size stored in $t0

	# TEST THAT WORLD SIZE IS WITHIN LIMITS
	blt $a1, MIN_WORLD_SIZE, world_size_test
	bgt $a1, MAX_WORLD_SIZE, world_size_test

	b skip_world_size_test

	world_size_test:

	la  $a0, error_world_size  
    li  $v0, 4
    syscall
	
	lw $ra, 0($sp)      # recover $ra from $stack
    add $sp, $sp, 4     # move stack pointer back up to what it was when main called
	# change the 4 later

	li	$v0, 1
	jr	$ra

	skip_world_size_test:		#	if (world_size < MIN_WORLD_SIZE ....

	# RETRIEVE RULE VALUE
	la  $a0, prompt_rule  		# printf("Enter rule: ");
    li  $v0, 4
    syscall

	li $v0, 5           		#   scanf("%d", &rule);
    syscall        

	move $a2, $v0               # 	rule stored in $t1

	# TEST THAT RULE VALUE IS WITHIN LIMITS
	blt $a2, MIN_RULE, rule_test
	bgt $a2, MAX_RULE, rule_test

	b skip_rule_test

	rule_test:

	la  $a0, error_rule	
    li  $v0, 4
    syscall
	
	lw $ra, 0($sp)      # recover $ra from $stack
    add $sp, $sp, 4     # move stack pointer back up to what it was when main called
	# change the 4 later

	li	$v0, 1
	jr	$ra

	skip_rule_test:	

	# RETRIEVE HOW MANY GENERATIONS
	la  $a0, prompt_n_generations  # printf("Enter how many generations: ");
    li  $v0, 4
    syscall

	li $v0, 5           		#   scanf("%d", &n_generations);
    syscall             		#

	move $s0, $v0               # 	n_generations stored in $t2

	# TEST IF VALID NUMBER OF GENERATIONS
	blt $s0, MIN_GENERATIONS, generations_test
	bgt $s0, MAX_GENERATIONS, generations_test

	b skip_generations_test

	generations_test:

	la  $a0, error_n_generations
    li  $v0, 4
    syscall
	
	lw $ra, 0($sp)      # recover $ra from $stack
    add $sp, $sp, 4     # move stack pointer back up to what it was when main called
	# change the 4 later

	li	$v0, 1
	jr	$ra

	skip_generations_test:	

	li $s1, 0							# reverse = 0
	bge $s0, 0, skip_reverse_test
	
	add $s1, $s1, 1						# reverse = 1
	mul $s0, $s0, -1					# n_generations = -n_generations

	skip_reverse_test:

	# IMPLEMENT 2D CELLS ARRAY

	li $t0, 1
	div $t2, $a1, 2

	la $t4, cells
	mul  $t5, $a1, 0
	add  $t5, $t5, $t2	
	mul  $t5, $t5, 4	# data size
	add  $t5, $t5, $t4
	sw   $t0, ($t5)

	# RUN GENERATION LOOP
	li $a3, 1							# g = 1

	run_generation_loop:
		bgt $a3, $s0, run_generation_end
		jal run_generation # PASS IN ARGUMENTS $t0, $t4, $t1
		add $a3, $a3, 1						# g++
		b run_generation_loop
	run_generation_end:

	li   $a0, '\n'      #   printf("%c", '\n');
	li   $v0, 11
    syscall

	# PRINT GENERATIONS LOOP
	beq $s1, 1, print_reverse

	# if reverse == 0
	li $a3, 0						# g = 0
	loop_print_generations:
		jal print_generation # PASS IN ARGUMENTS $t0, $t4
		add $a3, $a3, 1						# g++
	ble $a3, $s0, loop_print_generations

	b skip_print_reverse

	# if reverse == 1
	print_reverse:

	add $a3, $s0, 0						# g = n_generations
	loop_print_reverse:
		jal print_generation # PASS IN ARGUMENTS $t0, $t4
		sub $a3, $a3, 1						# g++
	bge $a3, 0, loop_print_reverse

	skip_print_reverse:

	lw $ra, 0($sp)      # recover $ra from $stack
    add $sp, $sp, 4     # move stack pointer back up to what it was when main called
	# change the 4 later

	li	$v0, 0
	jr	$ra
	
	# if your code for `main' preserves $ra by saving it on the
	# stack, and restoring it after calling `print_world' and
	# `run_generation'.  [ there are style marks for this ]

	#li	$v0, 10
	#syscall

	#
	# Given `world_size', `which_generation', and `rule', calculate
	# a new generation according to `rule' and store it in `cells'.
	#

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `run_generation', AND THE PURPOSES THEY ARE ARE USED FOR
	#
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	#

run_generation:
	# $t2 = x
	# $t3 = left
	li $t0, 0 		# int x = 0
	# $a3 = which_generation
	loop_run_generation:
		bge $t0, $a1, end_loop_run_generation
		
		li $t1, 0	# left = 0
		li $t2, 0	# centre = 0
		li $t3, 0	# right = 0

		add $a3, $a3, -1 	# which generation - 1
		mul $t6, $a1, 4		# size of 1D array worldsize * data size

		# PROCESS LEFT
		ble $t0, 0, skip_left_if
		
			# $t2 = base address
			# $t3 = 
			la $t4, cells

			add $t0, $t0, -1	# x - 1

			mul  $t5, $a3, $t6  # which_generation * array size
			add  $t5, $t5, $t4	# $t5 + start address of array
			mul  $t7, $t0, 4	# x * data size
			add  $t8, $t7, $t5
			lw   $a0, ($t8)

			move $t1, $a0		# $t1 = left

			add $t0, $t0, 1	# x + 1

		skip_left_if:


		# PROCESS CENTRE
		la $t4, cells

		mul  $t5, $a3, $t6  # which_generation * array size
		add  $t5, $t5, $t4	# $t5 * start address of array
		mul  $t7, $t0, 4	# x * data size
		add  $t8, $t7, $t5
		lw   $a0, ($t8)

		move $t2, $a0		# $t2 = centre

		#PROCESS RIGHT

		add $a1, $a1, -1	#world size - 1
		bge $t0, $a1, skip_right_if
			
			la $t4, cells

			add $t0, $t0, 1	# x + 1

			mul  $t5, $a3, $t6  # which_generation * array size
			add  $t5, $t5, $t4	# $t5 * start address of array
			mul  $t7, $t0, 4	# x * data size
			add  $t8, $t7, $t5
			lw   $a0, ($t8)

			move $t3, $a0		# $t3 = right

			add $t0, $t0, -1	# x - 1

		skip_right_if:
		add $a1, $a1, 1		# world size + 1

		add $a3, $a3, 1 	# which generation + 1

		li $t6, 0			# state = 0

		sll $t1, $t1, 2
		sll $t2, $t2, 1
		sll $t3, $t3, 0
		or $t6, $t1, $t2
		or $t6, $t6, $t3

		li $t7, 1		# bit =  1

		sllv $t7, $t7, $t6

		and $t8, $a2, $t7		#set = rule & bit

		beq $t8, 0, skip_if_set
			la $t4, cells

			li $t9, 1

			mul  $t5, $a3, $a1  # which_generation * world_size
			add  $t5, $t5, $t0	
			mul  $t5, $t5, 4	# data size
			add  $t5, $t5, $t4
			sw   $t9, ($t5)
			b end_if_set
		skip_if_set:
			la $t4, cells

			li $t9, 0

			mul  $t5, $a3, $a1  # which_generation * world_size
			add  $t5, $t5, $t0	
			mul  $t5, $t5, 4	# data size
			add  $t5, $t5, $t4
			sw   $t9, ($t5)
		end_if_set:

		add $t0, $t0, 1	#x++
		b loop_run_generation

	end_loop_run_generation:
		
	jr	$ra


	#
	# Given `world_size', and `which_generation', print out the
	# specified generation.
	#

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `print_generation', AND THE PURPOSES THEY ARE ARE USED FOR
	#
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `print_generation' FINISHES
	#

print_generation:
	move $a0, $a3      #   printf("%c", '\n');
	li   $v0, 1
    syscall
	li   $a0, ' '      #   printf("%c", '\n');
	li   $v0, 11
    syscall

	li $t0, 0	# x = 0
	
	print_gen_loop:
	bge $t0, $a1, end_print_gen_loop
		la $t4, cells

		mul  $t5, $a3, $a1  # which_generation * world_size
		add  $t5, $t5, $t0	
		mul  $t5, $t5, 4	# data size
		add  $t5, $t5, $t4
		lw   $a0, ($t5)

		move $t1, $a0		# $t1 = cells[i][j]

		beq $t1, 0, skip_if_print
			la  $a0, alive_char
    		li  $v0, 4
    		syscall
			add $t0, $t0, 1
			b print_gen_loop
		skip_if_print:
			la  $a0, dead_char
    		li  $v0, 4
    		syscall
			add $t0, $t0, 1
			b print_gen_loop
	end_print_gen_loop:

	li   $a0, '\n'      #   printf("%c", '\n');
	li   $v0, 11
    syscall

	jr	$ra

