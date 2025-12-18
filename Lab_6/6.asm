format ELF64

public _start

extrn initscr
extrn timeout
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn keypad
extrn stdscr
extrn move
extrn getch
extrn clear
extrn addch
extrn refresh
extrn endwin
extrn usleep
extrn attron
extrn curs_set
extrn attroff

section '.bss' writable
direction dq 0
x dq 0
y dq 0
max_x dq 0
max_y dq 0
speed dq 10000
current_color_pair dq 1
speed_level dq 1

section '.data' writable
current_char dq ' '

section '.text' executable

_start:
    call initscr
    mov rdi, [stdscr]

    call getmaxx
    mov [max_x], rax
    dec qword [max_x]
    call getmaxy
    mov [max_y], rax
    dec qword [max_y]

    xor rdi, rdi
    call curs_set
    call noecho
    call raw
    call refresh

    call start_color

    mov rdx, 1
    mov rsi, 0
    mov rdi, 1
    call init_pair

    mov rdx, 5
    mov rsi, 0
    mov rdi, 2
    call init_pair

    mov qword [x], 0
    mov qword [y], 0
    mov qword [direction], 1
    mov qword [current_color_pair], 1
    mov qword [speed_level], 1
    mov qword [speed], 50000

mloop:
    mov rdi, [y]
    mov rsi, [x]
    call move

    mov rdi, [current_color_pair]
    shl rdi, 8
    call attron

    mov rdi, [current_char]
    call addch

    mov rdi, [current_color_pair]
    shl rdi, 8
    call attroff

    call refresh

    mov rdi, [speed]
    call usleep

    mov rdi, 0
    call timeout
    call getch

    cmp rax, 'g'
    je .change_speed
    cmp rax, 'a'
    je next

    mov rax, [direction]
    cmp rax, 1
    je .move_right

.move_left:
    dec qword [x]
    cmp qword [x], 0
    jge .check_movement

    mov qword [x], 0
    mov qword [direction], 1
    jmp .move_down

.move_right:
    inc qword [x]
    mov rax, [x]
    cmp rax, [max_x]
    jle .check_movement

    mov rax, [max_x]
    mov [x], rax
    mov qword [direction], 0

.move_down:
    inc qword [y]

.check_movement:
    mov rax, [y]
    cmp rax, [max_y]
    jle mloop

    mov rax, [current_color_pair]
    cmp rax, 1
    jne .switch_to_color1

    mov qword [current_color_pair], 2
    jmp .restart_position

.switch_to_color1:
    mov qword [current_color_pair], 1

.restart_position:
    mov qword [x], 0
    mov qword [y], 0
    mov qword [direction], 1
    jmp mloop

.change_speed:
    mov rax, [speed_level]
    inc rax
    cmp rax, 6
    jl .set_speed_level
    mov rax, 1
.set_speed_level:
    mov [speed_level], rax

    cmp rax, 1
    je .speed1
    cmp rax, 2
    je .speed2
    cmp rax, 3
    je .speed3
    cmp rax, 4
    je .speed4
    cmp rax, 5
    je .speed5

.speed1:
    mov qword [speed], 200000
    jmp mloop
.speed2:
    mov qword [speed], 100000
    jmp mloop
.speed3:
    mov qword [speed], 50000
    jmp mloop
.speed4:
    mov qword [speed], 10000
    jmp mloop
.speed5:
    mov qword [speed], 1000
    jmp mloop

next:
    call endwin
    mov rax, 60
    xor rdi, rdi
    syscall