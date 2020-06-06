in_sym macro 						;get symbol
    mov ah, 01h
    int 21h
    sub al, '0'
    xor ah, ah
endm
out_sym macro 						;output symbol
    mov ah, 02h
    int 21h
endm

out_str macro 						;output str
    mov ah,9
    int 21h
endm
	.model tiny
	.code
	org 80h 				;smeschenie 80h ot start PSP
	cmd_length db ? 			;dlina cmdline
	cmd_line db ? 				;sama cmdline
	org 100h 
start:
	
	cld 					;for command strokovoy obrabotki
	mov bp, sp
	mov cx, -1
	mov di, offset cmd_line  		;start cmd_line
find_param:
	mov al, ' '
	repz scasb				;find no probel
	dec di					;adress start parametr
	push di
	inc word ptr argc
	mov si, di
	
scan_params:
	lodsb					;read symbol from parametr
	cmp al, 0Dh				;if 0Dh - last parametr
	je params_ended
	cmp al, 20h			;sravnenie s probel
	jne scan_params
	
	dec si				;first byte after parametr
	mov byte ptr [si], 0
	mov di, si
	inc di
	jmp short find_param
	
params_ended:
	dec si						;first byte after end
	mov byte ptr [si], 0		;write 0
	
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
	mov ah, 3Dh 				 ;enter file
	mov al, 00h     					;for reading
	int 21h
	jnc input_num
	lea dx, msg3
	out_str
	jmp exit
	
input_num: 
	mov cx, ax       ;identificator file
	pop ax
	pop bx
	push ax
	push cx
	
	xor     ax,ax                   
    mov     di, bx               ;number
    xor     ch,ch                   
    mov     cl, 5           
    mov     si,10                ;for mul   
    xor     bh,bh
    call input_number                   
    
    	mov len, ax		;length str
	cmp bp, 333		;invalid argument
	jne skip5
	lea dx, msg6
	out_str
	jmp exit
skip5:
	pop bx				
	xor bp, bp
	xor si, si
read_data:
	mov cx, 10000				;number bytes for read
	mov dx,offset buffer 			;here read
	mov ah,3Fh 			;read from file
	int 21h 
	jc close_file 
	mov cx,ax 			;count read bytes
	jcxz close_file			;if cx = 0
	call find_str 
	jmp short read_data 
	
close_file:
	mov dx, wp border_size
	cmp dx, len
	jge next2
	inc si
next2:
	mov ah,3Eh   ;close file
	int 21h
	
output_number:	
	lea dx, msg2
	out_str
	mov ax, si
	call ShowUInt16
	jmp exit
ShowUInt16       proc
        mov     bx,     10             
        mov     cx,     5              
        @@div:
                xor     dx,     dx     
                div     bx
                add     dl,     '0'   
                push    dx           
        loop     @@div                
		mov     cx,     5 
        @@show:
                mov     ah,     02h   
                pop     dx           
                int     21h            
        loop    @@show               
ret
endp
  
exit:
	mov ah,3Eh 			;close file
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

input_number proc			;get our entered number
m1:
	cmp  byte ptr [di], 0		;nothing enter
	je end_inp_num
    imul     si 
    jc err_msg 
    jo err_msg                    
    mov     bl,[di] 
    cmp     bl, 30h      					;<0                
    jl      err_msg
    cmp     bl, 39h 						;>9               
    jg      err_msg                  
    sub     bl,30h                  
    add     ax,bx
    jc err_msg 
    jo err_msg                
    inc     di                      
    loop    m1 
end_inp_num:
    ret
jmp skip3	
err_msg:
	mov bp, 333		;invalid argument
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
	cmp byte ptr [di], 0Dh		;back CR
	je next1
	inc dx
	jmp next
next1:						;proverka
	mov ax, dx
	xor dx, dx
	cmp ax, len
	jge next				;length str more than input number
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
	buffer db 1000 dup(0)
	msg1 db 0Dh, 0Ah,"Vvedite dlinu stroki",0Dh, 0Ah,'$'
	msg2 db 0Dh, 0Ah,"Chislo strok = ",'$'
	msg3 db 0Dh, 0Ah,"Fail ne naiden!",0Dh, 0Ah,'$'
	msg4 db 0Dh, 0Ah,"Makcimalnaya dlina stroki < 50 symb!!",0Dh, 0Ah,'$'
	msg5 db 0Dh, 0Ah,"Kol-vo argumentov dolzhno byt 2!!!",0Dh, 0Ah,'$'
	msg6 db 0Dh, 0Ah,"Invalid argument!!!",0Dh, 0Ah,'$'
end start