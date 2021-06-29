.model small
.stack 100h 

.data 
msg_input  db "Enter line: $" 
msg_line db "Line: $"
msg_output db "Result: $"
msg_error  db "Error! $"
endline db 0Dh,0Ah, '$'  
size equ 200
line db size DUP('$')

.code
output macro str 
    mov ah, 9
    mov dx, offset str
    int 21h
endm

input macro str 
    mov ah, 0Ah
    mov dx, offset str
    int 21h
endm 

start:         
    mov ax, @data
    mov ds, ax
    mov es, ax
    output msg_input 
    mov line[0], size-3  
    input line   
    cmp line[3], '$'
    je error_end
    mov di, 2

new:
    inc di
     
testing:
    cmp line[di], 31
    je new     
    cmp line[di], 0dh
    je pre_check 
    cmp line[di], 36
    je error_end      
    jmp new
     
string:
    mov ax, 3
    int 10h  
    output msg_line   
    mov ah, 9
    mov dx, offset line + 2
    int 21h  
    output endline
    output endline   
    xor bh, bh
    jmp main
    
main: 
    inc bh        
    mov ah, 9
    mov dx, offset line + 2
    int 21h 
    output endline
    xor si, si
    xor di, di
    xor ax, ax
    xor dx, dx    
    mov si, offset line + 2
    jmp word 
    
word:       
    cmp byte ptr[si], ' ' 
    jne check_compare 
    inc si
    cmp byte ptr[si], 13
    je the_end                
    jmp word
     
loop_line:
    inc si
    cmp byte ptr[si], ' '
    je check_whitespace 
    cmp byte ptr[si], 13 
    jne loop_line 
    cmp bh, 7
    je the_end
    cmp ax, 0
    jne main
    jmp the_end 
       
check_compare:
    cmp dx, 0
    jne compare 
    push si 
    mov dx, 1 
    jmp loop_line
    
check_whitespace:                            
    cmp byte ptr[si+1], ' '
    je loop_line 
    inc si 
    jmp check_compare
    
compare:
    pop di     
    push si 
    push di    
    mov cx, si
    sub cx, di
    repe cmpsb
    jl change
    pop di
    pop si
    push si 
    jmp loop_line
    
change:
    inc al
    pop di
    pop si
    xor cx, cx
    xor bl, bl
    mov dx, si   
    
loop1:  
    dec si
    inc cx
    cmp byte ptr [si-1], ' '
    je loop1
    
loop2:
    dec si
    mov bl, byte ptr [si] 
    push bx 
    inc ah
    cmp si, di
    jne loop2
    mov si, dx 
    
loop3:  
    cmp byte ptr [si], 13
    je loop4
    mov bl, byte ptr [si]
    xchg byte ptr [di], bl
    inc si
    inc di
    cmp  byte ptr [si], ' '
    jne loop3
    
loop4:
    mov byte ptr[di], ' '
    inc di
    loop loop4
    mov si, di
    mov dx, si
    dec si  
    
loop5: 
    inc si
    cmp byte ptr[si], 13
    je main
    pop bx
    mov byte ptr[si], bl
    dec ah
    cmp ah, 0
    je loop6
    jmp loop5
    
loop6:
    push dx
    mov dx, 1
    xor cx, cx
    jmp loop_line 
    
pre_check:
     xor di, di
     lea si, line
     mov si, 2
     jmp check      

check:
     inc si  
     cmp [si], '$'
     jne check
     jmp string
               
error_end:   
    mov ax, 3
    int 10h
    output msg_error
    mov ah, 4Ch
    int 21h   
    jmp endend 
        
the_end:   
    output endline  
    output msg_output 
    mov ah, 9
    mov dx, offset line + 2
    int 21h
    mov ah, 4Ch
    int 21h
    jmp endend
    
endend:
    end start