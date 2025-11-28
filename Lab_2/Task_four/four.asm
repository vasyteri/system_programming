format ELF64

public _start
public exit
public print_symbol

section '.data' writable
    place db ?
    N dq 11111111111111111111
    

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
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    
    mov [place], al      
    mov rax, 1           
    mov rdi, 1           
    mov rsi, place       
    mov rdx, 1           
    syscall
    
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

exit:
    mov rax, 60          
    mov rdi, 0           
    syscall