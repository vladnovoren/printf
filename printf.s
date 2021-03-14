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
; функции записи числа в буфер в различных системах счисления
; eax - число, которое нужно вывести
; edi - смещение, по которому нужно записать число
; cl - двоичный логарифм системы счисления
;--------------------------------------------------------------------------------
out_bin_deg_notation:
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
        shr eax, cl
        and bl, ch
        cmp edi, printf_buffer_size
        jae after_print_symb
        cmp bl, 10
        jb not_a_letter
        add bl, 39
not_a_letter:
        add bl, '0'
        mov [edi], bl
after_print_symb:
        cmp edx, 0
        jne write_bin_loop
        ret


;-------------------------------------------------------------------------------
; принтэфчик
; в стеке аргументы
; сначала форматная строка, потом аргументы
;-------------------------------------------------------------------------------
_printf:
        mov ebp, esp
        add ebp, 4
        mov esi, [ebp]
        add ebp, 4
        dec esi
        



global  func

func:
        mov eax, 1234 ; число, которое хотим вывести
        mov edi, printf_buffer ; указываем буфер, в который записывать число
        mov ecx, 3 ; 
        call out_bin_deg_notation

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
