#include <stdio.h>
#include <stdlib.h>
#include "queue.h"

void flush_stdout() {
    fflush(stdout);
}

int main() {
    Queue* queue = create_queue();
    if (!queue) {
        printf("Ошибка: Не удалось создать очередь\n");
        return 1;
    }

    unsigned long n;
    printf("Введите количество случайных элементов для генерации: ");
    scanf("%lu", &n);

    printf("\n1. Заполнение очереди %lu случайными числами\n", n);
    flush_stdout();
    fill_random(queue, n);
    printf("Очередь: ");
    flush_stdout();
    print_queue(queue);

    printf("Всего элементов: %lu\n", queue->size);
    printf("Чисел, оканчивающихся на 1: %u\n", count_numbers_ending_with_1(queue));
    flush_stdout();

    printf("\n2. Добавление числа 999 в конец\n");
    flush_stdout();
    enqueue(queue, 999);
    printf("Очередь после добавления: ");
    flush_stdout();
    print_queue(queue);

    printf("\n3. Удаление из начала: %lu\n", dequeue(queue));
    flush_stdout();
    printf("Очередь после удаления: ");
    flush_stdout();
    print_queue(queue);

    printf("\n4. Получение списка нечетных чисел\n");
    flush_stdout();
    Queue* odd_numbers = get_odd_numbers(queue);
    printf("Очередь нечетных чисел: ");
    flush_stdout();
    print_queue(odd_numbers);
    printf("Всего нечетных чисел: %lu\n", odd_numbers->size);
    flush_stdout();

    printf("\n5. Удаление четных чисел\n");
    flush_stdout();
    remove_even_numbers(queue);
    printf("Очередь после удаления четных чисел: ");
    flush_stdout();
    print_queue(queue);
    printf("Всего элементов: %lu\n", queue->size);
    printf("Чисел, оканчивающихся на 1: %u\n", count_numbers_ending_with_1(queue));
    flush_stdout();

    free_queue(odd_numbers);
    free_queue(queue);

    return 0;
}