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
package SuperLabel;
# use diagnostics;
use strict;
use Getopt::Long;

#---------------------------------------------------------------------------

package SuperLabel::Barcode;

sub new
{
    my $type = shift;
    my $this = {};
    my $class = ref($type) || $type;
    $this->{Zipcode} = shift;
    bless $this, $class;
    $this->check();
    return $this;
}

sub check
{
   my $this = shift;
   my $zipcode = $this->{Zipcode};
   my @chars = split //, $zipcode;
   if ( $#chars > 9 || $#chars < 4 ) { die "Error: zipcode= ", $zipcode,"\n"};
   if ( $zipcode =~ /[^\d-]/ ) { die "Zipcode->check() Error: invalid zip\n"};
   $this->make();
}

sub make
{
   my $this = shift;
   my $zipcode = $this->{Zipcode};
   if ($zipcode == "00000")
   {
      print "Barcode: zipcode == $zipcode\n";
      $this->{String} = "/zip {\n";
      $this->{String} .= "0 0  translate \n";
      $this->{String} .= "} def\n";
   }
   else
   {
      my $total = 0;
      my $digit;
      my $checksum = 0;
      my @chars = split //, $zipcode;
      my %digits=(0 => "zero", 1 => "one", 2 => "two", 3 => "three",
                  4 => "four", 5 => "five", 6 => "six", 7 => "seven",
                  8 => "eight", 9 => "nine");

      $this->{String} = "/zip {\n";
      $this->{String} .= "0 0  translate \n";
      $this->{String} .= "0 0  long stroke  \n";
      $this->{String} .= "dx 0  translate \n";

      foreach $digit (@chars)
      {
         if ($digit =~ /\d/ )
         {
            $total += $digit;
            $this->{String} .= "$digits{$digit} stroke\n";
            $this->{String} .= "Dx 0  translate\n";
         }
      }

      $checksum = (10 - $total%10)%10;
      $this->{String} .= "0  0  $digits{$checksum} \n";
      $this->{String} .= "Dx 0  translate \n";
      $this->{String} .= "0  0  long stroke  \n";
      $this->{String} .= "} def\n";
   }
}

sub print_defs
{
   my $string = "";
   $string .= "
/barwidth {1.3} def     % Barcode's bar width ..
/dx {3.325} def         % Barcode's bar separation ..
/D1 {dx dx add} def     % First digit gets 2 dx's
/D2 {D1 dx add} def     % Second digit etc...
/D3 {D2 dx add} def     % Third digit is  etc...
/Dx {D3 dx add} def\n";

   my $zero = "
/zero {
0 0 long stroke
dx 0 long stroke
D1 0 short stroke
D2 0 short stroke
D3 0 short stroke
} bind def";

   my $one = "
/one {
0 0 short stroke
dx 0 short stroke
D1 0 short stroke
D2 0 long stroke
D3 0 long stroke
} bind def";

   my $two = "
/two {
0 0 short stroke
dx 0 short stroke
D1 0 long stroke
D2 0 short stroke
D3 0 long stroke
} bind def";

   my $three = "
/three {
0 0 short stroke
dx 0 short stroke
D1 0 long stroke
D2 0 long stroke
D3 0 short stroke
} bind def";
   
   my $four = "
/four {
0 0 short stroke
dx 0 long stroke
D1 0 short stroke
D2 0 short stroke
D3 0 long stroke
} bind def";

   my $five = "
/five {
0 0 short stroke
dx 0 long stroke
D1 0 short stroke
D2 0 long stroke
D3 0 short stroke
} bind def";
   
   my $six = "
/six {
0 0 short stroke
dx 0 long stroke
D1 0 long stroke
D2 0 short stroke
D3 0 short stroke
} bind def";

   my $seven = "
/seven {
0 0 long stroke
dx 0 short stroke
D1 0 short stroke
D2 0 short stroke
D3 0 long stroke
} bind def";

   my $eight = "
/eight {
0 0 long stroke
dx 0 short stroke
D1 0 short stroke
D2 0 long stroke
D3 0 short stroke
} bind def";

   my $nine = "
/nine {
0 0 long stroke
dx 0 short stroke
D1 0 long stroke
D2 0 short stroke
D3 0 short stroke
} bind def";

   $string .= "
/short {
newpath
moveto
barwidth setlinewidth
0 4 rlineto
} bind def
/long {
newpath
moveto
barwidth setlinewidth
0 10 rlineto
} bind def \n";

   $string .= "$zero $one $two $three $four $five $six $seven $eight $nine\n";
   return $string;
}

############################################################################

#----------------------------------#
#------ Package LABELMAKER --------#
#----------------------------------#
package SuperLabel::LabelMaker;

my $fontheight;
my $maxrow;
my $maxcol;
my $pagewidth  =  8.5 * 72.0;
my $pageheight = 11.0 * 72.0;
my $x_margin   = .25  * 72.0;
my $y_margin   = .25  * 72.0;
my $width;
my $height;
my $x_max;
my $y_max;
my $D_y;
my $M_y;
my $G_Xoff;
my $G_Yoff;

my $colsep;
my $rowsep;

my $X0;
my $Y0;
my $return_add;

sub new 
{
    my $type = shift;
    my $self = { @_ };
#-------------------------------------------------------------
   $fontheight = 13;  # fontheight should be variable...... 

   $G_Xoff     = -.0625 * 72; # Global Xoffset = 1/4 inch.
   $G_Yoff     = -0.0865 * 72; # Global Yoffset = 1/5 inch.

#==================================================================
#====  Make the Return Address ====================================
#==================================================================
    if ( -s "$ENV{HOME}/return.lbl" )
    {
       $return_add=1;
       $self->{'Return'} = "\n"." /T_x0 0 store /T_y0 0 store\n ";
       $self->{'Return'} .= "/return \{"
                            ." /T_x0 0 store /T_y0 0 store"
                            ." newpath"
                            ." 0 T_y0 moveto \n";

       open (RX, "$ENV{HOME}/return.lbl") or die "Can't open return.lbl";
       while (<RX>) 
       {
          chomp $_;
          $self->{'Return'} .= "\(".$_."\) show N\n";
       }
       $self->{'Return'} .= "}def";
    }
#==================================================================
#== Test for Type =================================================
#==================================================================

    if ($self->{'Type'} eq "Label") 
    { 
       $maxrow = $self->{'Rows'}; 
       $maxcol = $self->{'Cols'}; 
       $width  = $self->{'Width'}  * 72; # Label width 
       $height = $self->{'Height'} * 72; # Label height
       $G_Xoff += $self->{'Xoff'}  * 72; # Label width 
       $G_Yoff += $self->{'Yoff'}  * 72; # Label width 

       # $width      = $pagewidth;  # Page width in points
       # $height     = $pageheight; # Page height in points
      
       $M_y        = 0.5    * 72; # Label y-margin = 1/2 inch.
       $D_y   = ( $height - (2.0 * $M_y))/$maxrow  ; # Label height
       

       $colsep = $width/$maxcol;   # Dist tween columns: Delta = 2*edges
       $rowsep = 72.0;                   # Distance between rows 
       # $D_y        = 1.0    * 72; # Label height = 1 in.
       $X0 = (3/8)*72 + $G_Xoff;             # X-Origin of page
       $Y0 = $height - $D_y - $M_y - $G_Yoff; # Y-Origin of page
    }
    if ($self->{'Type'} eq "Postcard") 
    { 
       $maxrow = $self->{'Rows'}; 
       $maxcol = $self->{'Cols'};
       $width      = $pagewidth;  # Page width in points
       $height     = $pageheight; # Page height in points
       $colsep = $width/$maxcol; 
       $rowsep = $height/$maxrow;
       $X0 = $width/($maxcol*2);
       $Y0 = $height - $height/( $maxrow * 2 );
    }
    if ($self->{'Type'} eq "Envelope") 
    { 
       $maxrow = $self->{'Rows'}; 
       $maxcol = $self->{'Cols'};
       $width  = $self->{'Width'}  * 72; # Envelope width 
       $height = $self->{'Height'} * 72; # Envelope height
       $x_max =  $width; 
       $y_max =  $pageheight; 
       $colsep = $width/$maxcol;
       $rowsep = $height/$maxrow;
       $X0 = $x_margin;
       $Y0 = $pageheight - $height;

       $X0 += (2/5)*$width;
       $Y0 += (7/12)*$height;
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
%%DocumentFonts: Courier
%%EndComments
";
   return $string;
}

sub print_tail
{
  my $string = "showpage\n";
  return $string;
}

sub print_label
{
   # print "Entering print_label\n";
   my $self = shift;
   my ($address, $zip) = @_;
   # print "print_label: zip = $zip\n";
   # print "print_label: address = $address\n";
   my $barcode = SuperLabel::Barcode->new($zip);
   my $string = "";
#==============================================
#== print the /address definition =============
#==============================================
   $string .= "/address {
   /T_x0 0 store
   /T_y0 0 store
   newpath
   0 T_y0 moveto";
   $string .= $address;
   $string .= "}def\n";
#==============================================
#== Print the barcode def =====================
#==============================================
   print "zipcode = $zip\n";
   $string .= $barcode->{String};
   
#==============================================
#== Print the actual label=====================
#==============================================
#------------------------------------------------------------------------
   $string .= "gsave\n";
   $string .= "  x0 y0 translate \n";
   if ( $self->{'Type'} eq "Postcard")
   {
      $string .= " 80 -40 translate \n";
      $string .= " 90     rotate \n";
      $string .= "  0 +50 translate\n";
      $string .= "  0   0 address stroke\n";
      $string .= "  0 -53 translate\n";
   }
   if ( $self->{'Type'} eq "Envelope")
   {

      # $string .=" /Times-Bold findfont $fontheight scalefont setfont ";
      $string .=" /Courier findfont $fontheight scalefont setfont ";
      $string .= " -90      rotate \n";
      $string .= "   0    0 address stroke\n";
      $string .= "   0  -53 translate\n";  # Make sure barcode below label.

   }
   if ( $self->{'Type'} eq "Label")
   {
      $string .= "   0 +50 translate\n";
      $string .= "   0 0 address stroke\n";
      $string .= "  -9 -53 translate\n";
   }

   $string .= "   0 0 zip  stroke\n";
   $string .= "grestore\n";

#------------------------------------------------------------------------
#-- Print Return Address on Postcards and Envelopes ----------------------
#------------------------------------------------------------------------
   
   if ( $return_add )
   {
      if ( $self->{'Type'} eq "Postcard" )
      {
         $string .= "gsave\n";
         $string .= "  x0   y0 translate\n";
         $string .= "-125 -180 translate\n";
         $string .= "  90      rotate \n";
         $string .= "   0   0  return  stroke\n";
         $string .= "grestore\n";
      }
      if ( $self->{'Type'} eq "Envelope" )
      {
         my $corner_x = $x_max - 0;
         my $corner_y = $y_max - 30;
         $string .= "gsave\n";
         $string .= "  $corner_x $corner_y translate\n";
         $string .= "   -90      rotate\n";
         $string .= "     0   0  return stroke\n";
         $string .= "grestore\n";
      }
   }
   return $string;
}


# Get the (address, zipcode) labels into an array..
sub get_labels
{
  my $self = shift;
  my $temp;
  my $file = $self->{AddressFile};
  my ($address, $zip);
  my %labels;
  my ($zipcode, $key );
  my $count = 0;
  my $prev = "";
  my $line = "";

#------------------------------------------------------------
  open (FX, $self->{AddressFile}) or die "Can't open $self->{AddressFile}";

# $line = address data... *****
   while (<FX>)
   {
      chomp($_);        # Remove extra newlines
      s/^\s+//g;        # Remove space 
      s/\s+$//g;        # Remove space
#------------------------------------------------------------
      if ( $_ =~ /^\s*$/ ) { $count = 0; $line = ""; }
      next if /^(Phone:)*\s*\(\d{3}\).* \d{3}\-\d{4}.*$/ ;
      next if /\w@\w/ ;

#------------------------------------------------------------
     if ( $prev =~ /^\s*$/ && $_ =~ /\w/ )
     {  
        $count = 1;
     }
#------------------------------------------------------------
     if ( $count && $count <= 4 )
     {  
        s/(\d{5})(\d{4})$/$1\-$2/s;  # clean up zipcode

        if ( $line )  # Start a new line if not first (see newlabel).
        {
          $line .= "N ";
        }
        $line .= "\($_\) show\n";
        
#        if ( ($_ =~ /\D(\d{5}(\-\d{4})?)$/  && $count > 2) && $_ !~ /box/i )
        if ( ($_ =~ /\D(\d{5}(\-\d{4})?)$/  && $count >= 2) && $_ !~ /box/i )
        { 
          $temp = $1;
          $labels{ $line } = $temp;         # $temp is a zipcode
          $count = 4;
          $line = "";
        }
       elsif ( ($count >= 4) && $_ !~ /box/i )
       {
          $temp = $1;
          $labels{ $line } = "00000";         # $temp is a zipcode
          $count = 4;
          $line = "";
       }
        
        ++$count;
     } 
   $prev = $_;
  }
#------------------------------------------------------------
   return %labels;  # Array with the Address+Zipcode..
}

sub print_body
{
   my $self = shift;
   my %hash = $self->get_labels();
   my @keys = sort { $hash{$a} cmp $hash{$b} } keys %hash; 
   my ($row, $column, $key);
   my $string = "";

   $row = 1;
   my $page = 1;
   $column = 1;

   foreach $key (@keys)
   {
      $string .= $self->print_label($key, $hash{$key});

      if ( $key eq $keys[$#keys] ) { return $string; }
      $string .= "newlabel\n";
      
      if ($row == $maxrow) 
      {
          if ( $column == $maxcol )
          {
              $page++;
              $string .= "showpage\n";
              $string .= "\%\%Page: 1  $page \n";
              $string .= "newpage\n";
              $column = 1;
          }
          else
          {
             $string .= "newcolumn\n";
             $column++;
          }
          $row=1;
      }
      else 
      { 
          $row++;
      }
   }
   print "THIS STRING === $string \n";
   return $string;
}

sub print_defs
{
   my $self = shift;
   my $x0  = $X0 + $self->{'Xoff'}*72.0;      # Normal x_0 - xoffset
   my $y0  = $Y0 + $self->{'Yoff'}*72.0;      # Normal y_0 - yoffset
   my $string = "";

   $string .=  "/X0 {  $x0  } def
/Y0 {$y0}  def      % Label Y Origin

/xtemp {$X0} def   % Temp Coords for the current label
/ytemp {$Y0} def   % Needed for postal barcode measurement


/x0 {$X0} def      % Current x position
/y0 {$Y0} def      % Current y position
/fontheight {$fontheight} def
/colsep {$colsep} def
/rowsep {$rowsep} def\n";

   $string .=  "/N {
/T_y0 T_y0 fontheight sub store
T_x0 T_y0 moveto
} bind def
   ";
   
   if ( $return_add )
   {
      $string .= "$self->{'Return'}\n";
   }

   $string .= "
/setXTemp {
/ytemp y0 store
/xtemp x0 store
} bind def
/newlabel {
/y0 ytemp rowsep sub store
/x0 xtemp store
x0 y0 moveto
setXTemp
} bind def
/newcolumn {
/x0 x0 colsep add store
/y0 Y0 store
x0 y0 moveto
setXTemp
} bind def
/newpage { /x0 X0 store /y0 Y0 store x0 y0 moveto setXTemp } bind def
";
   $string .= SuperLabel::Barcode->print_defs();
   $string .= "
/Times-Bold findfont 10 scalefont setfont
%%Page: 1 1
newpage\n";
  return $string;
}

1;
