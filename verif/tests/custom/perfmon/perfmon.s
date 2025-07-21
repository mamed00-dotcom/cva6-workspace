	.file	"perfmon.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata
	.align	2
	.type	load_data, @object
	.size	load_data, 12
load_data:
	.word	7
	.word	3
	.word	5
	.text
	.align	1
	.type	enable_hpm3, @function
enable_hpm3:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
 #APP
# 25 "perfmon.c" 1
	csrr a5, 0x320
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	andi	a5,a5,-9
	sw	a5,-24(s0)
	lw	a5,-24(s0)
 #APP
# 27 "perfmon.c" 1
	csrw 0x320, a5
# 0 "" 2
 #NO_APP
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	enable_hpm3, .-enable_hpm3
	.align	1
	.type	wl_stall, @function
wl_stall:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 32 "perfmon.c" 1
	la   t3, load_data
	lw   t0, 0(t3)
	addi t1, t0, 1
	lw   t2, 4(t3)
	addi t3, t2, 1
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_stall, .-wl_stall
	.align	1
	.type	wl_loads, @function
wl_loads:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 42 "perfmon.c" 1
	la   t3, load_data
	lw   t0, 0(t3)
	lw   t1, 4(t3)
	lw   t2, 8(t3)
	
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_loads, .-wl_loads
	.align	1
	.type	wl_stores, @function
wl_stores:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 51 "perfmon.c" 1
	sw x0, 0(sp)
	sw x0, 4(sp)
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_stores, .-wl_stores
	.align	1
	.type	wl_br, @function
wl_br:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 58 "perfmon.c" 1
	beq x0, x0, 1f
	nop
1:
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_br, .-wl_br
	.align	1
	.type	wl_call, @function
wl_call:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
 #APP
# 65 "perfmon.c" 1
	jal ra,1f
1:
# 0 "" 2
 #NO_APP
	nop
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_call, .-wl_call
	.align	1
	.type	wl_ret, @function
wl_ret:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
 #APP
# 68 "perfmon.c" 1
	la   t0, 1f
	mv   ra, t0
	jalr x0, ra, 0
1:
# 0 "" 2
 #NO_APP
	nop
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_ret, .-wl_ret
	.align	1
	.type	wl_addi, @function
wl_addi:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 77 "perfmon.c" 1
	addi t0, t0, 42
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_addi, .-wl_addi
	.align	1
	.type	wl_mul, @function
wl_mul:
	addi	sp,sp,-16
	sw	s0,12(sp)
	addi	s0,sp,16
 #APP
# 80 "perfmon.c" 1
	mul t1, t0, t0
# 0 "" 2
 #NO_APP
	nop
	lw	s0,12(sp)
	addi	sp,sp,16
	jr	ra
	.size	wl_mul, .-wl_mul
	.section	.rodata
	.align	2
.LC0:
	.string	"\n[%s] (event %u)\n"
	.align	2
.LC1:
	.string	"  HPM3 = %u\n  regs ="
	.align	2
.LC2:
	.string	" t%u=0x%08x(%u)"
	.text
	.align	1
	.type	run, @function
run:
	addi	sp,sp,-64
	sw	ra,60(sp)
	sw	s0,56(sp)
	addi	s0,sp,64
	sw	a0,-52(s0)
	sw	a1,-56(s0)
	sw	a2,-60(s0)
	mv	a5,a3
	sb	a5,-61(s0)
	lw	a2,-52(s0)
	lw	a1,-56(s0)
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	printf
	lw	a5,-52(s0)
 #APP
# 88 "perfmon.c" 1
	csrw 0x323, a5
# 0 "" 2
# 89 "perfmon.c" 1
	csrw 0xB03, 0
# 0 "" 2
# 92 "perfmon.c" 1
	li t0, 7
	li t1, 3
	li t2, 5
# 0 "" 2
 #NO_APP
	lw	a5,-60(s0)
	jalr	a5
 #APP
# 101 "perfmon.c" 1
	csrr a5, 0xB03
# 0 "" 2
 #NO_APP
	sw	a5,-24(s0)
	lw	a5,-24(s0)
	sw	a5,-28(s0)
 #APP
# 102 "perfmon.c" 1
	csrw 0x323, 0
# 0 "" 2
 #NO_APP
	sw	zero,-44(s0)
	sw	zero,-40(s0)
	sw	zero,-36(s0)
	sw	zero,-32(s0)
 #APP
# 106 "perfmon.c" 1
	mv a5, t0
# 0 "" 2
 #NO_APP
	sw	a5,-44(s0)
 #APP
# 107 "perfmon.c" 1
	mv a5, t1
# 0 "" 2
 #NO_APP
	sw	a5,-40(s0)
	lbu	a4,-61(s0)
	li	a5,2
	bleu	a4,a5,.L11
 #APP
# 108 "perfmon.c" 1
	mv a5, t2
# 0 "" 2
 #NO_APP
	sw	a5,-36(s0)
.L11:
	lbu	a4,-61(s0)
	li	a5,3
	bleu	a4,a5,.L12
 #APP
# 109 "perfmon.c" 1
	mv a5, t3
# 0 "" 2
 #NO_APP
	sw	a5,-32(s0)
