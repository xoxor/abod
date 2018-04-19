section .data			; Sezione contenente dati inizializzati
		;posizioni dei parametri ricevuti
		dsetpar		equ		8
		normspar	equ		12
		apar		equ		16
		npar		equ		20
		dpar		equ		24

		;costanti
		dim			equ		4 
		p			equ		4
		UNROLL		equ		3

section .bss			; Sezione contenente dati non inizializzati
		norms: 	resd 1
		dset: 	resd 1
		n: 		resd 1
		d: 		resd 1
		a:		resd 1
		temp:	resd 1
		
section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------

global distances
		
distances:
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
		mov		eax, [ebp+dsetpar]			
		mov		[dset], eax
		mov		eax, [ebp+npar]			
		mov		[n], eax
		mov		eax, [ebp+apar]			
		mov		[a], eax
		mov		eax, [ebp+dpar]			
		mov		[d], eax			

		mov		esp, [dset]
		mov		ebp, [norms]

		;------FUNZIONE

		mov		edx, [d]
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
		imul	edi, [d]
		add		edi, ecx
		imul	edi, 4

		movups	xmm1, [esp+edi]		;data[a*d+i]
		movups	xmm2, [esp+edi+16]
		movups	xmm3, [esp+edi+32]

		mov		edi, ebx		
		imul	edi, [d]
		add		edi, ecx
		imul	edi, 4

		movups	xmm4, [esp+edi]		;data[p*d+i]
		movups	xmm5, [esp+edi+16]
		movups	xmm6, [esp+edi+32]
		
		subps	xmm1, xmm4
		subps	xmm2, xmm5
		subps	xmm3, xmm6
		

		mulps	xmm1, xmm1
		mulps	xmm2, xmm2
		mulps	xmm3, xmm3
		;mulps	xmm4, xmm4

		addps	xmm1, xmm2
		addps	xmm1, xmm3
		haddps	xmm1, xmm1
		haddps	xmm1, xmm1

		addss	xmm0, xmm1

		add		ecx, p*UNROLL
		jmp		.fori
		
.cicloR:
		cmp		ecx, [d]
		jge		.inc
		
		mov		edi, [a]		
		imul	edi, [d]
		add		edi, ecx

		movss	xmm1, [esp+edi*4]		;data[a*d+i]

		mov		edi, ebx		
		imul	edi, [d]
		add		edi, ecx

		subss	xmm1, [esp+edi*4]		;data[p*d+i]
		
		
		mulss	xmm1, xmm1

		addss	xmm0, xmm1

		inc 	ecx
		jmp		.cicloR

.inc:
		sqrtss	xmm0, xmm0 			 ;sqrt(norm)
		
		mov		edi, ebp
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
		
		
		
		
		
		
		
		
		

		
