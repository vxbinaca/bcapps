#!/bin/perl

# text browser for OSM (openstreetmap.org)

require "/usr/local/lib/bclib.pl";

# TODO: let user set these
$lat = 35.116;
$lon = -106.554;

# get OSM data for 3x3 .01^2 degrees around user
for $i (-1..1) {
  for $j (-1..1) {
    ($noderef, $wayref) = parse_file(get_osm($lat+$i*.01, $lon+$j*.01));
    push(@nodes, @{$noderef});
    push(@ways, @{$wayref});
  }
}

debug(unfold($ways[1]));

die "TESTING";

# for each node, add distance and direction (from user)
for $i (@nodes) {
  $i->{distance} = gcdist($lat, $lon, $i->{lat}, $i->{lon});
  $i->{direction} = atan2($i->{lat}-$lat, ($i->{lon}-$lon)*cos($lat/180*$PI))*180/$PI;
}

for $i (sort {$a->{distance} <=> $b->{distance}} @nodes) {
  if ($i->{name}) {
    print "$i->{name} at $i->{distance}, $i->{direction}; $i->{lat}, $i->{lon}\n";
  }
}

=item get_osm($lat, $lon)

Obtain AND cache (important!) the OSM data for the .01 degree box
whose lower left corner is $lat, $lon

$lat and $lon are truncated to 2 decimal places for caching

=cut

sub get_osm {
  my($lat, $lon) = @_;
  $lat = sprintf("%.2f", $lat);
  $lon = sprintf("%.2f", $lon);

  # where to store this
  my($sha) = sha1_hex("$lat,$lon");

  # .01 degree tiles -> 360*100*180*100 = ~648M tiles total, so
  # splitting into dirs
  $sha=~m%^(..)(..)%;
  my($dir) = "/var/tmp/OSM/cache/$1/$2";

  # does it already exist?
  if (-f "$dir/$sha") {return read_file("$dir/$sha");}

  # TODO: test that below works
  system("mkdir -p $dir");

  # and get the data
 my($cmd) = sprintf("curl -o $dir/$sha 'http://api.openstreetmap.org/api/0.6/map/?bbox=%.2f,%.2f,%.2f,%.2f'", $lon, $lat, $lon+.01, $lat+.01);

  my($out, $err, $res) = cache_command($cmd);
}

# parses the result of what the API sends us

sub parse_file {
  my($data) = @_;
  my(@nodes);

  # convert <node .../> to <node ...></node>
  $data=~s%<(node[^>]*)/>%<$1></node>%isg;

  # handle nodes
  while ($data=~s%<node(.*?)>(.*?)</node>%%s) {
    my($head, $tags) = ($1, $2);

    # store node data in hash
    my(%node) = ();

    # values in tag itself
    while ($head=~s/(\S+)\=\"(.*?)\"//) {$node{$1} = $2;}

    # tag values
    while ($tags=~s%<tag k="(.*?)" v="(.*?)"/>%%s) {$node{$1} = $2;}

    push(@nodes, {%node});
  }

  # <h>ooh, baby I love your</h> ways
  while ($data=~s%<way(.*?)>(.*?)</way>%%is) {
    my($head, $tags) = ($1, $2);

    #<h>The following line of code is in tribute to Frank Sinatra</h>
    my(%way) = ();
    # list of nodes for this way
    my(@nodelist);

    # values in tag itself
    while ($head=~s/(\S+)\=\"(.*?)\"//) {$way{$1} = $2;}

    # tag values
    while ($tags=~s%<tag k="(.*?)" v="(.*?)"/>%%s) {$way{$1} = $2;}

    # nodes in way
    while ($tags=~s%<nd ref="(.*?)"/>%%) {push(@nodelist,$1);}
    
    $way{nodelist} = [@nodelist];
    push(@ways, {%way});

  }

  $data=~s/\s+/ /isg;
  debug("LEFT: $data");

  return [{@nodes}, {@ways}];
}




