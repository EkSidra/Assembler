    .model small
    .stack 100h  
    .data  
N_str db ?
N_dec dw ? 
K_str db ?
K_dec dw ? 
EPB dw 0000h
    dw offset cmd,0h           
    dw 005Ch,0h,006Ch,0h
program_name db ?  
cmd db 7Dh
    db " /?"    
buffer db ?
file_name db ?
open_file_error db "open file error",0Ah,0Dh,"$"  
read_file_error db "read file error",0Ah,0Dh,"$"
program_start_message db "program starts",0Ah,0Dh,"$"    
string_length dw 0h                   
cmd_status_message db "not enough command line parameters",0Ah,0Dh,"$"
dssize = $-N_str    
.code 
.386             
str_to_dec proc     
        mov ax,0h
        mov bx,0Ah   
positive_:               
        cmp ds:[si],'$'
        je end_        
        mul bx         
        sub ds:[si],30h
        add al,ds:[si]  
        inc si
        jmp positive_  
end_:                
        ret  
str_to_dec endp 

start: 
    mov ah,4Ah
    mov bx,((program_length/16)+1)+((dssize/16)+1)+32; shr 4h + 1h		;number of bytes for allocate
    int 21h   
    mov ax,@data
    mov ds,ax       
    lea dx,program_start_message
    mov ah,9h
    int 21h
    mov di,80h
    mov cl,es:[di]
    cmp cl,4h
    jle cmd_status                        
    mov di,81h
    mov al,' '
    repne scasb         
    mov bx,0h

get_K:
    cmp es:[di],' '
    je _set_string_end_
    mov al,es:[di]
    mov K_str[bx],al
    inc bx    
    inc di
    jmp get_K         

_set_string_end_:
    mov K_str[bx],'$'   
    lea si,K_str
    call str_to_dec
    mov K_dec,ax
    inc di          
    mov bx,0h
       
get_file_name:
    cmp es:[di],' '
    je set_string_end
    mov al,es:[di]
    mov file_name[bx],al
    inc bx    
    inc di
    jmp get_file_name         

set_string_end:
    mov file_name[bx],0h   
    mov ah,3Dh
    mov al,0h        
    lea dx,file_name
    int 21h   
    jc open_file_error_label 
    mov si,0h  
    mov bx,ax 
               
file_read:   
    mov cx,1h
    lea dx,buffer
    mov ah,3Fh
    int 21h
    jc read_file_error_label
    jmp skip
    
check: 
    dec K_dec
    jmp file_read 
skip:     
    cmp K_dec,0h
    je _continue_   
    cmp ax,0h
    je read_file_error_label
    cmp buffer,0Ah
    je check
    jne file_read
    
_continue_:
    cmp buffer,0Ah
    je break              
    mov dl,buffer
    mov program_name[si],dl 
    inc si
    cmp ax,0h
    jne file_read
break:  
    mov ah,3Eh
    int 21h         
    mov program_name[si-1h],'.'
    mov program_name[si],'E'
    mov program_name[si+1h],'X'
    mov program_name[si+2h],'E'
    mov program_name[si+3h],0h                 
    mov bx,0h    
    inc di          
    mov bx,0h            
    
get_N:
    cmp es:[di],0Dh
    je set_string_end_
    mov al,es:[di]
    mov N_str[bx],al
    inc bx    
    inc di
    jmp get_N
    
set_string_end_:
    mov N_str[bx],'$'
    lea si,N_str        
    call str_to_dec
    mov N_dec,ax       
    mov ax,cs
    mov word ptr EPB+4h,ax				;segment cmdline
    mov word ptr EPB+8h,ax			;segment first FCB
    mov word ptr EPB+0Ch,ax        	;segment second FCB
    mov cx,N_dec  
    
program_execution:           
    mov ax,4B00h
    lea dx,program_name
    lea bx,EPB   			;block EPB         
    int 21h
    loop program_execution 
    jmp exit    
    
open_file_error_label:
    lea dx,open_file_error
    mov ah,9h
    int 21h
    jmp exit   
    
read_file_error_label:
    lea dx,read_file_error
    mov ah,9h
    int 21h 
    mov ah,3Eh
    int 21h
    jmp exit   

cmd_status:
    lea dx,cmd_status_message
    mov ah,9h
    int 21h 
    jmp exit

exit:    
    mov ax,4C00h
    int 21h
    program_length equ $ - str_to_dec  
    end start