.model small
.stack 100h   

.data
message db "Hello, friend!",0Dh,0Ah, '$'
    
.code
start:
    mov ax, @data
    mov ds, ax 
    mov ah, 9   
    lea dx, message
    int 21h
    mov ax, 4C00h
    int 21h    
end start