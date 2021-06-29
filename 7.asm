.model small
.stack 100h 

.data

crlf db 0Dh, 0Ah,'$'
 
buffer db 126 dup ('$')
args db 0
number_of_program_starts db 0
number_of_digits_in_number db 0  
offset_cmd_lenght equ 80h
offset_cmd_line equ 81h
address dw 00h
epb      dw 0
cmd_off  dw ?
cmd_seg  dw ?
fcb1     dd 0            
fcb2     dd 0

error_empty_cmd db "Error: command line is empty", 0Ah, 0Dh, '$'
error_not_enough_params db "Error: not enough parameters", 0Ah, 0Dh, '$'
error_invalid_input db "Error: invalid input", 0Ah, 0Dh, '$'
error_overflow db "Error: overflow", 0Ah, 0Dh, '$'
error_memory_destroyed  db "Error: memory control unit destroyed", 0Ah, 0Dh, '$'
error_invalid_address db "Error: ES contains an invalid address", 0Ah, 0Dh, '$'
error_out_of_memory db "Error: out of memory", 0Ah, 0Dh, '$' 
error_not_found db "Error: file not found", 0Ah, 0Dh, '$'
error_access_denied db "Error: file access denied", 0Ah, 0Dh, '$'
error_wrong_format db "Error: wrong format", 0Ah, 0Dh, '$' 
error_wrong_surroundings db "Error: wrong surroundings", 0Ah, 0Dh,'$'

output_message macro message   
    mov dx, offset message
    mov ah, 9
    int 21h
endm

data_segment_size = $ - crlf

.code 

main:
    mov ax, @data
    mov ds, ax     
    cld 
writing_args:
    xor cx, cx 
    mov cl, es:offset_cmd_lenght
    cmp cl, 1
    jle empty_cmd  
    mov cx, -1
    mov di, offset_cmd_line 
find_parametres: 
    cmp args, 2
    je read_cmd
    mov al, 20h
    repz scasb ;find !byte from al in di
    dec di
    push di
    inc args  
    mov si, di 
    call switch_ds_es   
scan_parametrs:
    lodsb ;to al from cmd
    cmp al, 0Dh
    je switch
    cmp al, 20h ;space  
    jne scan_parametrs  
    mov di, si  
    dec si
    push si 
    call switch_ds_es 
    jmp find_parametres  
	
;---------------------Errors---------------------	
empty_cmd:
    output_message error_empty_cmd  
    jmp end_program
not_enough_params:
	output_message error_not_enough_params  
    jmp end_program
;------------------------------------------------ 

switch:
    dec si
    push si
    call switch_ds_es
read_cmd: 
    cmp args, 2
    jb not_enough_params 
    call switch_ds_es
    pop cx 
    mov es:address, cx ;end of lab7.exe
    pop si ;end of 1.com
    sub cx, si
    call switch_ds_es
    cmp cx, 3 
    ja overflow
    call switch_ds_es
    push cx 
    mov di, offset buffer
    rep movsb ;from si to di 
    call switch_ds_es
string_to_int:
    xor ax, ax 
    pop cx
    lea si, buffer
    xor bx, bx
    mov bl, 10
number_calculation:  
    mov dl, byte ptr[si]
    cmp dl,'0'
    jb not_number
    cmp dl,'9'
    ja not_number  
    sub dl, '0' 
    cmp cl, 1
    je last_digit 
	add al, dl
    jc overflow 
    mul bl
    jc overflow 
    inc si  
last_digit:
    loop number_calculation  
    add al, dl
    jc overflow
    cmp ax, 0
    je not_number
    mov number_of_program_starts, al ;number of iterations
    jmp name_program 
	
;---------------------Errors---------------------	
not_number:
    output_message error_invalid_input     
    jmp end_program   
overflow:
    output_message error_overflow     
    jmp end_program 
;------------------------------------------------   	

name_program:         
    call switch_ds_es
    pop cx
    pop si 
    sub cx, si 
    mov di, offset buffer
    rep movsb ;from si to di 
    mov es:di, 0
    call switch_ds_es
	
    ;free memory after end of program  
    mov ah,4Ah   
	;size in paragraphs + 1
    mov bx,((segment_code_size/16)+1)+256/16+((data_segment_size/16)+1)+256/16; ;!!!!!!!!!!!!!!!!!!
    int 21h
    jc memory_error
    jmp open_program 
	
;---------------------Errors---------------------    
memory_error:
    cmp ax, 7
    je memory_destroyed 
    cmp ax, 8 
    je out_of_memory
    cmp ax, 9 
    je invalid_address    
memory_destroyed:
    output_message error_memory_destroyed
    jmp end_program   
out_of_memory:    
   output_message error_out_of_memory
   jmp end_program      
invalid_address:
   output_message error_invalid_address 
   jmp end_program 
;------------------------------------------------   
        
open_program:         
    xor cx, cx
    mov cl, number_of_program_starts
cycle_open_program:
    push cx       
    mov dx, address
    sub dx, offset_cmd_line
    mov cl, es:offset_cmd_lenght
    sub cl, dl
    mov di, address
    dec di
    mov es:di, cl  
    mov cmd_off, di
    mov cmd_seg, es
    push es 
    mov ax, @data
    mov es, ax       
    mov ax, 4b00h        
    lea dx, buffer     
    lea bx, epb     
    int 21h
    jc errors
    pop es
    pop cx
    loop cycle_open_program
    jmp end_program
	
;---------------------Errors--------------------- 
errors:
   cmp ax, 02h
   je file_not_found
   cmp ax, 05h
   je file_access_denied
   cmp ax, 08h
   je out_of_memory
   cmp ax, 0Ah
   je wrong_surroundings
   cmp ax, 0Bh
   je wrong_format  
file_not_found:
   output_message error_not_found
   jmp end_program   
file_access_denied:
   output_message error_access_denied
   jmp end_program   
wrong_surroundings:
   output_message error_wrong_surroundings
   jmp end_program   
wrong_format:
   output_message error_wrong_format 
   jmp end_program
;------------------------------------------------

end_program:
    mov ax,4c00h
    int 21h 

switch_ds_es proc ;change places of ds and es
    mov ax,ds
    mov bx,es
    mov ds,bx
    mov es,ax
    ret
switch_ds_es endp

segment_code_size = $ - main  
 
end main