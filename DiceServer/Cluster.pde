// The Nature of Code
// <http://www.shiffman.net/teaching/nature>
// Spring 2010
// Toxiclibs example: http://toxiclibs.org/

// Force directed graph
// Heavily based on: http://code.google.com/p/fidgen/

class Cluster {

  // A cluster is a grouping of nodes
  ArrayList<Node> nodes;
 
  Cluster(int n, float diameter, Vec2D center) {
    // Initialize the ArrayList
    nodes = new ArrayList<Node>();
    
    updateCluster(nodes, n, diameter, center);
  }
  
  void updateCluster1(int index) {
    updateCluster(nodes, (index+1) * 2, random(100, width/4), new Vec2D(width/5, height/1.6));
  }
  
  // Update a Cluster with a number of nodes, a diameter, and centerpoint
  void updateCluster(ArrayList<Node> nodes, int n, float diameter, Vec2D center) {
    // Clear the existing nodes
    for (int i = 0; i < nodes.size(); i++)
      physics.removeParticle(nodes.get(i));
    nodes.clear();
    
    // Create the nodes
    for (int i = 0; i < n; i++) {
      // We can't put them right on top of each other
      nodes.add(new Node(center.add(Vec2D.randomVector())));
    }

    // Connect all the nodes with a Spring
    for (int i = 0; i < nodes.size()-1; i++) {
      VerletParticle2D ni = nodes.get(i);
      for (int j = i+1; j < nodes.size(); j++) {
        VerletParticle2D nj = nodes.get(j);
        // A Spring needs two particles, a resting length, and a strength
        physics.addSpring(new VerletSpring2D(ni, nj, diameter, 0.01));
      }
    }
  }

  void display() {
    // Show all the nodes
    for (Node n : nodes) {
      n.display();
    }
  }

  // Draw all the internal connections
  void showConnections() {
    stroke(255, 100 + out.left.level()*800);
    strokeWeight(out.left.level()*5);
    for (int i = 0; i < nodes.size()-1; i++) {
      VerletParticle2D pi = (VerletParticle2D) nodes.get(i);
      for (int j = i+1; j < nodes.size(); j++) {
        VerletParticle2D pj = (VerletParticle2D) nodes.get(j);

        line(pi.x, pi.y+out.left.get(i)*50, pj.x, pj.y+out.right.get(i)*50);
      }
    }
  }
}
