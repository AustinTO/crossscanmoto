
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

000000000088e3d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193d90>:
  88e3d0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  88e3d4:	a9014ff4 	stp	x20, x19, [sp, #16]
  88e3d8:	910003fd 	mov	x29, sp
  88e3dc:	aa0003f4 	mov	x20, x0
  88e3e0:	52800100 	mov	w0, #0x8                   	// #8
  88e3e4:	9401fe2b 	bl	90dc90 <_Znwm@plt>
  88e3e8:	aa0003f3 	mov	x19, x0
  88e3ec:	97f9bd74 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e3f0:	39400288 	ldrb	w8, [x20]
  88e3f4:	f9400689 	ldr	x9, [x20, #8]
  88e3f8:	d341fd0a 	lsr	x10, x8, #1
  88e3fc:	7200011f 	tst	w8, #0x1
  88e400:	9a890149 	csel	x9, x10, x9, eq	// eq = none
  88e404:	f100253f 	cmp	x9, #0x9
  88e408:	54000a60 	b.eq	88e554 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193f14>  // b.none
  88e40c:	f100213f 	cmp	x9, #0x8
  88e410:	54000580 	b.eq	88e4c0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193e80>  // b.none
  88e414:	f1001d3f 	cmp	x9, #0x7
  88e418:	54000c41 	b.ne	88e5a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193f60>  // b.any
  88e41c:	f9400a89 	ldr	x9, [x20, #16]
  88e420:	7200011f 	tst	w8, #0x1
  88e424:	528eac6a 	mov	w10, #0x7563                	// #30051
  88e428:	72aa49aa 	movk	w10, #0x524d, lsl #16
  88e42c:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  88e430:	b9400109 	ldr	w9, [x8]
  88e434:	b8403108 	ldur	w8, [x8, #3]
  88e438:	6b0a013f 	cmp	w9, w10
  88e43c:	52882a49 	mov	w9, #0x4152                	// #16722
  88e440:	72aa6849 	movk	w9, #0x5342, lsl #16
  88e444:	7a490100 	ccmp	w8, w9, #0x0, eq	// eq = none
  88e448:	54000ac1 	b.ne	88e5a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193f60>  // b.any
  88e44c:	52801d00 	mov	w0, #0xe8                  	// #232
  88e450:	9401fe10 	bl	90dc90 <_Znwm@plt>
  88e454:	aa0003f3 	mov	x19, x0
  88e458:	97f9bd59 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e45c:	900008a8 	adrp	x8, 9a2000 <_ZTISt10bad_typeid@@Base+0x2cf8>
  88e460:	b0ffd109 	adrp	x9, 2af000 <psa_to_md_errors@@Base-0x41ec14>
  88e464:	91051129 	add	x9, x9, #0x144
  88e468:	f945a908 	ldr	x8, [x8, #2896]
  88e46c:	91004108 	add	x8, x8, #0x10
  88e470:	a9002668 	stp	x8, x9, [x19]
  88e474:	d503201f 	nop
  88e478:	107bc448 	adr	x8, 985d00 <syscall@plt+0x759b0>
  88e47c:	ad450500 	ldp	q0, q1, [x8, #160]
  88e480:	3dc03102 	ldr	q2, [x8, #192]
  88e484:	f9406909 	ldr	x9, [x8, #208]
  88e488:	3d803662 	str	q2, [x19, #208]
  88e48c:	ad058660 	stp	q0, q1, [x19, #176]
  88e490:	ad430500 	ldp	q0, q1, [x8, #96]
  88e494:	f9007269 	str	x9, [x19, #224]
  88e498:	ad038660 	stp	q0, q1, [x19, #112]
  88e49c:	ad440102 	ldp	q2, q0, [x8, #128]
  88e4a0:	ad048262 	stp	q2, q0, [x19, #144]
  88e4a4:	ad410101 	ldp	q1, q0, [x8, #32]
  88e4a8:	3dc01102 	ldr	q2, [x8, #64]
  88e4ac:	ad018261 	stp	q1, q0, [x19, #48]
  88e4b0:	3dc01500 	ldr	q0, [x8, #80]
  88e4b4:	ad028262 	stp	q2, q0, [x19, #80]
  88e4b8:	ad400101 	ldp	q1, q0, [x8]
  88e4bc:	140000cc 	b	88e7ec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1941ac>
  88e4c0:	f9400a89 	ldr	x9, [x20, #16]
  88e4c4:	7200011f 	tst	w8, #0x1
  88e4c8:	d28eac6a 	mov	x10, #0x7563                	// #30051
  88e4cc:	f2aa49aa 	movk	x10, #0x524d, lsl #16
  88e4d0:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  88e4d4:	f2c8482a 	movk	x10, #0x4241, lsl #32
  88e4d8:	f9400109 	ldr	x9, [x8]
  88e4dc:	f2e62a6a 	movk	x10, #0x3153, lsl #48
  88e4e0:	eb0a013f 	cmp	x9, x10
  88e4e4:	54000d80 	b.eq	88e694 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x194054>  // b.none
  88e4e8:	d28eac6a 	mov	x10, #0x7563                	// #30051
  88e4ec:	f9400109 	ldr	x9, [x8]
  88e4f0:	f2aa49aa 	movk	x10, #0x524d, lsl #16
  88e4f4:	f2c8482a 	movk	x10, #0x4241, lsl #32
  88e4f8:	f2e64a6a 	movk	x10, #0x3253, lsl #48
  88e4fc:	eb0a013f 	cmp	x9, x10
  88e500:	540014a0 	b.eq	88e794 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x194154>  // b.none
  88e504:	d28eac69 	mov	x9, #0x7563                	// #30051
  88e508:	f9400108 	ldr	x8, [x8]
  88e50c:	f2aa49a9 	movk	x9, #0x524d, lsl #16
  88e510:	f2c82929 	movk	x9, #0x4149, lsl #32
  88e514:	f2ea6849 	movk	x9, #0x5342, lsl #48
  88e518:	eb09011f 	cmp	x8, x9
  88e51c:	54000421 	b.ne	88e5a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193f60>  // b.any
  88e520:	52804e00 	mov	w0, #0x270                 	// #624
  88e524:	9401fddb 	bl	90dc90 <_Znwm@plt>
  88e528:	aa0003f3 	mov	x19, x0
  88e52c:	97f9bd24 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e530:	900008a8 	adrp	x8, 9a2000 <_ZTISt10bad_typeid@@Base+0x2cf8>
  88e534:	b0ffd109 	adrp	x9, 2af000 <psa_to_md_errors@@Base-0x41ec14>
  88e538:	91051129 	add	x9, x9, #0x144
  88e53c:	f945ad08 	ldr	x8, [x8, #2904]
  88e540:	d503201f 	nop
  88e544:	107bd1a1 	adr	x1, 985f78 <syscall@plt+0x75c28>
  88e548:	91004260 	add	x0, x19, #0x10
  88e54c:	52804c02 	mov	w2, #0x260                 	// #608
  88e550:	1400008d 	b	88e784 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x194144>
  88e554:	f9400a89 	ldr	x9, [x20, #16]
  88e558:	7200011f 	tst	w8, #0x1
  88e55c:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  88e560:	d28eac69 	mov	x9, #0x7563                	// #30051
  88e564:	f2aa49a9 	movk	x9, #0x524d, lsl #16
  88e568:	f940010a 	ldr	x10, [x8]
  88e56c:	3940210b 	ldrb	w11, [x8, #8]
  88e570:	f2c82929 	movk	x9, #0x4149, lsl #32
  88e574:	f2ea6849 	movk	x9, #0x5342, lsl #48
  88e578:	eb09015f 	cmp	x10, x9
  88e57c:	5280064a 	mov	w10, #0x32                  	// #50
  88e580:	7a4a0160 	ccmp	w11, w10, #0x0, eq	// eq = none
  88e584:	54000c40 	b.eq	88e70c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1940cc>  // b.none
  88e588:	f940010a 	ldr	x10, [x8]
  88e58c:	39402108 	ldrb	w8, [x8, #8]
  88e590:	eb09015f 	cmp	x10, x9
  88e594:	52800669 	mov	w9, #0x33                  	// #51
  88e598:	7a490100 	ccmp	w8, w9, #0x0, eq	// eq = none
  88e59c:	54001320 	b.eq	88e800 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1941c0>  // b.none
  88e5a0:	d0ffcc01 	adrp	x1, 210000 <psa_to_md_errors@@Base-0x4bdc14>
  88e5a4:	91042021 	add	x1, x1, #0x108
  88e5a8:	aa1403e0 	mov	x0, x20
  88e5ac:	97f9bcde 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  88e5b0:	36000180 	tbz	w0, #0, 88e5e0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193fa0>
  88e5b4:	52802200 	mov	w0, #0x110                 	// #272
  88e5b8:	9401fdb6 	bl	90dc90 <_Znwm@plt>
  88e5bc:	aa0003f3 	mov	x19, x0
  88e5c0:	97f9bcff 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e5c4:	900008a8 	adrp	x8, 9a2000 <_ZTISt10bad_typeid@@Base+0x2cf8>
  88e5c8:	b0ffd109 	adrp	x9, 2af000 <psa_to_md_errors@@Base-0x41ec14>
  88e5cc:	91051129 	add	x9, x9, #0x144
  88e5d0:	f945b108 	ldr	x8, [x8, #2912]
  88e5d4:	d503201f 	nop
  88e5d8:	107bfa8a 	adr	x10, 986528 <syscall@plt+0x761d8>
  88e5dc:	14000038 	b	88e6bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x19407c>
  88e5e0:	b0ffd381 	adrp	x1, 2ff000 <psa_to_md_errors@@Base-0x3cec14>
  88e5e4:	91097421 	add	x1, x1, #0x25d
  88e5e8:	aa1403e0 	mov	x0, x20
  88e5ec:	97f9bcce 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  88e5f0:	360001c0 	tbz	w0, #0, 88e628 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193fe8>
  88e5f4:	52802600 	mov	w0, #0x130                 	// #304
  88e5f8:	9401fda6 	bl	90dc90 <_Znwm@plt>
  88e5fc:	aa0003f3 	mov	x19, x0
  88e600:	97f9bcef 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e604:	900008a8 	adrp	x8, 9a2000 <_ZTISt10bad_typeid@@Base+0x2cf8>
  88e608:	b0ffd109 	adrp	x9, 2af000 <psa_to_md_errors@@Base-0x41ec14>
  88e60c:	91051129 	add	x9, x9, #0x144
  88e610:	f945b508 	ldr	x8, [x8, #2920]
  88e614:	d503201f 	nop
  88e618:	107c0081 	adr	x1, 986628 <syscall@plt+0x762d8>
  88e61c:	91004260 	add	x0, x19, #0x10
  88e620:	52802402 	mov	w2, #0x120                 	// #288
  88e624:	14000058 	b	88e784 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x194144>
  88e628:	b0ffd381 	adrp	x1, 2ff000 <psa_to_md_errors@@Base-0x3cec14>
  88e62c:	91099421 	add	x1, x1, #0x265
  88e630:	aa1403e0 	mov	x0, x20
  88e634:	97f9bcbc 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  88e638:	36000840 	tbz	w0, #0, 88e740 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x194100>
  88e63c:	52801000 	mov	w0, #0x80                  	// #128
  88e640:	9401fd94 	bl	90dc90 <_Znwm@plt>
  88e644:	aa0003f3 	mov	x19, x0
  88e648:	97f9bcdd 	bl	6fd9bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x337c>
  88e64c:	900008a8 	adrp	x8, 9a2000 <_ZTISt10bad_typeid@@Base+0x2cf8>
