	.align 	2
LC0:
	.ascii	"%d\0"
	.align	2
LC1:
	.ascii 	"%lf\0"
	.align 	3
LC2:
	.long	1127219200
	.long	-2147483648
	.text
	.align	2
	.globl 	min_caml_print_newline
min_caml_print_newline:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu  	r1, -80(r1)
	mr 	r30, r1
	li	r3, 10
	bl 	putchar
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
    .section .text
	.align 	5
	.align 	2
	.globl	min_caml_print_int
min_caml_print_int:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -80(r1)
	mr 	r30, r1
	bcl 	20, 31, L2pb
L2pb:
	mflr 	r31
	mr	r4, r2
	addis 	r2, r31, LC0 - L2pb@ha
	la 	r3, LC0 - L2pb@l(r2)
	bl	printf
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align 	2
	.globl	min_caml_print_byte
min_caml_print_byte:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu  	r1, -80(r1)
	mr 	r30, r1
	stw	r3, 104(r30)
	mr	r3, r2
	bl 	putchar
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr	
#	prerr_int
	.text
	.align 	2
	.globl 	min_caml_prerr_int
min_caml_prerr_int:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -80(r1)
	mr 	r30, r1
	bcl 	20, 31, L3pb
L3pb:
	mflr 	r31
	mr	r6, r2
	mr	r2, r5
	mr	r5, r6
	addis 	r2, r31, L - L3pb@ha
	lwz 	r2, L - L3pb@l(r2)
	addi 	r0, r2, 176
	mr 	r3, r0
	addis 	r2, r31, LC0 - L3pb@ha
	la 	r4, LC0 - L3pb@l(r2)
	bl 	fprintf
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
L:
	.long	0
	.align 	5
	.align 	2
	.globl	min_caml_prerr_byte
min_caml_prerr_byte:
	mflr	r0
	stmw	r30, -8(r1)
	stw	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu	r1, -80(r1)
	mr	r30, r1
	bcl	20, 31, L4pb
L4pb:
	mflr	r31
	mr	r3, r2
	addis 	r2, r31, L - L4pb@ha
	lwz	r2, L - L4pb@l(r2)
	addi	r0, r2, 176
	mr	r4, r0
	bl	fputc
	lwz	r1, 0(r1)
	lwz	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr	r0
	lmw	r30, -8(r1)
	blr
	.align 	5
	.align 	2
	.globl 	min_caml_prerr_float
