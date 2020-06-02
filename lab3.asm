.model small
.stack 100h

.data    
    numTen dw 000Ah 
    sizeofNumber equ 2
    numStrLen equ 20
    numStr db numStrLen dup('$')
    i dw ?
    j dw ?
    rows dw 5 
    cols dw 6
    matrsize dw 30
    matr dw matrsize dup('$')    
      
    mes db "Enter matrix 5*6 value from -32768 to 32767",10,13,'$'
    mesnum db 10,13, "Enter element: ",'$' 
    messum db 10,13, "Sum of rows: ",'$'
    newLine db 13,10,'$'        
    space db " $"
    mesover db 10,13,"overflow",'$'
    mesonlynum db 10,13,"please enter numbers and signs",'$'
    invalidStr db 10,13,"invalid string",'$'
    tryAgain db 10,13,"try again",'$' 
    
    
.code  

inputNumbers proc    
    lea dx,newLine
    call outp
    lea dx,mesnum 
    call outp
repInput:
    lea dx,numStr
    call inp                        ;enter number
    lea si,numStr[2]
    call parseStr            ;analis str
    jc invalidInput
    call loadNumber             ;load number
    loop inputNumbers
ret 
invalidInput:
    lea dx,newLine
    call outp
    lea dx,invalidStr
    call outp 
    jno tryAgainOutput    ;not overflow
tryAgainOutput:              ;again enter
    lea dx,tryAgain
    call outp  
    lea dx,mesnum
    call outp
    jmp repInput
loadNumber:
    mov [di],ax
    add di,sizeofNumber
ret
inputNumbers endp


;string to number translation
parseStr proc
    xor dx,dx
    xor bx,bx
    xor ax,ax
    xor ch,ch
    jmp inHaveSign  
parseStrLoop:
    mov bl,[si]     ;in bl our number
    jmp isNumber 
validStr:
    sub bl,'0'        ;get digit
    imul numTen
    jo invalidStringOv      ;-digit
    js invalidStringOv      ;overflow
    cmp ch,1                ;negativ numb
    je negativeAdd
    add ax,bx
    js invalidStringOv
checkInvalid:
    inc si
    jmp parseStrLoop
negativeAdd:
    sub ax,bx
    jo  invalidStringOv   ;overflow
    jmp checkInvalid
isNumber:
    cmp bl,0Dh          ;end of str
    je endParsing             
    cmp bl,'0'
    jl invalidString     ;<0
    cmp bl,'9'
    jg invalidString      ;>9
    jmp validStr
inHaveSign:
    cmp [si],'-'
    je negative
    cmp [si],'+'
    jne isNullStr         ;nothing enter
    inc si
    jmp isNullStr
negative:
    mov ch,1       ;negativ number
    inc si
    jmp isNullStr
    
isNullStr:
    cmp [si],0Dh          ;enter str ended code 0dh
    je invalidString    ;error string
    jmp parseStrLoop
invalidString:
    lea dx,mesonlynum
    call outp
    xor ch,ch
    stc
ret   
invalidStringOv:
    lea dx,mesover
    call outp
    xor ch,ch
    stc           ;setting cf perenos
ret
endParsing:
    clc               ;sbros cf
    xor ch,ch
ret
parseStr endp 

findsum proc
    add ax,[si]
    jo endAdd           ;overflow
    add si,sizeofNumber
    loop findsum
endAdd:
ret
findsum endp

sumOfRows proc  
    lea dx,messum
    call outp    
    lea dx,newLine
    call outp
    mov i,0000h      ;columns
    mov j,0000h
    lea si,matr
    jmp lop2
lop1:  
    lea dx,newLine
    call outp
    inc i
    mov cx,i
    cmp cx,rows    ;end sum
    je lop2ret
lop2:
    mov cx,cols
    xor ax,ax
    call findsum
    jo overflowSum  ;overflow
    lea di,numStr[2]     ;start rou
    call numberToString    ;output number
    lea dx,numStr[2]
    call outp
    jmp lop1
lop2ret:    
ret   
overflowSum:
    lea dx,newLine
    call outp
    lea dx,mesover
    call outp
    jmp finish
sumOfRows endp

numberToString proc
    push 0
    push 0024h
    add ax,0000h      ;setting symbol
    js numberIsNegative  ;neg number
numberToStrLoop:
    xor dx,dx
    div numTen    ;div 10
    add dx,'0'      ;+ 0 for getting symbol
    push dx
    cmp ax,0h         ;end str
    jne numberToStrLoop 
movenum:
    pop ax
    cmp al,'$'          ;end str
    je endNumberToStr 
    mov [di],al           ;write number
    inc di               ;next position
    jmp movenum
endNumberToStr:
    pop ax
    mov [di],'$'
ret     
numberIsNegative:
    mov [di],'-'
    inc di
    not ax  ;inverse
    inc ax  ;add 1
    jmp numberToStrLoop
numberToString endp

inpMatr proc 
    xor cx,cx
    mov cx,matrsize  
    lea di,matr   
    call inputNumbers
    lea dx,newLine
    call outp
    ret
inpMatr endp  
      

outpMatr proc
    mov i,0000h
    mov j,0000h
    lea si,matr
    jmp loop2
loop1:
    lea dx,newLine
    call outp
    mov j,0000h
    inc i
    mov cx,i
    cmp cx,rows             ;end output
    je loop2ret
loop2:
    mov ax,[si]                     ;get number
    add si,sizeofNumber
    lea di,numStr[2]           
    call numberToString        ;write number to numStr
    lea dx,numStr[2]
    call outp
    lea dx,space                ;out probel
    call outp
    inc j
    mov cx,j
    cmp cx,cols                       ;end str
    jne loop2
    jmp loop1
loop2ret:   
ret
outpMatr endp


inp proc 
    mov ah,10
    int 21h
    ret
inp endp    
   
   
outp proc 
    mov ah,9
    int 21h
    ret
outp endp  
   

start: 

mov ax,@data
mov ds,ax   
mov es,ax
xor ax,ax

mov [numStr],numStrLen
lea dx,mes
call outp 
call inpMatr 
call outpMatr
call sumOfRows

finish:
    mov ax,4c00h
    int 21h
   ends
end start
