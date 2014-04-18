use warnings;
use strict;


use TagMaintenance;
use Storable qw(nstore retrieve);

our $index_file = "index.struct";
our $tags_file = "tags.struct";


my $fast = 1;
my $music_path = "/media/Canada/Music/";  # Should end with slash
my @music_exts = (".mp3", ".wma", ".mp4", ".ogg", ".m4a");

my $index = {};
my $tags = {
    AUTO => {},
    USER => {},
	FNAME => {}
};



{
    if (-e $index_file)
    {
        $index = retrieve($index_file);
    }
    
    if (-e $tags_file)
    {
        $tags = retrieve($tags_file);
    }
}


TagMaintenance::update_index($index, $tags, $fast, $music_path, \@music_exts);

{
    nstore $index, $index_file;
    nstore $tags, $tags_file;  
}

use Tk;


my $MW = MainWindow->new();

# Take up half the screen and centred
my $screen_width = $MW->screenwidth;
my $screen_height = $MW->screenheight;
my $mw_width = int($screen_width * 0.5);
my $mw_height = int($screen_height * 0.5);
my $mw_offset_x = int(($screen_width  - $mw_width ) / 2);
my $mw_offset_y = int(($screen_height  - $mw_height ) / 2);
$MW->geometry($mw_width . "x" . $mw_height . "+" . $mw_offset_x . "+" . $mw_offset_y);


#------------- Make list of all tags ------------- #

my @tags;

for my $auto_tag (keys %{$tags->{AUTO}})
{
	push @tags, "$auto_tag (AUTO)";
}

for my $user_tag (keys %{$tags->{USER}})
{
	push @tags, "$user_tag (USER)";
}

@tags = sort { lc($a) cmp lc($b) } @tags;

$MW->Scrolled("Listbox",
						-height => 10, 
						-listvariable => \@tags,
    					-background => "white",
    					-yscrollcommand => 1,
    					-width => 60)->pack;


MainLoop;


sub prune_list
{
    my ($prune_phrase, @list) = @_;

    my %pruned_list;

    for my $list_item (@list)
    {
		$pruned_list{$list_item} = 0;
        my @list_words = split " ", $list_item;

        for my $list_word (@list_words)
        {
            @prune_phase = split "", $prune_phrase;

            for my $prune_word (@prune_phase)
            {
                if ($list_word =~ $prune_word)
				{
                    $pruned_list{$list_item} += 1;
				}
            }
        }

		
    }
    return %pruned_list;
}






