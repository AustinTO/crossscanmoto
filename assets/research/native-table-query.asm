
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

00000000006fba20 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13e0>:
  6fba20:	d10203ff 	sub	sp, sp, #0x80
  6fba24:	a9027bfd 	stp	x29, x30, [sp, #32]
  6fba28:	f9001bfb 	str	x27, [sp, #48]
  6fba2c:	a90467fa 	stp	x26, x25, [sp, #64]
  6fba30:	a9055ff8 	stp	x24, x23, [sp, #80]
  6fba34:	a90657f6 	stp	x22, x21, [sp, #96]
  6fba38:	a9074ff4 	stp	x20, x19, [sp, #112]
  6fba3c:	910083fd 	add	x29, sp, #0x20
  6fba40:	d53bd058 	mrs	x24, tpidr_el0
  6fba44:	aa0803f3 	mov	x19, x8
  6fba48:	aa0103f4 	mov	x20, x1
  6fba4c:	f9401708 	ldr	x8, [x24, #40]
  6fba50:	91000439 	add	x25, x1, #0x1
  6fba54:	9109201a 	add	x26, x0, #0x248
  6fba58:	d0ffd8b5 	adrp	x21, 211000 <psa_to_md_errors@@Base-0x4bcc14>
  6fba5c:	913252b5 	add	x21, x21, #0xc94
  6fba60:	928443fb 	mov	x27, #0xffffffffffffdde0    	// #-8736
  6fba64:	d0ffead6 	adrp	x22, 455000 <psa_to_md_errors@@Base-0x278c14>
  6fba68:	913e0ad6 	add	x22, x22, #0xf82
  6fba6c:	f81f83a8 	stur	x8, [x29, #-8]
  6fba70:	a9007e7f 	stp	xzr, xzr, [x19]
  6fba74:	f9000a7f 	str	xzr, [x19, #16]
  6fba78:	14000003 	b	6fba84 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1444>
  6fba7c:	b101a37b 	adds	x27, x27, #0x68
  6fba80:	540012c0 	b.eq	6fbcd8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1698>  // b.none
  6fba84:	8b1b0348 	add	x8, x26, x27
  6fba88:	f950e517 	ldr	x23, [x8, #8648]
  6fba8c:	aa1703e0 	mov	x0, x23
  6fba90:	9408488c 	bl	90dcc0 <strlen@plt>
  6fba94:	39400288 	ldrb	w8, [x20]
  6fba98:	f9400689 	ldr	x9, [x20, #8]
  6fba9c:	d341fd0a 	lsr	x10, x8, #1
  6fbaa0:	7200011f 	tst	w8, #0x1
  6fbaa4:	9a890149 	csel	x9, x10, x9, eq	// eq = none
  6fbaa8:	eb09001f 	cmp	x0, x9
  6fbaac:	54fffe81 	b.ne	6fba7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x143c>  // b.any
  6fbab0:	aa0003e2 	mov	x2, x0
  6fbab4:	b100041f 	cmn	x0, #0x1
  6fbab8:	54001280 	b.eq	6fbd08 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x16c8>  // b.none
  6fbabc:	f9400a89 	ldr	x9, [x20, #16]
  6fbac0:	7200011f 	tst	w8, #0x1
  6fbac4:	aa1703e1 	mov	x1, x23
  6fbac8:	9a890320 	csel	x0, x25, x9, eq	// eq = none
  6fbacc:	940848c1 	bl	90ddd0 <memcmp@plt>
  6fbad0:	35fffd60 	cbnz	w0, 6fba7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x143c>
  6fbad4:	a9007fff 	stp	xzr, xzr, [sp]
  6fbad8:	f9000bff 	str	xzr, [sp, #16]
  6fbadc:	910003e0 	mov	x0, sp
  6fbae0:	aa1503e1 	mov	x1, x21
  6fbae4:	940848b7 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbae8:	8b1b0357 	add	x23, x26, x27
  6fbaec:	f950e2e1 	ldr	x1, [x23, #8640]
  6fbaf0:	940848b4 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbaf4:	aa1603e1 	mov	x1, x22
  6fbaf8:	940848b2 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbafc:	910003e0 	mov	x0, sp
  6fbb00:	aa1503e1 	mov	x1, x21
  6fbb04:	940848af 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb08:	8b1b0348 	add	x8, x26, x27
  6fbb0c:	f950e501 	ldr	x1, [x8, #8648]
  6fbb10:	940848ac 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb14:	aa1603e1 	mov	x1, x22
  6fbb18:	940848aa 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb1c:	910003e0 	mov	x0, sp
  6fbb20:	aa1503e1 	mov	x1, x21
  6fbb24:	940848a7 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb28:	8b1b0348 	add	x8, x26, x27
  6fbb2c:	f950e901 	ldr	x1, [x8, #8656]
  6fbb30:	940848a4 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb34:	aa1603e1 	mov	x1, x22
  6fbb38:	940848a2 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb3c:	910003e0 	mov	x0, sp
  6fbb40:	aa1503e1 	mov	x1, x21
  6fbb44:	9408489f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb48:	8b1b0348 	add	x8, x26, x27
  6fbb4c:	f950ed01 	ldr	x1, [x8, #8664]
  6fbb50:	9408489c 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb54:	aa1603e1 	mov	x1, x22
  6fbb58:	9408489a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb5c:	910003e0 	mov	x0, sp
  6fbb60:	aa1503e1 	mov	x1, x21
  6fbb64:	94084897 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb68:	8b1b0348 	add	x8, x26, x27
  6fbb6c:	f950f101 	ldr	x1, [x8, #8672]
  6fbb70:	94084894 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb74:	aa1603e1 	mov	x1, x22
  6fbb78:	94084892 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb7c:	910003e0 	mov	x0, sp
  6fbb80:	aa1503e1 	mov	x1, x21
  6fbb84:	9408488f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb88:	8b1b0348 	add	x8, x26, x27
  6fbb8c:	f950f501 	ldr	x1, [x8, #8680]
  6fbb90:	9408488c 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb94:	aa1603e1 	mov	x1, x22
  6fbb98:	9408488a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbb9c:	910003e0 	mov	x0, sp
  6fbba0:	aa1503e1 	mov	x1, x21
  6fbba4:	94084887 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbba8:	8b1b0348 	add	x8, x26, x27
  6fbbac:	f950f901 	ldr	x1, [x8, #8688]
  6fbbb0:	94084884 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbb4:	aa1603e1 	mov	x1, x22
  6fbbb8:	94084882 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbbc:	910003e0 	mov	x0, sp
  6fbbc0:	aa1503e1 	mov	x1, x21
  6fbbc4:	9408487f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbc8:	8b1b0348 	add	x8, x26, x27
  6fbbcc:	f950fd01 	ldr	x1, [x8, #8696]
  6fbbd0:	9408487c 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbd4:	aa1603e1 	mov	x1, x22
  6fbbd8:	9408487a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbdc:	910003e0 	mov	x0, sp
  6fbbe0:	aa1503e1 	mov	x1, x21
  6fbbe4:	94084877 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbe8:	8b1b0348 	add	x8, x26, x27
  6fbbec:	f9510101 	ldr	x1, [x8, #8704]
  6fbbf0:	94084874 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbf4:	aa1603e1 	mov	x1, x22
  6fbbf8:	94084872 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbbfc:	910003e0 	mov	x0, sp
  6fbc00:	aa1503e1 	mov	x1, x21
  6fbc04:	9408486f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc08:	8b1b0348 	add	x8, x26, x27
  6fbc0c:	f9510501 	ldr	x1, [x8, #8712]
  6fbc10:	9408486c 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc14:	aa1603e1 	mov	x1, x22
  6fbc18:	9408486a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc1c:	910003e0 	mov	x0, sp
  6fbc20:	aa1503e1 	mov	x1, x21
  6fbc24:	94084867 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc28:	8b1b0348 	add	x8, x26, x27
  6fbc2c:	f9510901 	ldr	x1, [x8, #8720]
  6fbc30:	94084864 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc34:	aa1603e1 	mov	x1, x22
  6fbc38:	94084862 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc3c:	910003e0 	mov	x0, sp
  6fbc40:	aa1503e1 	mov	x1, x21
  6fbc44:	9408485f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc48:	8b1b0348 	add	x8, x26, x27
  6fbc4c:	f9510d01 	ldr	x1, [x8, #8728]
  6fbc50:	9408485c 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc54:	aa1603e1 	mov	x1, x22
  6fbc58:	9408485a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc5c:	910003e0 	mov	x0, sp
  6fbc60:	aa1503e1 	mov	x1, x21
  6fbc64:	94084857 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc68:	f95112e1 	ldr	x1, [x23, #8736]
  6fbc6c:	94084855 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc70:	aa1503e1 	mov	x1, x21
  6fbc74:	94084853 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fbc78:	a940a277 	ldp	x23, x8, [x19, #8]
  6fbc7c:	eb0802ff 	cmp	x23, x8
  6fbc80:	54000102 	b.cs	6fbca0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1660>  // b.hs, b.nlast
  6fbc84:	394003e8 	ldrb	w8, [sp]
  6fbc88:	37000148 	tbnz	w8, #0, 6fbcb0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1670>
  6fbc8c:	f9400be8 	ldr	x8, [sp, #16]
  6fbc90:	3dc003e0 	ldr	q0, [sp]
  6fbc94:	f9000ae8 	str	x8, [x23, #16]
  6fbc98:	3d8002e0 	str	q0, [x23]
  6fbc9c:	14000008 	b	6fbcbc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x167c>
  6fbca0:	910003e1 	mov	x1, sp
  6fbca4:	aa1303e0 	mov	x0, x19
  6fbca8:	940001ed 	bl	6fc45c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1e1c>
  6fbcac:	14000005 	b	6fbcc0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1680>
  6fbcb0:	a94087e2 	ldp	x2, x1, [sp, #8]
  6fbcb4:	aa1703e0 	mov	x0, x23
  6fbcb8:	97fffa9f 	bl	6fa734 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0xf4>
  6fbcbc:	910062e0 	add	x0, x23, #0x18
  6fbcc0:	394003e8 	ldrb	w8, [sp]
  6fbcc4:	f9000660 	str	x0, [x19, #8]
  6fbcc8:	3607eda8 	tbz	w8, #0, 6fba7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x143c>
  6fbccc:	f9400be0 	ldr	x0, [sp, #16]
  6fbcd0:	940847f8 	bl	90dcb0 <_ZdlPv@plt>
  6fbcd4:	17ffff6a 	b	6fba7c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x143c>
  6fbcd8:	f9401708 	ldr	x8, [x24, #40]
  6fbcdc:	f85f83a9 	ldur	x9, [x29, #-8]
  6fbce0:	eb09011f 	cmp	x8, x9
  6fbce4:	54000441 	b.ne	6fbd6c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x172c>  // b.any
  6fbce8:	a9474ff4 	ldp	x20, x19, [sp, #112]
  6fbcec:	f9401bfb 	ldr	x27, [sp, #48]
  6fbcf0:	a94657f6 	ldp	x22, x21, [sp, #96]
  6fbcf4:	a9455ff8 	ldp	x24, x23, [sp, #80]
  6fbcf8:	a94467fa 	ldp	x26, x25, [sp, #64]
  6fbcfc:	a9427bfd 	ldp	x29, x30, [sp, #32]
  6fbd00:	910203ff 	add	sp, sp, #0x80
  6fbd04:	d65f03c0 	ret
  6fbd08:	f9401708 	ldr	x8, [x24, #40]
  6fbd0c:	f85f83a9 	ldur	x9, [x29, #-8]
  6fbd10:	eb09011f 	cmp	x8, x9
  6fbd14:	540002c1 	b.ne	6fbd6c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x172c>  // b.any
  6fbd18:	aa1403e0 	mov	x0, x20
  6fbd1c:	94000268 	bl	6fc6bc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x207c>
