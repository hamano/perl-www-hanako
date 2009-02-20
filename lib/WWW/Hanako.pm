package WWW::Hanako;

use 5.010000;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use WWW::Mechanize;
use Web::Scraper;

our @ISA = qw();

our $VERSION = '0.02';

my $HANAKO_BASE_URI = 'http://kafun.taiki.go.jp/';

# Preloaded methods go here.

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {
        area => $_{area} || 0,
        mst => $_{mst} || 0,
        mech => WWW::Mechanize->new(agent=>"Net-Hanako/$VERSION"),
        debug => 0,
    };
    %$self = (%$self, @_);
    bless($self, $class);
    return $self;
}

sub today
{
    my $self = shift;
    my @ret;
    my $path = sprintf("Hyou0.aspx?MstCode=%d&AreaCode=%02d",
                       $self->{'mst'}, $self->{'area'});
    my $uri = $HANAKO_BASE_URI . $path;
    my $uri2 = $HANAKO_BASE_URI . "Hyou2.aspx";

    if($self->{debug}){
        print "uri: $uri\n";
        print "uri2: $uri2\n";
    }

    # set cookie
    $self->{mech}->get($uri);
    # get cookie
    $self->{mech}->get($uri2);

    if(!$self->{mech}->success()){
        carp("error");
        return;
    }

    if($self->{mech}->status() != 200){
        carp("response code: " . $self->{mech}->status());
        return;
    }

    my $content = $self->{mech}->content();

    my $scraper = scraper {
        process '//table[@class="bun"]/tr[2]/td/font', 'head[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[1]/font', 'hour[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[2]/font', 'pollen[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[3]/font', 'wd[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[4]/font', 'ws[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[5]/font', 'temp[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[6]/font', 'prec[]' => 'TEXT';
        process '//table[@class="bun"]/tr/td[7]/font', 'prec_bool[]' => 'TEXT';
    };
    my $res = $scraper->scrape($content);
    if(!$res->{"hour"}){
        carp("scrape error");
        return;
    }

    my $num = @{$res->{"hour"}};
    for my $i (0 .. @{$res->{"hour"}} - 3){
        my $hour = $res->{'hour'}->[$i+2];
        $hour =~ s/^(\d*)\x{6642}/$1/;
        my $pollen = $res->{'pollen'}->[$i+2];
        my $wd = $res->{'wd'}->[$i];
        my $ws = $res->{'ws'}->[$i+2];
        my $temp = $res->{'temp'}->[$i];
        my $prec = $res->{'prec'}->[$i];

        push(@ret, {hour => $hour,
                    pollen => $pollen,
                    ws => $ws,
                    temp => $temp,
                    prec => $prec});
    }
    return @ret;
}

sub now
{
    my $self = shift;
    my @today = $self->today();
    my $ret = pop(@today);
    return $ret;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

WWW::Hanako - Perl interface for Hanako(Pollen observation system at Japan)

=head1 SYNOPSIS

  use WWW::Hanako;
  my $hanako = WWW::Hanako->new(area=>3, mst=>51300200);
  print $hanako->now()->{pollen} . "\n";

=head1 DESCRIPTION

This perl module provides an interface to the Hanako that is Pollen
observation system at Japan.

=head1 METHODS

=head2 new
Create new instance of WWW::Hanako

=head2 today
Method that returns the today's information.

=head2 now
Method that returns the current information.

=head1 SEE ALSO

See http://kafun.taiki.go.jp/ for more information on Hanako

=head1 AUTHOR

Tsukasa Hamano, E<lt>hamano@klab.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tsukasa Hamano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
