section .data			; Sezione contenente dati inizializzati
		;posizioni dei parametri ricevuti
		dsetpar		equ		8
		diffspar	equ		12
		normspar	equ		16
		apar		equ		20
		npar		equ		24
		dpar		equ		28

		;costanti
		dim			equ		4 
		p			equ		4
		UNROLL		equ		4

section .bss			; Sezione contenente dati non inizializzati
		norms: 	resd 1
		diffs:	resd 1
		dset: 	resd 1
		n: 		resd 1
		d: 		resd 1
		a:		resd 1
		temp:	resd 1
		
section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------

global normdiff_aps
		
normdiff_aps:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		ebp				; salva il Base Pointer
		mov			ebp, esp			; il Base Pointer punta al Record di Attivazione corrente
		mov			[temp], esp		
		push		ebx				; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------

		mov		eax, [ebp+normspar]			; indirizzo iniziale del training set T
		mov		[norms], eax			
		mov		eax, [ebp+npar]			
		mov		[n], eax
		mov		eax, [ebp+apar]			
		mov		[a], eax

		mov		esp, [ebp+dsetpar]
		mov		esi, [ebp+dpar]	
		mov		ebp, [ebp+diffspar]			
				


		;------FUNZIONE

		mov		edx, esi
		sub		edx, p*UNROLL
		
		mov		eax, 0	;v
		
		mov		ebx, 0	;p

.forp:	
		cmp		ebx, [a]
		je		.incp

		xorps	xmm0,xmm0	;norms
		mov		ecx, 0		; i = 0
.fori:
		cmp		ecx, edx
		jg		.cicloR
	
		mov		edi, [a]		
		imul	edi, esi
		add		edi, ecx
		imul	edi, 4

		movaps	xmm1, [esp+edi]		;data[a*d+i]
		movaps	xmm2, [esp+edi+16]
		movaps	xmm3, [esp+edi+32]
		movaps	xmm4, [esp+edi+48]

		mov		edi, ebx		
		imul	edi, esi
		add		edi, ecx
		imul	edi, 4

		subps	xmm1, [esp+edi]		;data[p*d+i]
		subps	xmm2, [esp+edi+16]
		subps	xmm3, [esp+edi+32]
		subps	xmm4, [esp+edi+48]
		
		mov		edi, eax		
		imul	edi, esi
		add		edi, ecx			;v*d+i
		imul	edi, 4

		movaps	[ebp+edi],    xmm1	;diffs[v*d+i]
		movaps	[ebp+edi+16], xmm2
		movaps	[ebp+edi+32], xmm3
		movaps	[ebp+edi+48], xmm4

		mulps	xmm1, xmm1
		mulps	xmm2, xmm2
		mulps	xmm3, xmm3
		mulps	xmm4, xmm4

		addps	xmm1, xmm2
		addps	xmm1, xmm3
		addps	xmm1, xmm4
		haddps	xmm1, xmm1
		haddps	xmm1, xmm1

		addss	xmm0, xmm1

		add		ecx, p*UNROLL
		jmp		.fori
		
.cicloR:
		mov		edi, esi
		sub		edi, 4
		cmp		ecx, edi
		jg		.inc
		
		mov		edi, [a]		
		imul	edi, esi
		add		edi, ecx

		movaps	xmm1, [esp+edi*4]		;data[a*d+i]

		mov		edi, ebx		
		imul	edi, esi
		add		edi, ecx

		subps	xmm1, [esp+edi*4]		;data[p*d+i]
		
		mov		edi, eax		
		imul	edi, esi
		add		edi, ecx

		movaps	[ebp+edi*4], xmm1		;diffs[v*d+i]
		
		mulps	xmm1, xmm1

		haddps	xmm1, xmm1
		haddps	xmm1, xmm1

		addss	xmm0, xmm1

		add 	ecx, p
		jmp		.cicloR

.inc:
		sqrtss	xmm0, xmm0 			 ;sqrt(norm)
		
		mov		edi, [norms]
		movss	[edi+eax*4], xmm0	 ;norms[v]
		inc		eax					 ;v++

.incp:
		inc		ebx					;p++		
		cmp		ebx, [n]
		jb		.forp
						
		;------FINE FUNZIONE
.fine:
		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		pop	edi					; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, [temp]				; ripristina lo Stack Pointer
		pop	ebp					; ripristina il Base Pointer
		ret						; torna alla funzione C chiamante
		
		
		
		
		
		
		
		
		

		
