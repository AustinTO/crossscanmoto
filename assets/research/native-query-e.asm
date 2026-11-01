
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

00000000006f7c10 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base>:
  6f7c10:	d107c3ff 	sub	sp, sp, #0x1f0
  6f7c14:	a91a7bfd 	stp	x29, x30, [sp, #416]
  6f7c18:	f900dbfc 	str	x28, [sp, #432]
  6f7c1c:	a91c5ff8 	stp	x24, x23, [sp, #448]
  6f7c20:	a91d57f6 	stp	x22, x21, [sp, #464]
  6f7c24:	a91e4ff4 	stp	x20, x19, [sp, #480]
  6f7c28:	910683fd 	add	x29, sp, #0x1a0
  6f7c2c:	d53bd058 	mrs	x24, tpidr_el0
  6f7c30:	aa0203e1 	mov	x1, x2
  6f7c34:	2a0403f4 	mov	w20, w4
  6f7c38:	f9401708 	ldr	x8, [x24, #40]
  6f7c3c:	aa0303f5 	mov	x21, x3
  6f7c40:	aa0003f3 	mov	x19, x0
  6f7c44:	d10083b6 	sub	x22, x29, #0x20
  6f7c48:	f81f83a8 	stur	x8, [x29, #-8]
  6f7c4c:	d10083a8 	sub	x8, x29, #0x20
  6f7c50:	97fffd28 	bl	6f70f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x36c>
  6f7c54:	d100e3a8 	sub	x8, x29, #0x38
  6f7c58:	aa1303e0 	mov	x0, x19
  6f7c5c:	aa1503e1 	mov	x1, x21
  6f7c60:	97fffd24 	bl	6f70f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_j@@Base+0x36c>
  6f7c64:	71000a9f 	cmp	w20, #0x2
  6f7c68:	b24002c8 	orr	x8, x22, #0x1
  6f7c6c:	540002ec 	b.gt	6f7cc8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb8>
  6f7c70:	340005b4 	cbz	w20, 6f7d24 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x114>
  6f7c74:	7100069f 	cmp	w20, #0x1
  6f7c78:	54000bc0 	b.eq	6f7df0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x1e0>  // b.none
  6f7c7c:	71000a9f 	cmp	w20, #0x2
  6f7c80:	54000961 	b.ne	6f7dac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x19c>  // b.any
  6f7c84:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7c88:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7c8c:	7200013f 	tst	w9, #0x1
  6f7c90:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7c94:	aa1503e0 	mov	x0, x21
  6f7c98:	9408580a 	bl	90dcc0 <strlen@plt>
  6f7c9c:	b100201f 	cmn	x0, #0x8
  6f7ca0:	54005c22 	b.cs	6f8824 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc14>  // b.hs, b.nlast
  6f7ca4:	aa0003f4 	mov	x20, x0
  6f7ca8:	f1005c1f 	cmp	x0, #0x17
  6f7cac:	54001b82 	b.cs	6f801c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x40c>  // b.hs, b.nlast
  6f7cb0:	531f7a88 	lsl	w8, w20, #1
  6f7cb4:	d10323a9 	sub	x9, x29, #0xc8
  6f7cb8:	b2400136 	orr	x22, x9, #0x1
  6f7cbc:	381383a8 	sturb	w8, [x29, #-200]
  6f7cc0:	b5001c74 	cbnz	x20, 6f804c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x43c>
  6f7cc4:	140000e6 	b	6f805c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x44c>
  6f7cc8:	71000e9f 	cmp	w20, #0x3
  6f7ccc:	540004e0 	b.eq	6f7d68 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x158>  // b.none
  6f7cd0:	7100129f 	cmp	w20, #0x4
  6f7cd4:	54000b00 	b.eq	6f7e34 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x224>  // b.none
  6f7cd8:	7100169f 	cmp	w20, #0x5
  6f7cdc:	54000681 	b.ne	6f7dac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x19c>  // b.any
  6f7ce0:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7ce4:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7ce8:	7200013f 	tst	w9, #0x1
  6f7cec:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7cf0:	aa1503e0 	mov	x0, x21
  6f7cf4:	940857f3 	bl	90dcc0 <strlen@plt>
  6f7cf8:	b100201f 	cmn	x0, #0x8
  6f7cfc:	54005a02 	b.cs	6f883c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc2c>  // b.hs, b.nlast
  6f7d00:	aa0003f4 	mov	x20, x0
  6f7d04:	f1005c1f 	cmp	x0, #0x17
  6f7d08:	54001d02 	b.cs	6f80a8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x498>  // b.hs, b.nlast
  6f7d0c:	531f7a88 	lsl	w8, w20, #1
  6f7d10:	910123e9 	add	x9, sp, #0x48
  6f7d14:	b2400136 	orr	x22, x9, #0x1
  6f7d18:	390123e8 	strb	w8, [sp, #72]
  6f7d1c:	b5001df4 	cbnz	x20, 6f80d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x4c8>
  6f7d20:	140000f2 	b	6f80e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x4d8>
  6f7d24:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7d28:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7d2c:	7200013f 	tst	w9, #0x1
  6f7d30:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7d34:	aa1503e0 	mov	x0, x21
  6f7d38:	940857e2 	bl	90dcc0 <strlen@plt>
  6f7d3c:	b100201f 	cmn	x0, #0x8
  6f7d40:	540054e2 	b.cs	6f87dc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xbcc>  // b.hs, b.nlast
  6f7d44:	aa0003f4 	mov	x20, x0
  6f7d48:	f1005c1f 	cmp	x0, #0x17
  6f7d4c:	54000962 	b.cs	6f7e78 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x268>  // b.hs, b.nlast
  6f7d50:	531f7a88 	lsl	w8, w20, #1
  6f7d54:	d101a3a9 	sub	x9, x29, #0x68
  6f7d58:	b2400136 	orr	x22, x9, #0x1
  6f7d5c:	381983a8 	sturb	w8, [x29, #-104]
  6f7d60:	b5000a54 	cbnz	x20, 6f7ea8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x298>
  6f7d64:	14000055 	b	6f7eb8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x2a8>
  6f7d68:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7d6c:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7d70:	7200013f 	tst	w9, #0x1
  6f7d74:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7d78:	aa1503e0 	mov	x0, x21
  6f7d7c:	940857d1 	bl	90dcc0 <strlen@plt>
  6f7d80:	b100201f 	cmn	x0, #0x8
  6f7d84:	54005382 	b.cs	6f87f4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xbe4>  // b.hs, b.nlast
  6f7d88:	aa0003f4 	mov	x20, x0
  6f7d8c:	f1005c1f 	cmp	x0, #0x17
  6f7d90:	54000ba2 	b.cs	6f7f04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x2f4>  // b.hs, b.nlast
  6f7d94:	531f7a88 	lsl	w8, w20, #1
  6f7d98:	9102a3e9 	add	x9, sp, #0xa8
  6f7d9c:	b2400136 	orr	x22, x9, #0x1
  6f7da0:	3902a3e8 	strb	w8, [sp, #168]
  6f7da4:	b5000c94 	cbnz	x20, 6f7f34 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x324>
  6f7da8:	14000067 	b	6f7f44 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x334>
  6f7dac:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7db0:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7db4:	7200013f 	tst	w9, #0x1
  6f7db8:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7dbc:	aa1503e0 	mov	x0, x21
  6f7dc0:	940857c0 	bl	90dcc0 <strlen@plt>
  6f7dc4:	b100201f 	cmn	x0, #0x8
  6f7dc8:	54005222 	b.cs	6f880c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xbfc>  // b.hs, b.nlast
  6f7dcc:	aa0003f4 	mov	x20, x0
  6f7dd0:	f1005c1f 	cmp	x0, #0x17
  6f7dd4:	54000de2 	b.cs	6f7f90 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x380>  // b.hs, b.nlast
  6f7dd8:	531f7a88 	lsl	w8, w20, #1
  6f7ddc:	910063e9 	add	x9, sp, #0x18
  6f7de0:	b2400136 	orr	x22, x9, #0x1
  6f7de4:	390063e8 	strb	w8, [sp, #24]
  6f7de8:	b5000ed4 	cbnz	x20, 6f7fc0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x3b0>
  6f7dec:	14000079 	b	6f7fd0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x3c0>
  6f7df0:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7df4:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7df8:	7200013f 	tst	w9, #0x1
  6f7dfc:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7e00:	aa1503e0 	mov	x0, x21
  6f7e04:	940857af 	bl	90dcc0 <strlen@plt>
  6f7e08:	b100201f 	cmn	x0, #0x8
  6f7e0c:	54005242 	b.cs	6f8854 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc44>  // b.hs, b.nlast
  6f7e10:	aa0003f4 	mov	x20, x0
  6f7e14:	f1005c1f 	cmp	x0, #0x17
  6f7e18:	540018e2 	b.cs	6f8134 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x524>  // b.hs, b.nlast
  6f7e1c:	531f7a88 	lsl	w8, w20, #1
  6f7e20:	d10263a9 	sub	x9, x29, #0x98
  6f7e24:	b2400136 	orr	x22, x9, #0x1
  6f7e28:	381683a8 	sturb	w8, [x29, #-152]
  6f7e2c:	b50019d4 	cbnz	x20, 6f8164 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x554>
  6f7e30:	140000d1 	b	6f8174 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x564>
  6f7e34:	385e03a9 	ldurb	w9, [x29, #-32]
  6f7e38:	f85f03aa 	ldur	x10, [x29, #-16]
  6f7e3c:	7200013f 	tst	w9, #0x1
  6f7e40:	9a8a0115 	csel	x21, x8, x10, eq	// eq = none
  6f7e44:	aa1503e0 	mov	x0, x21
  6f7e48:	9408579e 	bl	90dcc0 <strlen@plt>
  6f7e4c:	b100201f 	cmn	x0, #0x8
  6f7e50:	540050e2 	b.cs	6f886c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc5c>  // b.hs, b.nlast
  6f7e54:	aa0003f4 	mov	x20, x0
  6f7e58:	f1005c1f 	cmp	x0, #0x17
  6f7e5c:	54001b22 	b.cs	6f81c0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x5b0>  // b.hs, b.nlast
  6f7e60:	531f7a88 	lsl	w8, w20, #1
  6f7e64:	9101e3e9 	add	x9, sp, #0x78
  6f7e68:	b2400136 	orr	x22, x9, #0x1
  6f7e6c:	3901e3e8 	strb	w8, [sp, #120]
  6f7e70:	b5001c14 	cbnz	x20, 6f81f0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x5e0>
  6f7e74:	140000e3 	b	6f8200 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x5f0>
  6f7e78:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f7e7c:	b2400a89 	orr	x9, x20, #0x7
  6f7e80:	91002108 	add	x8, x8, #0x8
  6f7e84:	f1005d3f 	cmp	x9, #0x17
  6f7e88:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f7e8c:	91000517 	add	x23, x8, #0x1
  6f7e90:	aa1703e0 	mov	x0, x23
  6f7e94:	9408577f 	bl	90dc90 <_Znwm@plt>
  6f7e98:	b24002e8 	orr	x8, x23, #0x1
  6f7e9c:	aa0003f6 	mov	x22, x0
  6f7ea0:	a93a03b4 	stp	x20, x0, [x29, #-96]
  6f7ea4:	f81983a8 	stur	x8, [x29, #-104]
  6f7ea8:	aa1603e0 	mov	x0, x22
  6f7eac:	aa1503e1 	mov	x1, x21
  6f7eb0:	aa1403e2 	mov	x2, x20
  6f7eb4:	94085787 	bl	90dcd0 <memmove@plt>
  6f7eb8:	385c83a8 	ldurb	w8, [x29, #-56]
  6f7ebc:	f85d83a9 	ldur	x9, [x29, #-40]
  6f7ec0:	38346adf 	strb	wzr, [x22, x20]
  6f7ec4:	7200011f 	tst	w8, #0x1
  6f7ec8:	d100e3a8 	sub	x8, x29, #0x38
  6f7ecc:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f7ed0:	aa1503e0 	mov	x0, x21
  6f7ed4:	9408577b 	bl	90dcc0 <strlen@plt>
  6f7ed8:	b100201f 	cmn	x0, #0x8
  6f7edc:	54004d42 	b.cs	6f8884 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc74>  // b.hs, b.nlast
  6f7ee0:	aa0003f4 	mov	x20, x0
  6f7ee4:	f1005c1f 	cmp	x0, #0x17
  6f7ee8:	54001b22 	b.cs	6f824c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x63c>  // b.hs, b.nlast
  6f7eec:	531f7a88 	lsl	w8, w20, #1
  6f7ef0:	d10203a9 	sub	x9, x29, #0x80
  6f7ef4:	b2400136 	orr	x22, x9, #0x1
  6f7ef8:	381803a8 	sturb	w8, [x29, #-128]
  6f7efc:	b5001c14 	cbnz	x20, 6f827c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x66c>
  6f7f00:	140000e3 	b	6f828c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x67c>
  6f7f04:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f7f08:	b2400a89 	orr	x9, x20, #0x7
  6f7f0c:	91002108 	add	x8, x8, #0x8
  6f7f10:	f1005d3f 	cmp	x9, #0x17
  6f7f14:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f7f18:	91000517 	add	x23, x8, #0x1
  6f7f1c:	aa1703e0 	mov	x0, x23
  6f7f20:	9408575c 	bl	90dc90 <_Znwm@plt>
  6f7f24:	b24002e8 	orr	x8, x23, #0x1
  6f7f28:	aa0003f6 	mov	x22, x0
  6f7f2c:	a90b03f4 	stp	x20, x0, [sp, #176]
  6f7f30:	f90057e8 	str	x8, [sp, #168]
  6f7f34:	aa1603e0 	mov	x0, x22
  6f7f38:	aa1503e1 	mov	x1, x21
  6f7f3c:	aa1403e2 	mov	x2, x20
  6f7f40:	94085764 	bl	90dcd0 <memmove@plt>
  6f7f44:	385c83a8 	ldurb	w8, [x29, #-56]
  6f7f48:	f85d83a9 	ldur	x9, [x29, #-40]
  6f7f4c:	38346adf 	strb	wzr, [x22, x20]
  6f7f50:	7200011f 	tst	w8, #0x1
  6f7f54:	d100e3a8 	sub	x8, x29, #0x38
  6f7f58:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f7f5c:	aa1503e0 	mov	x0, x21
  6f7f60:	94085758 	bl	90dcc0 <strlen@plt>
  6f7f64:	b100201f 	cmn	x0, #0x8
  6f7f68:	540049a2 	b.cs	6f889c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xc8c>  // b.hs, b.nlast
  6f7f6c:	aa0003f4 	mov	x20, x0
  6f7f70:	f1005c1f 	cmp	x0, #0x17
  6f7f74:	54001b82 	b.cs	6f82e4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x6d4>  // b.hs, b.nlast
  6f7f78:	531f7a88 	lsl	w8, w20, #1
  6f7f7c:	910243e9 	add	x9, sp, #0x90
  6f7f80:	b2400136 	orr	x22, x9, #0x1
  6f7f84:	390243e8 	strb	w8, [sp, #144]
  6f7f88:	b5001c74 	cbnz	x20, 6f8314 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x704>
  6f7f8c:	140000e6 	b	6f8324 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x714>
  6f7f90:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f7f94:	b2400a89 	orr	x9, x20, #0x7
  6f7f98:	91002108 	add	x8, x8, #0x8
  6f7f9c:	f1005d3f 	cmp	x9, #0x17
  6f7fa0:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f7fa4:	91000517 	add	x23, x8, #0x1
  6f7fa8:	aa1703e0 	mov	x0, x23
  6f7fac:	94085739 	bl	90dc90 <_Znwm@plt>
  6f7fb0:	b24002e8 	orr	x8, x23, #0x1
  6f7fb4:	aa0003f6 	mov	x22, x0
  6f7fb8:	a90203f4 	stp	x20, x0, [sp, #32]
  6f7fbc:	f9000fe8 	str	x8, [sp, #24]
  6f7fc0:	aa1603e0 	mov	x0, x22
  6f7fc4:	aa1503e1 	mov	x1, x21
  6f7fc8:	aa1403e2 	mov	x2, x20
  6f7fcc:	94085741 	bl	90dcd0 <memmove@plt>
  6f7fd0:	385c83a8 	ldurb	w8, [x29, #-56]
  6f7fd4:	f85d83a9 	ldur	x9, [x29, #-40]
  6f7fd8:	38346adf 	strb	wzr, [x22, x20]
  6f7fdc:	7200011f 	tst	w8, #0x1
  6f7fe0:	d100e3a8 	sub	x8, x29, #0x38
  6f7fe4:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f7fe8:	aa1503e0 	mov	x0, x21
  6f7fec:	94085735 	bl	90dcc0 <strlen@plt>
  6f7ff0:	b100201f 	cmn	x0, #0x8
  6f7ff4:	54004602 	b.cs	6f88b4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xca4>  // b.hs, b.nlast
  6f7ff8:	aa0003f4 	mov	x20, x0
  6f7ffc:	f1005c1f 	cmp	x0, #0x17
  6f8000:	54001be2 	b.cs	6f837c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x76c>  // b.hs, b.nlast
  6f8004:	531f7a88 	lsl	w8, w20, #1
  6f8008:	910003e9 	mov	x9, sp
  6f800c:	b2400136 	orr	x22, x9, #0x1
  6f8010:	390003e8 	strb	w8, [sp]
  6f8014:	b5001cd4 	cbnz	x20, 6f83ac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x79c>
  6f8018:	140000e9 	b	6f83bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x7ac>
  6f801c:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8020:	b2400a89 	orr	x9, x20, #0x7
  6f8024:	91002108 	add	x8, x8, #0x8
  6f8028:	f1005d3f 	cmp	x9, #0x17
  6f802c:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8030:	91000517 	add	x23, x8, #0x1
  6f8034:	aa1703e0 	mov	x0, x23
  6f8038:	94085716 	bl	90dc90 <_Znwm@plt>
  6f803c:	b24002e8 	orr	x8, x23, #0x1
  6f8040:	aa0003f6 	mov	x22, x0
  6f8044:	a93403b4 	stp	x20, x0, [x29, #-192]
  6f8048:	f81383a8 	stur	x8, [x29, #-200]
  6f804c:	aa1603e0 	mov	x0, x22
  6f8050:	aa1503e1 	mov	x1, x21
  6f8054:	aa1403e2 	mov	x2, x20
  6f8058:	9408571e 	bl	90dcd0 <memmove@plt>
  6f805c:	385c83a8 	ldurb	w8, [x29, #-56]
  6f8060:	f85d83a9 	ldur	x9, [x29, #-40]
  6f8064:	38346adf 	strb	wzr, [x22, x20]
  6f8068:	7200011f 	tst	w8, #0x1
  6f806c:	d100e3a8 	sub	x8, x29, #0x38
  6f8070:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f8074:	aa1503e0 	mov	x0, x21
  6f8078:	94085712 	bl	90dcc0 <strlen@plt>
  6f807c:	b100201f 	cmn	x0, #0x8
  6f8080:	54004262 	b.cs	6f88cc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xcbc>  // b.hs, b.nlast
  6f8084:	aa0003f4 	mov	x20, x0
  6f8088:	f1005c1f 	cmp	x0, #0x17
  6f808c:	54001c42 	b.cs	6f8414 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x804>  // b.hs, b.nlast
  6f8090:	531f7a88 	lsl	w8, w20, #1
  6f8094:	910303e9 	add	x9, sp, #0xc0
  6f8098:	b2400136 	orr	x22, x9, #0x1
  6f809c:	390303e8 	strb	w8, [sp, #192]
  6f80a0:	b5001d34 	cbnz	x20, 6f8444 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x834>
  6f80a4:	140000ec 	b	6f8454 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x844>
  6f80a8:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f80ac:	b2400a89 	orr	x9, x20, #0x7
  6f80b0:	91002108 	add	x8, x8, #0x8
  6f80b4:	f1005d3f 	cmp	x9, #0x17
  6f80b8:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f80bc:	91000517 	add	x23, x8, #0x1
  6f80c0:	aa1703e0 	mov	x0, x23
  6f80c4:	940856f3 	bl	90dc90 <_Znwm@plt>
  6f80c8:	b24002e8 	orr	x8, x23, #0x1
  6f80cc:	aa0003f6 	mov	x22, x0
  6f80d0:	a90503f4 	stp	x20, x0, [sp, #80]
  6f80d4:	f90027e8 	str	x8, [sp, #72]
  6f80d8:	aa1603e0 	mov	x0, x22
  6f80dc:	aa1503e1 	mov	x1, x21
  6f80e0:	aa1403e2 	mov	x2, x20
  6f80e4:	940856fb 	bl	90dcd0 <memmove@plt>
  6f80e8:	385c83a8 	ldurb	w8, [x29, #-56]
  6f80ec:	f85d83a9 	ldur	x9, [x29, #-40]
  6f80f0:	38346adf 	strb	wzr, [x22, x20]
  6f80f4:	7200011f 	tst	w8, #0x1
  6f80f8:	d100e3a8 	sub	x8, x29, #0x38
  6f80fc:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f8100:	aa1503e0 	mov	x0, x21
  6f8104:	940856ef 	bl	90dcc0 <strlen@plt>
  6f8108:	b100201f 	cmn	x0, #0x8
  6f810c:	54003ec2 	b.cs	6f88e4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xcd4>  // b.hs, b.nlast
  6f8110:	aa0003f4 	mov	x20, x0
  6f8114:	f1005c1f 	cmp	x0, #0x17
  6f8118:	54001ca2 	b.cs	6f84ac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x89c>  // b.hs, b.nlast
  6f811c:	531f7a88 	lsl	w8, w20, #1
  6f8120:	9100c3e9 	add	x9, sp, #0x30
  6f8124:	b2400136 	orr	x22, x9, #0x1
  6f8128:	3900c3e8 	strb	w8, [sp, #48]
  6f812c:	b5001d94 	cbnz	x20, 6f84dc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x8cc>
  6f8130:	140000ef 	b	6f84ec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x8dc>
  6f8134:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8138:	b2400a89 	orr	x9, x20, #0x7
  6f813c:	91002108 	add	x8, x8, #0x8
  6f8140:	f1005d3f 	cmp	x9, #0x17
  6f8144:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8148:	91000517 	add	x23, x8, #0x1
  6f814c:	aa1703e0 	mov	x0, x23
  6f8150:	940856d0 	bl	90dc90 <_Znwm@plt>
  6f8154:	b24002e8 	orr	x8, x23, #0x1
  6f8158:	aa0003f6 	mov	x22, x0
  6f815c:	a93703b4 	stp	x20, x0, [x29, #-144]
  6f8160:	f81683a8 	stur	x8, [x29, #-152]
  6f8164:	aa1603e0 	mov	x0, x22
  6f8168:	aa1503e1 	mov	x1, x21
  6f816c:	aa1403e2 	mov	x2, x20
  6f8170:	940856d8 	bl	90dcd0 <memmove@plt>
  6f8174:	385c83a8 	ldurb	w8, [x29, #-56]
  6f8178:	f85d83a9 	ldur	x9, [x29, #-40]
  6f817c:	38346adf 	strb	wzr, [x22, x20]
  6f8180:	7200011f 	tst	w8, #0x1
  6f8184:	d100e3a8 	sub	x8, x29, #0x38
  6f8188:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f818c:	aa1503e0 	mov	x0, x21
  6f8190:	940856cc 	bl	90dcc0 <strlen@plt>
  6f8194:	b100201f 	cmn	x0, #0x8
  6f8198:	54003b22 	b.cs	6f88fc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xcec>  // b.hs, b.nlast
  6f819c:	aa0003f4 	mov	x20, x0
  6f81a0:	f1005c1f 	cmp	x0, #0x17
  6f81a4:	54001d02 	b.cs	6f8544 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x934>  // b.hs, b.nlast
  6f81a8:	531f7a88 	lsl	w8, w20, #1
  6f81ac:	d102c3a9 	sub	x9, x29, #0xb0
  6f81b0:	b2400136 	orr	x22, x9, #0x1
  6f81b4:	381503a8 	sturb	w8, [x29, #-176]
  6f81b8:	b5001df4 	cbnz	x20, 6f8574 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x964>
  6f81bc:	140000f2 	b	6f8584 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x974>
  6f81c0:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f81c4:	b2400a89 	orr	x9, x20, #0x7
  6f81c8:	91002108 	add	x8, x8, #0x8
  6f81cc:	f1005d3f 	cmp	x9, #0x17
  6f81d0:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f81d4:	91000517 	add	x23, x8, #0x1
  6f81d8:	aa1703e0 	mov	x0, x23
  6f81dc:	940856ad 	bl	90dc90 <_Znwm@plt>
  6f81e0:	b24002e8 	orr	x8, x23, #0x1
  6f81e4:	aa0003f6 	mov	x22, x0
  6f81e8:	a90803f4 	stp	x20, x0, [sp, #128]
  6f81ec:	f9003fe8 	str	x8, [sp, #120]
  6f81f0:	aa1603e0 	mov	x0, x22
  6f81f4:	aa1503e1 	mov	x1, x21
  6f81f8:	aa1403e2 	mov	x2, x20
  6f81fc:	940856b5 	bl	90dcd0 <memmove@plt>
  6f8200:	385c83a8 	ldurb	w8, [x29, #-56]
  6f8204:	f85d83a9 	ldur	x9, [x29, #-40]
  6f8208:	38346adf 	strb	wzr, [x22, x20]
  6f820c:	7200011f 	tst	w8, #0x1
  6f8210:	d100e3a8 	sub	x8, x29, #0x38
  6f8214:	9a881535 	csinc	x21, x9, x8, ne	// ne = any
  6f8218:	aa1503e0 	mov	x0, x21
  6f821c:	940856a9 	bl	90dcc0 <strlen@plt>
  6f8220:	b100201f 	cmn	x0, #0x8
  6f8224:	54003782 	b.cs	6f8914 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd04>  // b.hs, b.nlast
  6f8228:	aa0003f4 	mov	x20, x0
  6f822c:	f1005c1f 	cmp	x0, #0x17
  6f8230:	54001d62 	b.cs	6f85dc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x9cc>  // b.hs, b.nlast
  6f8234:	531f7a88 	lsl	w8, w20, #1
  6f8238:	910183e9 	add	x9, sp, #0x60
  6f823c:	b2400136 	orr	x22, x9, #0x1
  6f8240:	390183e8 	strb	w8, [sp, #96]
  6f8244:	b5001e54 	cbnz	x20, 6f860c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x9fc>
  6f8248:	140000f5 	b	6f861c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa0c>
  6f824c:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8250:	b2400a89 	orr	x9, x20, #0x7
  6f8254:	91002108 	add	x8, x8, #0x8
  6f8258:	f1005d3f 	cmp	x9, #0x17
  6f825c:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8260:	91000517 	add	x23, x8, #0x1
  6f8264:	aa1703e0 	mov	x0, x23
  6f8268:	9408568a 	bl	90dc90 <_Znwm@plt>
  6f826c:	b24002e8 	orr	x8, x23, #0x1
  6f8270:	aa0003f6 	mov	x22, x0
  6f8274:	a93883b4 	stp	x20, x0, [x29, #-120]
  6f8278:	f81803a8 	stur	x8, [x29, #-128]
  6f827c:	aa1603e0 	mov	x0, x22
  6f8280:	aa1503e1 	mov	x1, x21
  6f8284:	aa1403e2 	mov	x2, x20
  6f8288:	94085692 	bl	90dcd0 <memmove@plt>
  6f828c:	38346adf 	strb	wzr, [x22, x20]
  6f8290:	d10143a8 	sub	x8, x29, #0x50
  6f8294:	d101a3a0 	sub	x0, x29, #0x68
  6f8298:	d10203a1 	sub	x1, x29, #0x80
  6f829c:	d10143b4 	sub	x20, x29, #0x50
  6f82a0:	9400904a 	bl	71c3c8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x21d88>
  6f82a4:	385b03a8 	ldurb	w8, [x29, #-80]
  6f82a8:	f9400269 	ldr	x9, [x19]
  6f82ac:	f85c03aa 	ldur	x10, [x29, #-64]
  6f82b0:	7200011f 	tst	w8, #0x1
  6f82b4:	f9429d28 	ldr	x8, [x9, #1336]
  6f82b8:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f82bc:	aa1303e0 	mov	x0, x19
  6f82c0:	d63f0100 	blr	x8
  6f82c4:	385b03a8 	ldurb	w8, [x29, #-80]
  6f82c8:	aa0003f3 	mov	x19, x0
  6f82cc:	37001d48 	tbnz	w8, #0, 6f8674 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa64>
  6f82d0:	385803a8 	ldurb	w8, [x29, #-128]
  6f82d4:	37001d88 	tbnz	w8, #0, 6f8684 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa74>
  6f82d8:	385983a8 	ldurb	w8, [x29, #-104]
  6f82dc:	37001dc8 	tbnz	w8, #0, 6f8694 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa84>
  6f82e0:	1400012b 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f82e4:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f82e8:	b2400a89 	orr	x9, x20, #0x7
  6f82ec:	91002108 	add	x8, x8, #0x8
  6f82f0:	f1005d3f 	cmp	x9, #0x17
  6f82f4:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f82f8:	91000517 	add	x23, x8, #0x1
  6f82fc:	aa1703e0 	mov	x0, x23
  6f8300:	94085664 	bl	90dc90 <_Znwm@plt>
  6f8304:	b24002e8 	orr	x8, x23, #0x1
  6f8308:	aa0003f6 	mov	x22, x0
  6f830c:	a90983f4 	stp	x20, x0, [sp, #152]
  6f8310:	f9004be8 	str	x8, [sp, #144]
  6f8314:	aa1603e0 	mov	x0, x22
  6f8318:	aa1503e1 	mov	x1, x21
  6f831c:	aa1403e2 	mov	x2, x20
  6f8320:	9408566c 	bl	90dcd0 <memmove@plt>
  6f8324:	38346adf 	strb	wzr, [x22, x20]
  6f8328:	d10143a8 	sub	x8, x29, #0x50
  6f832c:	9102a3e0 	add	x0, sp, #0xa8
  6f8330:	910243e1 	add	x1, sp, #0x90
  6f8334:	d10143b4 	sub	x20, x29, #0x50
  6f8338:	94009070 	bl	71c4f8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x21eb8>
  6f833c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8340:	f9400269 	ldr	x9, [x19]
  6f8344:	f85c03aa 	ldur	x10, [x29, #-64]
  6f8348:	7200011f 	tst	w8, #0x1
  6f834c:	f9429d28 	ldr	x8, [x9, #1336]
  6f8350:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f8354:	aa1303e0 	mov	x0, x19
  6f8358:	d63f0100 	blr	x8
  6f835c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8360:	aa0003f3 	mov	x19, x0
  6f8364:	370019c8 	tbnz	w8, #0, 6f869c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa8c>
  6f8368:	394243e8 	ldrb	w8, [sp, #144]
  6f836c:	37001a08 	tbnz	w8, #0, 6f86ac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa9c>
  6f8370:	3942a3e8 	ldrb	w8, [sp, #168]
  6f8374:	37001a48 	tbnz	w8, #0, 6f86bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xaac>
  6f8378:	14000105 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f837c:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8380:	b2400a89 	orr	x9, x20, #0x7
  6f8384:	91002108 	add	x8, x8, #0x8
  6f8388:	f1005d3f 	cmp	x9, #0x17
  6f838c:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8390:	91000517 	add	x23, x8, #0x1
  6f8394:	aa1703e0 	mov	x0, x23
  6f8398:	9408563e 	bl	90dc90 <_Znwm@plt>
  6f839c:	b24002e8 	orr	x8, x23, #0x1
  6f83a0:	aa0003f6 	mov	x22, x0
  6f83a4:	a90083f4 	stp	x20, x0, [sp, #8]
  6f83a8:	f90003e8 	str	x8, [sp]
  6f83ac:	aa1603e0 	mov	x0, x22
  6f83b0:	aa1503e1 	mov	x1, x21
  6f83b4:	aa1403e2 	mov	x2, x20
  6f83b8:	94085646 	bl	90dcd0 <memmove@plt>
  6f83bc:	38346adf 	strb	wzr, [x22, x20]
  6f83c0:	d10143a8 	sub	x8, x29, #0x50
  6f83c4:	910063e0 	add	x0, sp, #0x18
  6f83c8:	910003e1 	mov	x1, sp
  6f83cc:	d10143b4 	sub	x20, x29, #0x50
  6f83d0:	94008ffe 	bl	71c3c8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x21d88>
  6f83d4:	385b03a8 	ldurb	w8, [x29, #-80]
  6f83d8:	f9400269 	ldr	x9, [x19]
  6f83dc:	f85c03aa 	ldur	x10, [x29, #-64]
  6f83e0:	7200011f 	tst	w8, #0x1
  6f83e4:	f9429d28 	ldr	x8, [x9, #1336]
  6f83e8:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f83ec:	aa1303e0 	mov	x0, x19
  6f83f0:	d63f0100 	blr	x8
  6f83f4:	385b03a8 	ldurb	w8, [x29, #-80]
  6f83f8:	aa0003f3 	mov	x19, x0
  6f83fc:	37001648 	tbnz	w8, #0, 6f86c4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xab4>
  6f8400:	394003e8 	ldrb	w8, [sp]
  6f8404:	37001688 	tbnz	w8, #0, 6f86d4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xac4>
  6f8408:	394063e8 	ldrb	w8, [sp, #24]
  6f840c:	370016c8 	tbnz	w8, #0, 6f86e4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xad4>
  6f8410:	140000df 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8414:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8418:	b2400a89 	orr	x9, x20, #0x7
  6f841c:	91002108 	add	x8, x8, #0x8
  6f8420:	f1005d3f 	cmp	x9, #0x17
  6f8424:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8428:	91000517 	add	x23, x8, #0x1
  6f842c:	aa1703e0 	mov	x0, x23
  6f8430:	94085618 	bl	90dc90 <_Znwm@plt>
  6f8434:	b24002e8 	orr	x8, x23, #0x1
  6f8438:	aa0003f6 	mov	x22, x0
  6f843c:	a90c83f4 	stp	x20, x0, [sp, #200]
  6f8440:	f90063e8 	str	x8, [sp, #192]
  6f8444:	aa1603e0 	mov	x0, x22
  6f8448:	aa1503e1 	mov	x1, x21
  6f844c:	aa1403e2 	mov	x2, x20
  6f8450:	94085620 	bl	90dcd0 <memmove@plt>
  6f8454:	38346adf 	strb	wzr, [x22, x20]
  6f8458:	d10143a8 	sub	x8, x29, #0x50
  6f845c:	d10323a0 	sub	x0, x29, #0xc8
  6f8460:	910303e1 	add	x1, sp, #0xc0
  6f8464:	d10143b4 	sub	x20, x29, #0x50
  6f8468:	94009070 	bl	71c628 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x21fe8>
  6f846c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8470:	f9400269 	ldr	x9, [x19]
  6f8474:	f85c03aa 	ldur	x10, [x29, #-64]
  6f8478:	7200011f 	tst	w8, #0x1
  6f847c:	f9429d28 	ldr	x8, [x9, #1336]
  6f8480:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f8484:	aa1303e0 	mov	x0, x19
  6f8488:	d63f0100 	blr	x8
  6f848c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8490:	aa0003f3 	mov	x19, x0
  6f8494:	370012c8 	tbnz	w8, #0, 6f86ec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xadc>
  6f8498:	394303e8 	ldrb	w8, [sp, #192]
  6f849c:	37001308 	tbnz	w8, #0, 6f86fc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xaec>
  6f84a0:	385383a8 	ldurb	w8, [x29, #-200]
  6f84a4:	37001348 	tbnz	w8, #0, 6f870c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xafc>
  6f84a8:	140000b9 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f84ac:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f84b0:	b2400a89 	orr	x9, x20, #0x7
  6f84b4:	91002108 	add	x8, x8, #0x8
  6f84b8:	f1005d3f 	cmp	x9, #0x17
  6f84bc:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f84c0:	91000517 	add	x23, x8, #0x1
  6f84c4:	aa1703e0 	mov	x0, x23
  6f84c8:	940855f2 	bl	90dc90 <_Znwm@plt>
  6f84cc:	b24002e8 	orr	x8, x23, #0x1
  6f84d0:	aa0003f6 	mov	x22, x0
  6f84d4:	a90383f4 	stp	x20, x0, [sp, #56]
  6f84d8:	f9001be8 	str	x8, [sp, #48]
  6f84dc:	aa1603e0 	mov	x0, x22
  6f84e0:	aa1503e1 	mov	x1, x21
  6f84e4:	aa1403e2 	mov	x2, x20
  6f84e8:	940855fa 	bl	90dcd0 <memmove@plt>
  6f84ec:	38346adf 	strb	wzr, [x22, x20]
  6f84f0:	d10143a8 	sub	x8, x29, #0x50
  6f84f4:	910123e0 	add	x0, sp, #0x48
  6f84f8:	9100c3e1 	add	x1, sp, #0x30
  6f84fc:	d10143b4 	sub	x20, x29, #0x50
  6f8500:	940090e2 	bl	71c888 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x22248>
  6f8504:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8508:	f9400269 	ldr	x9, [x19]
  6f850c:	f85c03aa 	ldur	x10, [x29, #-64]
  6f8510:	7200011f 	tst	w8, #0x1
  6f8514:	f9429d28 	ldr	x8, [x9, #1336]
  6f8518:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f851c:	aa1303e0 	mov	x0, x19
  6f8520:	d63f0100 	blr	x8
  6f8524:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8528:	aa0003f3 	mov	x19, x0
  6f852c:	37000f48 	tbnz	w8, #0, 6f8714 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb04>
  6f8530:	3940c3e8 	ldrb	w8, [sp, #48]
  6f8534:	37000f88 	tbnz	w8, #0, 6f8724 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb14>
  6f8538:	394123e8 	ldrb	w8, [sp, #72]
  6f853c:	37000fc8 	tbnz	w8, #0, 6f8734 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb24>
  6f8540:	14000093 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8544:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f8548:	b2400a89 	orr	x9, x20, #0x7
  6f854c:	91002108 	add	x8, x8, #0x8
  6f8550:	f1005d3f 	cmp	x9, #0x17
  6f8554:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f8558:	91000517 	add	x23, x8, #0x1
  6f855c:	aa1703e0 	mov	x0, x23
  6f8560:	940855cc 	bl	90dc90 <_Znwm@plt>
  6f8564:	b24002e8 	orr	x8, x23, #0x1
  6f8568:	aa0003f6 	mov	x22, x0
  6f856c:	a93583b4 	stp	x20, x0, [x29, #-168]
  6f8570:	f81503a8 	stur	x8, [x29, #-176]
  6f8574:	aa1603e0 	mov	x0, x22
  6f8578:	aa1503e1 	mov	x1, x21
  6f857c:	aa1403e2 	mov	x2, x20
  6f8580:	940855d4 	bl	90dcd0 <memmove@plt>
  6f8584:	38346adf 	strb	wzr, [x22, x20]
  6f8588:	d10143a8 	sub	x8, x29, #0x50
  6f858c:	d10263a0 	sub	x0, x29, #0x98
  6f8590:	d102c3a1 	sub	x1, x29, #0xb0
  6f8594:	d10143b4 	sub	x20, x29, #0x50
  6f8598:	94008f40 	bl	71c298 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x21c58>
  6f859c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f85a0:	f9400269 	ldr	x9, [x19]
  6f85a4:	f85c03aa 	ldur	x10, [x29, #-64]
  6f85a8:	7200011f 	tst	w8, #0x1
  6f85ac:	f9429d28 	ldr	x8, [x9, #1336]
  6f85b0:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f85b4:	aa1303e0 	mov	x0, x19
  6f85b8:	d63f0100 	blr	x8
  6f85bc:	385b03a8 	ldurb	w8, [x29, #-80]
  6f85c0:	aa0003f3 	mov	x19, x0
  6f85c4:	37000bc8 	tbnz	w8, #0, 6f873c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb2c>
  6f85c8:	385503a8 	ldurb	w8, [x29, #-176]
  6f85cc:	37000c08 	tbnz	w8, #0, 6f874c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb3c>
  6f85d0:	385683a8 	ldurb	w8, [x29, #-152]
  6f85d4:	37000c48 	tbnz	w8, #0, 6f875c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb4c>
  6f85d8:	1400006d 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f85dc:	927df288 	and	x8, x20, #0xfffffffffffffff8
  6f85e0:	b2400a89 	orr	x9, x20, #0x7
  6f85e4:	91002108 	add	x8, x8, #0x8
  6f85e8:	f1005d3f 	cmp	x9, #0x17
  6f85ec:	9a890108 	csel	x8, x8, x9, eq	// eq = none
  6f85f0:	91000517 	add	x23, x8, #0x1
  6f85f4:	aa1703e0 	mov	x0, x23
  6f85f8:	940855a6 	bl	90dc90 <_Znwm@plt>
  6f85fc:	b24002e8 	orr	x8, x23, #0x1
  6f8600:	aa0003f6 	mov	x22, x0
  6f8604:	a90683f4 	stp	x20, x0, [sp, #104]
  6f8608:	f90033e8 	str	x8, [sp, #96]
  6f860c:	aa1603e0 	mov	x0, x22
  6f8610:	aa1503e1 	mov	x1, x21
  6f8614:	aa1403e2 	mov	x2, x20
  6f8618:	940855ae 	bl	90dcd0 <memmove@plt>
  6f861c:	38346adf 	strb	wzr, [x22, x20]
  6f8620:	d10143a8 	sub	x8, x29, #0x50
  6f8624:	9101e3e0 	add	x0, sp, #0x78
  6f8628:	910183e1 	add	x1, sp, #0x60
  6f862c:	d10143b4 	sub	x20, x29, #0x50
  6f8630:	9400904a 	bl	71c758 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x22118>
  6f8634:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8638:	f9400269 	ldr	x9, [x19]
  6f863c:	f85c03aa 	ldur	x10, [x29, #-64]
  6f8640:	7200011f 	tst	w8, #0x1
  6f8644:	f9429d28 	ldr	x8, [x9, #1336]
  6f8648:	9a941541 	csinc	x1, x10, x20, ne	// ne = any
  6f864c:	aa1303e0 	mov	x0, x19
  6f8650:	d63f0100 	blr	x8
  6f8654:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8658:	aa0003f3 	mov	x19, x0
  6f865c:	37000848 	tbnz	w8, #0, 6f8764 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb54>
  6f8660:	394183e8 	ldrb	w8, [sp, #96]
  6f8664:	37000888 	tbnz	w8, #0, 6f8774 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb64>
  6f8668:	3941e3e8 	ldrb	w8, [sp, #120]
  6f866c:	370008c8 	tbnz	w8, #0, 6f8784 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb74>
  6f8670:	14000047 	b	6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8674:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8678:	9408558e 	bl	90dcb0 <_ZdlPv@plt>
  6f867c:	385803a8 	ldurb	w8, [x29, #-128]
  6f8680:	3607e2c8 	tbz	w8, #0, 6f82d8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x6c8>
  6f8684:	f85903a0 	ldur	x0, [x29, #-112]
  6f8688:	9408558a 	bl	90dcb0 <_ZdlPv@plt>
  6f868c:	385983a8 	ldurb	w8, [x29, #-104]
  6f8690:	360007e8 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8694:	f85a83a0 	ldur	x0, [x29, #-88]
  6f8698:	1400003c 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f869c:	f85c03a0 	ldur	x0, [x29, #-64]
  6f86a0:	94085584 	bl	90dcb0 <_ZdlPv@plt>
  6f86a4:	394243e8 	ldrb	w8, [sp, #144]
  6f86a8:	3607e648 	tbz	w8, #0, 6f8370 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x760>
  6f86ac:	f94053e0 	ldr	x0, [sp, #160]
  6f86b0:	94085580 	bl	90dcb0 <_ZdlPv@plt>
  6f86b4:	3942a3e8 	ldrb	w8, [sp, #168]
  6f86b8:	360006a8 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f86bc:	f9405fe0 	ldr	x0, [sp, #184]
  6f86c0:	14000032 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f86c4:	f85c03a0 	ldur	x0, [x29, #-64]
  6f86c8:	9408557a 	bl	90dcb0 <_ZdlPv@plt>
  6f86cc:	394003e8 	ldrb	w8, [sp]
  6f86d0:	3607e9c8 	tbz	w8, #0, 6f8408 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x7f8>
  6f86d4:	f9400be0 	ldr	x0, [sp, #16]
  6f86d8:	94085576 	bl	90dcb0 <_ZdlPv@plt>
  6f86dc:	394063e8 	ldrb	w8, [sp, #24]
  6f86e0:	36000568 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f86e4:	f94017e0 	ldr	x0, [sp, #40]
  6f86e8:	14000028 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f86ec:	f85c03a0 	ldur	x0, [x29, #-64]
  6f86f0:	94085570 	bl	90dcb0 <_ZdlPv@plt>
  6f86f4:	394303e8 	ldrb	w8, [sp, #192]
  6f86f8:	3607ed48 	tbz	w8, #0, 6f84a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x890>
  6f86fc:	f9406be0 	ldr	x0, [sp, #208]
  6f8700:	9408556c 	bl	90dcb0 <_ZdlPv@plt>
  6f8704:	385383a8 	ldurb	w8, [x29, #-200]
  6f8708:	36000428 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f870c:	f85483a0 	ldur	x0, [x29, #-184]
  6f8710:	1400001e 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f8714:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8718:	94085566 	bl	90dcb0 <_ZdlPv@plt>
  6f871c:	3940c3e8 	ldrb	w8, [sp, #48]
  6f8720:	3607f0c8 	tbz	w8, #0, 6f8538 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x928>
  6f8724:	f94023e0 	ldr	x0, [sp, #64]
  6f8728:	94085562 	bl	90dcb0 <_ZdlPv@plt>
  6f872c:	394123e8 	ldrb	w8, [sp, #72]
  6f8730:	360002e8 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8734:	f9402fe0 	ldr	x0, [sp, #88]
  6f8738:	14000014 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f873c:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8740:	9408555c 	bl	90dcb0 <_ZdlPv@plt>
  6f8744:	385503a8 	ldurb	w8, [x29, #-176]
  6f8748:	3607f448 	tbz	w8, #0, 6f85d0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x9c0>
  6f874c:	f85603a0 	ldur	x0, [x29, #-160]
  6f8750:	94085558 	bl	90dcb0 <_ZdlPv@plt>
  6f8754:	385683a8 	ldurb	w8, [x29, #-152]
  6f8758:	360001a8 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f875c:	f85783a0 	ldur	x0, [x29, #-136]
  6f8760:	1400000a 	b	6f8788 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb78>
  6f8764:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8768:	94085552 	bl	90dcb0 <_ZdlPv@plt>
  6f876c:	394183e8 	ldrb	w8, [sp, #96]
  6f8770:	3607f7c8 	tbz	w8, #0, 6f8668 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xa58>
  6f8774:	f9403be0 	ldr	x0, [sp, #112]
  6f8778:	9408554e 	bl	90dcb0 <_ZdlPv@plt>
  6f877c:	3941e3e8 	ldrb	w8, [sp, #120]
  6f8780:	36000068 	tbz	w8, #0, 6f878c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb7c>
  6f8784:	f94047e0 	ldr	x0, [sp, #136]
  6f8788:	9408554a 	bl	90dcb0 <_ZdlPv@plt>
  6f878c:	385c83a8 	ldurb	w8, [x29, #-56]
  6f8790:	36000068 	tbz	w8, #0, 6f879c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb8c>
  6f8794:	f85d83a0 	ldur	x0, [x29, #-40]
  6f8798:	94085546 	bl	90dcb0 <_ZdlPv@plt>
  6f879c:	385e03a8 	ldurb	w8, [x29, #-32]
  6f87a0:	36000068 	tbz	w8, #0, 6f87ac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xb9c>
  6f87a4:	f85f03a0 	ldur	x0, [x29, #-16]
  6f87a8:	94085542 	bl	90dcb0 <_ZdlPv@plt>
  6f87ac:	f9401708 	ldr	x8, [x24, #40]
  6f87b0:	f85f83a9 	ldur	x9, [x29, #-8]
  6f87b4:	eb09011f 	cmp	x8, x9
  6f87b8:	54002621 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f87bc:	aa1303e0 	mov	x0, x19
  6f87c0:	a95e4ff4 	ldp	x20, x19, [sp, #480]
  6f87c4:	f940dbfc 	ldr	x28, [sp, #432]
  6f87c8:	a95d57f6 	ldp	x22, x21, [sp, #464]
  6f87cc:	a95c5ff8 	ldp	x24, x23, [sp, #448]
  6f87d0:	a95a7bfd 	ldp	x29, x30, [sp, #416]
  6f87d4:	9107c3ff 	add	sp, sp, #0x1f0
  6f87d8:	d65f03c0 	ret
  6f87dc:	f9401708 	ldr	x8, [x24, #40]
  6f87e0:	f85f83a9 	ldur	x9, [x29, #-8]
  6f87e4:	eb09011f 	cmp	x8, x9
  6f87e8:	540024a1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f87ec:	d101a3a0 	sub	x0, x29, #0x68
  6f87f0:	940007ac 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f87f4:	f9401708 	ldr	x8, [x24, #40]
  6f87f8:	f85f83a9 	ldur	x9, [x29, #-8]
  6f87fc:	eb09011f 	cmp	x8, x9
  6f8800:	540023e1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8804:	9102a3e0 	add	x0, sp, #0xa8
  6f8808:	940007a6 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f880c:	f9401708 	ldr	x8, [x24, #40]
  6f8810:	f85f83a9 	ldur	x9, [x29, #-8]
  6f8814:	eb09011f 	cmp	x8, x9
  6f8818:	54002321 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f881c:	910063e0 	add	x0, sp, #0x18
  6f8820:	940007a0 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f8824:	f9401708 	ldr	x8, [x24, #40]
  6f8828:	f85f83a9 	ldur	x9, [x29, #-8]
  6f882c:	eb09011f 	cmp	x8, x9
  6f8830:	54002261 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8834:	d10323a0 	sub	x0, x29, #0xc8
  6f8838:	9400079a 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f883c:	f9401708 	ldr	x8, [x24, #40]
  6f8840:	f85f83a9 	ldur	x9, [x29, #-8]
  6f8844:	eb09011f 	cmp	x8, x9
  6f8848:	540021a1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f884c:	910123e0 	add	x0, sp, #0x48
  6f8850:	94000794 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f8854:	f9401708 	ldr	x8, [x24, #40]
  6f8858:	f85f83a9 	ldur	x9, [x29, #-8]
  6f885c:	eb09011f 	cmp	x8, x9
  6f8860:	540020e1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8864:	d10263a0 	sub	x0, x29, #0x98
  6f8868:	9400078e 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f886c:	f9401708 	ldr	x8, [x24, #40]
  6f8870:	f85f83a9 	ldur	x9, [x29, #-8]
  6f8874:	eb09011f 	cmp	x8, x9
  6f8878:	54002021 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f887c:	9101e3e0 	add	x0, sp, #0x78
  6f8880:	94000788 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f8884:	f9401708 	ldr	x8, [x24, #40]
  6f8888:	f85f83a9 	ldur	x9, [x29, #-8]
  6f888c:	eb09011f 	cmp	x8, x9
  6f8890:	54001f61 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8894:	d10203a0 	sub	x0, x29, #0x80
  6f8898:	94000782 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f889c:	f9401708 	ldr	x8, [x24, #40]
  6f88a0:	f85f83a9 	ldur	x9, [x29, #-8]
  6f88a4:	eb09011f 	cmp	x8, x9
  6f88a8:	54001ea1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f88ac:	910243e0 	add	x0, sp, #0x90
  6f88b0:	9400077c 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f88b4:	f9401708 	ldr	x8, [x24, #40]
  6f88b8:	f85f83a9 	ldur	x9, [x29, #-8]
  6f88bc:	eb09011f 	cmp	x8, x9
  6f88c0:	54001de1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f88c4:	910003e0 	mov	x0, sp
  6f88c8:	94000776 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f88cc:	f9401708 	ldr	x8, [x24, #40]
  6f88d0:	f85f83a9 	ldur	x9, [x29, #-8]
  6f88d4:	eb09011f 	cmp	x8, x9
  6f88d8:	54001d21 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f88dc:	910303e0 	add	x0, sp, #0xc0
  6f88e0:	94000770 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f88e4:	f9401708 	ldr	x8, [x24, #40]
  6f88e8:	f85f83a9 	ldur	x9, [x29, #-8]
  6f88ec:	eb09011f 	cmp	x8, x9
  6f88f0:	54001c61 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f88f4:	9100c3e0 	add	x0, sp, #0x30
  6f88f8:	9400076a 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f88fc:	f9401708 	ldr	x8, [x24, #40]
  6f8900:	f85f83a9 	ldur	x9, [x29, #-8]
  6f8904:	eb09011f 	cmp	x8, x9
  6f8908:	54001ba1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f890c:	d102c3a0 	sub	x0, x29, #0xb0
  6f8910:	94000764 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f8914:	f9401708 	ldr	x8, [x24, #40]
  6f8918:	f85f83a9 	ldur	x9, [x29, #-8]
  6f891c:	eb09011f 	cmp	x8, x9
  6f8920:	54001ae1 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8924:	910183e0 	add	x0, sp, #0x60
  6f8928:	9400075e 	bl	6fa6a0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x60>
  6f892c:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8930:	aa0003f3 	mov	x19, x0
  6f8934:	370000c8 	tbnz	w8, #0, 6f894c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd3c>
  6f8938:	394183e8 	ldrb	w8, [sp, #96]
  6f893c:	37000b48 	tbnz	w8, #0, 6f8aa4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe94>
  6f8940:	3941e3e8 	ldrb	w8, [sp, #120]
  6f8944:	37001208 	tbnz	w8, #0, 6f8b84 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf74>
  6f8948:	140000af 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f894c:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8950:	940854d8 	bl	90dcb0 <_ZdlPv@plt>
  6f8954:	394183e8 	ldrb	w8, [sp, #96]
  6f8958:	3607ff48 	tbz	w8, #0, 6f8940 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd30>
  6f895c:	14000052 	b	6f8aa4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe94>
  6f8960:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8964:	aa0003f3 	mov	x19, x0
  6f8968:	370000c8 	tbnz	w8, #0, 6f8980 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd70>
  6f896c:	385503a8 	ldurb	w8, [x29, #-176]
  6f8970:	37000aa8 	tbnz	w8, #0, 6f8ac4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xeb4>
  6f8974:	385683a8 	ldurb	w8, [x29, #-152]
  6f8978:	37001108 	tbnz	w8, #0, 6f8b98 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf88>
  6f897c:	140000a2 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8980:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8984:	940854cb 	bl	90dcb0 <_ZdlPv@plt>
  6f8988:	385503a8 	ldurb	w8, [x29, #-176]
  6f898c:	3607ff48 	tbz	w8, #0, 6f8974 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd64>
  6f8990:	1400004d 	b	6f8ac4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xeb4>
  6f8994:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8998:	aa0003f3 	mov	x19, x0
  6f899c:	370000c8 	tbnz	w8, #0, 6f89b4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xda4>
  6f89a0:	3940c3e8 	ldrb	w8, [sp, #48]
  6f89a4:	37000a08 	tbnz	w8, #0, 6f8ae4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xed4>
  6f89a8:	394123e8 	ldrb	w8, [sp, #72]
  6f89ac:	37001008 	tbnz	w8, #0, 6f8bac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf9c>
  6f89b0:	14000095 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f89b4:	f85c03a0 	ldur	x0, [x29, #-64]
  6f89b8:	940854be 	bl	90dcb0 <_ZdlPv@plt>
  6f89bc:	3940c3e8 	ldrb	w8, [sp, #48]
  6f89c0:	3607ff48 	tbz	w8, #0, 6f89a8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd98>
  6f89c4:	14000048 	b	6f8ae4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xed4>
  6f89c8:	385b03a8 	ldurb	w8, [x29, #-80]
  6f89cc:	aa0003f3 	mov	x19, x0
  6f89d0:	370000c8 	tbnz	w8, #0, 6f89e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xdd8>
  6f89d4:	394303e8 	ldrb	w8, [sp, #192]
  6f89d8:	37000968 	tbnz	w8, #0, 6f8b04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xef4>
  6f89dc:	385383a8 	ldurb	w8, [x29, #-200]
  6f89e0:	37000f08 	tbnz	w8, #0, 6f8bc0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfb0>
  6f89e4:	14000088 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f89e8:	f85c03a0 	ldur	x0, [x29, #-64]
  6f89ec:	940854b1 	bl	90dcb0 <_ZdlPv@plt>
  6f89f0:	394303e8 	ldrb	w8, [sp, #192]
  6f89f4:	3607ff48 	tbz	w8, #0, 6f89dc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xdcc>
  6f89f8:	14000043 	b	6f8b04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xef4>
  6f89fc:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8a00:	aa0003f3 	mov	x19, x0
  6f8a04:	370000c8 	tbnz	w8, #0, 6f8a1c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe0c>
  6f8a08:	394003e8 	ldrb	w8, [sp]
  6f8a0c:	370008c8 	tbnz	w8, #0, 6f8b24 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf14>
  6f8a10:	394063e8 	ldrb	w8, [sp, #24]
  6f8a14:	37000e08 	tbnz	w8, #0, 6f8bd4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfc4>
  6f8a18:	1400007b 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8a1c:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8a20:	940854a4 	bl	90dcb0 <_ZdlPv@plt>
  6f8a24:	394003e8 	ldrb	w8, [sp]
  6f8a28:	3607ff48 	tbz	w8, #0, 6f8a10 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe00>
  6f8a2c:	1400003e 	b	6f8b24 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf14>
  6f8a30:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8a34:	aa0003f3 	mov	x19, x0
  6f8a38:	370000c8 	tbnz	w8, #0, 6f8a50 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe40>
  6f8a3c:	394243e8 	ldrb	w8, [sp, #144]
  6f8a40:	37000828 	tbnz	w8, #0, 6f8b44 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf34>
  6f8a44:	3942a3e8 	ldrb	w8, [sp, #168]
  6f8a48:	37000d08 	tbnz	w8, #0, 6f8be8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfd8>
  6f8a4c:	1400006e 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8a50:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8a54:	94085497 	bl	90dcb0 <_ZdlPv@plt>
  6f8a58:	394243e8 	ldrb	w8, [sp, #144]
  6f8a5c:	3607ff48 	tbz	w8, #0, 6f8a44 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe34>
  6f8a60:	14000039 	b	6f8b44 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf34>
  6f8a64:	385b03a8 	ldurb	w8, [x29, #-80]
  6f8a68:	aa0003f3 	mov	x19, x0
  6f8a6c:	370000c8 	tbnz	w8, #0, 6f8a84 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe74>
  6f8a70:	385803a8 	ldurb	w8, [x29, #-128]
  6f8a74:	37000788 	tbnz	w8, #0, 6f8b64 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf54>
  6f8a78:	385983a8 	ldurb	w8, [x29, #-104]
  6f8a7c:	37000c08 	tbnz	w8, #0, 6f8bfc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfec>
  6f8a80:	14000061 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8a84:	f85c03a0 	ldur	x0, [x29, #-64]
  6f8a88:	9408548a 	bl	90dcb0 <_ZdlPv@plt>
  6f8a8c:	385803a8 	ldurb	w8, [x29, #-128]
  6f8a90:	3607ff48 	tbz	w8, #0, 6f8a78 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe68>
  6f8a94:	14000034 	b	6f8b64 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf54>
  6f8a98:	aa0003f3 	mov	x19, x0
  6f8a9c:	394183e8 	ldrb	w8, [sp, #96]
  6f8aa0:	3607f508 	tbz	w8, #0, 6f8940 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd30>
  6f8aa4:	f9403be0 	ldr	x0, [sp, #112]
  6f8aa8:	94085482 	bl	90dcb0 <_ZdlPv@plt>
  6f8aac:	3941e3e8 	ldrb	w8, [sp, #120]
  6f8ab0:	370006a8 	tbnz	w8, #0, 6f8b84 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf74>
  6f8ab4:	14000054 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8ab8:	aa0003f3 	mov	x19, x0
  6f8abc:	385503a8 	ldurb	w8, [x29, #-176]
  6f8ac0:	3607f5a8 	tbz	w8, #0, 6f8974 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd64>
  6f8ac4:	f85603a0 	ldur	x0, [x29, #-160]
  6f8ac8:	9408547a 	bl	90dcb0 <_ZdlPv@plt>
  6f8acc:	385683a8 	ldurb	w8, [x29, #-152]
  6f8ad0:	37000648 	tbnz	w8, #0, 6f8b98 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf88>
  6f8ad4:	1400004c 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8ad8:	aa0003f3 	mov	x19, x0
  6f8adc:	3940c3e8 	ldrb	w8, [sp, #48]
  6f8ae0:	3607f648 	tbz	w8, #0, 6f89a8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xd98>
  6f8ae4:	f94023e0 	ldr	x0, [sp, #64]
  6f8ae8:	94085472 	bl	90dcb0 <_ZdlPv@plt>
  6f8aec:	394123e8 	ldrb	w8, [sp, #72]
  6f8af0:	370005e8 	tbnz	w8, #0, 6f8bac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xf9c>
  6f8af4:	14000044 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8af8:	aa0003f3 	mov	x19, x0
  6f8afc:	394303e8 	ldrb	w8, [sp, #192]
  6f8b00:	3607f6e8 	tbz	w8, #0, 6f89dc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xdcc>
  6f8b04:	f9406be0 	ldr	x0, [sp, #208]
  6f8b08:	9408546a 	bl	90dcb0 <_ZdlPv@plt>
  6f8b0c:	385383a8 	ldurb	w8, [x29, #-200]
  6f8b10:	37000588 	tbnz	w8, #0, 6f8bc0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfb0>
  6f8b14:	1400003c 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b18:	aa0003f3 	mov	x19, x0
  6f8b1c:	394003e8 	ldrb	w8, [sp]
  6f8b20:	3607f788 	tbz	w8, #0, 6f8a10 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe00>
  6f8b24:	f9400be0 	ldr	x0, [sp, #16]
  6f8b28:	94085462 	bl	90dcb0 <_ZdlPv@plt>
  6f8b2c:	394063e8 	ldrb	w8, [sp, #24]
  6f8b30:	37000528 	tbnz	w8, #0, 6f8bd4 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfc4>
  6f8b34:	14000034 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b38:	aa0003f3 	mov	x19, x0
  6f8b3c:	394243e8 	ldrb	w8, [sp, #144]
  6f8b40:	3607f828 	tbz	w8, #0, 6f8a44 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe34>
  6f8b44:	f94053e0 	ldr	x0, [sp, #160]
  6f8b48:	9408545a 	bl	90dcb0 <_ZdlPv@plt>
  6f8b4c:	3942a3e8 	ldrb	w8, [sp, #168]
  6f8b50:	370004c8 	tbnz	w8, #0, 6f8be8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfd8>
  6f8b54:	1400002c 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b58:	aa0003f3 	mov	x19, x0
  6f8b5c:	385803a8 	ldurb	w8, [x29, #-128]
  6f8b60:	3607f8c8 	tbz	w8, #0, 6f8a78 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xe68>
  6f8b64:	f85903a0 	ldur	x0, [x29, #-112]
  6f8b68:	94085452 	bl	90dcb0 <_ZdlPv@plt>
  6f8b6c:	385983a8 	ldurb	w8, [x29, #-104]
  6f8b70:	37000468 	tbnz	w8, #0, 6f8bfc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xfec>
  6f8b74:	14000024 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b78:	aa0003f3 	mov	x19, x0
  6f8b7c:	3941e3e8 	ldrb	w8, [sp, #120]
  6f8b80:	36000428 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b84:	f94047e0 	ldr	x0, [sp, #136]
  6f8b88:	1400001e 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8b8c:	aa0003f3 	mov	x19, x0
  6f8b90:	385683a8 	ldurb	w8, [x29, #-152]
  6f8b94:	36000388 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8b98:	f85783a0 	ldur	x0, [x29, #-136]
  6f8b9c:	14000019 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8ba0:	aa0003f3 	mov	x19, x0
  6f8ba4:	394123e8 	ldrb	w8, [sp, #72]
  6f8ba8:	360002e8 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8bac:	f9402fe0 	ldr	x0, [sp, #88]
  6f8bb0:	14000014 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8bb4:	aa0003f3 	mov	x19, x0
  6f8bb8:	385383a8 	ldurb	w8, [x29, #-200]
  6f8bbc:	36000248 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8bc0:	f85483a0 	ldur	x0, [x29, #-184]
  6f8bc4:	1400000f 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8bc8:	aa0003f3 	mov	x19, x0
  6f8bcc:	394063e8 	ldrb	w8, [sp, #24]
  6f8bd0:	360001a8 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8bd4:	f94017e0 	ldr	x0, [sp, #40]
  6f8bd8:	1400000a 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8bdc:	aa0003f3 	mov	x19, x0
  6f8be0:	3942a3e8 	ldrb	w8, [sp, #168]
  6f8be4:	36000108 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8be8:	f9405fe0 	ldr	x0, [sp, #184]
  6f8bec:	14000005 	b	6f8c00 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff0>
  6f8bf0:	aa0003f3 	mov	x19, x0
  6f8bf4:	385983a8 	ldurb	w8, [x29, #-104]
  6f8bf8:	36000068 	tbz	w8, #0, 6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8bfc:	f85a83a0 	ldur	x0, [x29, #-88]
  6f8c00:	9408542c 	bl	90dcb0 <_ZdlPv@plt>
  6f8c04:	385c83a8 	ldurb	w8, [x29, #-56]
  6f8c08:	36000268 	tbz	w8, #0, 6f8c54 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x1044>
  6f8c0c:	f85d83a0 	ldur	x0, [x29, #-40]
  6f8c10:	94085428 	bl	90dcb0 <_ZdlPv@plt>
  6f8c14:	14000010 	b	6f8c54 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x1044>
  6f8c18:	aa0003f3 	mov	x19, x0
  6f8c1c:	17fffffa 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c20:	aa0003f3 	mov	x19, x0
  6f8c24:	17fffff8 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c28:	aa0003f3 	mov	x19, x0
  6f8c2c:	17fffff6 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c30:	aa0003f3 	mov	x19, x0
  6f8c34:	17fffff4 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c38:	aa0003f3 	mov	x19, x0
  6f8c3c:	17fffff2 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c40:	aa0003f3 	mov	x19, x0
  6f8c44:	17fffff0 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c48:	aa0003f3 	mov	x19, x0
  6f8c4c:	17ffffee 	b	6f8c04 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0xff4>
  6f8c50:	aa0003f3 	mov	x19, x0
  6f8c54:	385e03a8 	ldurb	w8, [x29, #-32]
  6f8c58:	36000068 	tbz	w8, #0, 6f8c64 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x1054>
  6f8c5c:	f85f03a0 	ldur	x0, [x29, #-16]
  6f8c60:	94085414 	bl	90dcb0 <_ZdlPv@plt>
  6f8c64:	f9401708 	ldr	x8, [x24, #40]
  6f8c68:	f85f83a9 	ldur	x9, [x29, #-8]
  6f8c6c:	eb09011f 	cmp	x8, x9
  6f8c70:	54000061 	b.ne	6f8c7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_e@@Base+0x106c>  // b.any
  6f8c74:	aa1303e0 	mov	x0, x19
  6f8c78:	9408444d 	bl	909dac <__emutls_get_address@@Base+0x980>
  6f8c7c:	94085419 	bl	90dce0 <__stack_chk_fail@plt>

Disassembly of section __lcxx_override:

Disassembly of section .plt:
