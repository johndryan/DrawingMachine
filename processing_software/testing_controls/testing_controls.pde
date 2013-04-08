import processing.serial.*;

Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port
Boolean pentoggle = false;

void setup() 
{
  size(200, 200);
  println(Serial.list());
  String portName = Serial.list()[4];
  myPort = new Serial(this, portName, 9600);
}

void draw() {
  
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
      case UP: 
        myPort.write("w");
        break;
      case DOWN: 
        myPort.write("s");
        break;
      case LEFT: 
        myPort.write("d");
        break;
      case RIGHT: 
        myPort.write("a");
        break;
    }
    println(keyCode);
  } else {
    switch(key) {
      case '-': 
        myPort.write("l");
        break;
      case '=': 
        myPort.write("m");
        break;
      case '[': 
        myPort.write("[");
        break;
      case ']': 
        myPort.write("]");
        break;
      case ' ':
        if (pentoggle) {
          myPort.write(",");
          pentoggle = false;
        } else {
          myPort.write(".");
          pentoggle = true;
        }
        break;
    }    
  }
}

void keyReleased() {
  myPort.write("x\n");
  println("STOP");
}
