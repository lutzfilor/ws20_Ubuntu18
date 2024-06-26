#!/usr/bin/perl
#   Author      Lutz Filor
#   Date        2019-12-02
#   Synopsis    Testing forms and springs, 
#   Source      docstore.mik.ua/orelly/perl3/tk/ch02_04.htm
#
use Tk;
#use strict;


$mw = MainWindow->new(	-title 	=> 	'Play w/form'	); 

# Create a Frame at the bottom of the window to use 'form' in 
$f = $mw->Frame	(	-borderwidth=> 	2
				, 	-relief 	=> 'groove') ->	pack(	-side 	=> 	'bottom'
													, 	-expand	=> 	1
													, 	-fill 	=>	'both');

# Display the Button in the default position to start 
$button = $f->Button	(	-text 		=> "Go!"
						, 	-command 	=> \&reForm)->form;
						
# Use grid to create the Entry widgets to take our options: 
$f1 = $mw->Frame->pack	(	-side 	=> 	'top'
						, 	-fill 	=>	'x'	);
						
$f1->Label	(	-text 		=> '-top'	)->grid		(	$f1->Entry(	-textvariable 	=> 	\$top			)
													, 	$f1->Label(	-text 			=> 	'-topspring'	)
													, 	$f1->Entry(	-textvariable	=> 	\$topspring		)
													, 	-sticky	=> 	'w'
													, 	-padx 	=> 	2
													, 	-pady 	=> 	5	);
									
$f1->Label	(	-text 		=> '-bottom')->grid		(	$f1->Entry(	-textvariable 	=> 	\$bottom		)
													,	$f1->Label(	-text 			=> 	'-bottomspring'	)
													,	$f1->Entry(	-textvariable 	=>	\$bottomspring	)
													,	-sticky	=> 	'w'
													,	-padx 	=> 	2
													,	-pady 	=> 	5	);
									
$f1->Label	(	-text 		=> '-left'	)->grid		(	$f1->Entry(	-textvariable 	=> 	\$left			)
													,	$f1->Label(	-text 			=>	'-leftspring'	)
													,	$f1->Entry(	-textvariable 	=>	\$leftspring	)
													,	-sticky => 	'w'
													,	-padx 	=> 	2
													,	-pady 	=> 	5	);
									
$f1->Label	(	-text 		=> 	'-right')->grid		(	$f1->Entry(	-textvariable 	=> 	\$right			)
													,	$f1->Label(	-text			=> 	'-rightspring'	)
													,	$f1->Entry(	-textvariable 	=> 	\$rightspring	)
													,	-sticky => 	'w'
													,	-padx 	=> 	2
													,	-pady 	=> 	5	);
									
# Add this Button in case the options we put in causes the 'formed' Button # to go off screen somewhere. 
$f1->Button	(	-text 		=> 	"Go!"
			, 	-command 	=> 	\&reForm)->grid		(	'-'
													, 	'-'
													, 	'-'
													, 	-pady 	=> 	5	);

MainLoop;

sub reForm { 
	print "top          => $top\t";
	print "topspring    => $topspring\n";
	print "bottom       => $bottom\t";
	print "bottomspring => $bottomspring\n";
	print "left         => $left\t";
	print "leftspring   => $leftspring\n";
	print "right        => $right\t";
	print "rightspring 	=> $rightspring\n";
	print "-----------------------------\n";
	# Remove Button from container for now $button->formForget;
	my @args = ( );
	if ($top ne '') { 
		push (@args, ('-top'			, $top		)	);
	} 
	if ($bottom ne '') { 
		push (@args, ('-bottom'			, $bottom	)	);
	}
	if ($right ne '') {
		push (@args, ('-right'			, $right	)	);
	}
	if ($left ne '') { 
		push (@args, ('-left'			, $left		)	);
	}
	if ($topspring ne '') { 
		push (@args, ('-topspring'		, $topspring)	);
	}
	if ($bottomspring ne '') {
		push (@args, ('-bottomspring'	, $bottomspring));
	}
	if ($rightspring ne '') { 
		push (@args, ('-rightspring'	, $rightspring)	);
	} 
	if ($rightspring ne '') {
		push (@args, ('-rightspring'	, $rightspring)	);
	}
	print "ARGS: @args\n";
	# Put Button back in container using new args $button->form(@args);
}#sub reForm
 

