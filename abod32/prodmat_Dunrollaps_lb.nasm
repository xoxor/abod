section .data			; Sezione contenente dati inizializzati
						; posizioni dei parametri ricevuti
		Bpar		equ		8
		npar		equ		12
		dpar		equ		16
		normspar	equ		20
		abpar		equ		24
		rpar		equ		28
		denpar		equ		32
		;costanti
		dim			equ		4 
		p			equ		4
		UNROLL		equ		4
		

section .bss			; Sezione contenente dati non inizializzati
		B: resd	1
		n: resd 1
		d: resd 1
		norms: resd 1
		temp: resd 1
		ab:	resd 1
		r: resd 1
		den: resd 1

section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------

global prodmat_Dunrollaps_lb
		
prodmat_Dunrollaps_lb:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		ebp						; salva il Base Pointer
		mov			ebp, esp				; il Base Pointer punta al Record di Attivazione corrente
		mov			[temp], esp		
		push		ebx						; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
		mov		eax, [ebp+normspar]			; indirizzo iniziale del training set T
		mov		[norms], eax
		mov		eax, [ebp+npar]			
		mov		[n], eax
		mov		eax, [ebp+abpar]			
		mov		[ab], eax
		mov		eax, [ebp+rpar]
		mov		[r], eax
		mov		eax, [ebp+denpar]
		mov		[den], eax
		mov		esp, [ebp+Bpar]			
		mov		ebp, [ebp+dpar]			

		;------FUNZIONE
		
		mov			edx, ebp
		sub			edx, p*UNROLL
		
		mov			eax, 0			; i = 0
.fori:		
		mov			ebx, eax		; j = i+1
		add			ebx, 1
.forj:	
		cmp			ebx, [n]
		jge			.inci
		xorps		xmm5, xmm5
		
		mov			ecx, 0			; k = 0
.fork:	
		cmp			ecx, edx		; k<=d-16
		jg			.forkk			
		
		mov			esi, ebp
		imul		esi, ebx		; 	j*d
		add			esi, ecx		; k+j*d
		imul		esi, 4

		movaps		xmm1, [esp+esi]		; B[k+j*d]
		movaps		xmm2, [esp+esi+16]
		movaps		xmm3, [esp+esi+32]
		movaps		xmm4, [esp+esi+48]

		mov			esi, ebp
		imul		esi, eax			; 	i*d
		add 		esi, ecx			; k+i*d
		imul		esi, 4

		movaps		xmm0, [esp+esi]		; B[k+i*d]
		mulps		xmm0, xmm1
		addps		xmm5, xmm0		
		movaps		xmm0, [esp+esi+16]	 
		mulps		xmm0, xmm2
		addps		xmm5, xmm0		
		movaps		xmm0, [esp+esi+32]	
		mulps		xmm0, xmm3
		addps		xmm5, xmm0		
		movaps		xmm0, [esp+esi+48]	
		mulps		xmm0, xmm4
		addps		xmm5, xmm0		

		add			ecx, p*UNROLL
		jmp			.fork

.forkk:
		mov 		esi, ebp
		sub			esi, 4				; d-4 
		cmp			ecx, esi
		jg			.inc
		
		mov			esi, ebp
		imul		esi, ebx			; j*d
		add			esi, ecx			; k+j*d

		movaps		xmm1, [esp+esi*4]	; B[k+j*d]
		
		mov			esi, ebp
		imul		esi, eax			; 	i*d
		add 		esi, ecx			; k+i*d

		movaps		xmm0, [esp+esi*4]	; 
		mulps		xmm0, xmm1
		addps		xmm5, xmm0		; 
		
		add			ecx, p
		jmp			.forkk

.inc:
		haddps		xmm5,xmm5
		haddps		xmm5,xmm5		; xmm5 = ps
	
		mov			ecx, [norms]		
		movss		xmm1, [ecx+eax*4]
		mulss		xmm1, [ecx+ebx*4]
		rcpss		xmm0, xmm1			; xmm0 = w
		
		mulss		xmm5, xmm0
		mulss		xmm5, xmm0			; xmm5 = alpha

		addss		xmm0, xmm0			; xmm0 = 2*w = y

		movss		xmm2, xmm5
		mulss		xmm2, xmm5
		mulss		xmm2, xmm0			; xmm2 = x
		
		movss		xmm3, xmm5
		mulss		xmm3, xmm0			; xmm3 = z
		
		movlhps		xmm2, xmm3				; xmm2= [z,z,x,x]

		addps		xmm7, xmm2
				
		
		inc			ebx
		jmp			.forj
.inci:		
		inc			eax			
		cmp			eax, [n]
		jb			.fori

		;abof[a] = x/den - ((z+r2)*(z+r2))/(den*den);
		
		movhlps		xmm0, xmm7		; xmm0=z
		addss		xmm0, [r]		; xmm0= z+r2

		movss		xmm1, [den]
		divss		xmm7, xmm1		; xmm7= x/den

		mulss		xmm0, xmm0		; xmm0= z^2
		mulss		xmm1, xmm1		; xmm1= den^2
		divss		xmm0, xmm1
		subss		xmm7, xmm0		; xmm7= abof
		
		mov			eax, [ab]
		movss		[eax], xmm7
		
		xorps		xmm7, xmm7		; va azzerato per la prossima chiamata
						
		;------FINE FUNZIONE

		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		pop	edi					; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, [temp]			; ripristina lo Stack Pointer
		pop	ebp					; ripristina il Base Pointer
		ret						; torna alla funzione C chiamante
		
		
		
		
		
		
		
		
		

		
