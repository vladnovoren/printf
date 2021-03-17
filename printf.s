section .text


; навигция по стеку
;--------------------------------------------------------------------------------
; помещает в eax следующий аргумент, если это число
;--------------------------------------------------------------------------------
get_next_num_arg:
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
        dec ecx
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
; esi, edi, ecx
;--------------------------------------------------------------------------------
string_handler:
        call str_len
        add edi, ecx
        dec edi
        call check_buf_overflow
        inc edi
        sub edi, ecx
        rep movsb
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
        call check_buf_overflow
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
cnt_n_ranks_dec: ; в ecx кладем кол-во разрядов
        xor edx, edx
        div ebx
        inc ecx
        cmp eax, dword 0
        jne cnt_n_ranks_dec

        add edi, ecx
        dec edi
        call check_buf_overflow
        inc edi

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
        call check_buf_overflow
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
                 dd err_non_frmt_char_handler
                 dd binary_handler
                 dd character_handler
                 dd decimal_handler
        times 10 dd err_non_frmt_char_handler
                 dd octal_handler
        times 3  dd err_non_frmt_char_handler
                 dd string_handler
        times 4  dd err_non_frmt_char_handler
                 dd hexadecimal_handler
