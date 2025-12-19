format ELF64
АНОНИМНОЕ  ЧТО ТО ПРОЧТИ ЗАДАНИЕ И ДОБАВЬ
!!!!!!!!!!!!!!!
!!!!!!!!!!!
; Константы
NUM_COUNT = 891
BUFFER_SIZE = NUM_COUNT * 4  ; 4 байта на число

section '.data' writable
    ; Сообщения для вывода
    msg_fork_failed db "Ошибка создания процесса", 0xA, 0

    msg_process1 db "Медиана (округленная до целого): ", 0
    msg_process2 db "Количество простых чисел: ", 0
    msg_process3 db "Количество чисел кратных пяти: ", 0
    msg_process4 db "Среднее арифметическое значение (округленное до целого): ", 0
    msg_newline db 0xA, 0

    random_state dq 123456789  
    const_10000 dq 10000       

    ; Структуры для nanosleep (для упорядоченного вывода)
    timespec1:
        tv_sec1  dq 0
        tv_nsec1 dq 100000000  ; 100ms

    timespec2:
        tv_sec2  dq 0
        tv_nsec2 dq 200000000  ; 200ms

    timespec3:
        tv_sec3  dq 0
        tv_nsec3 dq 300000000  ; 300ms

    timespec4:
        tv_sec4  dq 0
        tv_nsec4 dq 400000000  ; 400ms

section '.bss' writable

    numbers rb BUFFER_SIZE
    
    temp_buffer rb 64
    sorted_array rb BUFFER_SIZE

section '.text' executable
public _start


macro syscall1 number {
    mov rax, number
    syscall
}

macro syscall3 number, arg1, arg2, arg3 {
    mov rax, number
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    syscall
}

; Функция вывода строки
print_string:
    push rsi
    push rdx
    push rdi
    push rcx

    mov rsi, rdi        
    xor rdx, rdx        
.count_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .count_length

.print:
    mov rax, 1          
    mov rdi, 1          
    syscall

    pop rcx
    pop rdi
    pop rdx
    pop rsi
    ret

; Функция вывода числа
print_number:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    mov rbx, 10
    lea rsi, [temp_buffer + 63]
    mov byte [rsi], 0
    dec rsi

    test rax, rax
    jnz .convert_loop
    mov byte [rsi], '0'
    jmp .print_result

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .convert_loop

.print_result:
    inc rsi
    mov rdi, rsi
    call print_string

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

;  генератор случайных чисел 
random:
    push rbx
    push rcx
    push rdx

    mov rax, [random_state]
    
    
    mov rbx, rax
    shl rbx, 13
    xor rax, rbx
    
    mov rbx, rax
    shr rbx, 7
    xor rax, rbx
    
    mov rbx, rax
    shl rbx, 17
    xor rax, rbx
    
    mov [random_state], rax
    
    ; Ограничиваем диапазон до 0-9999
    ; Берем остаток от деления на 10000
    xor rdx, rdx
    mov rbx, 10000
    div rbx
    mov rax, rdx        
    
    pop rdx
    pop rcx
    pop rbx
    ret

; Функция паузы через nanosleep
nanosleep:
    mov rax, 35         
    syscall
    ret

; Проверка числа на простоту
is_prime:
    push rbx
    push rcx
    push rdx
    push r8
    
    mov eax, edi        
    cmp eax, 1
    jle .not_prime
    cmp eax, 2
    je .prime
    cmp eax, 3
    je .prime
    
    
    test eax, 1
    jz .not_prime
    
    mov ecx, 3          
    mov ebx, eax
    
.check_loop:
    mov eax, ebx
    xor edx, edx
    div ecx
    test edx, edx
    jz .not_prime
    
    add ecx, 2          
    mov eax, ecx
    mul ecx
    cmp eax, ebx
    jle .check_loop
    
.prime:
    mov rax, 1
    jmp .done_check
    
.not_prime:
    xor rax, rax
    
.done_check:
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

; Процесс 1: Медиана (округленная до целого)
process1:
    mov rdi, timespec1
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process1]
    call print_string

    
    mov rsi, numbers
    mov rdi, sorted_array
    mov rcx, NUM_COUNT
.copy_loop1:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    loop .copy_loop1

    ; Сортировка пузырьком
    mov rcx, NUM_COUNT
    dec rcx
    jle .sort_done1

.outer_loop1:
    mov rbx, rcx
    mov rdi, sorted_array

