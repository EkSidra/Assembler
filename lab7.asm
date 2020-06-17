.model      small
.stack      100h

.data
    startMessage      db "start", '$'
    applicationError  db "Application start error", '$'
    negativeExit      db "Enter correct number", '$'
    allocatingError   db "Allocating error", '$'
    badFileMessage    db "Cannot open file", 0dh, 0ah, '$'
    badArguments      db "Bad cmd arguments", 0dh, 0ah, '$'
    fileError         db "Error while opening file", '$'
    badFileName       db "Bad file name", '$'
    strNotFound       db "String whith given number not found", '$'
    progEnd           db "Programm ended", '$'
    skobka1           db "(", '$'
    skobka2           db ")", '$'
    
    iterations        db 0
    fileid            dw 0
    argsSize          db ?
    args              db 120 dup('$')
    path              db 256 dup(?)
    stringNumber      db 0
    endl              db 13, 10, '$'
    symbol            db 0
    numOfCurrentLine  db 1
    n                 db 1			
    buffer            db 100 dup(0)
    
    fileName          db 256 dup(0)
    applicationName   db 256 dup(0)
    env               dw 0
    dsize=$-startMessage       
.code
.386
printString proc  
    push    bp
    mov     bp, sp   
    pusha 
    
    mov     dx, [ss:bp+4+0]     
    mov     ax, 0900h
    int     21h 
    
    mov     dx, offset endl
    mov     ax, 0900h
    int     21h  
    
    popa
    pop     bp      
    ret 
endp

outStr macro str
    mov ah, 09h
    mov dx, offset str
    int 21h
    
    mov dl, 0Ah             
    mov ah, 02h           
    int 21h 
	
    mov dl, 0Dh             
    mov ah, 02h             
    int 21h     
endm 


processingArgs proc
    xor ax, ax
    xor bx, bx
    mov bl, 10
    xor cx, cx 
    mov si, offset args
processingArgsIter: 
    lodsb 
    cmp al, ' '
    je processingArgsIterEnd
    cmp al, '0'
    jb processingArgsError
    cmp al, '9'
    ja processingArgsError
    sub al, '0'
    xchg ax, cx
    mul bl     
    add ax, cx
    xchg ax, cx
    cmp cx, 00FFh
    ja badRange
    jmp processingArgsIter
processingArgsIterEnd:
    mov iterations, cl
    xor cx, cx
    processingArgsNum: 
    lodsb 
    cmp al, ' '
    je processingArgsNumEnd
    cmp al, '0'
    jb processingArgsError
    cmp al, '9'
    ja processingArgsNum
    sub al, '0'
    xchg ax, cx
    mul bl     
    add ax, cx
    xchg ax, cx
    cmp cx, 00FFh
    ja badRange
    jmp processingArgsNum
processingArgsNumEnd:
    mov stringNumber, cl
    
    mov di, offset filename
processingArgsFilename:    
    cmp byte ptr [si], 0Dh
    je processingEnded
    movsb
    jmp processingArgsFilename    
processingArgsError: 
    outStr badArguments
    call    exit
    ret
processingEnded:
    ret               
processingArgs endp

badFileNameCall proc
    outStr badFileName
    call    exit
endp

exit proc
    outStr progEnd
    mov     ax, 4c00h
    int     21h
endp

badRange:
    outStr negativeExit
    call    exit
ret


applicationStartError:
    outStr applicationError
    call    exit
ret


allocateMemory proc
    push    ax
    push    bx 
    
    clc
    mov     bx, ((csize/16)+1)+((dsize/16)+1)+32
    mov     ah, 4Ah
    int     21h 

    jc      allocateMemoryError
    jmp     allocateMemoryEnd 

    allocateMemoryError:
        outStr allocatingError
        call    exit  
      
    allocateMemoryEnd:
        pop     bx
        pop     ax
        ret
endp

loadAndRun proc
    mov     ax, 4B00h
    lea     dx, path
    lea     bx, env
    int     21h
    jc applicationStartError 
    
    ret
endp

fileErrorCall:
    outStr fileError
    call    exit
ret



readSymbol proc 
    pusha
    mov dx, offset symbol
    mov bx, fileid
    mov cx, 1
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je clearCall
    cmp symbol, 0Ah
    je lineEnded
    popa
    ret
clearCall:
    outstr strNotFound 
    call clear 
lineEnded:
    inc numOfCurrentLine   
    popa  
    ret
readSymbol endp      

findlLine proc
findLineBegLoop:
    mov bl, stringNumber 
    cmp numOfCurrentLine, bl
    je findLineBegEnd  
    call readSymbol
    jmp findLineBegLoop
findLineBegEnd: 
    ret         
findlLine endp 
    
    
readLine proc
    mov ah,3Fh		
	mov cx,100
	mov bx, fileid	
	mov dx,OFFSET Buffer
	int 21h 
	
	
    pusha
    mov si, offset buffer
    mov di, offset path
continueReading:
    movsb
    cmp byte ptr [si], 0Ah
    je endt
    cmp byte ptr [si], 0Dh
    je endt
    cmp byte ptr [si], ' '
    je endt
    jmp continueReading
endt:
    popa
    ret
readLine endp   

clear proc
clearM:    
    mov ah, 3Eh
    mov bx, fileid
    int 21h  
    call exit
clear endp 


badArgumentsCall:
    outStr badArguments
    call    exit
ret


start proc
    ;mov ax, 03
    ;int 10h
    ;outStr startMessage
    call    allocateMemory
    
    mov ax, @data
    mov es, ax    
    xor cx, cx
	mov cl, ds:[80h]			
	mov argsSize, cl 		
	mov si, 82h                                                                
	mov di, offset args 
	rep movsb
	mov ds, ax
	call processingArgs 
	
	mov ax, 3D00h
    mov dx, offset fileName
    int 21h
    jc badFileNameCall 
    mov fileid, ax
    
    call findlLine
    call readLine
    xor dx, dx
    cmp dl, iterations
    jne load
    call exit
load:        
    call loadAndRun
    mov dl, n
    add dl, 1
    inc n
    cmp dl, iterations
    jne load
    call exit
endp

csize = $ - printString

end start