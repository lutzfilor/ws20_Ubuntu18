#include <stdlib.h>
#include <stdio.h>
#include <iostream> 
#include <sstream>

extern int util(int, char **);
//extern _Bool isPowerOfTwo(int);
//extern int mostSignificantSetBitPosition(int);

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

void    present (int value, int pos)
{
        cout    <<  "mostSignificantSetBitPosition("
                <<  value
                <<  ")  =  "
                <<  pos <<  "\n";
        return;
}//     present


void test(int argc, char **argv)
{
    int MSSP;
    MSSP = mostSignificantSetBitPosition(32);
    present( 32, MSSP );
    MSSP = mostSignificantSetBitPosition(1024);
    MSSP = mostSignificantSetBitPosition(47);
    MSSP = mostSignificantSetBitPosition(0);
    return;
}

int main(int argc, char **argv)
{
    util(argc, argv);
    test(argc, argv);
    return 0;
}
