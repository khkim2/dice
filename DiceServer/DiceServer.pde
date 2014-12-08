import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.net.*;

import toxi.geom.*;
import toxi.physics2d.*;

float GSENSOR_ROTATE = 26 * 3.14159f / 180.f;
float DICE_THRESHOLD = 8.0;

Minim minim;

FilePlayer beat, scratch;
FilePlayer[] phase1, phase2;
FilePlayer playing1, playing2;
Summer mixer;
AudioOutput out;

int port = 8080;       
Server server;        

PVector sensor = new PVector();
int number = 0;

// Reference to physics world
VerletPhysics2D physics;

// A list of cluster objects
Cluster cluster;
Cluster2 cluster2;

// Boolean that indicates whether we draw connections or not
boolean showPhysics = true;
boolean showParticles = true;

void setup()
{
  size(1024, 768);
  server = new Server(this, port);
  
  minim = new Minim(this);

  // get an AudioRecordingStream from Minim, which is what FilePlayer will control
  beat = new FilePlayer(minim.loadFileStream("1_Beat_bip.wav", 1024, true));
  beat.loop();

  scratch = new FilePlayer(minim.loadFileStream("Scratch_EFX_bip.wav", 1024, true));

  phase1 = new FilePlayer[6];
  phase2 = new FilePlayer[6];
  for (int i = 0; i < 6; i++)
  {
    phase1[i] = new FilePlayer(
      minim.loadFileStream("A_" + (i+1) + "_bip.wav", 1024, true));
    phase2[i] = new FilePlayer(
      minim.loadFileStream("B_" + (i+1) + "_bip.wav", 1024, true));
  }

  mixer = new Summer();
  out = minim.getLineOut();

  Gain gain = new Gain(-10);
  beat.patch(gain);  
  gain.patch(mixer);
  mixer.patch(out);

  // Initialize the physics
  physics = new VerletPhysics2D();
  physics.setWorldBounds(new Rect(10, 10, width-20, height-20));

  // Spawn a new random graph
  cluster = new Cluster(8, 100, new Vec2D(width/5, height/1.6));
  cluster2 = new Cluster2(6, 100, new Vec2D(width/1.3, height/3.3));
}

void setPlayer1(int index)
{
  if (playing1 != null) playing1.unpatch(mixer);
  scratch.unpatch(mixer);

  phase1[index].patch(mixer);
  playing1 = phase1[index];    
}

void setPlayer2(int index)
{
  if (playing2 != null) playing2.unpatch(mixer);
  scratch.unpatch(mixer);

  phase2[index].patch(mixer);
  playing2 = phase2[index];    
}

void playScratch()
{
  if (playing1 != null) playing1.unpatch(mixer);
  playing1 = null;
  
  if (playing2 != null) playing2.unpatch(mixer);
  playing2 = null;

  scratch.patch(mixer);
}

void keyPressed()
{
  if ('1' <= key && key <= '6')
    setPlayer1(key - '1');
  else if (key == 'q') setPlayer2(0);
  else if (key == 'w') setPlayer2(1);
  else if (key == 'e') setPlayer2(2);
  else if (key == 'r') setPlayer2(3);
  else if (key == 't') setPlayer2(4);
  else if (key == 'y') setPlayer2(5);
  else if (key == '0') playScratch();

  if (key == ' ') {
    physics.clear();
    cluster = new Cluster(int(random(1, 6)), random(100, width/4), new Vec2D(width/5, height/1.6));
    cluster2 = new Cluster2(int(random(1, 6)), random(100, width/3), new Vec2D(width/1.3, height/3.3));
  }
}

void draw()
{
  background(128);
  
  // Get the next available client
  Client thisClient = server.available();

  // If the client is not null, and says something, display what it said
  if (thisClient != null) {
    String message = thisClient.readStringUntil('\n');
    if (message != null) {
      String[] value = split(message, '|');
      if (value.length != 3)
      {
        println("ERROR: failed to parse message from client");
        return;
      }

      sensor.x = float(value[0]);
      sensor.y = float(value[1]);
      sensor.z = float(value[2]);

      PVector rotate_yz = new PVector(sensor.y, sensor.z);
      rotate_yz.rotate(-31 * 3.14159 / 180);
      sensor.y = rotate_yz.x;
      sensor.z = rotate_yz.y;      

      PVector rotate_xz = new PVector(sensor.x, sensor.z);
      rotate_xz.rotate(-57 * 3.14159 / 180);
      sensor.x = rotate_xz.x;
      sensor.z = rotate_xz.y;      
      
      //println("sensor: " + sensor.x + ", " + sensor.y + ", " + sensor.z);

      int new_number = -1;
      
      if (sensor.x > DICE_THRESHOLD) new_number = 1;
      else if (sensor.x < -DICE_THRESHOLD) new_number = 6;
      else if (sensor.y > DICE_THRESHOLD) new_number = 2;
      else if (sensor.y < -DICE_THRESHOLD) new_number = 5;
      else if (sensor.z > DICE_THRESHOLD) new_number = 3;
      else if (sensor.z < -DICE_THRESHOLD) new_number = 4;
      else new_number = 0;
      
      if (number != new_number)
      {
        println("update: " + number + " -> " + new_number);
        number = new_number;
        
        if (number == 0)
          playScratch();
        else
          setPlayer1(number - 1);
      }
    } 
  }
 
  line(width/2, height/2, 
    sensor.x / 9.8 * (width/2) + (width/2), 
    sensor.y / 9.8 * (height/2) + (height/2));
   
  text("" + number, 15, 15);  

  stroke(255);
  for (int i = 0; i < out.bufferSize() - 1; i++)
  {
    line(i, 50 + out.left.get(i)*50, i+1, 50 + out.left.get(i+1)*50);
    line(i, 150 + out.right.get(i)*50, i+1, 150 + out.right.get(i+1)*50);
  }

  // Update the physics world
  physics.update();

  // Display all points
  if (showParticles) {
    cluster.display();
    cluster2.display();
  }

  // If we want to see the physics
  if (showPhysics) {
    cluster.showConnections();
    cluster2.showConnections();
  }
}
