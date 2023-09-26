#---------------------------------------------------------------------------
# Name: postmark.pl 
# Desc:       Makes Postal Barcodes.
# Author:     Dr. Philip A. Carinhas  pac@fortuitous.com
# Date:       Fri Sep 17,1999 AD 
# Location:   Austin, Texas, USA, Earth, Solar System, Milky Way Galaxy.
# Copyright:  © Fortuitous Technologies Inc.® http://www.fortuitous.com 
# License:    This code may be distributed freely for non-commercial use as
#             long as this header remains in tact. Users also agree to 
#             provisions set forth in http://www.fortuitous.com/visitor.html
#             ragarding waranties and liabilites. Use at your own risk!
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
package Certificate;
use strict;
use Getopt::Long;

#---------------------------------------------------------------------------
package Certificate::Cert;

my $pagewidth  =  8.5 * 72.0;
my $pageheight = 11.0 * 72.0;
my $x_margin   = .25  * 72.0;
my $y_margin   = .25  * 72.0;
my $width;
my $height;

my $X0;
my $Y0;
my $return_add;

sub new
{
    my $type = shift;
    my $self = { @_ };

#==================================================================
#== Test for Type =================================================
#==================================================================

    if ($self->{'Type'} eq "Certificate")
    {

       $width  = $self->{'Width'}  * 72; # Course Certificates
       $height = $self->{'Height'} * 72; # Certificate height

       $X0 = $pagewidth/21;
       $Y0 = $pageheight/2;
    }
    bless $self, $type;
}

sub print
{
  my $self = shift;
  my $string;
  $string  = $self->print_header();
  $string .= $self->print_defs();
  $string .= $self->print_body();
  $string .= $self->print_tail();
  return $string;
}

sub print_header
{
   my $string =  "";
$string =
"%!PS-Adobe-3.0
%%Title: Labels.ps
%%Pages: 99
%%PagesOrder: Ascend
%%DocumentFonts: Times-Roman
%%EndComments
";
   return $string;
}

sub print_tail
{
  my $string = "showpage\n";
  return $string;
}

# Get the names into an array..
sub get_names
{
  my $self = shift;
  my $file = $self->{AddressFile};
  my @names ;

  open (FX, $self->{AddressFile}) or die "Can't open $self->{AddressFile}";

   while (<FX>)
   {
      chomp($_);        # Remove extra newlines
      s/^\s+//g;        # Remove space
      s/\s+$//g;        # Remove space
      push @names, $_;
   }
#------------------------------------------------------------
   return @names;  # Array with the Address+Zipcode..
}

sub print_body
{
   my $self = shift;
   my @names = $self->get_names();
   my $string = "";
   my $page = 0;
   my $name;

   foreach $name (@names)
   {
      $page++;
      $string .= "\%\%Page: 1  $page \n";
      $string .= "newpage\n" if ($page != 1) ;
      $string .= "/student \($name\) store\n";
      $string .= "cert\n";
   }
   return $string;
}

sub print_defs
{
   my $self = shift;
   my $string = "";

   $string .=  "
/X0 $X0 def      % Label X Origin
/Y0 $Y0 def      % Label Y Origin
/x0 X0 def      % Current x position
/y0 Y0 def      % Current y position
/pagewidth $pagewidth      def
/pageheight $pageheight    def
/student {(John Doe)} def
/x_skip {pagewidth 21 div} def

/inc_x
{ 
/inc exch def
/x0 x0 x_skip inc mul add
store x0 y0 moveto
} bind def

/newpage { /x0 X0 store /y0 Y0 store x0 y0 moveto } bind def

/CenterShow
{
gsave
dup stringwidth 2 div neg exch 2 div neg exch rmoveto show
grestore
} bind def

/cert
{
X0 Y0 moveto

4 inc_x

gsave
90 rotate
/Hershey-Gothic-English-Bold  findfont 36 scalefont setfont
($self->{'Company'}) CenterShow
grestore

2 inc_x

gsave
90 rotate
/Hershey-Gothic-English findfont 20 scalefont setfont
($self->{'Preamble'}) CenterShow
0  -30 rmoveto
(Be it Known that) CenterShow
grestore

4 inc_x

gsave
90 rotate
/Hershey-Gothic-English-Bold  findfont 28 scalefont setfont
student CenterShow
grestore


3 inc_x

gsave
90 rotate
/Hershey-Gothic-English findfont 22 scalefont setfont
($self->{'Midamble'}) CenterShow
grestore

2 inc_x

gsave
90 rotate
/Hershey-Gothic-English-Bold  findfont 24 scalefont setfont
($self->{'Title'}) CenterShow
grestore

2 inc_x

gsave
90 rotate
/Hershey-Gothic-English findfont 16 scalefont setfont
($self->{'Postamble'}) CenterShow
grestore

showpage
} bind def\n";

  return $string;
}

1;
