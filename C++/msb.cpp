#include <stdlib.h>
#include <stdio.h>

int mostSignificantSetBitPosition   ( int x )
{
    int MSSBP   =   -1;                     //  default value for x == 0
    int operand =   x;
    if ( operand == 0 ) {                   //  ZERO is position MINUS ONE -- This if-statement is NOT neccessary
    } else {                                //  only added for clarity, because set implicite at initialization/declaration
        while ( operand > 0 ) {
            MSSBP++;                        //  Increment the Position counter  ONE would be position ZERO
            operand >>= 1;                  //  shift the operand to the right (divide by 2
        }//while
    }//else
    return MSSBP;
}// mostSignificantSetBitPosition


//_Bool isPowerOfTwo(int x)
bool isPowerOfTwo(int x)
{
    while( x % 2 == 0 ) x/= 2;
    return x;
}

int util(int argc, char **argv)
{
    printf("argc  %d\n",argc);
    //printf("value %d\n",(int) argv[1]);
    printf("value %d\n",atoi(argv[1]));
    return 0;
}
