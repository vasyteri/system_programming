#include <stdio.h>

int main() {
    int a = 10;
    int b = 5;
    int c = 2;
    double result;
    
    if (b == 0 || c == 0) {
        printf("Ошибка: деление на ноль!\n");
        return 1;
    }
    
    result = (((double)a / b) + a) / c;
    
    printf("Вычисление выражения: (((a/b)+a)/c)\n");
    printf("a = %d, b = %d, c = %d\n", a, b, c);
    printf("Результат: %.2f\n", result);
    
    return 0;
}