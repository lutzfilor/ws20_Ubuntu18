#!/usr/bin/perl -w 
#	Source	docstore.mik.ua/orelly/perl3/tk/ch04_09.htm
use Tk;

$mw = MainWindow->new; 
$mw->title("Checkbutton"); 

## Create other widgets, but don't pack them yet! 
for ($i = 1; $i <= 5; $i++) { 
	push (@buttons, $mw->Button(-text => "Button$i")); 
} 

$mw->Checkbutton(	-text 		=> 	"Show all widgets"
				, 	-variable 	=> 	\$cb_value
				, 	-command 	=>	sub{
                                    	if ($cb_value) { 
                                    		foreach (@buttons) { 
                                    			$_->pack(-side => 'left'); 
                                    		}#foreach 
                                    	} else { 
                                    		foreach (@buttons) { 
                                    			$_->pack('forget');
                                    		}#foreach
                                    	}#
                                    }                                       )->pack(-side => 'top');
                #, 	-command 	=>	\&genbtn($cb_value, @buttons)	)->pack(-side => 'top');

MainLoop; 

### sub genbtn{
### 	my ($CB_VALUE, @BTNS)	= @_;
### 	if ($CB_VALUE) { 
### 		foreach (@BTNS) { 
### 			$_->pack(-side => 'left'); 
### 		}#foreach 
### 	} else { 
### 		foreach (@BTNS) { 
### 			$_->pack('forget');
### 		}#foreach
### 	}#
### }                                           
