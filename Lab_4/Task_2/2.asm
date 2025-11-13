
format ELF64
public _start
public exit
include '/workspaces/system_programming/func.asm'
include '/workspaces/system_programming/help.asm'

section '.bss' writable
    buffer rb 256
    n dq 0
    sum dq 0

section '.text' executable
_start:
    ; Ввод числа n
    mov rsi, buffer
    call input_keyboard

    ; Преобразование строки в число
    call atoi
    mov [n], rax      ; сохраняем n
    
    mov rcx, 1        ; начинаем с k = 1
    mov qword [sum], 0 ; обнуляем сумму

loop_start:
    ; Вычисляем k^2
    mov rax, rcx
    imul rax, rax     ; rax = k * k
    
    ; Определяем знак: (-1)^(k+1)
    ; Нечетные k: +, четные k: -
    test rcx, 1       ; проверяем четность k
    jz even_k         ; если четный (ZF=1) - минус
    
    ; Нечетный k - плюс
    add [sum], rax
    jmp next_iter
    
even_k:
    ; Четный k - минус  
    sub [sum], rax

next_iter:
    ; Переход к следующему k
    inc rcx
    cmp rcx, [n]
    jle loop_start    ; пока k <= n

    ; Выводим итоговую сумму
    mov rax, [sum]
    call print_int
    call new_line

    call exit