format elf64
public _start

extrn printf

section '.data' writeable
    ; Форматы вывода
    header  db "Точность | Члены ряда | Члены дроби", 0xa, 0
    row     db "%-8.0e  | %-10d | %-10d", 0xa, 0
    fmt_math_e db "math.h e   = %.15f", 0xa, 0
    result  db "e = %.15f", 0xa, 0
    line    db "---------------------------", 0xa, 0

    ; Точности
    prec dq 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8
    count = ($ - prec) / 8
    
    ; Константы
    two    dq 2.0
    one   dq 1.0
    math_e dq 2.718281828459045
    
section '.bss' writeable
    res1   rq 1
    res2   rq 1
    c1     rd 1
    c2     rd 1
    i      rd 1
    g      rd 1
    old    rq 1
    
section '.text' executable

; Функция для вычисления через ряд
calc_series:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    ; Сохраняем точность в памяти для fcomp
    movq [rsp], xmm0
    movq [rsp+8], xmm0
    
    finit
    fld qword [two]      ; st0 = 2.0 (начальное приближение)
    fld1                 ; st0 = 1.0, st1 = 2.0
    mov dword [i], 2     ; начинаем с n=2
    mov dword [c1], 1    ; уже учли 2.0
    
.s_loop:
    ; Вычисляем 1/n!
    fild dword [i]       ; st0 = n, st1 = 1.0, st2 = текущая сумма
    fdivp st1, st0       ; st0 = 1.0/n, st1 = текущая сумма
    
    ; Проверяем точность
    fld st0              ; копируем текущий член
    fabs                 ; берем модуль
    fcomp qword [rsp]    ; сравниваем с точностью
    fstsw ax
    sahf
    jb .s_end            ; если член < точности, заканчиваем
    
    ; Добавляем к сумме
    fadd st1, st0        ; добавляем член к сумме
    inc dword [c1]       ; увеличиваем счетчик членов
    inc dword [i]        ; увеличиваем n
    
    ; Защита от бесконечного цикла
    cmp dword [c1], 900
    jl .s_loop
    
.s_end:
    fstp st0             ; удаляем оставшийся член
    fstp qword [res1]    ; сохраняем результат
    
    movq xmm0, [res1]    ; возвращаем результат в xmm0
    
    add rsp, 16
    pop rbp
    ret

; Функция для вычисления через дробь
calc_fraction:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    ; Сохраняем точность
    movq [rsp], xmm0
    
    mov dword [g], 1     ; глубина дроби
    mov dword [c2], 0    ; счетчик итераций
    
    ; Начальное приближение: 2.0
    fld qword [two]
    fstp qword [old]
    
.f_loop:
    inc dword [g]
    
    finit
    fldz                 ; начинаем с 0
    
    mov ecx, [g]
    mov [i], ecx
    
.f_inner:
    fild dword [i]       ; st0 = i, st1 = текущее значение
    fld st0              ; st0 = i, st1 = i, st2 = текущее значение
    fadd st0, st2        ; st0 = i + текущее_значение
    fdivp st1, st0       ; st1 = i / (i + текущее_значение), st0 = текущее_значение
    
    ; Меняем местами для правильного порядка
    fxch st1
    fstp st0             ; теперь st0 = новое значение
    
    dec dword [i]
    cmp dword [i], 1
    jg .f_inner
    
    ; Добавляем 2.0
    fld qword [two]
    faddp st1, st0
    fst qword [res2]
    
    cmp dword [c2], 0
    je .f_first          ; пропускаем проверку на первой итерации
    
    ; Проверяем изменение
    fld qword [old]
    fsub st0, st1
    fabs
    fcomp qword [rsp]    ; сравниваем с точностью
    fstsw ax
    sahf
    jb .f_end            ; если изменение < точности, заканчиваем
    
    fstp st0
    
.f_first:
    fld qword [res2]
    fstp qword [old]     ; сохраняем новое значение
    
    inc dword [c2]
    cmp dword [g], 50    ; ограничение глубины
    jl .f_loop
    
.f_end:
    inc dword [c2]
    fstp qword [res2]
    movq xmm0, [res2]    ; возвращаем результат
    
    add rsp, 16
    pop rbp
    ret

_start:
    ; Вывод эталонного значения
    mov rdi, fmt_math_e
    movq xmm0, [math_e]
    mov rax, 1
    call printf

    ; Заголовок таблицы
    mov rdi, header
    xor rax, rax
    call printf
    
    mov rdi, line
    call printf
    
    ; Основной цикл по точностям
    mov rbx, prec        ; адрес массива точностей
    mov r12, count       ; количество точностей
    
.main_loop:
    push rbx
    push r12
    
    ; Вычисление рядом
    movq xmm0, [rbx]
    call calc_series
    movq [res1], xmm0    ; сохраняем результат
    
    ; Вычисление дробью
    movq xmm0, [rbx]
    call calc_fraction
    movq [res2], xmm0    ; сохраняем результат
    
    ; Вывод строки
    movq xmm0, [rbx]     ; точность для форматирования
    mov esi, [c1]        ; количество членов ряда
    mov edx, [c2]        ; количество членов дроби
    mov rax, 1           ; 1 аргумент с плавающей точкой
    mov rdi, row
    call printf
    
    pop r12
    pop rbx
    
    add rbx, 8           ; следующий элемент массива (8 байт)
    dec r12
    jnz .main_loop
    
    ; Разделитель
    mov rdi, line
    xor rax, rax
    call printf
    
    ; Финальные результаты для максимальной точности (1.0e-8)
    movq xmm0, [prec + (count-1)*8]
    call calc_series
    mov rdi, result
    mov rax, 1
    call printf
    
    movq xmm0, [prec + (count-1)*8]
    call calc_fraction
    mov rdi, result
    mov rax, 1
    call printf
    
    ; Завершение программы
    mov eax, 60
    xor edi, edi
    syscall