min_caml_prerr_float:
	mflr 	r0
	stmw 	r29, -12(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, L5pb
L5pb:
	mflr 	r31
	addis 	r2, r31, L - L5pb@ha
	lwz 	r2, L - L5pb@l(r2)
	addi 	r29, r2, 176
	stfd 	f0, 64(r30)
	lwz 	r2, 64(r30)
	lwz 	r3, 68(r30)
	mr 	r10, r3
	mr 	r9, r2
	stw 	r2, 64(r30)
	stw 	r3, 68(r30)
	lfd 	f13, 64(r30)
#	fmr 	f0, f13
	mr 	r3, r29
	addis 	r2, r31, LC1 - L5pb@ha
	la 	r4, LC1 - L5pb@l(r2)
	mr 	r5, r9
	mr 	r6, r10
	fmr 	f1, f0
	bl 	fprintf
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lmw 	r29, -12(r1)
	blr	
#	read_int
	.text
	.align 	2
	.globl	min_caml_read_int
min_caml_read_int:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, L6pb
L6pb:
	mflr 	r31
	addis 	r2, r31, LC0 - L6pb@ha
	la 	r3, LC0 - L6pb@l(r2)
	addi 	r4, r30, 56
	bl 	scanf
	lwz 	r2, 56(r30)
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align	2
	.globl	min_caml_read_float
min_caml_read_float:	
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -112(r1)
	mr 	r30, r1
	bcl 	20, 31, L7pb
L7pb:
	mflr	r31
	addis	r2, r31, LC1 - L7pb@ha
	la	r3, LC1 - L7pb@l(r2)
	addi	r4, r30, 56
	bl	scanf
	lfd	f0, 56(r30)
	lwz	r1, 0(r1)
	lwz	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr	r0
	lmw	r30, -8(r1)
	blr
#	create_array
	.text
	.align	2
	.globl	min_caml_create_array
min_caml_create_array:	
	mr	r6, r2
	mr	r2, r4
create_array_loop:
	cmpwi	cr7, r6, 0
	bne	cr7, create_array_cont
	b	create_array_exit
create_array_exit:
	blr
create_array_cont:
	stw	r5, 0(r4)
	subi  	r6, r6, 1
	addi	r4, r4, 4
	b	create_array_loop
#	create_float_array
	.globl	min_caml_create_float_array
min_caml_create_float_array:
	mr	r5, r2
	mr	r2, r4
create_float_array_loop:
	cmpwi	cr7, r5, 0
	bne	cr7, create_float_array_cont
	blr
create_float_array_cont:
	stfd	f0, 0(r4)
	subi	r5, r5, 1
	addi	r4, r4, 8
	b	create_float_array_loop
	.globl	min_caml_abs_float
min_caml_abs_float:
	fabs	f0, f0
	blr
#	sqrt
	.text
	.align 	2
	.globl min_caml_sqrt
min_caml_sqrt:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, L8pb
L8pb:
	mflr	r31
	fmr	f1, f0
	bl 	sqrt
	fmr	f0, f1
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align 	2
	.globl 	min_caml_floor
min_caml_floor:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -80(r1)
	mr 	r30, r1
	fmr	f1, f0
	stfd 	f1, 56(r30)
	lfd 	f1, 56(r30)
	bl 	floor
	fmr 	f0, f1
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lmw 	r30,  -8(r1)
	blr	
	.align 	5
	.align	2
	.globl	min_caml_int_of_float
min_caml_int_of_float:
	.globl	min_caml_truncate
min_caml_truncate:
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stwu 	r1, -64(r1)
	mr 	r30, r1
	stfd 	f0, 24(r30)
	lfd 	f1, 24(r30)
	fctiwz 	f1, f1
	stfd 	f1, 32(r30)
	lwz 	r31, 36(r30)
	mr 	r2, r31
	lwz 	r1, 0(r1)
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
#	float_of_int
	.globl	min_caml_float_of_int
min_caml_float_of_int:
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw	r3, 8(r1)
	stw	r4, 12(r1)
	stwu 	r1, -48(r1)
	mr 	r30, r1
	mflr 	r0
	bcl 	20, 31, Lapb
Lapb:
	mflr 	r10
	mtlr 	r0
	stw 	r2, 72(r30)
	lwz 	r0, 72(r30)
	lis 	r2, 0x4330
	addis 	r9, r10, LC2 - Lapb@ha
	lfd 	f13, LC2 - Lapb@l(r9)
	xoris 	r0, r0, 0x8000
	stw 	r0, 28(r30)
	stw 	r2, 24(r30)
	lfd 	f0, 24(r30)
	fsub 	f0, f0, f13
	lwz 	r1, 0(r1)
	lwz	r3, 8(r1)
	lwz	r4, 12(r1)
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
#	cos
	.text
	.align 	2
	.globl min_caml_cos
min_caml_cos:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, Lbpb
Lbpb:
	mflr 	r31
	fmr	f1, f0
	bl 	cos
	fmr 	f0, f1
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align 	2
	.globl 	min_caml_sin
min_caml_sin:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, Lcpb
Lcpb:	
	mflr 	r31
	fmr	f1, f0
	bl 	sin
	fmr 	f0, f1
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align 	2
	.globl min_caml_atan
min_caml_atan:
	mflr 	r0
	stw 	r30, -8(r1)
	stw 	r31, -4(r1)
	stw 	r0, 8(r1)
	stw	r3, 12(r1)
	stw	r4, 16(r1)
	stwu 	r1, -96(r1)
	mr 	r30, r1
	bcl 	20, 31, Ldpb
Ldpb:
	mflr 	r31
	fmr	f1, f0
	bl 	atan
	fmr 	f0, f1
	lwz 	r1, 0(r1)
	lwz 	r0, 8(r1)
	lwz	r3, 12(r1)
	lwz	r4, 16(r1)
	mtlr 	r0
	lwz 	r30, -8(r1)
	lwz 	r31, -4(r1)
	blr
	.align 	5
	.align	8
float_0:
	.long	0x0
	.long	0x0
float_1:
	.long	0x3ff00000
	.long	0x0
	
	
