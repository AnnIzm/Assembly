.model tiny 
org 100h

.data
message db "Hello, friend!",0Dh,0Ah, '$'    
  
.code
start: 
    mov ah,9
    lea dx, message
    int 21h
    ret 
end start