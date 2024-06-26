// Name of program mainreturn.cpp 
//#include <boost/lexical_cast.hpp>   //  for lexical_cast() not installed
#include <iostream> 
#include <sstream>
#include <string>

using namespace std; 

bool isPowerOfTwo( int x )
{
    int x_in    =   x;
    int iter    =   0;
    char key    =   'n';
    //while ( x % 2 == 0 )    
    //{
    //    iter++;
    //    cout    <<   iter   << " : "    <<   x   << " = "
    //            <<  (x % 2) << " test " << (x/2) << " remainder " 
    //            <<  "\n";
    //    key = 'n';
    //    x /= 2;
    //    while ( key != 'y' ) {
    //        cin >> key;
    //    }
    //}
    while ( x % 2 == 0 ) x /= 2;
    return x;
}// isPowerOfTwo

bool    isPowerOfTwo_n( int x )
{
        int pot;
        if ( x < 1 )
        {
            cout << "Warning " << x << " is out of range [ -N .. -1, 0] not defined \n";
            return 0;               //  Not a power of 2
        }   else if ( x == 1 ) {
            return 1;               //  Power of power 2
        }   else { 
            return  !(x & 1);       //  Returns ONE if Power of Two, else ZERO
        }
}//     isPowerOfTwo_n

int     test1   ( int x )
{
        //int po2 =   isPowerOfTwo ( x );
        int po2 =   isPowerOfTwo_n ( x );
        cout    << x    << " = "
                << po2  << "\n";
        return 0;
}//     test1

int mostSignificantSetBitPosition   ( int x )
{
    int MSSBP =   -1;                               //  default value for 0
    int operand =   x;
    if ( operand == 0 ) {                           //  ZERO is position MINUS ONE -- This if-statement is NOT neccessary
    } else {                                        //  only added for clarity, because set implicite at initialization/declaration
        while ( operand > 0 ) {
            MSSBP++;                                //  Increment the Position counter  ONE would be position ZERO
            operand >>= 1;                          //  shift the operand to the right (divide by 2
        }//while
    }//else
    return MSSBP;
}// mostSignificantSetBitPosition

int     test2( int v )
{
        int  mp  =   0;                             //  Max bit position
        mp  =   mostSignificantSetBitPosition( v );
        cout    << v    << " = "
                << mp   << "\n";
        return 0;
}

  
int main(int argc, char** argv) 
{ 
    int  x   =   0;                         //  Input variable
    bool y   =   0;                         //  
    string s =  "12345";
    stringstream geek( s );
    cout << "You have entered " << argc 
         << " arguments:" << "\n"; 
  
    for (int i = 0; i < argc; ++i) 
    {
        x   =   atoi(argv[i]);
        test1( x );
        //cout << argv[i] << "\n"; 
    }
    
    //for (int i = 1; i < argc; ++i) 
    //{
    //    x   =   atoi(argv[i]);          //  Input
    //    y   =   isPowerOfTwo( x );      //  Result
    //    
    //    cout    << x << " = "
    //            << y
    //            << "\n";
    //}
        //     << isPowerOfTwo( x ) << "\n";      

    //  for (int i = 1; i < argc; ++i)
    //  {
    //      x   =   atoi(argv[i]);
    //      test2( x );
    //  }

  
    return 0; 
}// main-end
