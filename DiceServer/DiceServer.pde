import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import processing.net.*;

float GSENSOR_ROTATE = 26 * 3.14159f / 180.f;
float DICE_THRESHOLD = 8.0;

Minim minim;

AudioPlayer beat, scratch;
AudioPlayer[] phase1, phase2;
AudioPlayer playing1, playing2;

int port = 8080;       
Server server;        

PVector sensor = new PVector();
int number = 0;

void setup()
{
  size(400, 400);
  server = new Server(this, port);
  
  minim = new Minim(this);

  beat = minim.loadFile("1_Beat_bip.wav");
  beat.setGain(-10);
  beat.loop();
  
  scratch = minim.loadFile("Scratch_EFX_bip.wav");

  phase1 = new AudioPlayer[6];
  phase2 = new AudioPlayer[6];
  
  for (int i = 0; i < 6; i++)
  {
    phase1[i] = minim.loadFile("A_" + (i+1) + "_bip.wav");
    phase2[i] = minim.loadFile("B_" + (i+1) + "_bip.wav");
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

void playScratch()
{
  scratch.cue(0);
  scratch.loop();
  
  if (playing1 != null) playing1.pause();
  playing1 = null;
  
  if (playing2 != null) playing2.pause();
  playing2 = null;
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
  for (int i = 0; i < beat.bufferSize() - 1; i++)
  {
    line(i, 50 + beat.left.get(i)*50, i+1, 50 + beat.left.get(i+1)*50);
    line(i, 150 + beat.right.get(i)*50, i+1, 150 + beat.right.get(i+1)*50);
  }
}
