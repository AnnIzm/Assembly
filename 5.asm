.model  small  
.stack 100h

.data
error_of_opening db "Error of file opening", 0Dh, 0Ah, '$'
word_error db "Error: word bigger than 50 bytes", 0Dh, 0Ah, '$'
wrong_args db "Wrong arguments", 0Dh, 0Ah, '$'
result_string db "Count of string with your word: $" 
file_name db 126 dup (0)
file_descriptor dw ?
buffer db ?
file_size dd 0	
cur_pointer	dd 0	
word_temp db 126 dup (0)
word_temp_size dw 0
word_scan db 50 dup (?)
counter dw 0
string_flag db 0

.code  	
start:	
	mov ax, @data
	mov	ds, ax
	call scan_cmd
	call get_word_size
	call open_file
	mov di, 0
	mov	string_flag, 1
main_loop:
	call get_char
	cmp	buffer, 32 
	je cmp_words_sign
	cmp	buffer, 09 
	je cmp_words_sign
	cmp	buffer, 13 
	je cmp_words_sign
	cmp	buffer, 10 
	je end_of_string
	jmp	write_char_in_buffer	
end_of_string:
	mov	string_flag, 1
	jmp	next_iteration		
cmp_words_sign:
	call cmp_words
	mov	di, 0
	jmp	next_iteration
write_char_in_buffer:
	cmp	di, 50
	je	error_word_length
	mov	al, buffer
	mov	word_scan + di, al
	inc	di
next_iteration:	
	call get_cur_pointer
	mov	ax, word ptr cur_pointer + 2
	cmp	ax, word ptr file_size + 2
	jb	main_loop
	mov	ax, word ptr cur_pointer
	cmp	ax, word ptr file_size
	jb	main_loop
	call cmp_words
	call close_file
	mov	ah, 09h
	mov	dx, offset result_string
	int	21h
	mov	ax, counter
	call outputInt
	mov	ax, 4C00h
	int	21h
error_word_length:	
	mov	ah, 09h
	mov	dx, offset word_error
	int	21h
	mov	ax, 4C00h
	int	21h   
	
;--------------procedures--------------; 

cmp_words proc
	cmp	di, word_temp_size
	jne	exit_cmp_words
	mov	di, 0
cmp_words_loop:
	mov	al, word_scan + di
	cmp	al, word_temp + di
	jne	exit_cmp_words
	inc	di
	cmp	di, word_temp_size
	jl	cmp_words_loop
	cmp	string_flag, 1
	jne	exit_cmp_words
	inc	counter
	mov	string_flag, 0
exit_cmp_words:
	ret
cmp_words endp

get_word_size proc 
	mov		di, 0
get_word_size_loop:
	inc	di
	inc	word_temp_size
	cmp	word_temp + di, 0
	jne	get_word_size_loop
	cmp	word_temp_size, 50
	jg	get_word_size_error
	ret
get_word_size_error:	
	mov	ah, 09h
	mov	dx, offset word_error
	int	21h
	mov	ax, 4C00h
	int	21h
get_word_size endp

get_char proc
	mov	ah, 3Fh
	mov	bx, file_descriptor
	mov	cx, 1
	mov	dx, offset buffer
	int	21h
	ret
get_char endp

get_cur_pointer proc
	mov	ah, 42h
	mov	bx, file_descriptor
	xor	cx, cx
	xor	dx, dx
	mov	al, 01h
	int	21h
	mov	word ptr cur_pointer + 2, dx
	mov	word ptr cur_pointer, ax
	ret
get_cur_pointer endp

open_file proc
	mov	dx, offset file_name
	mov	ah, 3Dh
	mov	al, 2
	int 21h
	jc error_of_file_opening
	mov	file_descriptor, ax
	
	mov	ah, 42h
	mov	bx, file_descriptor
	xor	cx, cx
	xor	dx, dx
	mov	al, 02h
	int	21h
	mov	word ptr file_size + 2, dx
	mov	word ptr file_size, ax
	
	mov	ah, 42h
	mov	al, 00h
	mov	bx, file_descriptor
	xor	cx, cx
	xor	dx, dx
	int	21h
	ret
	error_of_file_opening:
	mov	ah, 09h
	mov	dx, offset error_of_opening
	int	21h
	mov	ax, 4C00h
	int	21h
open_file endp

close_file proc
	mov	ah, 3Eh
	mov	bx, file_descriptor
	int 21h  ethm
	ret
close_file endp

scan_cmd proc		
	mov	bx, 80h
	xor	ch ,ch	
	mov	cl, es:[bx]
	cmp	cl, 1
	jle	exit_scan_cmd
	mov	di, 81h
skip_spaces:
	cmp	byte ptr es:[di], 0Dh
	je	exit_scan_cmd
	cmp	byte ptr es:[di], ' '
	jne	end_skip_spaces
	inc	di
	jmp	skip_spaces
end_skip_spaces:
	mov	bx, 0	
scan_file_name:
	cmp	byte ptr es:[di], 0Dh
	je	exit_scan_cmd
	cmp	byte ptr es:[di], ' '
	je	skip_spaces1
	mov	dl, es:[di]
	mov	file_name + bx, dl
	inc	bx
	inc	di
	jmp	scan_file_name
skip_spaces1:
	cmp	byte ptr es:[di], 0Dh
	je	exit_scan_cmd
	cmp	byte ptr es:[di], ' '
	jne	end_skip_spaces1
	inc	di
	jmp	skip_spaces1
end_skip_spaces1:
	mov	bx, 0
scan_word_temp:
	cmp	byte ptr es:[di], 0Dh
	je	end_scan_word_temp
	cmp	byte ptr es:[di], ' '
	je	end_scan_word_temp
	mov	dl, byte ptr es:[di]
	mov	word_temp + bx, dl
	inc	bx
	inc	di
	jmp		scan_word_temp	
end_scan_word_temp:	
	ret
exit_scan_cmd:
	mov	ah, 09h
	mov	dx, offset wrong_args
	int	21h	
	mov	ax, 4C00h
	int 21h
scan_cmd endp

outputInt proc
    push ax
    push bx
    push cx
    push dx  
    xor cx, cx
    mov bx, 10 
step1:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz step1
    mov ah, 02h
step2:
    pop dx
    cmp dl, 9
    jbe step3
    add dl, 7
step3:
    add dl, '0'
    int 21h
    loop step2   
    pop dx
    pop cx
    pop bx
    pop ax
    ret 
outputInt endp
end start       