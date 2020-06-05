in_sym macro 
    mov ah, 01h
    int 21h
    sub al, '0'
    xor ah, ah
endm
out_sym macro 
    mov ah, 02h
    int 21h
endm

out_str macro 
    mov ah,9
    int 21h
endm
	.model tiny
	.code
	org 80h 
	cmd_length db ? 
	cmd_line db ? 
	org 100h 
start:
	
	cld 
	mov bp, sp
	;mov cl, cmd_length
	mov cx, -1
	mov di, offset cmd_line
find_param:
	mov al, ' '
	repz scasb
	dec di
	push di
	inc word ptr argc
	mov si, di
	
scan_params:
	lodsb
	cmp al, 0Dh
	je params_ended
	cmp al, 20h
	jne scan_params
	
	dec si
	mov byte ptr [si], 0
	mov di, si
	inc di
	jmp short find_param
	
params_ended:
	dec si
	mov byte ptr [si], 0
	
	mov cx, 2
	cmp cx, wp argc
	je skip1
	lea dx, msg5
	out_str
	jmp exit
skip1:	
	xor si, si
	pop dx
	push dx
	mov ah, 3Dh
	mov al, 00h
	int 21h
	jnc input_num
	lea dx, msg3
	out_str
	jmp exit
	
input_num: 
	mov cx, ax         ;сохраняем идентификатор файла в cx
	pop ax
	pop bx
	push ax
	push cx
	
	xor     ax,ax                   
    mov     di, bx               
    xor     ch,ch                   
    mov     cl, 5           
    mov     si,10                   
    xor     bh,bh
    call input_number                   
    
    mov     len, ax
	cmp bp, 333
	jne skip5
	lea dx, msg6
	out_str
	jmp exit
skip5:
	pop bx				;идентификатор файла в bx
	xor bp, bp
	xor si, si
read_data:
	mov cx, 10000
	mov dx,offset buffer 
	mov ah,3Fh 
	int 21h 
	jc close_file 
	mov cx,ax 
	jcxz close_file
	call find_str 
	jmp short read_data 
	
close_file:
mov dx, wp border_size
	cmp dx, len
	jge next2
	inc si
next2:
	mov ah,3Eh 
	int 21h
	
output_number:	
	lea dx, msg2
	out_str
	mov ax, si
	call ShowUInt16
	jmp exit
ShowUInt16       proc
        mov     bx,     10              ;делитель (основание системы счисления)
        mov     cx,     5               ;количество выводимых цифр
        @@div:
                xor     dx,     dx      ;делим (dx:ax) на bx
                div     bx
                add     dl,     '0'     ;преобразуем остаток деления в символ цифры
                push    dx              ;и сохраняем его в стеке
        loop     @@div                   ;да - повторить цикл выделения цифры
		mov     cx,     5 
        @@show:
                mov     ah,     02h     ;функция ah=02h int 21h - вывести символ из dl на экран
                pop     dx              ;извлекаем из стека очередную цифру
                int     21h             ;и выводим её на экран
        loop    @@show                  ;и так поступаем столько раз, сколько нашли цифр в числе (cx)        pop     bx
ret
endp
  
exit:
	mov ah,3Eh 
	int 21h
	int 20h

new_line proc 
    mov dl, 0Ah
    out_sym
    mov dl, 0Dh
    out_sym
    xor bp, bp
ret
endp

input_number proc
m1:
	cmp  byte ptr [di], 0
	je end_inp_num
    mul     si                      
    mov     bl,[di] 
    cmp     bl, 30h                
    jl      err_msg
    cmp     bl, 39h                
    jg      err_msg                  
    sub     bl,30h                  
    add     ax,bx                   
    inc     di                      
    loop    m1 
end_inp_num:
    ret
jmp skip3	
err_msg:
	mov bp, 333
	ret	
skip3:
endp

find_str proc
    push di
    push dx
    push cx
	
	mov dx, wp border_size
	lea di, buffer 
loop1:
	cmp byte ptr [di], 0Dh
	je next1
	;cmp byte ptr [di], 0Ah
	;je next1
	inc dx
	jmp next
next1:
	mov ax, dx
	xor dx, dx
	cmp ax, len
	jge next
	;cmp ax, 0
	;je next
	inc si
next:
	inc di
loop loop1
    mov word ptr border_size, dx
	xor ax,ax
    pop cx
    pop dx
    pop di  
ret    
endp
	argc dw 0 
	wp equ word ptr
	len dw 0
	border_size dw 0
	buffer db 10000 dup(0)
	msg1 db 0Dh, 0Ah,"Vvedite dlinu stroki",0Dh, 0Ah,'$'
	msg2 db 0Dh, 0Ah,"Chislo strok = ",'$'
	msg3 db 0Dh, 0Ah,"Fail ne naiden!",0Dh, 0Ah,'$'
	msg4 db 0Dh, 0Ah,"Makcimalnaya dlina stroki < 50 symb!!",0Dh, 0Ah,'$'
	msg5 db 0Dh, 0Ah,"Kol-vo argumentov dolzhno byt 2!!!",0Dh, 0Ah,'$'
	msg6 db 0Dh, 0Ah,"Invalid argument!!!",0Dh, 0Ah,'$'
end start