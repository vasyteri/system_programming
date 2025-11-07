format ELF64

public create_queue
public free_queue
public enqueue
public dequeue
public is_empty
public fill_random
public get_odd_numbers
public remove_even_numbers
public count_numbers_ending_with_1
public print_queue
public ranint

section '.data' writable
f  db "/dev/urandom", 0
newline db 10, 0
space db " ", 0
empty_msg db "Queue is empty", 10, 0

section '.bss' writable
number rq 1
temp_buffer rb 32
heap_start rq 1
current_brk rq 1

section '.text' executable


create_queue:
    push rdi

    mov rdi, 24
    call malloc
    test rax, rax
    jz .error

    mov qword [rax], 0      
    mov qword [rax + 8], 0  
    mov qword [rax + 16], 0 
    jmp .done

.error:
    xor rax, rax

.done:
    pop rdi
    ret


free_queue:
    push rdi rsi rbx r12

    mov r12, rdi
    test r12, r12
    jz .done

    mov rbx, [r12]  

.free_nodes:
    test rbx, rbx
    jz .free_struct

    mov rdi, rbx
    mov rbx, [rbx + 8]  

    push rbx
    call free
    pop rbx

    jmp .free_nodes

.free_struct:
    mov rdi, r12
    call free

.done:
    pop r12 rbx rsi rdi
    ret


enqueue:
    push rdi rsi rbx r12 r13

    mov r12, rdi  
    mov r13, rsi  

    mov rdi, 16
    call malloc
    test rax, rax
    jz .done

    mov [rax], r13       
    mov qword [rax + 8], 0 

    mov rbx, [r12 + 8]   
    test rbx, rbx
    jz .first_node

    mov [rbx + 8], rax   
    jmp .update_rear

.first_node:
    mov [r12], rax      

.update_rear:
    mov [r12 + 8], rax   

    mov rbx, [r12 + 16]
    inc rbx
    mov [r12 + 16], rbx

.done:
    pop r13 r12 rbx rsi rdi
    ret


dequeue:
    push rdi rbx r12

    mov r12, rdi  ; Queue* q

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .empty

    mov rbx, [r12]       
    mov rax, [rbx]       

    mov rcx, [rbx + 8]   
    mov [r12], rcx   

    test rcx, rcx
    jnz .update_size
    mov qword [r12 + 8], 0 

.update_size:
    mov rcx, [r12 + 16]
    dec rcx
    mov [r12 + 16], rcx

    push rax
    mov rdi, rbx
    call free
    pop rax
    jmp .done

.empty:
    xor rax, rax

.done:
    pop r12 rbx rdi
    ret


is_empty:
    mov rax, [rdi]      
    test rax, rax
    setz al
    movzx rax, al
    ret


fill_random:
    push rdi rsi rbx r12 r13 r14

    mov r12, rdi  
    mov r13, rsi  

    xor r14, r14

.fill_loop:
    cmp r14, r13
    jge .done

    call ranint
    mov rdi, r12
    mov rsi, rax
    and rsi, 0xFFF
    inc rsi
    call enqueue

    inc r14
    jmp .fill_loop

.done:
    pop r14 r13 r12 rbx rsi rdi
    ret


get_odd_numbers:
    push rdi rsi rbx r12 r13 r14

    mov r12, rdi  

    call create_queue
    mov r13, rax 
    test r13, r13
    jz .done

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]  

.process_loop:
    test rbx, rbx
    jz .done

    mov rsi, [rbx]  
    test rsi, 1
    jz .next_node

    mov rdi, r13
    call enqueue

.next_node:
    mov rbx, [rbx + 8]
    jmp .process_loop

.done:
    mov rax, r13
    pop r14 r13 r12 rbx rsi rdi
    ret


remove_even_numbers:
    push rdi rsi rcx r12 r13

    mov r12, rdi  
    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    call create_queue
    mov r13, rax
    test r13, r13
    jz .done

.process_loop:
    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .transfer_back

    mov rdi, r12
    call dequeue
    mov rsi, rax

    test rsi, 1
    jz .skip_odd

    mov rdi, r13
    call enqueue

.skip_odd:
    jmp .process_loop

.transfer_back:
.transfer_loop:
    mov rdi, r13
    call is_empty
    test rax, rax
    jnz .cleanup

    mov rdi, r13
    call dequeue
    mov rsi, rax

    mov rdi, r12
    call enqueue
    jmp .transfer_loop

.cleanup:
    mov rdi, r13
    call free_queue

.done:
    pop r13 r12 rcx rsi rdi
    ret


count_numbers_ending_with_1:
    push rdi rbx r12 r13

    mov r12, rdi
    xor r13, r13

    mov rdi, r12
    call is_empty
    test rax, rax
    jnz .done

    mov rbx, [r12]  

.count_loop:
    test rbx, rbx
    jz .done

    mov rax, [rbx]
    mov rcx, rax
    xor rdx, rdx
    mov r8, 10
    div r8
    
    cmp rdx, 1
    jne .not_ending_with_1
    
    inc r13

.not_ending_with_1:
    mov rbx, [rbx + 8]
    jmp .count_loop

.done:
    mov rax, r13
    pop r13 r12 rbx rdi
    ret

print_queue:
    push rdi rbx r12

    mov r12, rdi

    mov rdi, r12
    call is_empty
    test rax, rax
    jz .print_elements

    mov rdi, empty_msg
    call print_string
    jmp .done

.print_elements:
    mov rbx, [r12]

.print_loop:
    test rbx, rbx
    jz .end_print

    mov rdi, [rbx]
    call print_number

    mov rdi, space
    call print_string

    mov rbx, [rbx + 8]
    jmp .print_loop

.end_print:
    mov rdi, newline
    call print_string

.done:
    pop r12 rbx rdi
    ret


ranint:
    push rdi rsi rdx r8 r9 r10 r11

    mov rax, 228
    mov rdi, 1
    mov rsi, number
    syscall

    mov rax, [number + 8]

    pop r11 r10 r9 r8 rdx rsi rdi
    ret


print_string:
    push rdi rsi rdx rax rcx r11

    mov rsi, rdi
    xor rdx, rdx
.length_loop:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .length_loop

.print:
    mov rax, 1
    mov rdi, 1
    syscall

    pop r11 rcx rax rdx rsi rdi
    ret


print_number:
    push rdi rsi rdx rcx r8 r9 r10 r11

    mov rax, rdi
    lea rdi, [temp_buffer + 31]
    mov byte [rdi], 0
    mov r8, 10

.convert_loop:
    dec rdi
    xor rdx, rdx
    div r8
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz .convert_loop

    call print_string

    pop r11 r10 r9 r8 rcx rdx rsi rdi
    ret


malloc:
    push rbx rcx rdx rsi rdi r8 r9 r10 r11

    mov rbx, rdi

    mov rax, 12
    xor rdi, rdi
    syscall
    mov [current_brk], rax

    mov rdi, rax
    add rdi, rbx
    mov rax, 12
    syscall

    cmp rax, [current_brk]
    je .error

    mov rax, [current_brk]
    jmp .done

.error:
    xor rax, rax

.done:
    pop r11 r10 r9 r8 rdi rsi rdx rcx rbx
    ret


free:
    ret