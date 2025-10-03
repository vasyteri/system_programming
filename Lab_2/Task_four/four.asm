format ELF64

public _start
public exit
public print_symbol

section '.data' writable
    place db ?
    N dq 1019734634
    

section '.text' executable
  _start:
    mov rax, [N]
    mov rcx, 10
    xor rbx, rbx
    xor rsi, rsi
    iter1:
      xor rdx, rdx
      div rcx
      add rsi, rdx
      push rsi
      inc rbx
      cmp rax, 0
    jne iter1

    mov rax, rsi
    xor rbx, rbx
    iter2:
      xor rdx, rdx
      div rcx
      add rdx, '0'
      push rdx
      inc rbx
      cmp rax, 0
    jne iter2
      
    iter3:
      pop rax
      call print_symbol
      dec rbx
      cmp rbx, 0
    jne iter3

 mov rax, 0xA
 call print_symbol
 call exit


print_symbol:
     push rbx
     push rdx
     push rcx
     push rax
     push rax

     
     mov eax, 4
     mov ebx, 1
     pop rdx
     mov [place], dl
     mov ecx, place
     mov edx, 1
     int 0x80


     pop rax
     pop rcx
     pop rdx
     pop rbx
     ret

exit:
    mov eax, 1
    mov ebx, 0
    int 0x80