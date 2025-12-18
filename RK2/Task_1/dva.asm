format ELF64
public _start

extrn initscr
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn curs_set
extrn stdscr
extrn move
extrn getch
extrn addch
extrn refresh
extrn endwin
extrn timeout
extrn attron
extrn attroff
extrn COLOR_PAIR

section '.bss' writable
    xmax      dq 0
    ymax      dq 0
    xpos      dq 0
    ypos      dq 0
    direction dq 0
    color_pair dq 1
    rand_fd   dq 0
    delay_ms  dq 50

section '.data' writable
    urandom_path db '/dev/urandom', 0
    O_RDONLY equ 0

section '.text' executable

_start:
    call initscr
    call start_color
    call raw
    call noecho
    xor rdi, rdi
    call curs_set

    mov rdi, [stdscr]
    call getmaxx
    mov [xmax], rax

    mov rdi, [stdscr]
    call getmaxy
    mov [ymax], rax

    mov rdi, 1
    mov rsi, 1  ; Красный
    mov rdx, 0
    call init_pair

    mov rdi, 2
    mov rsi, 2  ; Зеленый
    mov rdx, 0
    call init_pair

    mov rdi, 3
    mov rsi, 3  ; Желтый
    mov rdx, 0
    call init_pair

    mov rdi, 4
    mov rsi, 4  ; Синий
    mov rdx, 0
    call init_pair

    mov rdi, 5
    mov rsi, 5  ; Маджента
    mov rdx, 0
    call init_pair

    mov rax, 2
    mov rdi, urandom_path
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    mov [rand_fd], rax

    mov rax, [xmax]
    shr rax, 1
    mov [xpos], rax

    mov rax, [ymax]
    shr rax, 1
    mov [ypos], rax

    mov rdi, 0
    call timeout

main_loop:
    mov rax, 0
    mov rdi, [rand_fd]
    lea rsi, [direction]
    mov rdx, 1
    syscall

    movzx rax, byte [direction]
    and al, 3

    mov rbx, [xpos]
    mov rcx, [ypos]

    cmp al, 0
    je .move_up
    cmp al, 1
    je .move_down
    cmp al, 2
    je .move_left
    cmp al, 3
    je .move_right

.move_up:
    dec rcx
    jmp .check_bounds
.move_down:
    inc rcx
    jmp .check_bounds
.move_left:
    dec rbx
    jmp .check_bounds
.move_right:
    inc rbx
    jmp .check_bounds

.check_bounds:
    xor rdx, rdx

    cmp rbx, 0
    jge .check_x_max
    mov rbx, 0
    mov rdx, 1
    jmp .check_y_check

.check_x_max:
    cmp rbx, [xmax]
    jl .check_y_check
    mov rbx, [xmax]
    dec rbx
    mov rdx, 1

.check_y_check:
    cmp rcx, 0
    jge .check_y_max
    mov rcx, 0
    mov rdx, 1
    jmp .apply_pos

.check_y_max:
    cmp rcx, [ymax]
    jl .apply_pos
    mov rcx, [ymax]
    dec rcx
    mov rdx, 1

.apply_pos:
    mov [xpos], rbx
    mov [ypos], rcx

    cmp rdx, 1
    jne .draw

    mov rax, [color_pair]
    inc rax
    cmp rax, 6
    jl .set_color_var
    mov rax, 1
.set_color_var:
    mov [color_pair], rax

.draw:
    mov rdi, [color_pair]
    call COLOR_PAIR
    mov rdi, rax
    call attron


    mov rdi, [ypos]
    mov rsi, [xpos]
    call move

    mov rdi, 'N'
    call addch


    mov rdi, [color_pair]
    call COLOR_PAIR
    mov rdi, rax
    call attroff

    call refresh

    call getch
    cmp eax, 'q'
    je .exit

    mov rdi, [delay_ms]
    call delay_ms_func

    jmp main_loop

.exit:
    mov rax, 3
    mov rdi, [rand_fd]
    syscall

    call endwin

    mov rax, 60
    xor rdi, rdi
    syscall

delay_ms_func:
    push rbp
    mov rbp, rsp

    imul rax, rdi, 1000000

    sub rsp, 16
    mov qword [rsp], 0
    mov qword [rsp+8], rax

    mov rax, 35
    mov rdi, rsp
    xor rsi, rsi
    syscall

    leave
    ret