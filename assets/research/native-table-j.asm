
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

00000000006f6d84 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base>:
  6f6d84:	d10303ff 	sub	sp, sp, #0xc0
  6f6d88:	a9077bfd 	stp	x29, x30, [sp, #112]
  6f6d8c:	f90043f9 	str	x25, [sp, #128]
  6f6d90:	a9095ff8 	stp	x24, x23, [sp, #144]
  6f6d94:	a90a57f6 	stp	x22, x21, [sp, #160]
  6f6d98:	a90b4ff4 	stp	x20, x19, [sp, #176]
  6f6d9c:	9101c3fd 	add	x29, sp, #0x70
  6f6da0:	d53bd059 	mrs	x25, tpidr_el0
  6f6da4:	aa0203e1 	mov	x1, x2
  6f6da8:	aa0303f4 	mov	x20, x3
  6f6dac:	f9401728 	ldr	x8, [x25, #40]
  6f6db0:	aa0003f3 	mov	x19, x0
  6f6db4:	d10083b5 	sub	x21, x29, #0x20
  6f6db8:	f81f83a8 	stur	x8, [x29, #-8]
  6f6dbc:	d10083a8 	sub	x8, x29, #0x20
  6f6dc0:	940000cc 	bl	6f70f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x36c>
  6f6dc4:	385e03a8 	ldurb	w8, [x29, #-32]
  6f6dc8:	f85f03a9 	ldur	x9, [x29, #-16]
  6f6dcc:	7200011f 	tst	w8, #0x1
  6f6dd0:	9a951536 	csinc	x22, x9, x21, ne	// ne = any
  6f6dd4:	aa1603e0 	mov	x0, x22
  6f6dd8:	94085bba 	bl	90dcc0 <strlen@plt>
  6f6ddc:	b100201f 	cmn	x0, #0x8
  6f6de0:	540012e2 	b.cs	6f703c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x2b8>  // b.hs, b.nlast
  6f6de4:	aa0003f5 	mov	x21, x0
  6f6de8:	f1005c1f 	cmp	x0, #0x17
  6f6dec:	540000e2 	b.cs	6f6e08 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x84>  // b.hs, b.nlast
  6f6df0:	531f7aa8 	lsl	w8, w21, #1
  6f6df4:	9100e3e9 	add	x9, sp, #0x38
  6f6df8:	b2400137 	orr	x23, x9, #0x1
  6f6dfc:	3900e3e8 	strb	w8, [sp, #56]
  6f6e00:	b50001d5 	cbnz	x21, 6f6e38 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0xb4>
  6f6e04:	14000011 	b	6f6e48 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0xc4>
  6f6e08:	927df2a8 	and	x8, x21, #0xfffffffffffffff8
  6f6e0c:	b2400aa9 	orr	x9, x21, #0x7
  6f6e10:	91002108 	add	x8, x8, #0x8
  6f6e14:	f1005d3f 	cmp	x9, #0x17
  6f6e18:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f6e1c:	91000518 	add	x24, x8, #0x1
  6f6e20:	aa1803e0 	mov	x0, x24
  6f6e24:	94085b9b 	bl	90dc90 <_Znwm@plt>
  6f6e28:	b2400308 	orr	x8, x24, #0x1
  6f6e2c:	aa0003f7 	mov	x23, x0
  6f6e30:	a90403f5 	stp	x21, x0, [sp, #64]
  6f6e34:	f9001fe8 	str	x8, [sp, #56]
  6f6e38:	aa1703e0 	mov	x0, x23
  6f6e3c:	aa1603e1 	mov	x1, x22
  6f6e40:	aa1503e2 	mov	x2, x21
  6f6e44:	94085ba3 	bl	90dcd0 <memmove@plt>
  6f6e48:	38356aff 	strb	wzr, [x23, x21]
  6f6e4c:	9100e3e0 	add	x0, sp, #0x38
  6f6e50:	94065d60 	bl	88e3d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x193d90>
  6f6e54:	3940e3e8 	ldrb	w8, [sp, #56]
  6f6e58:	aa0003f5 	mov	x21, x0
  6f6e5c:	36000068 	tbz	w8, #0, 6f6e68 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0xe4>
  6f6e60:	f94027e0 	ldr	x0, [sp, #72]
  6f6e64:	94085b93 	bl	90dcb0 <_ZdlPv@plt>
  6f6e68:	b4000cb5 	cbz	x21, 6f6ffc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x278>
  6f6e6c:	910083e8 	add	x8, sp, #0x20
  6f6e70:	aa1303e0 	mov	x0, x19
  6f6e74:	aa1403e1 	mov	x1, x20
  6f6e78:	910083f4 	add	x20, sp, #0x20
  6f6e7c:	9400009d 	bl	6f70f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x36c>
  6f6e80:	394083e8 	ldrb	w8, [sp, #32]
  6f6e84:	f9401be9 	ldr	x9, [sp, #48]
  6f6e88:	7200011f 	tst	w8, #0x1
  6f6e8c:	9a941536 	csinc	x22, x9, x20, ne	// ne = any
  6f6e90:	aa1603e0 	mov	x0, x22
  6f6e94:	94085b8b 	bl	90dcc0 <strlen@plt>
  6f6e98:	b100201f 	cmn	x0, #0x8
  6f6e9c:	54000dc2 	b.cs	6f7054 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x2d0>  // b.hs, b.nlast
  6f6ea0:	aa0003f4 	mov	x20, x0
  6f6ea4:	f1005c1f 	cmp	x0, #0x17
  6f6ea8:	540000e2 	b.cs	6f6ec4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x140>  // b.hs, b.nlast
  6f6eac:	531f7a88 	lsl	w8, w20, #1
  6f6eb0:	910023e9 	add	x9, sp, #0x8
  6f6eb4:	b2400137 	orr	x23, x9, #0x1
  6f6eb8:	390023e8 	strb	w8, [sp, #8]
  6f6ebc:	b50001d4 	cbnz	x20, 6f6ef4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x170>
  6f6ec0:	14000011 	b	6f6f04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x180>
  6f6ec4:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f6ec8:	b2400a89 	orr	x9, x20, #0x7
  6f6ecc:	91002108 	add	x8, x8, #0x8
  6f6ed0:	f1005d3f 	cmp	x9, #0x17
  6f6ed4:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f6ed8:	91000518 	add	x24, x8, #0x1
  6f6edc:	aa1803e0 	mov	x0, x24
  6f6ee0:	94085b6c 	bl	90dc90 <_Znwm@plt>
  6f6ee4:	b2400308 	orr	x8, x24, #0x1
  6f6ee8:	aa0003f7 	mov	x23, x0
  6f6eec:	a90103f4 	stp	x20, x0, [sp, #16]
  6f6ef0:	f90007e8 	str	x8, [sp, #8]
  6f6ef4:	aa1703e0 	mov	x0, x23
  6f6ef8:	aa1603e1 	mov	x1, x22
  6f6efc:	aa1403e2 	mov	x2, x20
  6f6f00:	94085b74 	bl	90dcd0 <memmove@plt>
  6f6f04:	f94002a8 	ldr	x8, [x21]
  6f6f08:	38346aff 	strb	wzr, [x23, x20]
  6f6f0c:	f9400108 	ldr	x8, [x8]
  6f6f10:	910023e1 	add	x1, sp, #0x8
  6f6f14:	aa1503e0 	mov	x0, x21
  6f6f18:	d63f0100 	blr	x8
  6f6f1c:	394023e8 	ldrb	w8, [sp, #8]
  6f6f20:	aa0003f6 	mov	x22, x0
  6f6f24:	aa0103f4 	mov	x20, x1
  6f6f28:	36000068 	tbz	w8, #0, 6f6f34 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x1b0>
  6f6f2c:	f9400fe0 	ldr	x0, [sp, #24]
  6f6f30:	94085b60 	bl	90dcb0 <_ZdlPv@plt>
  6f6f34:	f9400268 	ldr	x8, [x19]
  6f6f38:	f9401908 	ldr	x8, [x8, #48]
  6f6f3c:	f0ffdea1 	adrp	x1, 2cd000 <psa_to_md_errors@@Base-0x400c14>
  6f6f40:	9105d821 	add	x1, x1, #0x176
  6f6f44:	aa1303e0 	mov	x0, x19
  6f6f48:	d63f0100 	blr	x8
  6f6f4c:	f9400268 	ldr	x8, [x19]
  6f6f50:	aa0003f5 	mov	x21, x0
  6f6f54:	f9429d08 	ldr	x8, [x8, #1336]
  6f6f58:	f0ffd8c1 	adrp	x1, 211000 <psa_to_md_errors@@Base-0x4bcc14>
  6f6f5c:	912fb821 	add	x1, x1, #0xbee
  6f6f60:	aa1303e0 	mov	x0, x19
  6f6f64:	d63f0100 	blr	x8
  6f6f68:	f9400268 	ldr	x8, [x19]
  6f6f6c:	aa0003e3 	mov	x3, x0
  6f6f70:	f942b108 	ldr	x8, [x8, #1376]
  6f6f74:	aa1303e0 	mov	x0, x19
  6f6f78:	2a1603e1 	mov	w1, w22
  6f6f7c:	aa1503e2 	mov	x2, x21
  6f6f80:	d63f0100 	blr	x8
  6f6f84:	aa0003f5 	mov	x21, x0
  6f6f88:	710006df 	cmp	w22, #0x1
  6f6f8c:	5400030b 	b.lt	6f6fec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x268>  // b.tstop
  6f6f90:	aa1f03f7 	mov	x23, xzr
  6f6f94:	92407ad8 	and	x24, x22, #0x7fffffff
  6f6f98:	f9400268 	ldr	x8, [x19]
  6f6f9c:	f8777a81 	ldr	x1, [x20, x23, lsl #3]
  6f6fa0:	f9429d08 	ldr	x8, [x8, #1336]
  6f6fa4:	aa1303e0 	mov	x0, x19
  6f6fa8:	d63f0100 	blr	x8
  6f6fac:	f9400268 	ldr	x8, [x19]
  6f6fb0:	aa0003f6 	mov	x22, x0
  6f6fb4:	f942b908 	ldr	x8, [x8, #1392]
  6f6fb8:	aa1303e0 	mov	x0, x19
  6f6fbc:	aa1503e1 	mov	x1, x21
  6f6fc0:	2a1703e2 	mov	w2, w23
  6f6fc4:	aa1603e3 	mov	x3, x22
  6f6fc8:	d63f0100 	blr	x8
  6f6fcc:	f9400268 	ldr	x8, [x19]
  6f6fd0:	f9405d08 	ldr	x8, [x8, #184]
  6f6fd4:	aa1303e0 	mov	x0, x19
  6f6fd8:	aa1603e1 	mov	x1, x22
  6f6fdc:	d63f0100 	blr	x8
  6f6fe0:	910006f7 	add	x23, x23, #0x1
  6f6fe4:	eb17031f 	cmp	x24, x23
  6f6fe8:	54fffd81 	b.ne	6f6f98 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x214>  // b.any
  6f6fec:	394083e8 	ldrb	w8, [sp, #32]
  6f6ff0:	36000068 	tbz	w8, #0, 6f6ffc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x278>
  6f6ff4:	f9401be0 	ldr	x0, [sp, #48]
  6f6ff8:	94085b2e 	bl	90dcb0 <_ZdlPv@plt>
  6f6ffc:	385e03a8 	ldurb	w8, [x29, #-32]
  6f7000:	36000068 	tbz	w8, #0, 6f700c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x288>
  6f7004:	f85f03a0 	ldur	x0, [x29, #-16]
  6f7008:	94085b2a 	bl	90dcb0 <_ZdlPv@plt>
  6f700c:	f9401728 	ldr	x8, [x25, #40]
  6f7010:	f85f83a9 	ldur	x9, [x29, #-8]
  6f7014:	eb09011f 	cmp	x8, x9
  6f7018:	540006a1 	b.ne	6f70ec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x368>  // b.any
  6f701c:	aa1503e0 	mov	x0, x21
  6f7020:	a94b4ff4 	ldp	x20, x19, [sp, #176]
  6f7024:	f94043f9 	ldr	x25, [sp, #128]
  6f7028:	a94a57f6 	ldp	x22, x21, [sp, #160]
  6f702c:	a9495ff8 	ldp	x24, x23, [sp, #144]
  6f7030:	a9477bfd 	ldp	x29, x30, [sp, #112]
  6f7034:	910303ff 	add	sp, sp, #0xc0
