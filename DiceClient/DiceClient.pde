import processing.net.*;

//String ip = "127.0.0.1";
//String ip = "192.168.2.1";
String ip = "169.254.53.22";
int port = 8080;
Client client; 

float posX, posY, posZ; 
 
void setup() { 
  size(200, 200); 
  client = new Client(this, ip, port); 
} 

void mouseDragged() {
  posX = (float)mouseX/width*2*9.8-9.8;
  posY = (float)mouseY/height*2*9.8-9.8;
  posZ = sqrt(9.8*9.8 - posX*posX - posY*posY);
  client.write(posX + "|" + posY + "|" + posZ + "\n");
}
 
void draw() {
  background(0);
  fill(128);
  ellipse(width/2, height/2, width, height);
  fill(128);
  text("pos: " + posX + ", " + posY, 5, 15);
}
