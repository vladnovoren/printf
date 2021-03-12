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


; печатает строку
; esi - адрес строки
print_str:
        mov eax, 4
        mov ebx, 1
        mov ecx, esi
        call str_len
        int 0x80
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
        mov esi, [esp + 4]
        call print_str
        ret


segment .data

