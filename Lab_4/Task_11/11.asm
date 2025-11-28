format ELF64

include '/workspaces/system_programming/func.asm'
include '/workspaces/system_programming/help.asm'

section '.bss' writeable
    buffer rb 256

section '.data' writeable
    msg_judges     db 'Введите общее количество судей (N): ', 0
    msg_vote       db 'Голос судьи (1=Да, 0=Нет): ', 0
    msg_yes        db ' голосов "Да"', 0
    msg_no         db ' голосов "Нет"', 0
    msg_result_yes db 'Решение принято: Да', 0
    msg_result_no  db 'Решение принято: Нет', 0

section '.text' executable
public _start

_start:
    mov rsi, msg_judges
    call print_str
    
    mov rsi, buffer     
    call input_keyboard
    
    call atoi
    mov rbp, rax        

    xor rcx, rcx        
    xor rbx, rbx        

.vote_loop:
    cmp rcx, rbp
    jge .show_results   

    mov rsi, msg_vote
    call print_str
    
    mov rsi, buffer     
    call input_keyboard
    

    call atoi            
    
    cmp rax, 1
    jne .next_vote      
    inc rbx             

.next_vote:
    inc rcx             
    jmp .vote_loop

.show_results:


    mov rax, rbp       
    xor rdx, rdx
    mov rdi, 2
    div rdi             
    inc rax             
    mov rdi, rax        

    mov rax, rbp        
    sub rax, rbx        
    mov rdx, rax        

    mov rax, rbx        
    call print_int
    mov rsi, msg_yes
    call print_str
    call new_line

    mov rax, rdx        
    call print_int
    mov rsi, msg_no
    call print_str
    call new_line
    


    cmp rbx, rdi
    jge .decision_yes   ; Если votes_yes >= (N/2 + 1)

.decision_no:
    mov rsi, msg_result_no
    call print_str
    call new_line
    jmp .exit

.decision_yes:
    mov rsi, msg_result_yes
    call print_str
    call new_line

.exit:
    call exit
