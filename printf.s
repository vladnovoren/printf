section .text


;--------------------------------------------------------------------------------
; возвращает в edx длину строки
; esi - смещение строки
;--------------------------------------------------------------------------------
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
; функции записи в буфер числа в системах счисления, являющихся степенью двойки
; eax - число, которое нужно вывести
; edi - смещение, по которому нужно записать число
; cl - двоичный логарифм системы счисления
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
        cmp edi, printf_buffer_size
        ja buf_overflow_handler ; если число вылезает за конец буфера, не печатаем его и переходим к концу printf
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
; вывод неотрицательного числа в десятичной системе счисления
; eax - число, которое нужно вывести
; edi - позиция, с которой выводить число
;-------------------------------------------------------------------------------
write_non_neg_dec_notation_to_buf:
        push eax ; сохраняем в стеке число

        mov ebx, dword 10
cnt_n_ranks_dec: ; в ecx кладем кол-во разрядов
        xor edx, edx
        div ebx
        inc ecx
        cmp eax, dword 0
        jne cnt_n_ranks_dec

        add edi, ecx
        cmp edi, printf_buffer_size
        ja buf_overflow_handler

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






;-------------------------------------------------------------------------------
; jmp-table для форматных символов, не включая %
;-------------------------------------------------------------------------------
jmp_table:
                 dd err_non_frmt_char_handler
                 dd binary_handler
                 dd character_handler
                 dd decimal_handler
        times 10 dd err_non_frmt_char_handler
                 dd octal_handler
        times 3  dd err_non_frmt_char_handler
                 dd string_handler
        times 4  dd err_non_frmt_char_handler
                 dd hexodecimal_handler


err_non_frmt_char_handler:
character_handler:
decimal_handler:
octal_handler:
string_handler:
hexodecimal_handler:

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
        mov ebp, esp
        add ebp, 4
        mov esi, [ebp]
        add ebp, 4
        dec esi
printf_loop:
        cmp [esi], byte '%'
        je procent_handler

        cmp [esi], byte 0
        jne non_frnt_char_handler

end_of_printf:

        ret
          


;-------------------------------------------------------------------------------
; binary
;-------------------------------------------------------------------------------
binary_handler:




;-------------------------------------------------------------------------------
; обработчики форматных символов
;-------------------------------------------------------------------------------
procent_handler:
        inc esi
        cmp [esi], byte '%'
        je non_frnt_char_handler

        cmp [esi], byte 'x'
        ja err_non_frmt_char_handler

        cmp [esi], byte 'b'
        jb err_non_frmt_char_handler

        cmp [esi], byte 0
        ; je ret


        xor eax, eax
        mov al, [esi]
        sub eax, 'a'
        xor ebx, ebx
        mov ebx, dword [jmp_table + 4 * eax]
        jmp ebx


;-------------------------------------------------------------------------------
; обработчик неформатных символов
;-------------------------------------------------------------------------------
non_frnt_char_handler:
        push dword [esi]
        inc esi
        pop dword [edi]
        inc edi
        jmp printf_loop


;-------------------------------------------------------------------------------
; обработка переполнения буфера
;-------------------------------------------------------------------------------
buf_overflow_handler:
        mov ecx, buf_overflow_msg
        mov edx, buf_overflow_msg_len
        call print_str
        xor eax, eax
        inc eax
        jmp end_of_printf





global  _start

_start:
        mov eax, -7 ; число, которое хотим вывести
        xor eax, -1
        inc eax
        mov edi, printf_buffer ; указываем буфер, в который записывать число
        mov ecx, 1 ;
        call write_non_neg_dec_notation_to_buf
        ; call write_bin_deg_notation_to_buf

        mov ecx, printf_buffer
        mov edx, dword [printf_buffer_size]
        call print_str

        mov eax, 1
        mov ebx, 0
        int 0x80

section .data

hello_str db "hello"


printf_buffer times 256 db 0
printf_buffer_size dd $ - printf_buffer
buf_overflow_msg db "error: _printf buffer overflow", 0x0a
buf_overflow_msg_len dd $ - buf_overflow_msg
