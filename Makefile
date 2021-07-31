printf_o: printf.s
	nasm -f elf -F dwarf -g -l printf.lst printf.s -o printf.o
printf: printf_o
	ld -m elf_i386 -o printf.out printf.o