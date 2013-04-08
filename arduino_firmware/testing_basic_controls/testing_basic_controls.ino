#include <AccelStepper.h>
#include <Servo.h> 

int mSpeed = 500;
int maxSpeed = 4000;
char incomingByte;
boolean isRunning = false;
boolean paperRunning = false;

Servo myservo;
AccelStepper stepper1(1, 3, 2);
AccelStepper stepper2(1, 5, 4);
AccelStepper stepper3(1, 7, 6);

void setup() {
  Serial.begin(9600);
  myservo.attach(9);
  
  stepper1.setMaxSpeed(maxSpeed);
  stepper1.setSpeed(mSpeed);
  stepper2.setMaxSpeed(maxSpeed);
  stepper2.setSpeed(mSpeed);
  stepper3.setMaxSpeed(maxSpeed);
  stepper3.setSpeed(mSpeed);
} 

void loop(){
  
  if (Serial.available() > 0) {
    incomingByte = Serial.read();
    Serial.write(incomingByte);
    
    switch (incomingByte) {
      case 'w':
        // UP
        Serial.write("UP");
        isRunning = true;
        stepper1.setSpeed(-mSpeed);
        stepper2.setSpeed(mSpeed);
        break;
      case 's':
        // DOWN
        Serial.write("DOWN");
        isRunning = true;
        stepper1.setSpeed(mSpeed);
        stepper2.setSpeed(-mSpeed);
        break;
      case 'a':
        // LEFT
        Serial.write("LEFT");
        isRunning = true;
        stepper1.setSpeed(mSpeed);
        stepper2.setSpeed(mSpeed);
        break;
      case 'd':
        // RIGHT
        Serial.write("RIGHT");
        isRunning = true;
        stepper1.setSpeed(-mSpeed);
        stepper2.setSpeed(-mSpeed);
        break;
      case 'm':
        // ACCELERATE
        mSpeed *= 1.3;
        Serial.write(mSpeed);
        break;
      case 'l':
        // DECELERATE
        mSpeed /= 1.3;
        Serial.write(mSpeed);
        break;
      case '.':
        // PEN UP
        Serial.write("PEN UP");
        myservo.write(115);
        break;
      case ',':
        // PEN DOWN
        Serial.write("PEN DOWN");
        myservo.write(155);
        break;
      case '[':
        // PAPER UP
        Serial.write("PAPER UP");
        paperRunning = true;
        stepper3.setSpeed(mSpeed);
        break;
      case ']':
        // PAPER DOWN
        Serial.write("PAPER DOWN");
        paperRunning = true;
        stepper3.setSpeed(-mSpeed);
        break;
      default :
        isRunning = false;
        paperRunning = false;
//        stepper1.stop();
//        stepper2.stop();
    }
  }
    
  if (isRunning) {
    stepper1.runSpeed();
    stepper2.runSpeed();
  }
  if (paperRunning) {
    stepper3.runSpeed();
  }
}
