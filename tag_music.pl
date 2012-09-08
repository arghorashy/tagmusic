use warnings;
use strict;

use File::Find;
use Digest::MD5;
use Storable qw(nstore retrieve);
use File::Basename;


my $fast = 0;
my $music_path = "/media/Canada/Music";
my @music_exts = (".mp3", ".wma", ".mp4", ".ogg", ".m4a");

my $index_file = "index.struct";
my $tags_file = "tags.struct";
my $index = {};
my $tags = {
    AUTO => {},
    USER => {}
};


retrieve_memory_files($index, $tags);

# If index file retrieved, prepare list of existing paths
my $existing_paths;
if (defined $index)
{
    make_existing_filelist($existing_paths, $index);
}

# Walk directory and apply function
find sub{update_index($index, $tags, $fast)}, $music_path;

# Delete relative path entries to delete files from index
remove_deleted_files($index, $existing_paths);




# store index and tags
store_memory_files($index, $tags);





sub retrieve_memory_files
{
    my ($index, $tags) = @_;
    
    if (-e $index_file)
    {
        $index = retrieve($index_file);
    }
    
    if (-e $tags_file)
    {
        $tags = retrieve($tags_file);
    }
}

sub make_existing_filelist
{
    my ($existing_paths, $index);
    
    for my $hash (keys %$index)
    {
        for my $rel_path (@{$index->{$hash}->{REL_PATH}})
        {
            $existing_paths->{$rel_path}->{HASH} = $hash;
            $existing_paths->{$rel_path}->{FOUND} = 0;
        }
    } 
    
}

sub update_index
{
    # How to get this to work?
    my ($index, $tags, $fast) = @_;
    
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

    # if relative path already exists, make a note and stop function (fast check)
    if (exists $existing_paths->{$relative_name}->{HASH}
        && $fast)
    {
        print "already found $relative_name\n";
        $existing_paths->{$relative_name}->{FOUND} = 1;
        return 0;
    }
    
    # if relative path already exists and hashes are identical, make a note and
    # stop function (slow check)
    {
        # hash file
        open my $MUSIC, '<', $full_name;
        my $md5 = Digest::MD5->new;
        $md5->addfile($MUSIC);
        my $hash = $md5->b64digest;
        close $MUSIC;
    
        if (exists $existing_paths->{$relative_name}->{HASH}
            && $hash eq $existing_paths->{$relative_name}->{HASH}
            && ! $fast)
        {
            print "already found identical file $relative_name\n";
            $existing_paths->{$relative_name}->{FOUND} = 1;
            return 0;
        }
    }
    
    # if file not found, add to index
    # if slow process used and files found to be changed, add new file to index
    # (old entry will be deleted later)
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
        
        # add file to existing _paths also
        $existing_paths->{$relative_name}->{HASH} = $hash;
        $existing_paths->{$relative_name}->{FOUND} = 1;
        
        
        print "added   $hash";
    }
    
    print  "   " . $relative_name . "\n";
}


# if a file was found to be deleted, it should be removed from the index
sub remove_deleted_files
{
    my ($index, $existing_paths) = @_;
    
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
}

sub store_memory_files
{
    my ($index, $tags) = @_;
    
    nstore $index, $index_file;
    nstore $tags, $tags_file;  
}
