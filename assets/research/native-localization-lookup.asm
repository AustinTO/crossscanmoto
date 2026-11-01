
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

000000000081538c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ad4c>:
  81538c:	d10183ff 	sub	sp, sp, #0x60
  815390:	a9027bfd 	stp	x29, x30, [sp, #32]
  815394:	f9001bf7 	str	x23, [sp, #48]
  815398:	a90457f6 	stp	x22, x21, [sp, #64]
  81539c:	a9054ff4 	stp	x20, x19, [sp, #80]
  8153a0:	910083fd 	add	x29, sp, #0x20
  8153a4:	d53bd056 	mrs	x22, tpidr_el0
  8153a8:	aa0803f3 	mov	x19, x8
  8153ac:	aa0103f5 	mov	x21, x1
  8153b0:	f94016c8 	ldr	x8, [x22, #40]
  8153b4:	2a0003f4 	mov	w20, w0
  8153b8:	f81f83a8 	stur	x8, [x29, #-8]
  8153bc:	39400028 	ldrb	w8, [x1]
  8153c0:	f9400429 	ldr	x9, [x1, #8]
  8153c4:	a9007e7f 	stp	xzr, xzr, [x19]
  8153c8:	f9000a7f 	str	xzr, [x19, #16]
  8153cc:	d341fd0a 	lsr	x10, x8, #1
  8153d0:	7200011f 	tst	w8, #0x1
  8153d4:	9a890149 	csel	x9, x10, x9, eq	// eq = none
  8153d8:	f100093f 	cmp	x9, #0x2
  8153dc:	54000381 	b.ne	81544c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae0c>  // b.any
  8153e0:	f9400aa9 	ldr	x9, [x21, #16]
  8153e4:	7200011f 	tst	w8, #0x1
  8153e8:	528f4c6a 	mov	w10, #0x7a63                	// #31331
  8153ec:	9a951528 	csinc	x8, x9, x21, ne	// ne = any
  8153f0:	79400109 	ldrh	w9, [x8]
  8153f4:	6b0a013f 	cmp	w9, w10
  8153f8:	540004e0 	b.eq	815494 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae54>  // b.none
  8153fc:	79400109 	ldrh	w9, [x8]
  815400:	528cac8a 	mov	w10, #0x6564                	// #25956
  815404:	6b0a013f 	cmp	w9, w10
  815408:	54000600 	b.eq	8154c8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae88>  // b.none
  81540c:	79400109 	ldrh	w9, [x8]
  815410:	528d8caa 	mov	w10, #0x6c65                	// #27749
  815414:	6b0a013f 	cmp	w9, w10
  815418:	54000600 	b.eq	8154d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae98>  // b.none
  81541c:	79400109 	ldrh	w9, [x8]
  815420:	528dccaa 	mov	w10, #0x6e65                	// #28261
  815424:	6b0a013f 	cmp	w9, w10
  815428:	54000720 	b.eq	81550c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11aecc>  // b.none
  81542c:	79400109 	ldrh	w9, [x8]
  815430:	528e6caa 	mov	w10, #0x7365                	// #29541
  815434:	6b0a013f 	cmp	w9, w10
  815438:	54000840 	b.eq	815540 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11af00>  // b.none
  81543c:	79400108 	ldrh	w8, [x8]
  815440:	528e4cc9 	mov	w9, #0x7266                	// #29286
  815444:	6b09011f 	cmp	w8, w9
  815448:	54000840 	b.eq	815550 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11af10>  // b.none
  81544c:	d0ffcea1 	adrp	x1, 1eb000 <psa_to_md_errors@@Base-0x4e2c14>
  815450:	911b1021 	add	x1, x1, #0x6c4
  815454:	aa1503e0 	mov	x0, x21
  815458:	97fba133 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  81545c:	360000a0 	tbz	w0, #0, 815470 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae30>
  815460:	910003e8 	mov	x8, sp
  815464:	2a1403e0 	mov	w0, w20
  815468:	9401122e 	bl	859d20 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x15f6e0>
  81546c:	1400003c 	b	81555c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11af1c>
  815470:	b0ffe001 	adrp	x1, 416000 <psa_to_md_errors@@Base-0x2b7c14>
  815474:	91177021 	add	x1, x1, #0x5dc
  815478:	aa1503e0 	mov	x0, x21
  81547c:	97fba12a 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  815480:	36000120 	tbz	w0, #0, 8154a4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11ae64>
  815484:	910003e8 	mov	x8, sp
  815488:	2a1403e0 	mov	w0, w20
  81548c:	94013c1f 	bl	864508 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x169ec8>
  815490:	14000033 	b	81555c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11af1c>
  815494:	910003e8 	mov	x8, sp
  815498:	2a1403e0 	mov	w0, w20
  81549c:	940001dd 	bl	815c10 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11b5d0>
  8154a0:	1400002f 	b	81555c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11af1c>
  8154a4:	b0ffdf21 	adrp	x1, 3fa000 <psa_to_md_errors@@Base-0x2d3c14>
  8154a8:	91377421 	add	x1, x1, #0xddd
  8154ac:	aa1503e0 	mov	x0, x21
  8154b0:	97fba11d 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  8154b4:	360001a0 	tbz	w0, #0, 8154e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x11aea8>
  8154b8:	910003e8 	mov	x8, sp
  8154bc:	2a1403e0 	mov	w0, w20
