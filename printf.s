section .text


; навигция по стеку
;--------------------------------------------------------------------------------
; помещает в eax следующий аргумент, если это число
;--------------------------------------------------------------------------------
get_next_arg:
        mov eax, dword [ebp]
        add ebp, 4
        ret


; строки
;--------------------------------------------------------------------------------
; возвращает в ecx длину строки без учета терминирующего нуля
; esi - смещение строки
;--------------------------------------------------------------------------------
str_len:
        xor ecx, ecx
str_len_loop:
        inc ecx
        cmp [esi + ecx], byte 0
        jne str_len_loop
        ret


;--------------------------------------------------------------------------------
; запись строки в буфер
; esi - адрес строки
; edi - место в буфере, с которого начать запись
; destrlist:
; eax, edi, ecx
;--------------------------------------------------------------------------------
string_handler:
        push esi
        call get_next_arg
        mov esi, eax
        call str_len
        rep movsb
        pop esi
        ret


;--------------------------------------------------------------------------------
; печатает строку
; ecx - адрес строки
; edx - длина строки
; destrlist:
; eax, ebx
;--------------------------------------------------------------------------------
print_str:
        mov eax, 4
        mov ebx, 1
        int 0x80
        ret



; вывод чисел
;--------------------------------------------------------------------------------
; функции записи в буфер числа в системах счисления, являющихся степенью двойки
; eax - число, которое нужно вывести
; edi - смещение, по которому нужно записать число
; cl - двоичный логарифм системы счисления
; destrlist:
; eax, ebx, ecx, edx, edi
;--------------------------------------------------------------------------------
write_bin_deg_notation_to_buf:
        xor ebx, ebx ; помещаем в ch маску для разрядов (cl единичек в младших битах)
        inc ebx
        shl ebx, cl
        dec ebx
        mov ch, bl

        mov ebx, eax
        xor edx, edx
cnt_n_ranks_bin_deg: ; в edx помещаем кол-во разрядов в числе
        inc edx
        shr ebx, cl
        cmp ebx, 0
        jne cnt_n_ranks_bin_deg

        push edx ; сохраняем кол-во разрядов в числе
        add edi, edx
write_bin_loop: ; запись в буфер
        dec edi
        dec edx
        mov bl, al
        shr eax, cl
        and bl, ch
        cmp bl, 10
        jb not_a_letter
        add bl, 39
not_a_letter:
        add bl, '0'
        mov [edi], bl
        cmp edx, 0
        jne write_bin_loop
        pop edx
        add edi, edx
        ret


;-------------------------------------------------------------------------------
; запись неотрицательного числа в десятичной системе счисления в буфер
; eax - число, которое нужно вывести
; edi - позиция, с которой выводить число
; destrlist:
; eax, ebx, ecx, edx, edi
;-------------------------------------------------------------------------------
write_non_neg_dec_notation_to_buf:
        push eax ; сохраняем в стеке число

        mov ebx, dword 10
        xor ecx, ecx
cnt_n_ranks_dec: ; в ecx кладем кол-во разрядов
        xor edx, edx
        div ebx
        inc ecx
        cmp eax, dword 0
        jne cnt_n_ranks_dec

        add edi, ecx
        pop eax ; возвращаем число в eax
write_dec_loop:
        xor edx, edx
        div ebx
        dec edi
        add edx, '0'
        mov [edi], dl
        cmp eax, dword 0
        ja write_dec_loop

        add edi, ecx
        ret


;--------------------------------------------------------------------------------
; вывод произвольного числа в десятичной системе счисления в буфер
; eax - число, которое нужно вывести
; edi - позиция в буфере, с которой нужно начать вывод
; destrlist:
; eax, ebx, ecx, edx, edi
;--------------------------------------------------------------------------------
write_dec_notation_to_buf:
        cmp eax, 0
        jge positive
        mov [edi], byte '-'
        inc edi
        xor eax, dword -1
        inc eax
positive:
        call write_non_neg_dec_notation_to_buf
        ret



