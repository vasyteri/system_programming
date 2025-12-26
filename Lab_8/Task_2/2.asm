format elf64
public _start

extrn printf

section '.data' writeable
    ; Форматы вывода
    header      db "Точность | Члены ряда | Члены дроби", 0xa, 0
    row         db "%-8.0e  | %-10d | %-10d", 0xa, 0
    fmt_math_e  db "math.h e   = %.15f", 0xa, 0
    result_ser  db "ряд     e = %.15f", 0xa, 0
    result_frac db "дробь   e = %.15f", 0xa, 0
    line        db "---------------------------", 0xa, 0

    ; Точности
    prec    dq 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8
    count = ($ - prec) / 8
    
    ; Константы
    two     dq 2.0
    one     dq 1.0
    zero    dq 0.0
    math_e  dq 2.718281828459045
    
    ; Для вычислений
    epsilon dq 0.0
    term    dq 0.0
    fact    dq 1.0
    n_int   dq 2.0      ; начинаем с 2!

section '.bss' writeable
    e_series    rq 1    ; результат ряда
    e_fraction  rq 1    ; результат дроби
    cnt_series  rd 1    ; количество членов ряда
    cnt_frac    rd 1    ; количество членов дроби
    i           rd 1     ; индекс точности
    temp        rq 1     ; временная переменная
    temp_int    rd 1     ; временная целая переменная (4 байта)
    prev_val    rq 1     ; предыдущее значение для проверки точности
    diff        rq 1     ; разность
    
section '.text' executable

; Макрос для печати строки
macro print_string str_ptr {
    mov rdi, str_ptr
    xor rax, rax
    call printf
}

; Вычисление e через ряд: e = 2 + 1/2! + 1/3! + 1/4! + ...
; Возвращает в e_series и cnt_series
compute_series:
    ; Инициализация
    finit
    
    ; e_series = 2.0
    fld qword [two]
    fstp qword [e_series]
    
    ; fact = 1.0 (1!)
    fld1
    fstp qword [fact]
    
    ; n = 2.0
    fld qword [two]
    fstp qword [n_int]
    
    mov dword [cnt_series], 0
    
.series_loop:
    ; fact = fact * n
    fld qword [fact]
    fld qword [n_int]
    fmulp st1, st0
    fstp qword [fact]
    
    ; term = 1.0 / fact
    fld1
    fld qword [fact]
    fdivp st1, st0
    fst qword [term]
    
    ; Проверка точности
    fld qword [epsilon]
    fcomip st0, st1
    fstp st0            ; очищаем стек
    ja .series_end
    
    ; e_series = e_series + term
    fld qword [e_series]
    fld qword [term]
    faddp st1, st0
    fstp qword [e_series]
    
    ; n = n + 1
    fld qword [n_int]
    fld1
    faddp st1, st0
    fstp qword [n_int]
    
    ; увеличиваем счетчик
    inc dword [cnt_series]
    jmp .series_loop

.series_end:
    ret

; Вычисление e через цепную дробь: e = 2 + 2/(2 + 3/(3 + 4/(4 + ...)))
compute_fraction:
    ; Инициализация
    finit
    
    mov dword [cnt_frac], 0
    
    ; Начинаем с достаточно большой глубины
    ; Будем увеличивать глубину, пока не достигнем точности
    mov ecx, 2          ; начальная глубина
    
.depth_loop:
    ; Сохраняем текущую глубину
    mov [temp_int], ecx
    
    ; Начинаем вычисление с конца: result = n
    fild dword [temp_int]
    fst qword [temp]    ; сохраняем начальное значение
    
    ; Если глубина 2, пропускаем вычисления
    cmp ecx, 2
    je .compute_e_from_result
    
    ; Вычисляем цепную дробь от n-1 до 2
    mov ebx, ecx
    dec ebx             ; начинаем с n-1
    
.inner_loop:
    cmp ebx, 1
    jle .compute_e_from_result
    
    ; Сохраняем текущий результат
    fst qword [prev_val]
    
    ; Вычисляем: k + (k+1)/result
    mov [temp_int], ebx
    
    ; Загружаем k
    fild dword [temp_int]
    
    ; k+1
    fild dword [temp_int]
    fld1
    faddp st1, st0      ; st0 = k+1, st1 = k, st2 = результат
    
    ; (k+1)/результат
    fxch st2           ; st0 = результат, st1 = k, st2 = k+1
    fdivp st2, st0     ; st0 = k, st1 = (k+1)/результат
    
    ; k + (k+1)/результат
    faddp st1, st0
    
    ; Увеличиваем счетчик
    inc dword [cnt_frac]
    
    dec ebx
    jmp .inner_loop