.inner_loop1:
    mov eax, [rdi]
    mov edx, [rdi + 4]
    cmp eax, edx
    jle .no_swap1
    mov [rdi], edx
    mov [rdi + 4], eax
.no_swap1:
    add rdi, 4
    dec rbx
    jnz .inner_loop1
    loop .outer_loop1

.sort_done1:
    
    mov rax, NUM_COUNT
    mov rbx, 2
    xor rdx, rdx
    div rbx
    
    test rdx, rdx
    jnz .odd_count1
    
    ; Четное количество: среднее двух средних
    mov rsi, sorted_array
    shl rax, 2
    add rsi, rax
    mov eax, [rsi - 4]  
    mov edx, [rsi]      
    add eax, edx
    add eax, 1          
    shr eax, 1          
    mov edi, eax
    jmp .print_median1
    
.odd_count1:
    ; Нечетное количество: средний элемент
    mov rsi, sorted_array
    shl rax, 2
    add rsi, rax
    mov edi, [rsi]

.print_median1:
    call print_number
    
    lea rdi, [msg_newline]
    call print_string
    
    mov rax, 60
    xor rdi, rdi
    syscall

; Процесс 2: Количество простых чисел
process2:
    mov rdi, timespec2
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process2]
    call print_string

    mov rsi, numbers
    mov rcx, NUM_COUNT
    xor rbx, rbx        

.process2_loop:
    mov edi, [rsi]      
    call is_prime
    test rax, rax
    jz .not_prime2
    
    inc rbx

.not_prime2:
    add rsi, 4
    loop .process2_loop

    mov rdi, rbx
    call print_number

    lea rdi, [msg_newline]
    call print_string
    
    mov rax, 60
    xor rdi, rdi
    syscall

; Процесс 3: Количество чисел кратных пяти
process3:
    mov rdi, timespec3
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process3]
    call print_string

    mov rsi, numbers
    mov rcx, NUM_COUNT
    xor rbx, rbx        

.process3_loop:
    mov eax, [rsi]
    
    ; Проверяем кратность 5
    xor edx, edx
    mov edi, 5
    div edi
    test edx, edx
    jnz .not_multiple3
    
    inc rbx

.not_multiple3:
    add rsi, 4
    loop .process3_loop

    mov rdi, rbx
    call print_number

    lea rdi, [msg_newline]
    call print_string
    
    mov rax, 60
    xor rdi, rdi
    syscall

; Процесс 4: Среднее арифметическое (округленное до целого)
process4:
    mov rdi, timespec4
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process4]
    call print_string

    mov rsi, numbers
    mov rcx, NUM_COUNT
    xor rax, rax        
    xor rbx, rbx        
    xor r8, r8          

.process4_loop:
    mov ebx, [rsi]
    add rax, rbx
    add rsi, 4
    loop .process4_loop

    
    mov rcx, NUM_COUNT
    xor rdx, rdx
    div rcx
    
    
    mov r8, rdx         
    add r8, r8         
    cmp r8, rcx         
    jb .no_round
    inc rax             
.no_round:
    
    mov rdi, rax
    call print_number

    lea rdi, [msg_newline]
    call print_string
    
    mov rax, 60
    xor rdi, rdi
    syscall

_start:
    ; Заполняем массив случайными числами (от 0 до 9999)
    mov rsi, numbers
    mov rcx, NUM_COUNT

.fill_loop:
    call random
    mov [rsi], eax
    add rsi, 4
    dec rcx
    jnz .fill_loop

    ; Создаем 4 процесса
    mov r15, 4          

.create_processes:
    mov rax, 57         ; sys_fork
    syscall
    
    cmp rax, 0
    jl .fork_error
    je .child_process   
    
    push rax
    dec r15
    jnz .create_processes
    
    mov r15, 4
    
    
.wait_loop:
    pop rdi            
    xor rsi, rsi        
    xor rdx, rdx
    xor r10, r10
    mov rax, 61         
    syscall
    
    
    dec r15
    jnz .wait_loop

   
    mov rax, 60
    xor rdi, rdi
    syscall

.child_process:
   
    mov rax, 4
    sub rax, r15
    
    cmp rax, 1
    je process1
    cmp rax, 2
    je process2
    cmp rax, 3
    je process3
    jmp process4

.fork_error:
    lea rdi, [msg_fork_failed]
    call print_string
    mov rax, 60
    mov rdi, 1
    syscall