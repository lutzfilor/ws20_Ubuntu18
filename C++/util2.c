#include <stdlib.h>
#include <stdio.h>

_Bool isPowerOfTwo(int x)
{
    while( x % 2 == 0 ) x/= 2;
    return x;
}

int util(int argc, char **argv)
{
    printf("argc  %d\n",argc);
    printf("value %d\n", atoi(argv[1]) );
    return 0;
}
