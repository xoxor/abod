section .data			; Sezione contenente dati inizializzati
		;costanti
		dim			equ		4 
		p			equ		8
		UNROLL		equ		2

section .bss			; Sezione contenente dati non inizializzati

		
section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------

global distances
		
distances:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push	rbp
		mov 	rbp, rsp
		pushaq
		
	
		;------FUNZIONE

		mov		r9, r8
		sub		r9, p*UNROLL		; d-16
		
		mov		r13, r8
		imul	r13, rdx			; a*d
		
		mov		rax, 0	;v
		
		mov		rbx, 0	;p

.forp:	
		cmp		rbx, rdx
		je		.incp

		mov		r14, r8
		imul	r14, rbx	; p*d
		
		vxorps	ymm0,ymm0	; norms
		
		mov		r10, 0		; i = 0
.fori:
		cmp		r10, r9
		jg		.cicloR
	
		mov		r11, r13
		add		r11, r10
		imul	r11, 4

		vmovups	ymm1, [rdi+r11]		;data[a*d+i]
		vmovups	ymm2, [rdi+r11+32]

		mov		r11, r14
		add		r11, r10
		imul	r11, 4

		vmovups	ymm4, [rdi+r11]		;data[p*d+i]
		vmovups	ymm5, [rdi+r11+32]
		
		vsubps	ymm1, ymm4
		vsubps	ymm2, ymm5

		vmulps	ymm1, ymm1
		vmulps	ymm2, ymm2

		vaddps	ymm1, ymm2
		vhaddps	ymm1, ymm1
		vhaddps	ymm1, ymm1
		vperm2f128 ymm7, ymm1, ymm1, 1
		vaddss	xmm1, xmm7		 

		vaddss	xmm0, xmm1

		add		r10, p*UNROLL
		jmp		.fori
		
.cicloR:
		mov		r15, r8
		sub		r15, 8
		cmp		r10, r15
		jg		.inc
		
		mov		r11, r13
		add		r11, r10

		vmovups	ymm1, [rdi+r11*4]		;data[a*d+i]

		mov		r11, r14
		add		r11, r10

		vsubps	ymm1, [rdi+r11*4]		;data[p*d+i]
		vmulps	ymm1, ymm1
		
		vhaddps	ymm1, ymm1
		vhaddps	ymm1, ymm1
		vperm2f128 ymm7, ymm1, ymm1, 1
		vaddss	xmm1, xmm7
		
		vaddss	xmm0, xmm1

		add 	r10, p
		jmp		.cicloR

.inc:
		vsqrtss	xmm0, xmm0 			 ;sqrt(norm)
		
		vmovss	[rsi+rax*4], xmm0	 ;norms[v]
		inc		rax					 ;v++

.incp:
		inc		rbx					;p++		
		cmp		rbx, rcx
		jb		.forp
						
		;------FINE FUNZIONE

		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante
		
		
		
		
		
		
		
		
		

		
