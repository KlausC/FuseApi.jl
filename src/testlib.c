#include<stdio.h> // define the header file
void testcallback(void (*callback)(char*, int), char *arg1, int arg2)   // define the main function
{
    printf("Welcome to test callback");
    callback(arg1, arg2);
}
