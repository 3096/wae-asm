	// main function
	.text
	.align	4
	.global	main
main:
	// save stack frame
	stp x29, x30, [sp, #-0x10]!
	mov x29, sp

	// save callee-saved registers we're gonna use
	stp x19, x20, [sp, #-0x10]!

	// image dimensions
	mov w19, 720
	mov w20, 1280


	// set up function call to framebufferCreate
	bl nwindowGetDefault
	mov x1, x0  // arg 1, p_win
	sub sp, sp, #0x50  // allocate Framebuffer struct on stack
	mov x0, sp  // arg 0, p_frameBuffer
	mov w2, w20  // arg 2, image_width
	mov w3, w19  // arg 3, image_height
	mov w4, 5  // arg 4, format: PIXEL_FORMAT_BGRA_8888 = 5
	mov w5, 1  // arg 5, how many framebuffers
	bl framebufferCreate


	// make a linear framebuffer, easier to work with
	mov x0, sp  // arg 0, p_frameBuffer
	bl framebufferMakeLinear


	// framebufferBegin will return a pointer to the framebuffer memory
	mov x0, sp  // arg 0, p_frameBuffer
	sub x1, sp, #8  // arg 1, unused, just pass in an unused stack region
	bl framebufferBegin


	// start copying our image into the framebuffer memory
	adr x9, image_bin

	mov w10, w19  // remaining rows to copy
.Row:
	mov w11, w20  // remaining columns to copy in row
.Column:
	ldr w12, [x9]  // load 4 bytes from the image
	orr w12, w12, 0xFF000000  // set alpha to FF, which is not part of our image data
	str w12, [x0]  // store pixel to framebuffer memory

	// move to next pixel
	add x0, x0, #4
	add x9, x9, #3

	// repeat colomns
	sub w11, w11, #1
	cbnz w11, .Column

	// repeat rows
	sub w10, w10, #1
	cbnz w10, .Row


	// framebufferEnd will flush and display our framebuffer
	mov x0, sp
	bl framebufferEnd


	// just an infinite loop so we can look at our image
.Loop:
	mov w0, 0x10000000
	svc 0xB  // svc sleep
	b	.Loop


	// there's no way to exit the infinite loop for now
	// but if we were to, here's to clean up
	mov x0, sp
	bl framebufferClose
	add sp, sp, #0x50

	// pop saved registers
	ldp x19, x20, [sp], #0x10

	// pop stack frame
	ldp x29, x30, [sp], #0x10
