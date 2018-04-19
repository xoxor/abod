section .data	
		;costanti
		dim			equ		4 
		p			equ		8
		UNROLL		equ		2

section .bss			; Sezione contenente dati non inizializzati

		
section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------
; normdiff_aps(DATASET data, MATRIX diffs, VECTOR norms,  int a, int n, int d);
; rdi = data
; rsi = diffs
; rdx = norms
; rcx = a
; r8 = n
; r9 = d

global normdiff_aps
		
normdiff_aps:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push	rbp
		mov 	rbp, rsp
		pushaq	
				

		;------FUNZIONE
		mov		rax, r9
		sub		rax, p*UNROLL ; d-16
		
		mov		r10, 0	;v
		
		mov		r11, 0	;p

.forp:	
		cmp		r11, rcx
		je		.incp

		vxorps	ymm0, ymm0	;norms
		mov		r12, 0		; i = 0
.fori:
		cmp		r12, rax
		jg		.cicloR
	
		mov		rbx, rcx		
		imul	rbx, r9
		add		rbx, r12
		imul	rbx, 4

		vmovaps	ymm1, [rdi+rbx]		;data[a*d+i]
		vmovaps	ymm2, [rdi+rbx+32]	

		mov		rbx, r11		
		imul	rbx, r9
		add		rbx, r12
		imul	rbx, 4

		vsubps	ymm1, [rdi+rbx]		;data[p*d+i]
		vsubps	ymm2, [rdi+rbx+32]
		
		mov		rbx, r10					
		imul	rbx, r9
		add		rbx, r12			;v*d+i
		imul	rbx, 4
	
		vmovaps	[rsi+rbx], 	  ymm1		;diffs[v*d+i]
		vmovaps	[rsi+rbx+32], ymm2	

		vmulps	ymm1, ymm1
		vmulps	ymm2, ymm2

		vaddps	ymm1, ymm2
		vhaddps	ymm1, ymm1
		vhaddps	ymm1, ymm1
		vperm2f128 ymm3, ymm1, ymm1, 1
		vaddss	xmm1, xmm3

		vaddss	xmm0, xmm1

		add		r12, p*UNROLL
		jmp		.fori
		
.cicloR:
		mov		rbx, r9
		sub		rbx, 8
		cmp		r12, rbx 
		jg		.inc
		
		mov		rbx, rcx		
		imul	rbx, r9
		add		rbx, r12

		vmovaps	ymm1, [rdi+rbx*4]		;data[a*d+i]

		mov		rbx, r11		
		imul	rbx, r9
		add		rbx, r12

		vsubps	ymm1, [rdi+rbx*4]		;data[p*d+i]
		
		mov		rbx, r10		
		imul	rbx, r9
		add		rbx, r12

		vmovaps	[rsi+rbx*4], ymm1		;diffs[v*d+i]
		
		vmulps	ymm1, ymm1

		vhaddps	ymm1, ymm1
		vhaddps	ymm1, ymm1
		vperm2f128 ymm3, ymm1, ymm1, 1
		vaddss	xmm1, xmm3

		vaddss	xmm0, xmm1

		add 	r12, p
		jmp		.cicloR

.inc:
		vsqrtss	xmm0, xmm0 			 ;sqrt(norm)
		
		vmovss	[rdx+r10*4], xmm0	 ;norms[v]
		inc		r10					 ;v++

.incp:
		inc		r11					;p++		
		cmp		r11, r8
		jb		.forp
						
		;------FINE FUNZIONE
.fine:
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		
		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante
		
		
		
		
		
		
		
		
		

		