.L12:
	lw	a1,-28(s0)
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	printf
	sb	zero,-17(s0)
	j	.L13
.L14:
	lbu	a4,-17(s0)
	lbu	a5,-17(s0)
	slli	a5,a5,2
	addi	a5,a5,-16
	add	a5,a5,s0
	lw	a2,-28(a5)
	lbu	a5,-17(s0)
	slli	a5,a5,2
	addi	a5,a5,-16
	add	a5,a5,s0
	lw	a5,-28(a5)
	mv	a3,a5
	mv	a1,a4
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	printf
	lbu	a5,-17(s0)
	addi	a5,a5,1
	sb	a5,-17(s0)
.L13:
	lbu	a4,-17(s0)
	lbu	a5,-61(s0)
	bltu	a4,a5,.L14
	li	a0,10
	call	putchar
	nop
	lw	ra,60(sp)
	lw	s0,56(sp)
	addi	sp,sp,64
	jr	ra
	.size	run, .-run
	.section	.rodata
	.align	2
.LC3:
	.string	"Pipeline stall"
	.align	2
.LC4:
	.string	"[Triple Memory LOAD] = %u\n"
	.align	2
.LC5:
	.string	"Memory LOADs"
	.align	2
.LC6:
	.string	"Memory STOREs"
	.align	2
.LC7:
	.string	"Branch instructions"
	.align	2
.LC8:
	.string	"CALL instructions"
	.align	2
.LC9:
	.string	"RETURN instructions"
	.align	2
.LC10:
	.string	"Integer ADDI"
	.align	2
.LC11:
	.string	"Integer MUL"
	.align	2
.LC12:
	.string	"\n[minstret delta] = %u\n"
	.text
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	call	enable_hpm3
	li	a3,4
	lui	a5,%hi(wl_stall)
	addi	a2,a5,%lo(wl_stall)
	lui	a5,%hi(.LC3)
	addi	a1,a5,%lo(.LC3)
	li	a0,22
	call	run
 #APP
# 124 "perfmon.c" 1
	csrw 0x323, 5
# 0 "" 2
# 125 "perfmon.c" 1
	csrw 0xB03, 0
# 0 "" 2
# 126 "perfmon.c" 1
	la   t3, load_data
	lw   t0, 0(t3)
	lw   t1, 4(t3)
	lw   t2, 8(t3)
# 0 "" 2
# 133 "perfmon.c" 1
	csrr a5, 0xB03
# 0 "" 2
 #NO_APP
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	sw	a5,-24(s0)
 #APP
# 134 "perfmon.c" 1
	csrw 0x323, 0
# 0 "" 2
 #NO_APP
	lw	a1,-24(s0)
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	printf
	li	a3,4
	lui	a5,%hi(wl_loads)
	addi	a2,a5,%lo(wl_loads)
	lui	a5,%hi(.LC5)
	addi	a1,a5,%lo(.LC5)
	li	a0,5
	call	run
	li	a3,2
	lui	a5,%hi(wl_stores)
	addi	a2,a5,%lo(wl_stores)
	lui	a5,%hi(.LC6)
	addi	a1,a5,%lo(.LC6)
	li	a0,6
	call	run
	li	a3,2
	lui	a5,%hi(wl_br)
	addi	a2,a5,%lo(wl_br)
	lui	a5,%hi(.LC7)
	addi	a1,a5,%lo(.LC7)
	li	a0,9
	call	run
	li	a3,2
	lui	a5,%hi(wl_call)
	addi	a2,a5,%lo(wl_call)
	lui	a5,%hi(.LC8)
	addi	a1,a5,%lo(.LC8)
	li	a0,12
	call	run
	li	a3,2
	lui	a5,%hi(wl_ret)
	addi	a2,a5,%lo(wl_ret)
	lui	a5,%hi(.LC9)
	addi	a1,a5,%lo(.LC9)
	li	a0,13
	call	run
	li	a3,2
	lui	a5,%hi(wl_addi)
	addi	a2,a5,%lo(wl_addi)
	lui	a5,%hi(.LC10)
	addi	a1,a5,%lo(.LC10)
	li	a0,20
	call	run
	li	a3,2
	lui	a5,%hi(wl_mul)
	addi	a2,a5,%lo(wl_mul)
	lui	a5,%hi(.LC11)
	addi	a1,a5,%lo(.LC11)
	li	a0,20
	call	run
 #APP
# 147 "perfmon.c" 1
	csrr a5, 0xB02
# 0 "" 2
 #NO_APP
	sw	a5,-28(s0)
	lw	a5,-28(s0)
	sw	a5,-32(s0)
 #APP
# 148 "perfmon.c" 1
	addi x0, x0, 0
# 0 "" 2
# 149 "perfmon.c" 1
	csrr a5, 0xB02
# 0 "" 2
 #NO_APP
	sw	a5,-36(s0)
	lw	a4,-36(s0)
	lw	a5,-32(s0)
	sub	a5,a4,a5
	mv	a1,a5
	lui	a5,%hi(.LC12)
	addi	a0,a5,%lo(.LC12)
	call	printf
	li	a5,0
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 13.1.0"
