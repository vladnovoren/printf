section .text


; возвращает в edx длину строки
; esi - смещение строки
str_len:
        xor edx, edx
        dec edx
str_len_loop:
        inc edx
        cmp [esi + edx], byte 0
        jne str_len_loop
        ret

;--------------------------------------------------------------------------------
; печатает строку
; ecx - адрес строки
; edx - длина строки
;--------------------------------------------------------------------------------
print_str:
        mov eax, 4
        mov ebx, 1
        int 0x80
        ret

;--------------------------------------------------------------------------------
; функции записи числа в буфер в различных системах счисления
; eax - число, которое нужно вывести
; edi - смещение, по которому нужно записать число
; cl - двоичный логарифм системы счисления
;--------------------------------------------------------------------------------
write_bin:
        xor ebx, ebx ; помещаем в ch маску для разрядов (cl единичек в младших битах)
        inc ebx
        shl ebx, cl
        dec ebx
        mov ch, bl

        mov ebx, eax
        xor edx, edx
cnt_n_ranks: ; в edx помещаем кол-во разрядов в числе
        inc edx
        shr ebx, cl
        cmp ebx, 0
        jne cnt_n_ranks
 
        add edi, edx
write_bin_loop: ; запись в буфер
        dec edi
        dec edx
        mov bl, al
        and bl, ch
        cmp edi, printf_buffer_size
        jae write_bin_loop
        mov [edi], byte bl
        cmp edx, 0 ; если символы закончились, выхоим из цикла
        je write_bin_loop_end
        jmp write_bin_loop
write_bin_loop_end:
        ret


;-------------------------------------------------------------------------------
; принтэфчик
;-------------------------------------------------------------------------------
_printf:
        mov esi, [esp + 4]
        dec esi
printf_loop:
        inc esi
        cmp [esi], byte '%'




global  func

func:
;         mov eax, 1234 ; число, которое хотим вывести
;         mov edi, printf_buffer ; указываем буфер, в который записывать число
;         mov ecx, 1 ; binary
;         call write_bin

        mov [printf_buffer], byte 'A'
        mov ecx, printf_buffer        
        xor edx, edx
        mov edx, dword [printf_buffer_size]
        call print_str
        ret

segment .data

printf_buffer times 256 db 0
printf_buffer_size dw $ - printf_buffer
