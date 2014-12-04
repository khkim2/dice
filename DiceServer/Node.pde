// The Nature of Code
// <http://www.shiffman.net/teaching/nature>
// Spring 2010
// Toxiclibs example: http://toxiclibs.org/

// Force directed graph
// Heavily based on: http://code.google.com/p/fidgen/

// Notice how we are using inheritance here!
// We could have just stored a reference to a VerletParticle object
// inside the Node class, but inheritance is a nice alternative

class Node extends VerletParticle2D {

  Node(Vec2D pos) {
    super(pos);
  }

  // All we're doing really is adding a display() function to a VerletParticle
  void display() {
    fill(255,beat.left.level()*500);
    stroke(random(255), random(255), random(255));
    strokeWeight(beat.left.level()*50);
    ellipse(x,y,beat.left.level()*50,beat.left.level()*50);
  }
}

