#!/usr/bin/perl -w

use strict;
use Cwd;
use File::Find;
use File::Path qw(make_path);
use Getopt::Long;

my $OUTPUT_DIR;
my $INPUT_DIR;
my $INPUT_FILE;
my $TEMPLATE_FILE;
my $cwd = getcwd;
my $ext = "wip";
my $usage = <<USAGE
$0 -i INPUT_DIR -o OUTPUT_DIR -t TEMPLATE_FILE

Converts .convert files in INPUT_DIR and writes them to OUTPUT_DIR, preserving
the directory structure. Uses TEMPLATE_FILE as the basis of the output files.
USAGE
;

GetOptions("help"       => sub {print "$usage"; exit;},
           "in=s"       => \$INPUT_DIR,
           "out=s"      => \$OUTPUT_DIR, 
           "template=s" => \$TEMPLATE_FILE,
          );

if ( ! defined $OUTPUT_DIR or 
     ! defined $INPUT_DIR or 
     ! defined $TEMPLATE_FILE
   ) {
    die "$usage";
}

# File::Find changes directories, so we need to use full paths
if ( $OUTPUT_DIR !~ /^\// ) { $OUTPUT_DIR = "$cwd/$OUTPUT_DIR"; }
if ( $INPUT_DIR !~ /^\// ) { $INPUT_DIR = "$cwd/$INPUT_DIR"; }
if ( $TEMPLATE_FILE !~ /^\// ) { $TEMPLATE_FILE = "$cwd/$TEMPLATE_FILE"; }

File::Find::find(\&convert_dir, $INPUT_DIR); 

sub convert_dir {
    use vars '*name';
    *name = *File::Find::name;

    if ( lstat($_) && /^.*\.$ext\z/s ) {
        $name =~ /^$INPUT_DIR(.*)\/(.+?).$ext$/;
        my $base_dir = '';
        my $base_name = $2;
        if (defined $1) { $base_dir = $1; }
        my $output_dir = "$OUTPUT_DIR/$base_dir";
        if ( ! -d $output_dir ) {
            make_path($output_dir);
        }
        print "$name -> $output_dir/$base_name.html\n";
        &convert_file($name, "$output_dir/$base_name.html", $TEMPLATE_FILE);
    }
}

sub convert_file {
    my ($input_file,$output_file,$template_file) = @_;

    open(my $TEMPLATE, '<', $template_file) or die "$0: $template_file: $!\n";
    open(my $OUTPUT,   '>', $output_file) or die "$0: $output_file: $!\n";

    my $converted = &process_input($input_file);

    while(<$TEMPLATE>) {
        if (/^\s*<\!--\s*##TITLE\s*-->.*$/) {
            print $OUTPUT "<title>$converted->{title}</title>\n";
        } elsif (/^(\s*)<\!--\s*##BODY\s*-->.*$/) {
            my $indent = '';
            if (defined $1) {
                $indent = $1;
            }
            for ( 
                  '<div class="navbar">',
                  '  <div class="navbar-inner">',
                  '    <div class="container">',
                  "      <h1>$converted->{title}</h1>",
                  '    </div>',
                  '  </div>',
                  '</div>',
                  '<div class="container-fluid">',
                  '<div class="row-fluid">',
                )
            {
                print $OUTPUT "$indent$_\n";
            }
            if (scalar @{$converted->{'toc'}}>4) {
                for ( 
                    '  <aside class="span3">',
                    '   <div class="well sidebar-nav affix">',
                    '    <ul class="nav nav-list">') 
                {
                    print $OUTPUT "$indent$_\n";
                }
                for (@{$converted->{'toc'}}) {
                    print $OUTPUT "$indent      $_";
                }
                for ( '    </ul>',
                    '   </div>',
                    '  </aside>')
                {
                    print $OUTPUT "$indent$_\n";
                }
            }
            for ( '',
                  '  <div class="span9">') {
                print $OUTPUT "$indent$_\n";
            }
            for (@{$converted->{'body'}}) {
                print $OUTPUT "$indent    $_";
            }
            for ( '  </div>',
                  '</div>',
                  '</div>') {
                print $OUTPUT "$indent$_\n";
            }
        } else {
            print $OUTPUT $_;
        }
    }
    close $TEMPLATE;
    close $OUTPUT;
}
    
sub process_input {
    my ($input_file) = @_;
    my $converted = {'title' => '',
                     'toc'   => [],
                     'body'  => []};
    my $first_section = 1;
    my $dl = {'last' => 0, 'cur' => 0};
    my $table = {'last' => 0, 'cur' => 0};
    open(my $INPUT, '<', $input_file) or die "$0: $input_file: $!\n";
    while (<$INPUT>) {
        chomp;
        # Empty lines and comments
        if (/^\s*(#.*)?$/) {
            next;
        } 
        $dl->{'cur'} = 0;
        $table->{'cur'} = 0;
        # FIXME(brosenberg): This is dumb. Do this better.
        if ($dl->{'last'} == 1 && !/^=DL=/) {
            push($converted->{'body'},"  </dl>\n");
        }
        if ($table->{'last'} == 1 && !/^=TAB=/) {
            push($converted->{'body'},"        </tbody>\n");
            push($converted->{'body'},"      </table>\n");
        }
    
        # Headings
        if (/^=([0-9])=(.+)$/) {
            my ($heading, $section) = ($1,$2);
            my $t;
            (my $section_safe = $section) =~ s/\W//g;
            $heading++;
            if ($heading<4) {
                my @classes;
                # Check to see if this is the first toc entry and first section
                if ($first_section) {
                    push @classes, "active";
                    $first_section--;
                } else {
                    push($converted->{'body'},"</section>\n");
                }
                if ($heading>2) {
                    push @classes, "subsection";
                }
                if (scalar @classes) {
                    $t = "<li class=\"".join(' ',@classes)."\">";
                } else {
                    $t = "<li>";
                }
                push($converted->{'body'},"\n");
                push($converted->{'body'},"<section id=\"$section_safe\">\n");
                $t .= "<a href=\"#$section_safe\">$section</a></li>\n";
                push($converted->{'toc'},$t);
            }
            push($converted->{'body'}, "  <h$heading>$section</h$heading>\n");
        # Description Lists
        } elsif (/^=DL=(.+?):(.+)$/) {
            if ($dl->{'last'} == 0) {
                push($converted->{'body'},"  <dl class=\"dl-horizontal\">\n");
            }
            push($converted->{'body'},"    <dt>$1</dt>\n");
            push($converted->{'body'},"    <dd>$2</dd>\n");
            $dl->{'cur'} = 1;
        # Emphasis
        } elsif (/^=E=(.+)$/) {
            push($converted->{'body'},"  <p><em>$1</em></p>\n");
        # Images
        } elsif (/^=I=(\S+)(\s*[0-9]+x[0-9]+\s*)?$/) {
            if (defined $2) {
                my ($path,$size) = ($1,$2);
                $size =~ /^\s*([0-9]+)x([0-9]+)\s*$/;
                push($converted->{'body'}, "  <img src=\"$path\" height=\"$1\" width=\"$2\">\n");
            } else {
                push($converted->{'body'}, "  <img src=\"$1\">\n");
            }
        # Links
        } elsif (/^=L=(.+?): (.+)$/) {
            push($converted->{'body'},"    <h4><a href=\"$1\">&raquo; $2</a></h4>\n");
        # Raw html
        } elsif (/^=R=(.+)$/) {
            push($converted->{'body'}, "  $1\n");
        # Title
        } elsif (/^=T=(.+)$/ && $converted->{'title'} eq '') {
            $converted->{'title'} = "$1";
        # Tables
        } elsif (/^=TAB=(.+)$/) {
            my @elems = split('::',$1);
            my $elem_tag = 'td';
            if ($table->{'last'} == 0) {
                $elem_tag = 'th';
                push($converted->{'body'},"      <table class=\"table table-hover\">\n");
                push($converted->{'body'},"        <thead><tr>\n");
            }

            push($converted->{'body'},"          <tr>\n");
            for my $elem (@elems) {
                push($converted->{'body'},"            <$elem_tag>$elem</$elem_tag>\n");
            }
            push($converted->{'body'},"          </tr>\n");

            if ($table->{'last'} == 0) {
                push($converted->{'body'},"        </tr></thead>\n");
                push($converted->{'body'},"        <tbody>\n");
            } 
            $table->{'cur'} = 1;
        } else {
            push($converted->{'body'}, "  <p>$_</p>\n");
        } 
        $dl->{'last'} = $dl->{'cur'};
        $table->{'last'} = $table->{'cur'};
    }
    if (!$first_section) {
        push($converted->{'body'},"</section>\n");
    }
    close $INPUT;
    return $converted;
}
