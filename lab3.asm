CR equ 0dh
                  
ROW_COUNT equ 5
COLUMN_COUNT equ 6
          
.model tiny

print_str macro out_str    ;print str
    mov ah, 9
    mov dx, offset out_str
    int 21h
endm

read_str macro in_str        ;enter str
    mov ah, 0ah
    mov dx, offset in_str
    int 21h
endm

.code
.org 100h

start proc
    
    xor si, si
    mov cx, ROW_COUNT
_scan_raws_loop:    
    push cx
    
    print_str input_row_msg   ;outp message
    read_str _mxln_row        ;input str
    mov word ptr [g_str_offs], 0
    
    mov cx, COLUMN_COUNT
_fill_row_loop:    
    call scan_int             ;get int
    mov row_arr[si], ax        ;fill array
    add si, 2
    loop _fill_row_loop
    
    print_str new_line_msg
    
    pop cx
    loop _scan_raws_loop
    
;;;;;;;;;;;;;;;; sum_row ;;;;;;;;;;;;;;;;;;;;;;
    
    xor si, si 
    sub di,2
    mov cx, ROW_COUNT
_column_sum_loop:
    push cx
    
    add di,2  
    mov cx, COLUMN_COUNT
_row_loop:    
    mov ax, row_arr[si]
    add sum_row[di], ax
	
	jc _sum_overflow   ;if perenos perehod na metku
	
    add si, 2
    loop _row_loop
    
    pop cx
    loop _column_sum_loop
    
;;;; print
    
    xor bx, bx
    xor ax, ax
    xor si, si
    
    mov cx, 5
    mov bx, 10
print_sum:
        xor di, di
        xor ax, ax
        std                    ; obratny poryadok zapisi
		lea	di,StringEnd-1 ; posledniy simvol stroki String

		mov ax, sum_row[si]      ;zapis summy
Repeat:
		xor	dx,dx         
		div	bx             ; delim na 10
                                       ; v ax chastnoe v dx ostatok
		xchg	ax,dx          ; menyem ih mestami(nas interesuet ostatok
		add	al,'0'         
		stosb                  ; zapisyvaem cifru is al v stroky
		xchg	ax,dx          ; vosstanavlivaem ax(chastnoe)
		or	ax,ax          ; sravnivaem s 0
		jne	Repeat         ; ne 0 povtoryem

		mov	ah,9
		lea	dx,[di+1]      ;nachalo stroki
		int	21h            ;  
    print_str new_line_msg
    add si,2 
    loop print_sum
    jmp _end_of_prog
    
_sum_overflow:
    print_str msg_sum_overflow

_end_of_prog:        
    xor ax, ax
    mov ah, 4Ch
    int 21h
start endp



is_digit proc
    push bp
    mov bp, sp
    push bx
    
    mov ax, 0
    mov bl, byte ptr [bp + 4]
    cmp bl, '0'
    jb _end
    cmp bl, '9'
    ja _end
    mov ax, 1
    
_end:
    pop bx    
    pop bp
    ret
is_digit endp
  
; PROC :: scan_int :: PROC     
; scans integer from g_row_str
; @params: string
; @ret_val: ax
; @side_effects: changes the value of ax, and g_row_str

scan_int proc
    push bp
    mov bp, sp 
    push bx
    push dx
    push si
    
    xor ax, ax
          
_skip_space_loop:
    mov si, [g_str_offs] ;start str
    mov al, byte ptr row_str[si]  ;in al number
    
    cmp byte ptr row_str[si], CR      ;if end of str
    je _pre_scan_int_loop
    cmp byte ptr row_str[si], ' '    ;if not probel
    jne _pre_scan_int_loop
    
    inc word ptr [g_str_offs]   ;next digit                                
    jmp _skip_space_loop

_pre_scan_int_loop:          
    xor bx, bx
    
_scan_int_loop:
    mov si, [g_str_offs]    ;on digit position
    cmp byte ptr row_str[si], CR       ;end of str
    je _end_scan_int                  ;end number
    push word ptr row_str[si]
    call is_digit
    cmp ax, 1          ;if ax 1 is digit
    pop ax
    jne _end_scan_int
    
    mov ax, 10
    mul bx            ;mul our digit on 10
    jc _cant_handle_big_numbers   ;appeare perenos
    
    mov dx, word ptr row_str[si]  ;in dx our digit
    xor dh, dh
    sub dx, '0'      ;get asci as our digit
    
    add ax, dx            ;add next digit to our number
    jc _cant_handle_big_numbers
    mov bx, ax              ;remember our digit

    inc word ptr [g_str_offs] ;next digit
    jmp _scan_int_loop
    
_cant_handle_big_numbers:       ;big numbers
    print_str new_line_msg
    print_str msg_cant_handle_big_numbers
    xor ax, ax
    mov ah, 4Ch
    int 21h
             
_end_scan_int:
    mov ax, bx 
    
    pop si
    pop dx
    pop bx          
    pop bp
    ret    
scan_int endp

row_arr dw 0, 0, 0, 0, 0, 0
        dw 0, 0, 0, 0, 0, 0
        dw 0, 0, 0, 0, 0, 0
        dw 0, 0, 0, 0, 0, 0
        dw 0, 0, 0, 0, 0, 0

sum_row dw 0, 0, 0, 0, 0

stack_top dw 0
stack dw 0, 0, 0, 0, 0, 0

g_str_offs dw 0

_mxln_row db 201   
row_str_len db 0
row_str db 200 dup(0)

input_row_msg db "input row: ", '$'
msg_input db "input number: ", 0ah, 0dh, '$'
msg_cant_handle_big_numbers db "can't handle big numbers", 0ah, 0dh, '$'
new_line_msg db 0ah, 0dh, '$'
msg_sum_overflow db "sum overflow", 0ah, 0dh, '$'     
String		db	5 dup (?),'$'  
StringEnd	=	$-1            
    
end start