.model small
.stack 100h

.data
    file_name db 80 dup(0)
    sourceId dw 0  
    
    numbers dw 0
    
    string_word db 80 dup('$')
  
    
    buffer db ?
    
    found_msg db 'found searchable word in line',0dh,0ah,'$'
    enter_string_word db 'enter word to search:',0dh,0ah,'$'
    new_line db 0dh,0ah,'$'
    
    count db 'number of lines contains searchable word:$'
    no_lines db 'number of lines which have searchable word in this file$' 
    
    end_file_msg db 'end file!',0dh,0ah,'$'
    files_error_msg db 'error create or open files',0dh,0ah,'$'
    files_success_msg db 'Success open and create files',0dh,0ah,'$'
    cmd_error_msg db 'error cmd arguments',0dh,0ah,'$' 
    cmd_success_msg db 'success copy file name',0dh,0ah,'$'
    finish_program db 'end program',0dh,0ah,'$'
.code
.386
; вывод
print macro out_str
    mov ah,9
    mov dx,offset out_str
    int 21h
endm
;               получаем имя файла из консоли
getFileName proc
    pusha                                                ;getFileName 
    
    mov di,offset file_name        ;offet  адрес
    
    xor ax,ax
    xor cx,cx 
    
    mov si,80h   ;80ш смд
    mov cl,es:[si] ;si в нем 80ш
    cmp cl,0 
    je cmdError
    
    add si,2 ;доуиеуои 2 стало 82h
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh; proverka na konets str
    je cmdError
    
copyCmd:
    mov ds:[di],al ; заполняем массив file_name
    inc di
    inc si
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh
    je endCmd
    loop copyCmd
cmdError:
    print cmd_error_msg 
    jmp to_end
endCmd: 
    mov byte ptr ds:[di],'$'
    print cmd_success_msg
    popa
    ret      
getFileName endp   
 
enterString proc                                            ;enterString
    pusha 
    print enter_string_word
    xor ax,ax
    mov ah,0ah ;chtenie str
    mov dx,offset string_word
    int 21h
    print new_line
    popa
    ret
enterString endp

; открываем файл
openFile proc                                    ;openFile
    pusha     
    ; data файл
    xor cx,cx
    mov dx,offset file_name
    mov ah,3dh;открываем существующий файл
    mov al,0;только для чтения
    int 21h
    jc error_in_files   
    
    mov sourceId,ax
    jmp success_in_files
    
error_in_files:
    print files_error_msg     
    jmp to_end
success_in_files:
    print files_success_msg    
    popa
    ret
openFile endp


main_read_file proc                                     ;main_read_file
    pusha 
str1:
    mov si,2    
skip_endl:;пропуск endl    
    mov ah,3fh;chtenir 1btyte
    mov bx,sourceId 
    mov cx,1 
    mov dx,offset buffer 
    int 21h
    cmp ax,cx ; после прерывания 21 в ax помещается количество считанных байт
    jnz end_file_found 
    cmp buffer,0ah 
    je skip_endl
    cmp buffer,0dh 
    je skip_endl  

start_check:;проверка на пробелы
    cmp buffer,' '
    jne x;если не пробел
    
    mov ah,3fh
    mov bx,sourceId
    mov cx,1
    mov dx,offset buffer
    int 21h      
    cmp ax,cx
    jnz end_file_found ; дошли до конца   
    jmp start_check
x:;найден первый символ не пробел
    mov bl,buffer
    cmp string_word[si],bl ; сравниваем считанный символ с введённым словом
    jnz bad_symbol ; jump not zero отнимает 1ый операнд от второго, 0 - значит они равны 
good_symbol:
    ;читаем след символ
    mov ah,3fh
    mov bx,sourceId
    mov cx,1
    mov dx,offset buffer
    int 21h     
    cmp ax,cx
    jnz end_file_found     
    inc si
    cmp string_word[si],0dh ; дошли ли до конца введённого слово 
    je final_check    ; проверяем закончилось ли слово в файле
    jmp x      ; сначала считываем, а потом проверяем символы       
bad_symbol:
    mov si,2
a:
    cmp buffer,0dh ; сравнение на конец  строки
    je new_line_found
   ;читаем екст символ
    mov ah,3fh
    mov bx,sourceId
    mov cx,1
    mov dx,offset buffer
    int 21h  
    cmp ax,cx
    jnz end_file_found    
    cmp buffer,' '
    je start_check
    jmp a  
final_check:
    cmp buffer,' ' ; если слово закончено переходим на found
    je found
    cmp buffer,0dh ; если слово закончено переходим на found
    je found
    jmp bad_symbol
found:
    
    inc numbers
    
to_new_str:
    mov ah,3fh
    mov bx,sourceId
    mov cx,1
    mov dx,offset buffer
    int 21h  
    cmp ax,cx
    jnz end_file_found
    cmp buffer,0ah
    je str1
    jmp to_new_str
new_line_found:  
    
    jmp str1     
end_file_found:
    print end_file_msg       
end_main_read_file:         
    popa                                    
    ret
main_read_file endp    


to_string proc ;в ax наше число                         ; to_string
    pusha
    xor cx,cx
    mov bx,10

again:
    xor dx,dx
    div bx
    inc cx
    push dx
    cmp ax,0
    jne again
loop_output:
    pop dx
    add dx,30h
    cmp dx,39h
    jle no_more_9
    add dx,7
no_more_9:
    mov ah,2
    int 21h
    loop loop_output
    popa  
    ret
to_string endp


start:
    mov ax,@data
    mov ds,ax
    
    
    call getFileName
    
    
    print file_name 
    print new_line
    
       
    call enterString ;
    
    call openFile;открываем наш файл
       
    call main_read_file
    
    mov ax,numbers
    cmp ax,0
    je no_this_lines 
    
    print count  
    mov ax,numbers;  
    call to_string 
    print new_line     
    jmp to_end
    
no_this_lines:
    print no_lines
    print new_line    
to_end: 
    print finish_program
    mov ah,4ch
    int 21h
end start