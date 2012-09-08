use warnings;
use strict;

use File::Find;
use Digest::MD5;
use Storable qw(nstore retrieve);
use File::Basename;


my $music_path = "/media/Canada/Music/";
my @music_exts = (".mp3", ".wma", ".mp4", ".ogg", ".m4a");
my $index_file = "index.struct";
my $index;
my $tags = {
    AUTO => {},
    USER => {}
};



# Get saved index file, if it exists
if (-e $index_file)
{
    $index = retrieve($index_file);
}

# If index file retrieved, prepare list of existing paths
my $existing_paths;
if (defined $index)
{
    for my $hash (keys %$index)
    {
        for my $rel_path (@{$index->{$hash}->{REL_PATH}})
        {
            $existing_paths->{$rel_path}->{HASH} = $hash;
            $existing_paths->{$rel_path}->{FOUND} = 0;
        }
    } 
}

my $create_file_hash = sub
{
    # How to get this to work?
    #my ($index) = @_;
    
    # Get full path name
    my $full_name = $File::Find::name;
    
    # If file is directory, skip
    if (-d $full_name)
    {
        return 0;
    }
    
    # Get relative path
    my $relative_name = $full_name;
    $relative_name =~ s/$music_path//g;

    # If file has wrong ext, skip
    my $right_ext = 0;
    for my $ext (@music_exts)
    {
        if ($full_name =~ m/$ext/)
        {
            $right_ext = 1;
        }
    }
    if (! $right_ext)
    {
        print "skipped $relative_name\n";
        return 0;
    }

    # if relative path already exists, make a note and stop function
    if (exists $existing_paths->{$relative_name}->{HASH})
    {
        print "already found $relative_name\n";
        $existing_paths->{$relative_name}->{FOUND} = 1;
        return 0;
    }
    # if not, add to index
    else
    {
        # hash file
        open my $MUSIC, '<', $full_name;
        my $md5 = Digest::MD5->new;
        $md5->addfile($MUSIC);
        my $hash = $md5->b64digest;
        close $MUSIC;
        
        # save the relative path for the file that produced this hash
        push @{$index->{$hash}->{REL_PATH}}, $relative_name;
        
        # get auto tags
        my @autotags = split "/", $relative_name;
        for my $tag (@autotags)
        {
            $tag =~ s/\.[a-z0-9A-Z]+//g;
            $tags->{AUTO}->{$tag} = $tag;
            $index->{$hash}->{TAGS}->{AUTO}->{$tag} = $tag;
            print "added tag $tag to relative path $relative_name\n";
        }
        
        
        
        $existing_paths->{$relative_name}->{HASH} = $hash;
        $existing_paths->{$relative_name}->{FOUND} = 1;
        


        print "added   $hash";
    }
    
    print  "   " . $relative_name . "\n";
};

# Walk directory and apply function
find $create_file_hash, $music_path;

# Delete relative path entries to delete files from index
for my $rel_path (keys %$existing_paths)
{
    if ($existing_paths->{$rel_path}->{FOUND} eq 0)
    {
        my $hash = $existing_paths->{$rel_path}->{HASH};
        
        
        @{$index->{$hash}->{REL_PATH}} = grep {$_ ne $rel_path} @{$index->{$hash}->{REL_PATH}};
        print "delete relative path $rel_path from hash $hash\n";
        
        # Delete hash entry in index if no more associated paths left
        if ((scalar @{$index->{$hash}->{REL_PATH}}) eq 0)
        {
            delete $index->{$hash};
            print "delete hash $hash";
        }
    }
}

# store index
nstore $index, $index_file;

exit;

