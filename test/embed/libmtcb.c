
#include <pthread.h>

pthread_t threadid;
void(*savedf2)(void);

void* cb_thread(void* arg);

void cb_setup(void(*f1)(void), void(*f2)(void)) {

    (*f1)();
    savedf2 = f2;

    pthread_create(&threadid, NULL, cb_thread, (void*)NULL);

    pthread_join(threadid, NULL);
    pthread_exit((void*)0);
}

void* cb_thread(void* arg) {
    (*savedf2)();
    return (void*)0;
}
     
