import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.net.*;

import toxi.geom.*;
import toxi.physics2d.*;

//float ROTATE_YZ = -31, ROTATE_XZ = -57;      
float ROTATE_YZ = 0, ROTATE_XZ = 0;      
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
int number1 = 1, number2 = 1;

// Reference to physics world
VerletPhysics2D physics;

// A cluster objects
Cluster cluster;

// Grid
int GridSize = 20;
int rows, cols;
PVector[][] pt;
color[][] fl;

void setup()
{
  size(800, 600);
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
  cluster = new Cluster();
  
  setPlayer1(number1 - 1);
  setPlayer2(number2 - 1);

  rows = height / GridSize;
  cols = width / GridSize;  
    
  // Initialize grid points
  colorMode(HSB, 255);
  pt = new PVector[rows+1][cols+1];
  fl = new color[rows+1][cols+1];
  for (int y = 0; y < rows+1; y++)
    for (int x = 0; x < cols+1; x++) {
      pt[y][x] = new PVector(
        // random in -GridSize/4 ~ +GridSize/4
        x * GridSize + random(-GridSize/4, GridSize/4), 
        y * GridSize + random(-GridSize/4, GridSize/4));
        // random HSB color
        fl[y][x] = color(0, random(180, 255), random(120, 255), 60);
    }
}

void setPlayer1(int index)
{
  if (!beat.isPlaying())
    beat.play();
  
  if (playing1 != null) playing1.unpatch(mixer);
  scratch.unpatch(mixer);

  phase1[index].play(beat.position());
  phase1[index].patch(mixer);
  playing1 = phase1[index];

  cluster.updateCluster1(index);  
}

void setPlayer2(int index)
{
  if (!beat.isPlaying())
    beat.play();

  if (playing2 != null) playing2.unpatch(mixer);
  scratch.unpatch(mixer);

  phase2[index].patch(mixer);
  playing2 = phase2[index];    

  cluster.updateCluster2(index);  
}

void playScratch()
{
  beat.pause();
  beat.rewind();
  
  if (playing1 != null) playing1.unpatch(mixer);
  playing1 = null;
  
  if (playing2 != null) playing2.unpatch(mixer);
  playing2 = null;

  scratch.patch(mixer);

  cluster.mergeCluster();
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
  else if (key == ' ') {
    setPlayer1((int)random(6));
    setPlayer2((int)random(6));
  }
}

void processClient(Client client)
{
  String message = client.readStringUntil('\n');
  if (message == null) return;
  
  // Ignore remain messages
  client.clear(); 
  
  String[] value = split(message, '|');
  if (value.length != 4)
  {
    println("ERROR: failed to parse message from client");
    return;
  }

  int ID = int(value[0]);
  //println(ID);
  sensor.x = float(value[1]);
  sensor.y = float(value[2]);
  sensor.z = float(value[3]);

  PVector rotate_yz = new PVector(sensor.y, sensor.z);
  rotate_yz.rotate(ROTATE_YZ * 3.14159 / 180);
  sensor.y = rotate_yz.x;
  sensor.z = rotate_yz.y;      

  PVector rotate_xz = new PVector(sensor.x, sensor.z);
  rotate_xz.rotate(ROTATE_XZ * 3.14159 / 180);
  sensor.x = rotate_xz.x;
  sensor.z = rotate_xz.y;      
  
  println("sensor: " + sensor.x + ", " + sensor.y + ", " + sensor.z);

  int new_number = -1;
  
  if (sensor.x > DICE_THRESHOLD) new_number = 1;
  else if (sensor.x < -DICE_THRESHOLD) new_number = 6;
  else if (sensor.y > DICE_THRESHOLD) new_number = 2;
  else if (sensor.y < -DICE_THRESHOLD) new_number = 5;
  else if (sensor.z > DICE_THRESHOLD) new_number = 3;
  else if (sensor.z < -DICE_THRESHOLD) new_number = 4;
  else new_number = 0;
  
  if (ID == 12 && number1 != new_number)
  {
    println("update1: " + number1 + " -> " + new_number);
    number1 = new_number;
    
    if (number1 == 0 || number2 == 0)
    {
      playScratch();
    }
    else
    {
      setPlayer1(number1 - 1);
      setPlayer2(number2 - 1);
    }
  }
  else if (ID == 34 && number2 != new_number)
  {
    println("update2: " + number2 + " -> " + new_number);
    number2 = new_number;
    
    if (number1 == 0 || number2 == 0)
    {
      playScratch();
    }
    else
    {
      setPlayer1(number1 - 1);
      setPlayer2(number2 - 1);
    }
  }
}

void updateGrid() {
  float[] buffer = beat.getLastValues();
  float level = 0;
  for (int i = 0; i < buffer.length; i++)
    level += buffer[i]*buffer[i];
  level = sqrt(level / buffer.length);
  level *= 10;

  for (int y = 0; y < rows; y++)
    for (int x = 0; x < cols; x++) {
      pt[y][x] = new PVector(
        pt[y][x].x + random(-level, level), 
        pt[y][x].y + random(-level, level)); 
        fl[y][x] = color(hue(fl[y][x]) + level, saturation(fl[y][x]), brightness(fl[y][x]), 60);
    }
}

void draw()
{
  background(0);

  // Network  
  Client thisClient = server.available();
  if (thisClient != null)
    processClient(thisClient);

  // Draw grid
  updateGrid();
  strokeWeight(0.5);
  for (int y = 0; y < rows; y++)
    for (int x = 0; x < cols; x++) {
      fill(0);
      stroke(fl[y][x]); 
      //fill(fl[y][x]);
      beginShape();
      vertex(pt[y][x].x, pt[y][x].y);
      vertex(pt[y][x+1].x, pt[y][x+1].y);
      vertex(pt[y+1][x+1].x, pt[y+1][x+1].y);
      vertex(pt[y+1][x].x, pt[y+1][x].y);
      endShape();
    }

  // Draw osiloscope
  Vec2D v1 = cluster.getCenter1();
  Vec2D v2 = cluster.getCenter2();
  //line(v1.x, v1.y, v2.x, v2.y);

  //stroke(255, 100 + out.mix.level()*800);
  stroke(100);
  strokeWeight(out.mix.level()*5);

  pushMatrix();
  translate(v1.x, v1.y);
  rotate(atan2(v2.y - v1.y, v2.x - v1.x));
  scale(v1.distanceTo(v2) / width, 1.0);
  
  int size = out.bufferSize();
  for (int i = 0; i < width; i++)
  {
    line(i, out.left.get(i % size) * 50, i+1, out.left.get((i+1) % size) * 50);
    line(i, out.right.get(i % size) * 50, i+1, out.right.get((i+1) % size) * 50);
  }
  popMatrix();

  // Update the physics world
  physics.update();

  // Draw cluster
  cluster.display();

  // Debug for g-sensor 
  stroke(255);
  strokeWeight(1);
  line(width/2, height/2, 
    sensor.x / 9.8 * (width/2) + (width/2), 
    sensor.y / 9.8 * (height/2) + (height/2));
  text("" + number1 + " " + number2, 15, 15);  
}
