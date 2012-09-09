use warnings;
use strict;

package TagFiles;

use Storable qw(nstore retrieve);

my $index_file = "index.struct";
my $tags_file = "tags.struct";


sub retrieve_memory_files
{
    my ($index, $tags) = @_;
    
my $index_file = "index.struct";
my $tags_file = "tags.struct";

    if (-e $index_file)
    {
        $index = retrieve($index_file);
    }
    
    if (-e $tags_file)
    {
        $tags = retrieve($tags_file);
    }
}

sub store_memory_files
{
    my ($index, $tags) = @_;
    
my $index_file = "index.struct";
my $tags_file = "tags.struct";
    
    nstore $index, $index_file;
    nstore $tags, $tags_file;  
}
1;