[org 0x0100]

jmp Main

TitleText: db '25L-0544'
ParagraphText:  db 'hi my name is Ammar', 10
			db 'Ammar loves to scroll instagram',10
			db 'Ammar hates to study', 10
			db 'Test text to check wrap and boundaries, Test text to check wrap and boundaries, Test text to check wrap and boundaries', 0
SearchWord: db 'Ammar', 0
MatchCount: dw 0
StatusPrefix:  db 'Total Matches Found: [', 0
StatusSuffix:  db '] | Viewport Status: ACTIVE', 0

PrintStatus:
	push ax
	push si
	push di
	push es

	mov ax, 0xb800
	mov es, ax
	cld
	mov di, 3680
	mov ah, 0x07

	mov si, StatusPrefix
	StatusPrefixLoop:
		lodsb
		cmp al, 0
		je StatusPrefixDone
		stosw
		jmp StatusPrefixLoop
		
	StatusPrefixDone:
		push word [MatchCount]
		push di
		call PrintNumber           ; ax = offset after the number
		mov di, ax
		mov ah, 0x07

	mov si, StatusSuffix
	
	StatusSuffixLoop:
		lodsb
		cmp al, 0
		je StatusSuffixDone
		stosw
		jmp StatusSuffixLoop
		
StatusSuffixDone:
	pop es
	pop di
	pop si
	pop ax
	ret


DrawViewport:
	push es
	push ax
	push bx
	push cx
	push di
	cld
	
	mov ax, 0xb800
	mov es, ax
	
	;upper left to right
	mov bx, 0
	mov ax, 3
	mov bl, 80
	mul bl
	add ax, 8
	shl ax, 1
	mov di, ax
	mov ax, 0x07CD
	mov cx, 64
	rep stosw
	
	;lower left to right
	mov bx, 0
	mov ax, 21
	mov bl, 80
	mul bl
	add ax, 8
	shl ax, 1
	mov di, ax
	mov ax, 0x07CD
	mov cx, 64
	rep stosw
	
	;left boundary
	mov bx, 0
	mov ax, 4
    mov bl, 80
    mul bl
    add ax, 8
    shl ax, 1
    mov di, ax
    mov ax, 0x07BA
    mov cx, 17
	LeftBorderLoop:
		mov [es:di], ax
		add di, 160
		loop LeftBorderLoop
	
	;right boundary
	mov bx,0
	mov ax, 4
	mov bl, 80
	mul bl
	add ax, 71
	shl ax, 1
	mov di, ax
	mov ax, 0x07BA
	mov cx, 17
	RightBorderLoop:
		mov [es:di], ax
		add di, 160
		loop RightBorderLoop
	
	pop di
	pop cx
	pop bx
	pop ax
	pop es
	ret


;string, attr
HighlightMatches:
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push es
	cld

	mov ax, 0xb800
	mov es, ax
	mov dh, 4

SearchRowLoop:
	mov al, dh
	mov ah, 0
	mov bl, 80
	mul bl
	add ax, 9
	shl ax, 1
	mov di, ax
	mov cx, 62

SearchCellLoop:
	mov bx, di
	mov si, [bp+6]

CompareCharLoop:
	lodsb
	cmp al, 0
	je MatchFound
	scasb
	jne NextCell
	inc di
	jmp CompareCharLoop

MatchFound:
	inc word [MatchCount]
	mov ax, [bp+4]
	
ApplyAttrLoop:
	mov [es:di-1], al
	sub di, 2
	cmp di, bx
	ja ApplyAttrLoop

NextCell:
	mov di, bx
	add di, 2
	dec cx
	jnz SearchCellLoop

	inc dh
	cmp dh, 21
	jb SearchRowLoop

	pop es
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4


