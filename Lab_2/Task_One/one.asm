format ELF64
public _start
public exit

section '.bss' writable
my db 0xA, "S=QLQGaThNTMUkUIfNqqbSWtpNV"
newline db 10, 0

section '.text' executable
_start:
    mov rcx, my
    add rcx, 27
    .iter:
        mov rax, 4
        mov rbx, 1

        mov rdx, 1
        int 0x80

        dec rcx
        cmp rcx, my
        jne .iter

    mov rax, 4
    mov rbx, 1

    mov rcx, newline
    mov rdx, 1
    int 0x80

    call exit

exit:
  mov rax, 1
  xor rbx, rbx
  int 0x80