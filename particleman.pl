#!/bin/perl

# attempt to convert particleman.c to Perl
require "/usr/local/lib/bclib.pl";
use OpenGL qw(:all);

# size currently ignored

# constants (of sorts)
$MAXPARTICLES = 65535;

# the interval for each redraw
$dt = .1;

# current "high water" particle (loops after hitting max)
$highwater = 0;

# defining the particle system
$num = 1.; # particles generated per time interval
$life = 800.; # life of each particle, in time units
$size_start = 0.001; # starting size of each particle
$size_end = 0.01; # ending size of each particle
%color_start = ("r",1,"g",1,"b",0); # starting color of each particle
%color_end = ("r",1,"g",0,"b",0); # ending color of each particle
%dir = ("x",0,"y",.02,"z",0); # direction in which particles are emitted
%turb_dir = ("x",0.01,"y",0,"z",0); # randomness of direction
%emitter = ("x",0,"y",-1,"z",0); # location of particle emitter
%gravity = ("x",0,"y",-.0001,"z",0); # the force of gravity (or whatever)

# originally main:
glutInit();

# use double buffering + depth buffering
glutInitDisplayMode(GLUT_DEPTH | GLUT_DOUBLE | GLUT_RGBA);

# optional: window size
glutInitWindowSize(800,600);

# create the window
glutCreateWindow("Particle Man");

# glutDisplayFunc(): what to do when display is damaged
glutDisplayFunc(display);

# glutIdleFunc(): what to do when application is idle
# often same as glutDisplayFunc()
glutIdleFunc(display);

glutMainLoop();

sub display {
  # update particles
  updateParticles();

  # clear buffer, translate
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glPushMatrix();

  # draw the particles
  for $i (@particles) {
    # skip dead particles
    if ($i->{size}==0) {next;}
    glBegin(GL_POINTS);
    glColor3f($i->{r},$i->{g},$i->{b});
    glVertex2f($i->{x},$i->{y});
    debug("DREW: ($i->{r},$i->{g},$i->{b},$i->{x},$i->{y})");
    glEnd();
  }

  glPopMatrix();
  glutSwapBuffers();
}

# update the particles (@particle and $t are global variables)
sub updateParticles () {
  my(@nparticle); # new particles

  # create new particles
  # TODO: this should be $num*$dt or something?
  for $i (1..$num) {
    # starting location = emitter
    for $j ("x","y","z") {$nparticle[$i]{$j} = $emitter{$j};}

    # starting direction
    for $j ("x","y","z") {$nparticle[$i]{"d$j"}=$dir{$j}+(rand()-.5)*$turb_dir{$j};}

    # starting color
    for $j ("r","g","b") {$nparticle[$i]{$j} = $color_start{$j};}

    # and size
    $nparticle[$i]{size} = $size_start;

    # and birth time
    $nparticle[$i]{birth} = $t;

  }

  # this list isglobal
  push(@particles, @nparticle);

  # random vector (list)
  @rand = (rand()-.5,rand()-.5,rand()-.5);

  # loop through particles
  for $i (@particles) {
    # age of this particle
    $age = $t-$i{birth};

    # if particle has exceeded lifetime, kill it (set size to 0)
    # ignore particles that already dead
    # TODO: should -1 be the "dead value" instead?
    # TODO: this is totally wrong for Perl?
    if ($age>$life||$i->{size}==0) {$i->{size}=0; next;}

    # adjust velocity
    for $j ("x","y","z") {$i->{"d$j"}+=$gravity{$j}*$dt;}

    # and position
    for $j ("x","y","z") {$i->{$j}+=$i->{"d$j"}*$dt;}

    # color (size is ignored for now)
    for $j ("r","g","b") {
      $i->{$j}=$color_start{$j}+($age/$life)*($color_end{$j}-$color_start{$j});
    }

    # TODO: maybe add bounce
  }

  # increment global time
  $t += $dt;
}