PrintTitle:
	push bx
	push ds
	push si
	push ax
	push cx
	push es
	push di
	
	mov si, TitleText
	
	mov ax, 0xb800
	mov es, ax
	
	mov bx, 0
	mov ax, 4
    mov bl, 80
    mul bl
    add ax, 36
    shl ax, 1
    mov di, ax
	
    mov ah, 0x1E
	mov cx, 8
	cld
	
	TitleCharLoop:
		lodsb
		stosw
		loop TitleCharLoop
	
	pop di
	pop es
	pop cx
	pop ax
	pop si
	pop ds
	pop bx
	ret


; top, left, bottom, right, n
ScrollUp:
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es

	mov ax, 0xb800
	mov ds, ax
	mov es, ax
	cld

	;rows to move
	mov bx, [bp+8]
	sub bx, [bp+12]
	inc bx
	sub bx, [bp+4]

	mov ax, [bp+12]
	mov di, 80
	mul di
	add ax, [bp+10]
	shl ax, 1
	mov di, ax

	mov ax, [bp+4]
	mov si, 160
	mul si
	add ax, di
	mov si, ax

	;width
	mov dx, [bp+6]
	sub dx, [bp+10]
	inc dx

	;skip val
	mov ax, 160
	sub ax, dx
	sub ax, dx

	CopyRowLoop:
		mov cx, dx
		rep movsw
		add si, ax
		add di, ax
		dec bx
		jnz CopyRowLoop

	mov bx, [bp+4]
	mov si, ax
	mov ax, 0x0720
	
	BlankRowLoop:
		mov cx, dx
		rep stosw
		add di, si
		dec bx
		jnz BlankRowLoop

	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 10


ClearScreen:
	push es
	push ax
	push cx
	push di
	
	mov ax, 0xb800
	mov es, ax
	
	mov di, 0
	mov ax, 0x0720
	mov cx, 2000
	
	cld
	rep stosw
	
	pop di
	pop cx
	pop ax
	pop es
	ret


;num, offset
PrintNumber:
	push bp
	mov bp, sp
	push bx
	push cx
	push dx
	push di
	push es

	mov ax, 0xb800
	mov es, ax
	mov ax, [bp+6]
	mov di, [bp+4]
	mov bx, 10
	xor cx, cx

	DigitExtractLoop:
		xor dx, dx
		div bx                  ; ax = qt, dx = rmndr
		push dx
		inc cx
		cmp ax, 0
		jne DigitExtractLoop

	DigitPrintLoop:
		pop dx
		add dl, '0'
		mov dh, 0x07
		mov [es:di], dx
		add di, 2
		loop DigitPrintLoop

	mov ax, di

	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop bp
	ret 4


PrintParagraph:
	push bp
    mov bp, sp
    push si
    push ax
    push bx
    push cx
    push dx
    push es
    push di
	
	mov ax, 0xb800
    mov es, ax
	mov si, [bp+6] ;message
	mov dh, 6 ;starting row
	mov dl, 10 ;starting col
	
	ParaNextLine:
		mov al, dh
		mov bl, 80
		mul bl
		mov bl, dl
		xor bh, bh
		add ax, bx
		shl ax, 1
		mov di, ax
		
		mov cx, 0
		
	ParaCharLoop:
		mov ax, [bp+4]
		lodsb
		cmp al, 0
		je ParaDone
		cmp al, 10
		je ParaLineBreak
		
		stosw
		inc cx
		cmp cx, 60
		je ParaLineBreak
		jmp ParaCharLoop
		
	ParaLineBreak:
		mov dl, 10
		inc dh
		cmp dh, 21
		jge ParaDone
		jmp ParaNextLine
		
	ParaDone:
		pop di
		pop es
		pop dx
		pop cx
		pop bx
		pop ax
		pop si
		pop bp
		ret 4


Main:
	call ClearScreen
	call DrawViewport
	call PrintTitle
	
	push ParagraphText
	push word 0x0700
	call PrintParagraph
	
	push word 6     ;top
	push word 9     ;left
	push word 20    ;bottom
	push word 70    ;right
	push word 1     ;n
	call ScrollUp
	
	
	push SearchWord
	push word 0xCE
	call HighlightMatches
	call PrintStatus
	
	mov ax, 0x4C00
    int 0x21