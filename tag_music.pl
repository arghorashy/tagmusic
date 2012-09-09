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
    USER => {}
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






