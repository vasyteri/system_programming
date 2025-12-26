format ELF64

NUM_COUNT = 891
BUFFER_SIZE = NUM_COUNT * 4
SORTED_SIZE = NUM_COUNT * 4
TEMP_BUFFER_SIZE = 64

SYS_MMAP = 9
SYS_MUNMAP = 11
SYS_FORK = 57
SYS_WAIT4 = 61
SYS_EXIT = 60
SYS_NANOSLEEP = 35
SYS_WRITE = 1

MAP_PRIVATE = 0x02
MAP_ANONYMOUS = 0x20
PROT_READ = 1
PROT_WRITE = 2

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
    numbers_ptr dq ?        
    sorted_ptr dq ?         
    temp_buffer_ptr dq ?    

section '.text' executable
public _start

macro syscall1 number {
    mov rax, number
    syscall
}

allocate_memory:
    push rdi
    push rsi
    push rdx
    push r10
    push r8
    push r9

    xor rdi, rdi
    mov rsi, [rsp + 40]    ; размер
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_PRIVATE or MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9

    mov rax, SYS_MMAP
    syscall

    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    ret

free_memory:
    mov rax, SYS_MUNMAP
    syscall
    ret

; Функция вывода строки
print_string_sync:
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
    mov rax, SYS_WRITE
    mov rdi, 1          
    mov rsi, rsi
    mov rdx, rdx
    syscall

    pop rcx
    pop rdi
    pop rdx
    pop rsi
    ret

; Функция вывода числа
print_number_sync:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    mov rbx, 10
    mov rsi, [temp_buffer_ptr]
    add rsi, TEMP_BUFFER_SIZE - 1
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
    call print_string_sync

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

; Генератор случайных чисел 
random_limited:
    push rbx
    push rcx
    push rdx

    mov rax, [random_state]
    
    ; Xorshift алгоритм
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
    and rax, 0x7FFFFFFF
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
    mov rax, SYS_NANOSLEEP
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
    
    ; Проверяем четность
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
    call print_string_sync

    ; Копируем массив для сортировки
    mov rsi, [numbers_ptr]
    mov rdi, [sorted_ptr]
    mov rcx, NUM_COUNT
.copy_loop1:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop1

    ; Сортировка пузырьком
    mov rcx, NUM_COUNT
    dec rcx
    jz .sort_done1

.outer_loop1:
    mov rbx, rcx
    mov rdi, [sorted_ptr]

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
    dec rcx
    jnz .outer_loop1

.sort_done1:
    ; Находим медиану
    mov rax, NUM_COUNT
    mov rbx, 2
    xor rdx, rdx
    div rbx
    
    test rdx, rdx
    jnz .odd_count1
    
    ; Четное количество: среднее двух средних
    mov rsi, [sorted_ptr]
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
    mov rsi, [sorted_ptr]
    shl rax, 2
    add rsi, rax
    mov edi, [rsi]

.print_median1:
    call print_number_sync
    
    lea rdi, [msg_newline]
    call print_string_sync
    
    ; Освобождаем память в дочернем процессе
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory
    
    mov rdi, [sorted_ptr]
    mov rsi, SORTED_SIZE
    call free_memory
    
    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Процесс 2: Количество простых чисел
process2:
    mov rdi, timespec2
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process2]
    call print_string_sync

    mov rsi, [numbers_ptr]
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
    dec rcx
    jnz .process2_loop

    mov rdi, rbx
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync
    
    ; Освобождаем память в дочернем процессе
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory
    
    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Процесс 3: Количество чисел кратных пяти
process3:
    mov rdi, timespec3
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process3]
    call print_string_sync

    mov rsi, [numbers_ptr]
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
    dec rcx
    jnz .process3_loop

    mov rdi, rbx
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync
    
    ; Освобождаем память в дочернем процессе
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory
    
    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Процесс 4: Среднее арифметическое (округленное до целого)
process4:
    mov rdi, timespec4
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process4]
    call print_string_sync

    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT
    xor rax, rax        
    xor rdx, rdx        

.process4_loop:
    mov ebx, [rsi]
    add rax, rbx
    adc rdx, 0          
    add rsi, 4
    dec rcx
    jnz .process4_loop

    ; Вычисляем среднее
    mov rbx, NUM_COUNT
    div rbx            
    
    ; Округляем
    mov r8, rdx         
    add r8, r8         
    cmp r8, rbx        
    jb .no_round
    inc rax             
.no_round:
    
    mov rdi, rax
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync
    
    ; Освобождаем память в дочернем процессе
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory
    
    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

_start:
    ; Выделяем память для массивов
    mov rdi, BUFFER_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [numbers_ptr], rax

    mov rdi, SORTED_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [sorted_ptr], rax

    mov rdi, TEMP_BUFFER_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [temp_buffer_ptr], rax

    ; Заполняем массив случайными числами (от 0 до 9999)
    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT

.fill_loop:
    call random_limited
    mov [rsi], eax
    add rsi, 4
    dec rcx
    jnz .fill_loop

    ; Создаем 4 процесса
    mov r15, 4          

.create_processes:
    syscall1 SYS_FORK
    
    test rax, rax
    jz .child_process
    js .fork_error
    
    push rax
    dec r15
    jnz .create_processes
    
    ; Ожидаем завершения всех дочерних процессов
.wait_loop:
    xor rdi, rdi        
    xor rsi, rsi        
    xor rdx, rdx        
    xor r10, r10        
    mov rax, SYS_WAIT4
    syscall
    
    test rax, rax
    jg .wait_loop

    ; Освобождаем память в родительском процессе
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory
    
    mov rdi, [sorted_ptr]
    mov rsi, SORTED_SIZE
    call free_memory
    
    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.child_process:
    ; Определяем номер процесса
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
    call print_string_sync
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.mmap_error:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall