#ifndef QUEUE_H
#define QUEUE_H

typedef struct Node {
    unsigned long data;
    struct Node* next;
} Node;

typedef struct {
    Node* front;
    Node* rear;
    unsigned long size;
} Queue;

Queue* create_queue();
void free_queue(Queue* q);
void enqueue(Queue* q, unsigned long value);
unsigned long dequeue(Queue* q);
int is_empty(Queue* q);

void fill_random(Queue* q, unsigned long count);
Queue* get_odd_numbers(Queue* q);
void remove_even_numbers(Queue* q);
unsigned int count_numbers_ending_with_1(Queue* q);

void print_queue(Queue* q);
unsigned int ranint();

#endif