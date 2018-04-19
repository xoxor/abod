section .data			
		;costanti
		dim			equ		4 
		p			equ		8
		UNROLL		equ		4

section .bss			; Sezione contenente dati non inizializzati



section .text			; Sezione contenente il codice macchina

; ------------------------------------------------------------
; Funzione
; ------------------------------------------------------------

global prodmat_Dunrollaps

; rdi <-B
; rsi <-n
; rdx <-d
; rcx <-norms
; r8  <-ab
		
prodmat_Dunrollaps:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push	rbp
		mov 	rbp, rsp
		pushaq

		;------FUNZIONE
		mov			r9, rdx
		sub			r9, p*UNROLL
		mov			r14, rdx
		sub			r14, p*2
		mov			r15, rdx
		sub			r15, p
		
		mov			rax, 0			; i = 0
.fori:		
		mov			rbx, rax		; j = i+1
		inc			rbx
		mov			r13, rdx
		imul		r13, rax	
.forj:	
		cmp			rbx, rsi
		jge			.inci
		vxorps		ymm5, ymm5
		
		mov			r12, rdx
		imul		r12, rbx		; j*d
		mov			r10, 0			; k = 0
.fork:	
		cmp			r10, r9				; k<=d-p*UNROLL
		jg			.forkk			
		
		mov			r11, r12
		add			r11, r10			; k+j*d
		imul		r11, dim

		vmovaps		ymm1, [rdi+r11]		; B[k+j*d]
		vmovaps		ymm2, [rdi+r11+32]
		vmovaps		ymm3, [rdi+r11+64]
		vmovaps		ymm4, [rdi+r11+96]

		mov			r11, r13
		add 		r11, r10			; k+i*d
		imul		r11, dim
 	
		vmulps		ymm1, [rdi+r11]	
		vaddps		ymm5, ymm1		 
		vmulps		ymm2, [rdi+r11+32]
		vaddps		ymm5, ymm2
		vmulps		ymm3, [rdi+r11+64]
		vaddps		ymm5, ymm3	
		vmulps		ymm4, [rdi+r11+96]
		vaddps		ymm5, ymm4	

		add			r10, p*UNROLL
		jmp			.fork

.forkk:	
		cmp			r10, r14			; k<=d-16
		jg			.forkkk			
		
		mov			r11, r12
		add			r11, r10			; k+j*d
		imul		r11, dim

		vmovaps		ymm1, [rdi+r11]		; B[k+j*d]
		vmovaps		ymm2, [rdi+r11+32]

		mov			r11, r13
		add 		r11, r10			; k+i*d
		imul		r11, dim

		vmovaps		ymm0, [rdi+r11]		
		vmulps		ymm0, ymm1
		vaddps		ymm5, ymm0		
		vmovaps		ymm0, [rdi+r11+32]	 
		vmulps		ymm0, ymm2
		vaddps		ymm5, ymm0		

		add			r10, p*2
		jmp			.forkk

.forkkk:
		cmp			r10, r15			; k<=d-8
		jg			.inc
		
		mov			r11, r12
		add			r11, r10			; k+j*d
		vmovaps		ymm1, [rdi+r11*4]	; B[k+j*d]
		
		mov			r11, r13
		add 		r11, r10			; k+i*d

		vmovaps		ymm0, [rdi+r11*4]	
		vmulps		ymm0, ymm1
		vaddps		ymm5, ymm0		
		
		add			r10, p
		jmp			.forkkk

.inc:
		vhaddps		ymm5, ymm5
		vhaddps		ymm5, ymm5
		vperm2f128 	ymm0, ymm5, ymm5, 1
		vaddss		xmm5, xmm0			; xmm5 = ps 
		
		vmovss		xmm1, [rcx+rax*4]
		vmulss		xmm1, [rcx+rbx*4]
		vrcpss		xmm0, xmm1			; xmm0 = w
		
		vmulss		xmm5, xmm0
		vmulss		xmm5, xmm0			; xmm5 = alpha

		vaddss		xmm0, xmm0			; xmm0 = 2*w = y

		vmovss		xmm2, xmm5
		vmulss		xmm2, xmm5
		vmulss		xmm2, xmm0			; xmm2 = x
		
		vmovss		xmm3, xmm5
		vmulss		xmm3, xmm0			; xmm3 = z
		
		vmovlhps	xmm2, xmm0				; xmm2= [y,y,x,x]
		vshufps		xmm2, xmm3, 00001000b	; xmm3= [z,z,y,x]

		vaddps		xmm7, xmm2
				
		
		inc			rbx
		jmp			.forj
.inci:		
		inc			rax			
		cmp			rax, rsi
		jb			.fori

		;abof[a] = x/y - (z*z)/(y*y);
		
		vmovhlps	xmm0, xmm7		; xmm0=z
		vmovshdup	xmm1, xmm7		; xmm1=y
	
		vdivss		xmm7, xmm1		; xmm7= x/y
		vmulss		xmm0, xmm0		; xmm0= z^2
		vmulss		xmm1, xmm1		; xmm1= y^2
		vdivss		xmm0, xmm1
		vsubss		xmm7, xmm0		; xmm7= abof
		
		vmovss		[r8], xmm7
		
		vxorps		xmm7, xmm7		; va azzerato per la prossima chiamata
						
		;------FINE FUNZIONE
		
		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------
		
		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante
		
		
		
		
		
		
		
		
		

		
