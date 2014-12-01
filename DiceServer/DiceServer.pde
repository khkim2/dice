import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.net.*;

Minim minim;

AudioPlayer beat, scratch;
AudioPlayer[] phase1, phase2;
AudioPlayer playing1, playing2;

int port = 8080;       
Server server;        

float threshold = 8.0;
float sensorX, sensorY, sensorZ;
int number = 0;

void setup()
{
  size(400, 400);
  server = new Server(this, port);
  
  minim = new Minim(this);

  beat = minim.loadFile("1_Beat_bip.mp3");
  beat.setGain(-10);
  beat.loop();
  
  scratch = minim.loadFile("Scratch_EFX_bip.mp3");

  phase1 = new AudioPlayer[6];
  phase2 = new AudioPlayer[6];
  
  for (int i = 0; i < 6; i++)
  {
    phase1[i] = minim.loadFile("A_" + (i+1) + "_bip.mp3");
    phase2[i] = minim.loadFile("B_" + (i+1) + "_bip.mp3");
  }
}

void setPlayer1(int index)
{
  if (playing1 != null) playing1.pause();
  if (scratch.isPlaying()) scratch.pause();
    
  phase1[index].cue(beat.position());
  phase1[index].loop();

  playing1 = phase1[index];    
}

void setPlayer2(int index)
{
  if (playing2 != null) playing2.pause();
  if (scratch.isPlaying()) scratch.pause();
    
  phase2[index].cue(beat.position());
  phase2[index].loop();

  playing2 = phase2[index];    
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
  else if (key == '0')
  {
    scratch.cue(0);
    scratch.loop();
    
    if (playing1 != null) playing1.pause();
    playing1 = null;
    
    if (playing2 != null) playing2.pause();
    playing2 = null;
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
      String[] sensor = split(message, '|');
      if (sensor.length != 3)
      {
        println("ERROR: failed to parse message from client");
        return;
      }
      
      sensorX = float(sensor[0]);
      sensorY = float(sensor[1]);
      sensorZ = float(sensor[2]);
      
      println("sensor: " + sensorX + ", " + sensorY + ", " + sensorZ);
      
      if (sensorX > threshold) number = 1;
      else if (sensorX < -threshold) number = 6;
      else if (sensorY > threshold) number = 2;
      else if (sensorY < -threshold) number = 5;
      else if (sensorZ > threshold) number = 3;
      else if (sensorZ < -threshold) number = 4;
      else number = 0;
    } 
  }
 
  line(width/2, height/2, 
    sensorX / 9.8 * (width/2) + (width/2), 
    sensorY / 9.8 * (height/2) + (height/2));
   
  text("" + number, 15, 15);  

  stroke(255);
  for (int i = 0; i < beat.bufferSize() - 1; i++)
  {
    line(i, 50 + beat.left.get(i)*50, i+1, 50 + beat.left.get(i+1)*50);
    line(i, 150 + beat.right.get(i)*50, i+1, 150 + beat.right.get(i+1)*50);
  }
}
