.model small          
.stack 100h 
 
.data
    counter dw 0  
    ten dw 10h
    number1	dw ? 
    number2	dw ?         
    input_first db    'Enter the  number #1 (-8000h...+7FFFh):$'
    input_second db   10,13, 'Enter the  number #2:$'  
    and_msg db 10, 13, 'Result of logic AND:$'   
    or_msg db 10, 13,'Result of logic OR:$'    
    xor_msg db 10, 13,'Result of logic XOR:$' 
    not_msg db  10,13,'Result of logic NOT:$'                    
    input_error_message db 10, 13,'Incorrect number!$'              
    
.code
macro print_message out_str 
    mov ah,09h
    mov dx,offset out_str
    int 21h               
endm

macro exit_app
   mov ax,4C00h
   int 21h  
endm 

input_number proc 
    xor bp, bp
    xor bx, bx
    xor dx, dx 
loop1:
    mov ah, 01h
    int 21h  
    inc counter 
    
    cmp al, 0Dh
    je finish_input 
    cmp al, '-'
    je check_minus 
    jmp isNumber
next_1: 
    sub al, '0'
    xor ah, ah
    mov cx, ax 
    xor ax, ax
    mov ax, bx 
    mul ten  
    jc error
    add ax, cx
    mov bx, ax 
    jmp check_overflow 
next_A: 
    sub al, 'A' 
    add al, 10
    xor ah, ah
    mov cx, ax 
    xor ax, ax
    mov ax, bx 
    mul ten 
    jc error
    add ax, cx
    mov bx, ax 
    jmp check_overflow 
next_symbol:
    sub al, 'a' 
    add al, 10
    xor ah, ah
    mov cx, ax 
    xor ax, ax
    mov ax, bx 
    mul ten 
    jc error
    add ax, cx
    mov bx, ax 
    jmp check_overflow   
    ret
input_number endp
 
check_minus proc 
    test bp, bp 
    jnz error 
    test bx, bx
    jnz error
    mov bp, 1
    jmp loop1 
    ret
check_minus endp
              
finish_input proc
loop3:
    cmp counter, 1
    je error
    mov counter, 0
    test bp, bp
    jz ex
    neg bx  
    jns error   
ex:
   mov ax, bx
   ret
finish_input endp  
  
error:
    print_message input_error_message
    exit_app
      
check_overflow proc
    cmp bp, 1
    jne check7FFF 
    cmp bx, 8000h
    je loop3
    ja  error
    jmp loop1
    check7FFF:
    cmp bx, 7FFFh
    je loop3
    ja  error
    jmp loop1
    ret
check_overflow endp 
 
isNumber proc
    cmp al, '0'
    je next_1
    cmp al, '1'
    je next_1
    cmp al, '2'
    je next_1
    cmp al, '3'
    je next_1
    cmp al, '4'
    je next_1
    cmp al, '5'
    je next_1
    cmp al, '6'
    je next_1
    cmp al, '7'
    je next_1
    cmp al, '8'
    je next_1
    cmp al, '9'
    je next_1
    cmp al, 'A'
    je next_A
    cmp al, 'B'
    je next_A
    cmp al, 'C'
    je next_A
    cmp al, 'D'
    je next_A
    cmp al, 'E'
    je next_A
    cmp al, 'F'
    je next_A 
    cmp al, 'a'
    je next_symbol
    cmp al, 'b'
    je next_symbol
    cmp al, 'c'
    je next_symbol
    cmp al, 'd'
    je next_symbol
    cmp al, 'e'
    je next_symbol
    cmp al, 'f'
    je next_symbol 
    jmp error
    ret
isNumber endp
 
show_number proc 
    xor cx, cx
    xor dx, dx
    xor bx, bx
    test ax, ax  
    jns nextNumber
    mov bx, ax 
    mov ah, 02h
    mov dl, '-'
    int 21h  
    mov ax, bx
    neg ax
nextNumber:
    xor dx, dx
    div ten
    jmp check_show
check_show:
    cmp dx, 10
    jae stack_symbolA 
stack_symbol0:
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz nextNumber  
    jmp showSymbolFromStack
stack_symbolA:
    add dl, 'A'
    sub dl, 10
    push dx
    inc cx
    test ax, ax
    jnz nextNumber  
    jmp showSymbolFromStack        
showSymbolFromStack:
    mov ah, 02h
    pop dx
    int 21h
    loop showSymbolFromStack 
    ret    
show_number endp 
         
start:
    mov ax,@data       
    mov ds,ax     
    print_message input_first 
    call input_number
    mov number1, ax  
    
    print_message input_second
    call input_number
    mov number2, ax
        
    print_message not_msg 
    mov ax, number1
    not ax 
    call show_number

    print_message and_msg
    mov ax, number1
    mov bx, number2
    and ax, bx
    call show_number
                         
    print_message xor_msg
    mov ax, number1
    mov bx, number2
    xor ax, number2  
    call show_number
    
    print_message or_msg
    mov ax, number1
    mov bx, number2
    or ax, bx    
    call show_number     
    exit_app
end start 