;-------------------------------------------------------------------------------
; jmp-table для форматных символов, не включая %
;-------------------------------------------------------------------------------
jmp_table:
                 dd printf_loop
                 dd binary_handler
                 dd character_handler
                 dd decimal_handler
        times 10 dd printf_loop
                 dd octal_handler
        times 3  dd printf_loop
                 dd string_handler
        times 4  dd printf_loop
                 dd hexadecimal_handler


;-------------------------------------------------------------------------------
; принтэфчик
; в стеке аргументы
; сначала форматная строка, потом аргументы
; текущая позиция в строке будет лежать в esi
; в eax возвращает код ошибки:
; 0 - all clear
; 1 - buf_overflow 
;-------------------------------------------------------------------------------
_printf:
        mov edi, printf_buffer
        mov ebp, esp
        add ebp, 4
        mov esi, [ebp]
        add ebp, 4
        dec esi

printf_loop:
        inc esi
try_non_frmt_char:
        cmp [esi], byte '%'
        je percent
        cmp [esi], byte 0
        je end_of_printf
        call non_frmt_char_handler
        jmp printf_loop
percent:
        inc esi
        check_if_percent:
                cmp [esi], byte '%'
                jne check_if_after_x
                call non_frmt_char_handler
                jmp printf_loop
        check_if_after_x:
                cmp [esi], byte 'x'
                jbe check_if_before_a
                jmp printf_loop
        check_if_before_a:
                cmp [esi], byte 'a'
                jae check_if_term_null
                jmp printf_loop
        check_if_term_null:
                cmp [esi], byte 0
                je end_of_printf
        xor eax, eax
        mov al, [esi]
        sub eax, 'a'
        mov ebx, dword [jmp_table + 4 * eax]
        cmp ebx, printf_loop
        je printf_loop
        call ebx
        jmp printf_loop

end_of_printf:
        mov ecx, printf_buffer
        mov edx, dword [printf_buffer_size]
        call print_str
        ret


;-------------------------------------------------------------------------------
; binary
; destrlist:
; eax, ebx, ecx, edx, edi
;-------------------------------------------------------------------------------
binary_handler:
        xor ecx, ecx
        inc ecx
        call get_next_arg
        call write_bin_deg_notation_to_buf
        ret


;-------------------------------------------------------------------------------
; character
;-------------------------------------------------------------------------------
character_handler:
        call get_next_arg
        mov [edi], eax
        ret


;-------------------------------------------------------------------------------
; decimal
; destrlist:
; eax, ebx, ecx, edx, edi
;-------------------------------------------------------------------------------
decimal_handler:
        call get_next_arg
        call write_dec_notation_to_buf
        ret


;-------------------------------------------------------------------------------
; octal
; destrlist:
; eax, ebx, ecx, edx, edi
;-------------------------------------------------------------------------------
octal_handler:
        mov ecx, 3
        call get_next_arg
        call write_bin_deg_notation_to_buf
        ret


;-------------------------------------------------------------------------------
; hexadecimal
; destrlist:
; eax, ebx, ecx, edx, edi
;-------------------------------------------------------------------------------
hexadecimal_handler:
        mov ecx, 4
        call get_next_arg
        call write_bin_deg_notation_to_buf
        ret

;-------------------------------------------------------------------------------
; обработчик неформатных символов
;------------------------------------------------------------------------------
non_frmt_char_handler:
        mov al, [esi]
        mov [edi], al
        inc edi
        ret

global  _start

_start:
        push 7
        push 7
        push 7
        push 7
        push love
        push frmt_str
        call _printf
        pop eax
        pop eax
        pop eax
        pop eax
        pop eax
        pop eax

        mov eax, 1
        mov ebx, 0
        int 0x80

section .data

hello_str db "hello", 0

love db "LOVE", 0
frmt_str db "I %s %d %x %o %b", 0
hello db "hello", 10, 0
printf_buffer times 256 db 0
printf_buffer_size dd $ - printf_buffer

