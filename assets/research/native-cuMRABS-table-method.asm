
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

0000000000892224 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197be4>:
  892224:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  892228:	a9014ff4 	stp	x20, x19, [sp, #16]
  89222c:	910003fd 	mov	x29, sp
  892230:	39400028 	ldrb	w8, [x1]
  892234:	f9400429 	ldr	x9, [x1, #8]
  892238:	aa0103f4 	mov	x20, x1
  89223c:	aa0003f3 	mov	x19, x0
  892240:	d341fd0a 	lsr	x10, x8, #1
  892244:	7200011f 	tst	w8, #0x1
  892248:	9a890149 	csel	x9, x10, x9, eq	// eq = none
  89224c:	f100253f 	cmp	x9, #0x9
  892250:	5400020c 	b.gt	892290 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197c50>
  892254:	f100193f 	cmp	x9, #0x6
  892258:	54000580 	b.eq	892308 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197cc8>  // b.none
  89225c:	f100213f 	cmp	x9, #0x8
  892260:	540009a1 	b.ne	892394 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d54>  // b.any
  892264:	f9400a89 	ldr	x9, [x20, #16]
  892268:	7200011f 	tst	w8, #0x1
  89226c:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  892270:	d2886829 	mov	x9, #0x4341                	// #17217
  892274:	f2aaaa89 	movk	x9, #0x5554, lsl #16
  892278:	f9400108 	ldr	x8, [x8]
  89227c:	f2ca8829 	movk	x9, #0x5441, lsl #32
  892280:	f2ea49e9 	movk	x9, #0x524f, lsl #48
  892284:	eb09011f 	cmp	x8, x9
  892288:	54000861 	b.ne	892394 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d54>  // b.any
  89228c:	14000051 	b	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>
  892290:	f100293f 	cmp	x9, #0xa
  892294:	54000520 	b.eq	892338 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197cf8>  // b.none
  892298:	f1002d3f 	cmp	x9, #0xb
  89229c:	540007c1 	b.ne	892394 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d54>  // b.any
  8922a0:	f9400a89 	ldr	x9, [x20, #16]
  8922a4:	7200011f 	tst	w8, #0x1
  8922a8:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  8922ac:	d2886829 	mov	x9, #0x4341                	// #17217
  8922b0:	f2aaaa89 	movk	x9, #0x5554, lsl #16
  8922b4:	f940010a 	ldr	x10, [x8]
  8922b8:	f840310b 	ldur	x11, [x8, #3]
  8922bc:	f2ca8829 	movk	x9, #0x5441, lsl #32
  8922c0:	f2ea49e9 	movk	x9, #0x524f, lsl #48
  8922c4:	eb09015f 	cmp	x10, x9
  8922c8:	d2882aaa 	mov	x10, #0x4155                	// #16725
  8922cc:	f2a9ea8a 	movk	x10, #0x4f54, lsl #16
  8922d0:	f2ca0a4a 	movk	x10, #0x5052, lsl #32
  8922d4:	f2ea69ea 	movk	x10, #0x534f, lsl #48
  8922d8:	fa4a0160 	ccmp	x11, x10, #0x0, eq	// eq = none
  8922dc:	540007a0 	b.eq	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>  // b.none
  8922e0:	f940010a 	ldr	x10, [x8]
  8922e4:	f8403108 	ldur	x8, [x8, #3]
  8922e8:	eb09015f 	cmp	x10, x9
  8922ec:	d2882aa9 	mov	x9, #0x4155                	// #16725
  8922f0:	f2a9ea89 	movk	x9, #0x4f54, lsl #16
  8922f4:	f2c86a49 	movk	x9, #0x4352, lsl #32
  8922f8:	f2e889a9 	movk	x9, #0x444d, lsl #48
  8922fc:	fa490100 	ccmp	x8, x9, #0x0, eq	// eq = none
  892300:	540004a1 	b.ne	892394 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d54>  // b.any
  892304:	14000033 	b	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>
  892308:	f9400a89 	ldr	x9, [x20, #16]
  89230c:	7200011f 	tst	w8, #0x1
  892310:	52882a0a 	mov	w10, #0x4150                	// #16720
  892314:	72a82a4a 	movk	w10, #0x4152, lsl #16
  892318:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  89231c:	b9400109 	ldr	w9, [x8]
  892320:	79400908 	ldrh	w8, [x8, #4]
  892324:	6b0a013f 	cmp	w9, w10
  892328:	528a69a9 	mov	w9, #0x534d                	// #21325
  89232c:	7a490100 	ccmp	w8, w9, #0x0, eq	// eq = none
  892330:	54000321 	b.ne	892394 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d54>  // b.any
  892334:	14000027 	b	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>
  892338:	f9400a89 	ldr	x9, [x20, #16]
  89233c:	7200011f 	tst	w8, #0x1
  892340:	d2882a0b 	mov	x11, #0x4150                	// #16720
  892344:	f2a82a4b 	movk	x11, #0x4152, lsl #16
  892348:	9a941528 	csinc	x8, x9, x20, ne	// ne = any
  89234c:	f2ca69ab 	movk	x11, #0x534d, lsl #32
  892350:	f9400109 	ldr	x9, [x8]
  892354:	7940110a 	ldrh	w10, [x8, #8]
  892358:	f2ea4beb 	movk	x11, #0x525f, lsl #48
  89235c:	eb0b013f 	cmp	x9, x11
  892360:	528a68a9 	mov	w9, #0x5345                	// #21317
  892364:	7a490140 	ccmp	w10, w9, #0x0, eq	// eq = none
  892368:	54000340 	b.eq	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>  // b.none
  89236c:	d2882a0a 	mov	x10, #0x4150                	// #16720
  892370:	f9400109 	ldr	x9, [x8]
  892374:	79401108 	ldrh	w8, [x8, #8]
  892378:	f2a82a4a 	movk	x10, #0x4152, lsl #16
  89237c:	f2ca69aa 	movk	x10, #0x534d, lsl #32
  892380:	f2ea8bea 	movk	x10, #0x545f, lsl #48
  892384:	eb0a013f 	cmp	x9, x10
  892388:	52884829 	mov	w9, #0x4241                	// #16961
  89238c:	7a490100 	ccmp	w8, w9, #0x0, eq	// eq = none
  892390:	54000200 	b.eq	8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>  // b.none
  892394:	90ffcb21 	adrp	x1, 1f6000 <psa_to_md_errors@@Base-0x4d7c14>
  892398:	913d8421 	add	x1, x1, #0xf61
  89239c:	aa1403e0 	mov	x0, x20
  8923a0:	97f9ad61 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  8923a4:	37000160 	tbnz	w0, #0, 8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>
  8923a8:	f0ffd001 	adrp	x1, 295000 <psa_to_md_errors@@Base-0x438c14>
  8923ac:	91302c21 	add	x1, x1, #0xc0b
  8923b0:	aa1403e0 	mov	x0, x20
  8923b4:	97f9ad5c 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  8923b8:	370000c0 	tbnz	w0, #0, 8923d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d90>
  8923bc:	f0ffd001 	adrp	x1, 295000 <psa_to_md_errors@@Base-0x438c14>
  8923c0:	91305421 	add	x1, x1, #0xc15
  8923c4:	aa1403e0 	mov	x0, x20
  8923c8:	97f9ad57 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  8923cc:	360000c0 	tbz	w0, #0, 8923e4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197da4>
  8923d0:	aa1f03e0 	mov	x0, xzr
  8923d4:	91004261 	add	x1, x19, #0x10
  8923d8:	a9414ff4 	ldp	x20, x19, [sp, #16]
  8923dc:	a8c27bfd 	ldp	x29, x30, [sp], #32
  8923e0:	d65f03c0 	ret
  8923e4:	f0ffe081 	adrp	x1, 4a5000 <psa_to_md_errors@@Base-0x228c14>
  8923e8:	913d9021 	add	x1, x1, #0xf64
  8923ec:	aa1403e0 	mov	x0, x20
  8923f0:	97f9ad4d 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  8923f4:	36000080 	tbz	w0, #0, 892404 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197dc4>
  8923f8:	91004261 	add	x1, x19, #0x10
  8923fc:	52800360 	mov	w0, #0x1b                  	// #27
  892400:	17fffff6 	b	8923d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d98>
  892404:	90ffd2a1 	adrp	x1, 2e6000 <psa_to_md_errors@@Base-0x3e7c14>
  892408:	913f0021 	add	x1, x1, #0xfc0
  89240c:	aa1403e0 	mov	x0, x20
  892410:	97f9ad45 	bl	6fd924 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x32e4>
  892414:	36000080 	tbz	w0, #0, 892424 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197de4>
  892418:	91002261 	add	x1, x19, #0x8
  89241c:	52800020 	mov	w0, #0x1                   	// #1
  892420:	17ffffee 	b	8923d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x197d98>
  892424:	d0ffd5e1 	adrp	x1, 350000 <psa_to_md_errors@@Base-0x37dc14>
  892428:	91021021 	add	x1, x1, #0x84
  89242c:	aa1403e0 	mov	x0, x20
