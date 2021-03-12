printf_o:
	nasm -f elf -l printf.lst printf.s -o printf.o
main_o:
	gcc -c main.c -o main.o -m32
main_out: printf_o main_o 
	gcc main.o printf.o -o main.out -m32
