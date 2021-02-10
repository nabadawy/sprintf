######################################################################
# spf-main.s
# 
# This is the main function that tests the sprintf function

# The "data" segment is a static memory area where we can 
# allocate and initialize memory for our program to use.
# This is separate from the stack or the heap, and the allocation
# cannot be changed once the program starts. The program can
# write data to this area, though.
	.data
	
# Note that the directives in this section will not be 
# translated into machine language. They are instructions 
# to the assembler, linker, and loader to set aside (and 
# initialize) space in the static memory area of the program. 
# The labels work like pointers-- by the time the code is 
# run, they will be replaced with appropriate addresses.

# For this program, we will allocate a buffer to hold the
# result of your sprintf function. The asciiz blocks will
# be initialized with null-terminated ASCII strings.

buffer:	.space	20000			# 2000 bytes of empty space 
					# starting at address 'buffer'
	
format:	.asciiz "string: %s, unsigned dec: %u, hex: 0x%x, oct: 0%o, dec: %d\n"
					# null-terminated string of 
					# ascii bytes.  Note that the 
					# \n counts as one byte: a newline 
					# character.
str:	.asciiz "thirty-nine"		# null-terminated string at
					# address 'str'
chrs:	.asciiz " characters:\n"	# null-terminated string at 
					# address 'chrs'

# The "text" of the program is the assembly code that will
# be run. This directive marks the beginning of our program's
# text segment.

	.text
	
# The sprintf procedure (really just a block that starts with the
# label 'sprintf') will be declared later.  This is like a function
# prototype in C.

	.globl sprintf
		
# The special label called "__start" marks the start point
# of execution. Later, the "done" pseudo-instruction will make
# the program terminate properly.	

main:
	addi	$sp,$sp,-32	# reserve stack space

	# $v0 = sprintf(buffer, format, str, 255, 255, 250, -255)
	
	la	$a0,buffer	# arg 0 <- buffer
	la	$a1,format	# arg 1 <- format
	la	$a2,str		# arg 2 <- str
	
	addi	$a3,$0,255	# arg 3 <- 255
	sw	$a3,16($sp)	# arg 4 <- 255
	
	addi	$t0,$0,250
	sw	$t0,20($sp)	# arg 5 <- 250

        addi    $t0,$0,-255
        sw      $t0,24($sp)     # arg 6 <- -255

	sw	$ra,28($sp)	# save return address
	jal	sprintf		# $v0 = sprintf(...)

	# print the return value from sprintf using
	# putint()
	add	$a0,$v0,$0	# $a0 <- $v0
	jal	putint		# putint($a0)

	## output the string 'chrs' then 'buffer' (which
	## holds the output of sprintf)
 	li 	$v0, 4	
	la     	$a0, chrs
	syscall
	#puts	chrs		# output string chrs
	
	li	$v0, 4
	la	$a0, buffer
	syscall
	#puts	buffer		# output string buffer
	
	addi	$sp,$sp,32	# restore stack
	li 	$v0, 10		# terminate program
	syscall

# putint writes the number in $a0 to the console
# in decimal. It uses the special command
# putc to do the output.
	
# Note that putint, which is recursive, uses an abbreviated
# stack. putint was written very carefully to make sure it
# did not disturb the stack of any other functions. Fortunately,
# putint only calls itself and putc, so it is easy to prove
# that the optimization is safe. Still, we do not recommend 
# taking shortcuts like the ones used here.

# HINT:	You should read and understand the body of putint,
# because you will be doing some similar conversions
# in your own code.
	
putint:	addi	$sp,$sp,-8	# get 2 words of stack
	sw	$ra,0($sp)	# store return address
	
	# The number is printed as follows:
	# It is successively divided by the base (10) and the 
	# reminders are printed in the reverse order they were found
	# using recursion.

	remu	$t0,$a0,10	# $t0 <- $a0 % 10
	addi	$t0,$t0,'0'	# $t0 += '0' ($t0 is now a digit character)
	divu	$a0,$a0,10	# $a0 /= 10
	beqz	$a0,onedig	# if( $a0 != 0 ) { 
	sw	$t0,4($sp)	#   save $t0 on our stack
	jal	putint		#   putint() (putint will deliberately use and modify $a0)
	lw	$t0,4($sp)	#   restore $t0
	                        # } 
