printf_o:
	nasm -f elf -F dwarf -g -l printf.lst printf.s -o printf.o
printf_no_main: printf_o
	ld -m elf_i386 -o printf_no_main.out printf.o
main_o:
	gcc -g -c main.c -o main.o -m32
main_out: printf_o main_o 
	gcc -g main.o printf.o -o main.out -m32
