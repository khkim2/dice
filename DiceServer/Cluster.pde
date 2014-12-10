// The Nature of Code
// <http://www.shiffman.net/teaching/nature>
// Spring 2010
// Toxiclibs example: http://toxiclibs.org/

// Force directed graph
// Heavily based on: http://code.google.com/p/fidgen/

class Cluster {

  // A cluster is a grouping of nodes
  ArrayList<Node> nodes1, nodes2;
 
  Cluster() {
    nodes1 = new ArrayList<Node>();
    nodes2 = new ArrayList<Node>();

    updateCluster1(0);
    updateCluster2(0);    
  }
  
  void updateCluster1(int index) {
    updateCluster(nodes1, (index+1) * 2 + 1, random(180, width/4), new Vec2D(width/5, height/1.6));
  }
  
  void updateCluster2(int index) {
    updateCluster(nodes2, (index+1) * 2 + 1, random(180, width/3), new Vec2D(width/1.3, height/3.3));
  }
  
  void mergeCluster() {
    for (int i = 0; i < nodes1.size(); i++) {
      VerletParticle2D n1 = nodes1.get(i);
      for (int j = 0; j < nodes2.size(); j++) {
        VerletParticle2D n2 = nodes2.get(j);
        float diameter = random(10, 150);
        
        physics.addSpring(new VerletSpring2D(n1, n2, diameter, 0.002));
      }
    }
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
        physics.addSpring(new VerletSpring2D(ni, nj, diameter, 0.005));
      }
    }
  }

  Vec2D getCenter1() {
    return averageNodes(nodes1);
  }
  
  Vec2D getCenter2() {
    return averageNodes(nodes2);
  }

  Vec2D averageNodes(ArrayList<Node> nodes) {
    Vec2D sum = new Vec2D(0, 0);
    for (int i = 0; i < nodes.size(); i++)
      sum = sum.add(nodes.get(i));
      
    return new Vec2D(sum.x / nodes.size(), sum.y / nodes.size());
  } 
  
  void display() {
    display(nodes1, playing1 != null ? playing1 : scratch);
    display(nodes2, playing2 != null ? playing2 : scratch);
  }

  void display(ArrayList<Node> nodes, FilePlayer player) {
    float[] buffer = player.getLastValues();
    float level = 0;
    for (int i = 0; i < buffer.length; i++)
      level += buffer[i]*buffer[i];
    level = sqrt(level / buffer.length);

    // Draw nodes
    for (Node n : nodes)
      n.display(level);

    // Draw lines between nodes    
    stroke(255, 150 + level*800);
    strokeWeight(level*15);
    
    for (int i = 0; i < nodes.size()-1; i++) {
      VerletParticle2D pi = (VerletParticle2D) nodes.get(i);
      for (int j = i+1; j < nodes.size(); j++) {
        VerletParticle2D pj = (VerletParticle2D) nodes.get(j);

        line(pi.x, pi.y+out.left.get(i)*50, pj.x, pj.y+out.right.get(i)*50);
      }
    }
  }
}
