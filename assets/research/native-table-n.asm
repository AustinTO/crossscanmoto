
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

00000000006f9574 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base>:
  6f9574:	d10243ff 	sub	sp, sp, #0x90
  6f9578:	a9047bfd 	stp	x29, x30, [sp, #64]
  6f957c:	a90567fa 	stp	x26, x25, [sp, #80]
  6f9580:	a9065ff8 	stp	x24, x23, [sp, #96]
  6f9584:	a90757f6 	stp	x22, x21, [sp, #112]
  6f9588:	a9084ff4 	stp	x20, x19, [sp, #128]
  6f958c:	910103fd 	add	x29, sp, #0x40
  6f9590:	d53bd058 	mrs	x24, tpidr_el0
  6f9594:	aa0203e1 	mov	x1, x2
  6f9598:	aa0003f4 	mov	x20, x0
  6f959c:	f9401708 	ldr	x8, [x24, #40]
  6f95a0:	f81f83a8 	stur	x8, [x29, #-8]
  6f95a4:	910083e8 	add	x8, sp, #0x20
  6f95a8:	97fff6d2 	bl	6f70f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x36c>
  6f95ac:	5285d500 	mov	w0, #0x2ea8                	// #11944
  6f95b0:	940851b8 	bl	90dc90 <_Znwm@plt>
  6f95b4:	aa0003f3 	mov	x19, x0
  6f95b8:	94000882 	bl	6fb7c0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1180>
  6f95bc:	910023e8 	add	x8, sp, #0x8
  6f95c0:	910083e1 	add	x1, sp, #0x20
  6f95c4:	aa1303e0 	mov	x0, x19
  6f95c8:	94000916 	bl	6fba20 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13e0>
  6f95cc:	f9400288 	ldr	x8, [x20]
  6f95d0:	f9401908 	ldr	x8, [x8, #48]
  6f95d4:	90ffdea1 	adrp	x1, 2cd000 <psa_to_md_errors@@Base-0x400c14>
  6f95d8:	9105d821 	add	x1, x1, #0x176
  6f95dc:	aa1403e0 	mov	x0, x20
  6f95e0:	d63f0100 	blr	x8
  6f95e4:	f9400288 	ldr	x8, [x20]
  6f95e8:	a940dbf7 	ldp	x23, x22, [sp, #8]
  6f95ec:	aa0003f5 	mov	x21, x0
  6f95f0:	f9429d08 	ldr	x8, [x8, #1336]
  6f95f4:	90ffd8c1 	adrp	x1, 211000 <psa_to_md_errors@@Base-0x4bcc14>
  6f95f8:	912fb821 	add	x1, x1, #0xbee
  6f95fc:	aa1403e0 	mov	x0, x20
  6f9600:	d63f0100 	blr	x8
  6f9604:	cb1702c8 	sub	x8, x22, x23
  6f9608:	52955569 	mov	w9, #0xaaab                	// #43691
  6f960c:	f940028a 	ldr	x10, [x20]
  6f9610:	d343fd08 	lsr	x8, x8, #3
  6f9614:	72b55549 	movk	w9, #0xaaaa, lsl #16
  6f9618:	aa0003e3 	mov	x3, x0
  6f961c:	1b097d01 	mul	w1, w8, w9
  6f9620:	f942b148 	ldr	x8, [x10, #1376]
  6f9624:	aa1403e0 	mov	x0, x20
  6f9628:	aa1503e2 	mov	x2, x21
  6f962c:	d63f0100 	blr	x8
  6f9630:	aa0003f5 	mov	x21, x0
  6f9634:	a94083f7 	ldp	x23, x0, [sp, #8]
  6f9638:	eb17001f 	cmp	x0, x23
  6f963c:	540004a0 	b.eq	6f96d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x15c>  // b.none
  6f9640:	b201f3fa 	mov	x26, #0xaaaaaaaaaaaaaaaa    	// #-6148914691236517206
  6f9644:	aa1f03f9 	mov	x25, xzr
  6f9648:	aa1f03f6 	mov	x22, xzr
  6f964c:	f295557a 	movk	x26, #0xaaab
  6f9650:	8b1902e8 	add	x8, x23, x25
  6f9654:	f940028a 	ldr	x10, [x20]
  6f9658:	39400109 	ldrb	w9, [x8]
  6f965c:	f940090b 	ldr	x11, [x8, #16]
  6f9660:	7200013f 	tst	w9, #0x1
  6f9664:	f9429d49 	ldr	x9, [x10, #1336]
  6f9668:	9a881561 	csinc	x1, x11, x8, ne	// ne = any
  6f966c:	aa1403e0 	mov	x0, x20
  6f9670:	d63f0120 	blr	x9
  6f9674:	f9400288 	ldr	x8, [x20]
  6f9678:	aa0003f7 	mov	x23, x0
  6f967c:	f942b908 	ldr	x8, [x8, #1392]
  6f9680:	aa1403e0 	mov	x0, x20
  6f9684:	aa1503e1 	mov	x1, x21
  6f9688:	2a1603e2 	mov	w2, w22
  6f968c:	aa1703e3 	mov	x3, x23
  6f9690:	d63f0100 	blr	x8
  6f9694:	f9400288 	ldr	x8, [x20]
  6f9698:	f9405d08 	ldr	x8, [x8, #184]
  6f969c:	aa1403e0 	mov	x0, x20
  6f96a0:	aa1703e1 	mov	x1, x23
  6f96a4:	d63f0100 	blr	x8
  6f96a8:	a94083f7 	ldp	x23, x0, [sp, #8]
  6f96ac:	910006d6 	add	x22, x22, #0x1
  6f96b0:	91006339 	add	x25, x25, #0x18
  6f96b4:	cb170008 	sub	x8, x0, x23
  6f96b8:	9343fd08 	asr	x8, x8, #3
  6f96bc:	9b1a7d08 	mul	x8, x8, x26
  6f96c0:	eb16011f 	cmp	x8, x22
  6f96c4:	54fffc68 	b.hi	6f9650 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0xdc>  // b.pmore
  6f96c8:	b5000097 	cbnz	x23, 6f96d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x164>
  6f96cc:	14000012 	b	6f9714 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x1a0>
  6f96d0:	aa0003f7 	mov	x23, x0
  6f96d4:	b4000217 	cbz	x23, 6f9714 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x1a0>
  6f96d8:	eb17001f 	cmp	x0, x23
  6f96dc:	54000180 	b.eq	6f970c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x198>  // b.none
  6f96e0:	aa0003f4 	mov	x20, x0
  6f96e4:	14000004 	b	6f96f4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x180>
  6f96e8:	eb17029f 	cmp	x20, x23
  6f96ec:	aa1403e0 	mov	x0, x20
  6f96f0:	540000c0 	b.eq	6f9708 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x194>  // b.none
  6f96f4:	385e8e88 	ldrb	w8, [x20, #-24]!
  6f96f8:	3607ff88 	tbz	w8, #0, 6f96e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x174>
  6f96fc:	f85f8000 	ldur	x0, [x0, #-8]
  6f9700:	9408516c 	bl	90dcb0 <_ZdlPv@plt>
  6f9704:	17fffff9 	b	6f96e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x174>
  6f9708:	f94007e0 	ldr	x0, [sp, #8]
  6f970c:	f9000bf7 	str	x23, [sp, #16]
  6f9710:	94085168 	bl	90dcb0 <_ZdlPv@plt>
  6f9714:	aa1303e0 	mov	x0, x19
  6f9718:	94085166 	bl	90dcb0 <_ZdlPv@plt>
  6f971c:	394083e8 	ldrb	w8, [sp, #32]
  6f9720:	36000068 	tbz	w8, #0, 6f972c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x1b8>
  6f9724:	f9401be0 	ldr	x0, [sp, #48]
  6f9728:	94085162 	bl	90dcb0 <_ZdlPv@plt>
  6f972c:	f9401708 	ldr	x8, [x24, #40]
  6f9730:	f85f83a9 	ldur	x9, [x29, #-8]
  6f9734:	eb09011f 	cmp	x8, x9
  6f9738:	54000401 	b.ne	6f97b8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x244>  // b.any
  6f973c:	aa1503e0 	mov	x0, x21
  6f9740:	a9484ff4 	ldp	x20, x19, [sp, #128]
  6f9744:	a94757f6 	ldp	x22, x21, [sp, #112]
  6f9748:	a9465ff8 	ldp	x24, x23, [sp, #96]
  6f974c:	a94567fa 	ldp	x26, x25, [sp, #80]
  6f9750:	a9447bfd 	ldp	x29, x30, [sp, #64]
  6f9754:	910243ff 	add	sp, sp, #0x90
  6f9758:	d65f03c0 	ret
  6f975c:	14000008 	b	6f977c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x208>
  6f9760:	aa0003f4 	mov	x20, x0
  6f9764:	14000009 	b	6f9788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x214>
  6f9768:	aa0003f4 	mov	x20, x0
  6f976c:	14000007 	b	6f9788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x214>
  6f9770:	aa0003f4 	mov	x20, x0
  6f9774:	14000007 	b	6f9790 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x21c>
  6f9778:	14000001 	b	6f977c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x208>
  6f977c:	aa0003f4 	mov	x20, x0
  6f9780:	910023e0 	add	x0, sp, #0x8
  6f9784:	97ffff5d 	bl	6f94f8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_m@@Base+0x210>
  6f9788:	aa1303e0 	mov	x0, x19
  6f978c:	94085149 	bl	90dcb0 <_ZdlPv@plt>
  6f9790:	394083e8 	ldrb	w8, [sp, #32]
  6f9794:	36000068 	tbz	w8, #0, 6f97a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x22c>
  6f9798:	f9401be0 	ldr	x0, [sp, #48]
  6f979c:	94085145 	bl	90dcb0 <_ZdlPv@plt>
  6f97a0:	f9401708 	ldr	x8, [x24, #40]
  6f97a4:	f85f83a9 	ldur	x9, [x29, #-8]
  6f97a8:	eb09011f 	cmp	x8, x9
  6f97ac:	54000061 	b.ne	6f97b8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_n@@Base+0x244>  // b.any
  6f97b0:	aa1403e0 	mov	x0, x20
  6f97b4:	9408417e 	bl	909dac <__emutls_get_address@@Base+0x980>
  6f97b8:	9408514a 	bl	90dce0 <__stack_chk_fail@plt>

Disassembly of section __lcxx_override:

Disassembly of section .plt:
