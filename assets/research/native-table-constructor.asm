
/tmp/motoscan.so:     file format elf64-littleaarch64


Disassembly of section .text:

00000000006fb7c0 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1180>:
  6fb7c0:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
  6fb7c4:	f9000bf3 	str	x19, [sp, #16]
  6fb7c8:	910003fd 	mov	x29, sp
  6fb7cc:	b00010c1 	adrp	x1, 914000 <syscall@plt+0x3cb0>
  6fb7d0:	910da021 	add	x1, x1, #0x368
  6fb7d4:	52803002 	mov	w2, #0x180                 	// #384
  6fb7d8:	aa0003f3 	mov	x19, x0
  6fb7dc:	94084931 	bl	90dca0 <memcpy@plt>
  6fb7e0:	b00010c1 	adrp	x1, 914000 <syscall@plt+0x3cb0>
  6fb7e4:	9113a021 	add	x1, x1, #0x4e8
  6fb7e8:	91060260 	add	x0, x19, #0x180
  6fb7ec:	52845102 	mov	w2, #0x2288                	// #8840
  6fb7f0:	9408492c 	bl	90dca0 <memcpy@plt>
  6fb7f4:	52848108 	mov	w8, #0x2408                	// #9224
  6fb7f8:	f00010c1 	adrp	x1, 916000 <syscall@plt+0x5cb0>
  6fb7fc:	911dc021 	add	x1, x1, #0x770
  6fb800:	8b080260 	add	x0, x19, x8
  6fb804:	52806402 	mov	w2, #0x320                 	// #800
  6fb808:	94084926 	bl	90dca0 <memcpy@plt>
  6fb80c:	5284e508 	mov	w8, #0x2728                	// #10024
  6fb810:	f00010c1 	adrp	x1, 916000 <syscall@plt+0x5cb0>
  6fb814:	912a4021 	add	x1, x1, #0xa90
  6fb818:	8b080260 	add	x0, x19, x8
  6fb81c:	5280f002 	mov	w2, #0x780                 	// #1920
  6fb820:	f9400bf3 	ldr	x19, [sp, #16]
  6fb824:	a8c27bfd 	ldp	x29, x30, [sp], #32
  6fb828:	1408491e 	b	90dca0 <memcpy@plt>
  6fb82c:	d101c3ff 	sub	sp, sp, #0x70
  6fb830:	a9027bfd 	stp	x29, x30, [sp, #32]
  6fb834:	f9001bf9 	str	x25, [sp, #48]
  6fb838:	a9045ff8 	stp	x24, x23, [sp, #64]
  6fb83c:	a90557f6 	stp	x22, x21, [sp, #80]
  6fb840:	a9064ff4 	stp	x20, x19, [sp, #96]
  6fb844:	910083fd 	add	x29, sp, #0x20
  6fb848:	d53bd058 	mrs	x24, tpidr_el0
  6fb84c:	aa0803f3 	mov	x19, x8
  6fb850:	aa0003f4 	mov	x20, x0
  6fb854:	f9401708 	ldr	x8, [x24, #40]
  6fb858:	d0ffd8b5 	adrp	x21, 211000 <psa_to_md_errors@@Base-0x4bcc14>
  6fb85c:	913252b5 	add	x21, x21, #0xc94
  6fb860:	52800b19 	mov	w25, #0x58                  	// #88
  6fb864:	d0ffead6 	adrp	x22, 455000 <psa_to_md_errors@@Base-0x278c14>
  6fb868:	913e0ad6 	add	x22, x22, #0xf82
  6fb86c:	f81f83a8 	stur	x8, [x29, #-8]
  6fb870:	a9007e7f 	stp	xzr, xzr, [x19]
  6fb874:	f9000a7f 	str	xzr, [x19, #16]
  6fb878:	14000004 	b	6fb888 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1248>
  6fb87c:	9100c339 	add	x25, x25, #0x30
  6fb880:	f106a33f 	cmp	x25, #0x1a8
  6fb884:	54000940 	b.eq	6fb9ac <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x136c>  // b.none
  6fb888:	a9007fff 	stp	xzr, xzr, [sp]
  6fb88c:	f9000bff 	str	xzr, [sp, #16]
  6fb890:	910003e0 	mov	x0, sp
  6fb894:	aa1503e1 	mov	x1, x21
  6fb898:	9408494a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb89c:	8b190288 	add	x8, x20, x25
  6fb8a0:	f85d8101 	ldur	x1, [x8, #-40]
  6fb8a4:	94084947 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8a8:	aa1603e1 	mov	x1, x22
  6fb8ac:	94084945 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8b0:	910003e0 	mov	x0, sp
  6fb8b4:	aa1503e1 	mov	x1, x21
  6fb8b8:	94084942 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8bc:	8b190288 	add	x8, x20, x25
  6fb8c0:	f85e0101 	ldur	x1, [x8, #-32]
  6fb8c4:	9408493f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8c8:	aa1603e1 	mov	x1, x22
  6fb8cc:	9408493d 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8d0:	910003e0 	mov	x0, sp
  6fb8d4:	aa1503e1 	mov	x1, x21
  6fb8d8:	9408493a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8dc:	8b190288 	add	x8, x20, x25
  6fb8e0:	f85e8101 	ldur	x1, [x8, #-24]
  6fb8e4:	94084937 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8e8:	aa1603e1 	mov	x1, x22
  6fb8ec:	94084935 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8f0:	910003e0 	mov	x0, sp
  6fb8f4:	aa1503e1 	mov	x1, x21
  6fb8f8:	94084932 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb8fc:	8b190288 	add	x8, x20, x25
  6fb900:	f85f0101 	ldur	x1, [x8, #-16]
  6fb904:	9408492f 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb908:	aa1603e1 	mov	x1, x22
  6fb90c:	9408492d 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb910:	910003e0 	mov	x0, sp
  6fb914:	aa1503e1 	mov	x1, x21
  6fb918:	9408492a 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb91c:	8b190288 	add	x8, x20, x25
  6fb920:	f85f8101 	ldur	x1, [x8, #-8]
  6fb924:	94084927 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb928:	aa1603e1 	mov	x1, x22
  6fb92c:	94084925 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb930:	910003e0 	mov	x0, sp
  6fb934:	aa1503e1 	mov	x1, x21
  6fb938:	94084922 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb93c:	f8796a81 	ldr	x1, [x20, x25]
  6fb940:	94084920 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb944:	aa1503e1 	mov	x1, x21
  6fb948:	9408491e 	bl	90ddc0 <_ZNSt6__ndk112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc@plt>
  6fb94c:	a940a277 	ldp	x23, x8, [x19, #8]
  6fb950:	eb0802ff 	cmp	x23, x8
  6fb954:	54000102 	b.cs	6fb974 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1334>  // b.hs, b.nlast
  6fb958:	394003e8 	ldrb	w8, [sp]
  6fb95c:	37000148 	tbnz	w8, #0, 6fb984 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1344>
  6fb960:	f9400be8 	ldr	x8, [sp, #16]
  6fb964:	3dc003e0 	ldr	q0, [sp]
  6fb968:	f9000ae8 	str	x8, [x23, #16]
  6fb96c:	3d8002e0 	str	q0, [x23]
  6fb970:	14000008 	b	6fb990 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1350>
  6fb974:	910003e1 	mov	x1, sp
  6fb978:	aa1303e0 	mov	x0, x19
  6fb97c:	940002b8 	bl	6fc45c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1e1c>
  6fb980:	14000005 	b	6fb994 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x1354>
  6fb984:	a94087e2 	ldp	x2, x1, [sp, #8]
  6fb988:	aa1703e0 	mov	x0, x23
  6fb98c:	97fffb6a 	bl	6fa734 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0xf4>
  6fb990:	910062e0 	add	x0, x23, #0x18
  6fb994:	394003e8 	ldrb	w8, [sp]
  6fb998:	f9000660 	str	x0, [x19, #8]
  6fb99c:	3607f708 	tbz	w8, #0, 6fb87c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x123c>
  6fb9a0:	f9400be0 	ldr	x0, [sp, #16]
  6fb9a4:	940848c3 	bl	90dcb0 <_ZdlPv@plt>
  6fb9a8:	17ffffb5 	b	6fb87c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x123c>
  6fb9ac:	f9401708 	ldr	x8, [x24, #40]
  6fb9b0:	f85f83a9 	ldur	x9, [x29, #-8]
  6fb9b4:	eb09011f 	cmp	x8, x9
  6fb9b8:	54000321 	b.ne	6fba1c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13dc>  // b.any
  6fb9bc:	a9464ff4 	ldp	x20, x19, [sp, #96]
  6fb9c0:	f9401bf9 	ldr	x25, [sp, #48]
  6fb9c4:	a94557f6 	ldp	x22, x21, [sp, #80]
  6fb9c8:	a9445ff8 	ldp	x24, x23, [sp, #64]
  6fb9cc:	a9427bfd 	ldp	x29, x30, [sp, #32]
  6fb9d0:	9101c3ff 	add	sp, sp, #0x70
  6fb9d4:	d65f03c0 	ret
  6fb9d8:	aa0003f4 	mov	x20, x0
  6fb9dc:	f9000677 	str	x23, [x19, #8]
  6fb9e0:	14000003 	b	6fb9ec <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13ac>
  6fb9e4:	14000001 	b	6fb9e8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13a8>
  6fb9e8:	aa0003f4 	mov	x20, x0
  6fb9ec:	394003e8 	ldrb	w8, [sp]
  6fb9f0:	36000068 	tbz	w8, #0, 6fb9fc <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13bc>
  6fb9f4:	f9400be0 	ldr	x0, [sp, #16]
  6fb9f8:	940848ae 	bl	90dcb0 <_ZdlPv@plt>
  6fb9fc:	aa1303e0 	mov	x0, x19
  6fba00:	97fff6be 	bl	6f94f8 <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_m@@Base+0x210>
  6fba04:	f9401708 	ldr	x8, [x24, #40]
  6fba08:	f85f83a9 	ldur	x9, [x29, #-8]
  6fba0c:	eb09011f 	cmp	x8, x9
  6fba10:	54000061 	b.ne	6fba1c <Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_nativeInitKeyVault@@Base+0x13dc>  // b.any
  6fba14:	aa1403e0 	mov	x0, x20
  6fba18:	940838e5 	bl	909dac <__emutls_get_address@@Base+0x980>
  6fba1c:	940848b1 	bl	90dce0 <__stack_chk_fail@plt>
