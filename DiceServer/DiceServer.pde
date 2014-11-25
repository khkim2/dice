import processing.net.*;

int port = 8080;       
Server server;        

float threshold = 8.0;
float sensorX, sensorY, sensorZ;
int number = 0;

void setup()
{
  size(400, 400);
  server = new Server(this, port);
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
}