onedig:	move	$a0, $t0
	li 	$v0, 11
	syscall			# putc #$t0
	#putc	$t0		# output the digit character $t0
	lw	$ra,0($sp)	# restore return address
	addi	$sp,$sp, 8	# restore stack
	jr	$ra		# return
# sprintf.s
#sprintf!
#$a0 has the pointer to the buffer to be printed to
#$a1 has the pointer to the format string
#$a2 and $a3 have (possibly) the first two substitutions for the format string
#the rest are on the stack
#return the number of characters (ommitting the trailing '\0') put in the buffer

        .text
        
#main: 
	
		
sprintf:
	#$ra from main is in 28($sp)
	sw $a3, 12($sp)			#saving a0-a3 to restore later
	sw $a2, 8($sp)
	sw $a1, 4($sp)
	sw $a0, 0($sp)
	
	jal pre_scan			#scan $a1 for any "%" flags
	jal pre_scan			#keep scanning a1 to find "%"
	jal pre_scan
	jal pre_scan
	jal pre_scan
	
	lw $ra, 28($sp)
	lw $a3, 12($sp)			#restoring $a0-$a3
	lw $a2, 8($sp)
	lw $a1, 4($sp)
	lw $a0, 0($sp)

	jr $ra				#this sprintf implementation rocks!

pre_scan:
	lw $t0, 0($a1)			#grab first element of s0
	beq $t0, 0, ret			#checks if the current char is null
	beq $t0, 0x25, scan		#checks for a "%"	
	addi $a1, $a1, 1		#add one to increase pointer
	j pre_scan_cont			#loop
scan:
	addi $a1, $a1, 1
	lw $t0, 0($a1)			#the next 5 will check for the chars: u, x, o, d, s and will go to their functions
	beq $t0, 0x75, handle_unsign
	beq $t0, 0x78, handle_hex
	beq $t0, 0x6F, handle_oct
	beq $t0, 0x64, handle_dec
	beq $t0, 0x73, handle_str

handle_unsign:
	addi $sp, $sp, -8
	sw $ra, 4($sp)			#save return register
	div $a3, $a3, 10		#divide by 10
	mfhi $a3			#save quotient
	mflo $t1			#save remainder
	sw $t1, 0($sp)			#save remainder
	beq $a3, $0, epi
	jal handle_unsign
	
handle_hex:
	lw $t2, 16($sp)			#get the number to convert into hex
	addi $sp, $sp, -8
	sw $ra, 4($sp)			#save return register
	div $t2, $t2, 16		#divide by 16
	mfhi $t2			#save quotient
	mflo $t4			#save remainder
	sw $t2, 0($sp)			#save remainder
	beq $t2, $0, epi
	jal handle_hex
	
handle_oct:
	lw $t5, 20($sp)			#get the number to convert into hex
	addi $sp, $sp, -8
	sw $ra, 4($sp)			#save return register
	div $t5, $t5, 8			#divide by 8
	mfhi $t5			#save quotient
	mflo $t6			#save remainder
	sw $t5, 0($sp)			#save remainder
	beq $t5, $0, epi
	jal handle_oct

handle_dec:
	addi $sp, $sp, -8
	sw $ra, 4($sp)			#save return register
	div $a3, $a3, 10		#divide by 10
	mfhi $a3			#save quotient
	mflo $t1			#save remainder
	sw $t1, 0($sp)			#save remainder
	beq $a3, $0, epi
	jal handle_unsign
	
handle_str:
	addi $sp, $sp , -8		
	sw $ra, 4($sp)			
	lw $t7, 0($a2)			#getting the first char in the string
	beq $t7, 0, epi_2		#check if char = null
	sw $t8, 0($a2) 			#store the char
	addi $a2, $a2, 1		#move the string pointer
	jal handle_str			

epi: 					#handles numbers
	lw $t0, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	li $a0, '0'
	add $a0, $a0, $t0
	li $v0, 11
	syscall
	jr $ra
	
epi2:					#handles strings
	lw $ra, 4($sp)
	lw $t9, 0($sp)
	addi $sp, $sp, 8
	move $t9, $a0
	li $v0, 11
	syscall
	jr $ra
	
ret: 
	jr $ra