.compute_e_from_result:
    ; Теперь в st0 результат цепной дроби
    ; e = 2 + 2/result
    
    ; Сохраняем результат
    fst qword [temp]
    
    ; Вычисляем 2/result
    fld qword [two]
    fld qword [temp]
    fdivp st1, st0      ; st0 = 2/result
    
    ; 2 + 2/result
    fld qword [two]
    faddp st1, st0      ; st0 = 2 + 2/result
    
    ; Сохраняем вычисленное e
    fstp qword [e_fraction]
    
    ; Проверяем точность (сравниваем с предыдущей глубиной)
    cmp ecx, 2
    je .increase_depth  ; для глубины 2 не с чем сравнивать
    
    ; Вычисляем e для предыдущей глубины
    push rcx
    dec ecx
    mov [temp_int], ecx
    
    ; Вычисляем e для глубины ecx-1
    fild dword [temp_int]
    
    ; Если глубина 1, то result = 1
    cmp ecx, 1
    jle .calc_prev_e
    
    mov ebx, ecx
    dec ebx
    
.prev_inner_loop:
    cmp ebx, 1
    jle .calc_prev_e
    
    mov [temp_int], ebx
    fild dword [temp_int]
    
    fild dword [temp_int]
    fld1
    faddp st1, st0
    fxch st2
    fdivp st2, st0
    faddp st1, st0
    
    dec ebx
    jmp .prev_inner_loop

.calc_prev_e:
    fst qword [temp]
    fld qword [two]
    fld qword [temp]
    fdivp st1, st0
    fld qword [two]
    faddp st1, st0
    
    ; Теперь st0 = e для глубины ecx-1
    ; Вычисляем разность |e_n - e_{n-1}|
    fld qword [e_fraction]
    fsubp st1, st0
    fabs
    fstp qword [diff]
    
    pop rcx
    
    ; Проверяем точность
    fld qword [epsilon]
    fld qword [diff]
    fcomip st0, st1
    fstp st0
    jb .fraction_done   ; если diff < epsilon

.increase_depth:
    ; Увеличиваем глубину
    inc ecx
    
    ; Проверяем максимальную глубину
    cmp ecx, 1000
    jg .fraction_done_force
    
    jmp .depth_loop

.fraction_done_force:
    ; Форсированно завершаем
    mov dword [cnt_frac], 1000
    
.fraction_done:
    ; Устанавливаем реальное количество членов
    mov [cnt_frac], ecx
    ret

_start:
    ; Сохраняем указатель стека для выравнивания
    push rbp
    mov rbp, rsp
    and rsp, -16        ; выравниваем стек по 16 байт
    
    ; Выводим заголовок
    print_string header
    print_string line
    
    ; Инициализируем индекс
    mov dword [i], 0
    
.loop_prec:
    ; Проверяем, не превысили ли количество точностей
    mov eax, [i]
    cmp eax, count
    jge .end_loop
    
    ; Загружаем текущую точность
    lea rbx, [prec]
    mov eax, [i]        ; eax = i (32 бита)
    cdqe                ; расширяем eax до rax (знаковое расширение)
    shl rax, 3          ; умножаем на 8 (размер qword)
    fld qword [rbx + rax]
    fstp qword [epsilon]
    
    ; Вычисляем e через ряд
    call compute_series
    
    ; Вычисляем e через дробь
    call compute_fraction
    
    ; Подготавливаем параметры для printf
    mov rdi, row
    mov esi, [cnt_series]
    mov edx, [cnt_frac]
    
    ; Загружаем epsilon в xmm0 для printf
    movq xmm0, [epsilon]
    mov rax, 1          ; один параметр с плавающей точкой
    call printf
    
    ; Переходим к следующей точности
    inc dword [i]
    jmp .loop_prec

.end_loop:
    ; Выводим разделитель
    print_string line
    
    ; Выводим значение e из math.h
    mov rdi, fmt_math_e
    movq xmm0, [math_e]
    mov rax, 1
    call printf
    
    ; Выводим последние вычисленные значения
    mov rdi, result_ser
    movq xmm0, [e_series]
    mov rax, 1
    call printf
    
    mov rdi, result_frac
    movq xmm0, [e_fraction]
    mov rax, 1
    call printf
    
    ; Восстанавливаем стек
    mov rsp, rbp
    pop rbp
    
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall