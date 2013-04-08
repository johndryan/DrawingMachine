import processing.serial.*;

import geomerative.RG;
import geomerative.RPath;
import geomerative.RPoint;
import geomerative.RShape;

import controlP5.*;

import java.io.File;
import java.io.FilenameFilter;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

//import MyPoint;
  
String BUFFER_ACC_PATH = "buffer_acc/";
String BUFFER_DONE_PATH = "buffer_done/";
String BUFFER_DENIED_PATH = "buffer_denied/";
    
int MAX_PLOTTER_X = 13940; //7000;
int MAX_PLOTTER_Y = 13500; //8000;
  
  //private static final int MAX_SCREEN_X = 800;
int MAX_SCREEN_Y = 700; 
int MENU_X = 190;
  
int SCREEN_PADDING = 20;
  
int START_X = 6000; //2000 //4000
int START_Y = 3500; //2000 //4000
int HOME_X = 9620; //7500
int HOME_Y = 9620; //7500
  
int STATE_START = 1;
int STATE_WAITING = 2;
int STATE_PLOTTING_SCREEN = 3;
int STATE_WAITING_INPUT = 4;
int STATE_SETUP_PLOTTER = 5;
int STATE_PLOTTING = 6;
int STATE_PAUSED = 7;
int STATE_RESUME = 8;
int STATE_ABORTING = 9;
int STATE_FINISHING = 10;

int state = STATE_START;
int oldState = STATE_START;
  
String[] STATES = {
    "NONE", "START", "WAITING", "PLOTTING_SCREEN", "WAITING_INPUT", "SETUP_PLOTTER", "PLOTTING", "PAUSED", "RESUME",
    "ABORTING", "FINISHING"
  };
  
int BACKGROUND_STD = 0xFFA0A0A0;
int BACKGROUND_PAUSED = 0xFFA07070;
int CANVAS_BACKGROUND_BLACK = 0xFF202020;
int CANVAS_BACKGROUND_WHITE = 0xFFFFFFFF;
int SHAPE_STROKE_BLACK = 0xFF000000;
int SHAPE_STROKE_WHITE = 0xFFFFFFFF;
int PLOTTER_STD = 0x642186F8;
int PLOTTER_PAUSED = 0x64FE1A1A; 
int PLOTTER_FINISHED = 0x641AFE1A; 
  // private static final float STROKE_WEIGHT_GRID = 10.0F;
float STROKE_WEIGHT_GRID = 1.0F;
int STROKE_GRID = 0xFFD0D0D0;  
  // private static final float STROKE_WEIGHT_SHAPE = 10.0F;
float STROKE_WEIGHT_SHAPE = 1.0F;
int STROKE_SHAPE = 0xFF808080;
float DELTA_STEP = 20.0F;
float MAX_COMPARE_DELTA = 70.0F;
  
float screenScale = 0.0F;
float plotterScale = 1.0F;
float svgScale = 5.0F;

float dx, dy = 0.0F;
  
ControlP5 cp5;
ControlP5 cp5files;
Button startButton;
Button pauseButton;
Button stopButton;
Button leftButton;
DropdownList portsList;
DropdownList filesList;
Textfield statusField;
PGraphics graphics;
RShape shape;
Serial port;
Kritzler plotter;
List<Instruction> currentInstructions;
String[] ports;
String[] fileNames;
String currentFileName;

long nextUpdate = 0;  
  
boolean buttonsEnabled = false;
boolean plotting = false;
boolean useCache = false;

boolean drawGrid = true;
boolean drawBoundingBox = true;
boolean blackOnWhite = true;
int canvasBackground = CANVAS_BACKGROUND_WHITE;
int shapeStroke = SHAPE_STROKE_BLACK;

/**
 * Initial sketch set up
 * 
 * @see processing.core.PApplet#setup()
 */
void setup() {

  // Set up the Geomerative library
  RG.init(this);

  // Determine the screen scale and window size
  screenScale = (MAX_SCREEN_Y - 2F * SCREEN_PADDING) / MAX_PLOTTER_Y;
  int xsize = (int)(MAX_PLOTTER_X * screenScale) + 2 * SCREEN_PADDING;
  int ysize = (int)(MAX_PLOTTER_Y * screenScale) + 2 * SCREEN_PADDING;
  System.out.println(screenScale + " " + xsize + " " + ysize);
  // screenScale *= 10;
  
  smooth();
  size(xsize + MENU_X, ysize);
  
  graphics = createGraphics((int)(MAX_PLOTTER_X * screenScale), (int)(MAX_PLOTTER_Y * screenScale), P2D);
  // graphics.smooth();  // do this after beginDraw()
  
  background(BACKGROUND_STD);

  cp5 = new ControlP5(this);
  cp5files = new ControlP5(this);

  // move buttons
  Button upButton = cp5.addButton("up")
    .setLabel("up")
    .setWidth(150)
    .setPosition(xsize + 10, 20);      
  upButton.getCaptionLabel().align(CENTER, CENTER);
  leftButton = cp5.addButton("left")
    .setLabel("left")
    .setWidth(74)
    .setPosition(xsize + 10, 40);  
  cp5.addButton("right")
    .setLabel("right")
    .setWidth(75)
    .setPosition(xsize + 85, 40);      
  Button downButton = cp5.addButton("down")
    .setLabel("down")
    .setWidth(150)
    .setPosition(xsize + 10, 60);
  downButton.getCaptionLabel().align(CENTER, CENTER);    
  cp5.addTextlabel("moveLabel")
  .setText("MOVE")
  .setPosition(xsize + 8, 82)
  ;     
  
  // scale buttons
  cp5.addButton("scaleUp")
    .setLabel("up")
    .setWidth(74)
    .setPosition(xsize + 10, 100);  
  cp5.addButton("scaleDown")
    .setLabel("Down")
    .setWidth(75)
    .setPosition(xsize + 85, 100);
  cp5.addTextlabel("label")
    .setText("SCALE")
    .setPosition(xsize + 8, 122)
    ; 
  
  // flip/mirror switches
  int y = 140;
  cp5.addToggle("toggleHorizontal")
    .setLabel("flip horizontal")
    .setPosition(xsize + 10, y)
    .setSize(25,10)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    ;
  cp5.addToggle("toggleVertical")
    .setLabel("flip vertical")
    .setPosition(xsize + 10, y + 30)
    .setSize(25,10)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    ;       
  cp5.addToggle("toggleBW")
    .setLabel("toggle B/W")
    .setPosition(xsize + 10, y + 60)
    .setSize(25,10)
    .setValue(false)
    .setMode(ControlP5.SWITCH)
    ;       

  // setup serial ports
  y = 250;
  cp5.addTextlabel("serlabel")
    .setText("SERIAL")
    .setPosition(xsize + 8, y + 2)
    ;
  portsList = cp5.addDropdownList("ports")
    .setPosition(xsize + 10, y)
    .setItemHeight(15)
    .setHeight(60)
    .setWidth(150)
    .setBarHeight(15)
    .setIndex(0)
  ;
  portsList.getCaptionLabel().getStyle().marginTop = 3;
  portsList.getCaptionLabel().getStyle().marginLeft = 3;
  portsList.getValueLabel().getStyle().marginTop = 3;

  ports = Serial.list();
  println(ports);
  for (int i = 0; i < ports.length; i++) {
    portsList.addItem(ports[i], i);
  }
   
  // startSerial(ports[1]); // default
  String portName = Serial.list()[4];
  port = new Serial(this, portName, 57600);  
  
  // setup files
  y = 310;
  cp5.addTextlabel("filelabel")
    .setText("SELECT FILE")
    .setPosition(xsize + 8, y + 2)
    ;
  filesList = cp5.addDropdownList("files")
    .setPosition(xsize + 10, y)
    .setBarHeight(15)
    .setItemHeight(15)
    .setHeight(60)
    .setWidth(150)
    .setIndex(0)
    ;    
  filesList.getCaptionLabel().getStyle().marginTop = 3;
  filesList.getCaptionLabel().getStyle().marginLeft = 3;
  filesList.getValueLabel().getStyle().marginTop = 3;
  updateFileList(); 
  if (fileNames != null) {
    currentFileName = fileNames[0];
  }
  
  // buttons
  y = 370;
  cp5.addTextlabel("runlabel")
    .setText("RUN")
    .setPosition(xsize + 8, y + 22)
    ;
  startButton = cp5.addButton("start")
    .setPosition(xsize + 10, y)
    .setWidth(49)
    .setValue(0);    
  pauseButton = cp5.addButton("pause")
    .setPosition(xsize + 60, y)
    .setWidth(49)
    .setValue(0);
  stopButton = cp5.addButton("stop")
    .setPosition(xsize + 110, y)
    .setWidth(49)
    .setValue(0);

  statusField = cp5.addTextfield("state")
    .setPosition(xsize + 10, 410)
    .setWidth(150)
    .setText("hello")
    .setLock(true);
  
  buttonsEnabled = true;
  println("plotter ready");
}

void controlEvent(ControlEvent e) {
  if (e.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    if (e.getGroup().getName().equals("ports")) {
      int i = (int)e.getGroup().getValue();
      startSerial(ports[i]);
      background(BACKGROUND_STD);
      state = STATE_PLOTTING_SCREEN;  // trigger screen redraw to get rid of opened drop down        
    }
    else if (e.getGroup().getName().equals("files")) {
      int i = (int)e.getGroup().getValue();
      currentFileName = fileNames[i];
      shape = null;
      background(BACKGROUND_STD);
      state = STATE_WAITING;        
    }
  } 
}

void status(String s) {
  statusField.setText(s);
}

void updateFileList() {
  fileNames = getFiles();
  println(fileNames);
  for (int i = 0; i < fileNames.length; i++) {
    filesList.addItem(fileNames[i], i);
  }    
}

void startSerial(String portName) {
  if (port != null) {
    port.clear();
    port.stop();
  }
  println("Connecting to Serial Port " + port);
  port = new Serial(this, portName, 57600);    
}

void start(int value) {
  if (buttonsEnabled) {
    actOnKey('p');
  }
}

void pause(int value) {
  if (buttonsEnabled) {
    actOnKey(' ');
  }
}

void stop(int value) {
  if (buttonsEnabled) {
    actOnKey('a');
  }
}

void up(int value) {
  actOnKey('u');
}

void down(int value) {
  actOnKey('d');
}

void left(int value) {
  actOnKey('l');
}

void right(int value) {
  actOnKey('r');
}

void toggleHorizontal(boolean b) {
  actOnKey('m');
}  

void toggleVertical(boolean b) {
  actOnKey('M');
}  

void toggleBW(boolean b) {
  if (buttonsEnabled) {
    actOnKey('w');
  }
}

void scaleUp(int value) {
  actOnKey('+');
}

void scaleDown(int value) {
  actOnKey('-');
}

/**
 * Main program loop
 * 
 * @see processing.core.PApplet#draw()
 */
void draw() {
  // clears the background of the menu (controlp5 area)
  noStroke();
  fill(BACKGROUND_STD);
  rect(width - MENU_X, 0, MENU_X, height);
  
  pushMatrix();    
  oldState = state;

  switch (state) {

  // Initial sketch set up
  case 1: //STATE_START
    dx = 0;
    dy = 0;
    shape = null;
    translate(SCREEN_PADDING, SCREEN_PADDING);
    scale(screenScale);
    rect(0, 0, MAX_PLOTTER_X, MAX_PLOTTER_Y);
    state = STATE_WAITING;
    break;

  // Load SVG file contents, wait to load
  case 2: //STATE_WAITING
    status("waiting ...");
    if (shape == null && System.currentTimeMillis() > nextUpdate) {
      nextUpdate = System.currentTimeMillis() + 3000;
      shape = loadNewShape(currentFileName);
      if (shape != null) {
        state = STATE_PLOTTING_SCREEN;
      }
    }
    break;

  // Draw the canvas to the screen
  case 3: //STATE_PLOTTING_SCREEN
    drawCanvas();
    state = STATE_WAITING_INPUT;
    break;

  // Waiting for user to begin plotting by pressing 'p'
  case 4: //STATE_WAITING_INPUT
    status("waiting input ...");
    if (plotting) {
      state = STATE_SETUP_PLOTTER;
      plotting = false;
    }
    break;

  // Generate Instructions from the SVG file, then set up the Kritzler
  // object
  case 5: //STATE_SETUP_PLOTTER
    currentInstructions = new ArrayList<Instruction>();
    List<RPath> paths = new ArrayList<RPath>();
    getAllPaths(paths, shape);
    paths = sortPaths(paths);
    convertToInstructions(currentInstructions, paths);
    setupPlotter(currentInstructions);
    state = STATE_PLOTTING;
    break;

  case 7: //STATE_PAUSED
    status("paused");
    drawCanvas();
    break;
    
  case 8: //STATE_RESUME
    drawCanvas();
    state = STATE_PLOTTING;
    break;
    
  // Actively plotting
  case 6: //STATE_PLOTTING
    status("plotting ...");
    plotter.checkSerial();
    // When finished drawing, return to the coordinates specified by
    // HOME_X and HOME_Y
    if (plotter.isFinished()) {
      status("finished");
      println("finished");
      state = STATE_FINISHING;
      useCache = false;
    }
    else {
      drawCanvas();
    }
    break;
    
  case 10: //STATE_FINISHING
    status("finished");
    drawCanvas();
    state = STATE_WAITING_INPUT;
    break;
    
  case 9: //STATE_ABORTING
    status("aborted");
    plotting = false;
    useCache = false;
    shape = null;
    drawCanvas();
    state = STATE_WAITING_INPUT;
    break;
  }  
  
  if (oldState != state) {
    println("switching: " + STATES[oldState] + " --> " + STATES[state]);
    oldState = state;
  }
  
  popMatrix();
  
  noFill();
  stroke(0,255,0);
  rect(245,150,280,360);
}

/**
 * Set up the Kritzler object
 * 
 * @param instructions
 *            Instruction set to use
 */
void setupPlotter(List<Instruction> instructions) {
  plotter = new Kritzler(this, port);
  plotter.setInstructions(instructions);
  plotter.translate(START_X + dx, START_Y + dy);
  plotter.setScale(plotterScale);
}

/**
 * Draw the canvas to the screen
 */
void drawCanvas() {

  if (useCache) {
    switch(state) {
    case 7: // STATE_PAUSED
      background(BACKGROUND_PAUSED);
      break;
    default:
      background(BACKGROUND_STD);
    }
    image(graphics, SCREEN_PADDING, SCREEN_PADDING);
    translate(SCREEN_PADDING, SCREEN_PADDING);
    scale(screenScale * plotterScale);      
    translate(dx, dy);
    drawBot();
    return;
  }
  
  graphics.beginDraw();
  graphics.smooth();
   
  switch(state) {
  case 7: // STATE_PAUSED
    graphics.background(BACKGROUND_PAUSED);
    break;
  default:
    graphics.background(BACKGROUND_STD);
  }
   
  // Draw the canvas rectangle
  // graphics.translate(SCREEN_PADDING, SCREEN_PADDING);
  graphics.scale(screenScale * plotterScale);
  graphics.fill(canvasBackground);
 
  graphics.rect(0, 0, MAX_PLOTTER_X, MAX_PLOTTER_Y);

  // Draw the grid
  if (drawGrid) {
    graphics.stroke(STROKE_GRID);
    graphics.strokeWeight(STROKE_WEIGHT_GRID);

    int cols = MAX_PLOTTER_X / 100;
    int rows = MAX_PLOTTER_Y / 100;
    for(int i=0; i<cols; i++) {
      graphics.line(i*100, 0, i*100, MAX_PLOTTER_Y);
    }
    for(int i=0; i<rows; i++) {
      graphics.line(0, i*100, MAX_PLOTTER_X, i*100);
    }
  }

  // Draw the homing crosshairs
  graphics.strokeWeight((float)(STROKE_WEIGHT_GRID * 2));
  graphics.line(MAX_PLOTTER_X/2, 0, MAX_PLOTTER_X/2, MAX_PLOTTER_Y);
  graphics.line(0, MAX_PLOTTER_Y/2, MAX_PLOTTER_X, MAX_PLOTTER_Y/2);

  graphics.translate(dx, dy);        

  // Draw the bounding box of the current shape
  if (drawBoundingBox && shape != null) {
    // Bounding box
    RPoint bounds[] = shape.getBoundsPoints();
    graphics.strokeWeight(STROKE_WEIGHT_GRID);
    graphics.stroke(255,0,0);
    graphics.line( bounds[0].x, bounds[0].y, bounds[1].x, bounds[1].y );
    graphics.line( bounds[1].x, bounds[1].y, bounds[2].x, bounds[2].y );
    graphics.line( bounds[2].x, bounds[2].y, bounds[3].x, bounds[3].y );
    graphics.line( bounds[3].x, bounds[3].y, bounds[0].x, bounds[0].y );

    // Center cross hairs
    RPoint center = shape.getCenter();
    graphics.line( center.x, bounds[0].y, center.x, bounds[0].y - 200 );
    graphics.line( center.x, bounds[3].y, center.x, bounds[3].y + 200 );
    graphics.line( bounds[0].x, center.y, bounds[0].x - 200, center.y );
    graphics.line( bounds[1].x, center.y, bounds[1].x + 200, center.y );
  }
  
  // Draw the SVG content
  graphics.strokeWeight(STROKE_WEIGHT_SHAPE);
  graphics.stroke(shapeStroke);
  if (shape != null) {
    drawShape(graphics, shape);
  }
  graphics.endDraw();
  image(graphics, SCREEN_PADDING, SCREEN_PADDING);
}

void drawBot() {
  if (plotter == null) {
    return;
  }
  noStroke();
  switch (state) {
  case 6: // STATE_PLOTTING
    fill(PLOTTER_STD);
    break;
  case 7: // STATE_PAUSED
    fill(PLOTTER_PAUSED);
    break;
  case 10: // STATE_FINISHING
    fill(PLOTTER_FINISHED);
    break;
  }
  Instruction i = currentInstructions.get(plotter.getCurrentInstructionIndex());
  ellipseMode(CENTER);    
  ellipse(i.x, i.y, 200, 200);
}  

/**
 * Draw the SVG file contents to the screen
 * 
 * @param shape
 *            Shape to draw
 */
void drawShape(PGraphics g, RShape shape) {
  // Recurse through any children of this shape
  for (int i = 0; i < shape.countChildren(); i++) {
    RShape s = shape.children[i];
    drawShape(g, s);
  }

  // Iterate through each path of the shape, drawing them to the screen
  for (int i = 0; i < shape.countPaths(); i++) {
    // Get the points of the current path
    RPath p = shape.paths[i];
    RPoint[] points = p.getPoints();

    // Connect each of the points using lines
    for (int k = 0; k < points.length - 1; k++) {
      g.line(points[k].x, points[k].y, points[k + 1].x, points[k + 1].y);
    }
  }
}

/**
 * Convert SVG file contents into Instruction objects
 * 
 * @param instructions
 *            Resulting List of Instruction objects
 * @param shape
 *            RShape to proces
 */
void convertToInstructions(List<Instruction> instructions, RShape shape) {
  // Recurse through any children of current shape
  for (int i = 0; i < shape.countChildren(); i++) {
    RShape s = shape.children[i];
    convertToInstructions(instructions, s);
  }

  // Generate Instruction objects for every path of shape
  for (int i = 0; i < shape.countPaths(); i++) {
    // Get the first point of this path
    RPath p = shape.paths[i];
    RPoint[] points = p.getPoints();
    RPoint p1 = points[0];

    // Move to that point
    instructions.add(new Instruction(Instruction.MOVE_ABS, p1.x, p1.y));

    // Draw lines to any subsequent points
    for (int k = 0; k < points.length - 1; k++) {
      RPoint p2 = points[k];
      instructions.add(new Instruction(Instruction.LINE_ABS, p2.x, p2.y));
    }
  }    
}

void convertToInstructions(List<Instruction> instructions, List<RPath> paths) {
  for (RPath p : paths) {
    RPoint[] points = p.getPoints();
    RPoint p1 = points[0];

    // Move to that point
    instructions.add(new Instruction(Instruction.MOVE_ABS, p1.x, p1.y));

    // Draw lines to any subsequent points
    for (int k = 0; k < points.length - 1; k++) {
      RPoint p2 = points[k];
      instructions.add(new Instruction(Instruction.LINE_ABS, p2.x, p2.y));
    }      
  }
}

public List<RPath> sortPaths(List<RPath> paths) {
  println("sorting paths ...");
  List<RPath> resultPath = new ArrayList<RPath>();
  PathComparator comparator = new PathComparator();
  RPoint tl = shape.getTopLeft();
  RPoint br = shape.getBottomRight();
  
  float y = tl.y;
  while (y < br.y) {
    List<RPath> sortedRow = new ArrayList<RPath>();
    for (int i = 0; i < paths.size(); i++) {
      RPath path = paths.get(i);
      RPoint p = path.getPoints()[0];
      if (p.y < y + MAX_COMPARE_DELTA && p.y >= y) {
        sortedRow.add(path);
      }
    }
    Collections.sort(sortedRow, comparator);
    resultPath.addAll(sortedRow);
    y += MAX_COMPARE_DELTA;
  }
  return resultPath;
}

void getAllPaths(List<RPath> paths, RShape shape) {
  for (int i = 0; i < shape.countChildren(); i++) {
    RShape s = shape.children[i];
    getAllPaths(paths, s);
  }
  for (int i = 0; i < shape.countPaths(); i++) {
    paths.add(shape.paths[i]);
  }
}

/**
 * Process keyboard input
 * 
 * @see processing.core.PApplet#keyPressed()
 */
void keyPressed() {
  actOnKey(key);
}  
  
void actOnKey(int key) {
  
  switch (key) {

  // a = abort
  case 'a':
    state = STATE_ABORTING;
    break;
  
  // p = begin plotting
  case 'p':
    plotting = true;
    useCache = true;
    break;

  // [space] = pause plotting
  case ' ':
    if (currentInstructions != null && state != STATE_PAUSED) {
      state = STATE_PAUSED;
    }
    else if (state == STATE_PAUSED) {
      state = STATE_RESUME;
    }
    break;

  // Arrow keys = translate shape around canvas
  case CODED:
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    // Move SVG shape around based on arrow keys
    switch (keyCode) {
    case UP: 
      dy -= DELTA_STEP; 
      state = STATE_PLOTTING_SCREEN;
      break;
    case DOWN: 
      dy += DELTA_STEP; 
      state = STATE_PLOTTING_SCREEN;
      break;
    case LEFT: 
      dx -= DELTA_STEP; 
      state = STATE_PLOTTING_SCREEN;
      break;
    case RIGHT: 
      dx += DELTA_STEP; 
      state = STATE_PLOTTING_SCREEN;
      break;
    }
    break;
    
  case 'u':
    dy -= DELTA_STEP; 
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'd':
    dy += DELTA_STEP; 
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'l':
    dx -= DELTA_STEP; 
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'r': 
    dx += DELTA_STEP; 
    state = STATE_PLOTTING_SCREEN;
    break;
    
  case 'w':
    blackOnWhite = !blackOnWhite;
    shapeStroke = (blackOnWhite) ? SHAPE_STROKE_BLACK : SHAPE_STROKE_WHITE;
    canvasBackground = (blackOnWhite) ? CANVAS_BACKGROUND_WHITE : CANVAS_BACKGROUND_BLACK;
    state = STATE_PLOTTING_SCREEN;
    break;

  // l = scale shape down
  case '-':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    shape.scale(0.95F);
    print(shape, "-: ");
    state = STATE_PLOTTING_SCREEN;
    break;

  // L = scale shape up
  case '+':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    shape.scale(1.05F);
    print(shape, "+: ");
    state = STATE_PLOTTING_SCREEN;
    break;

  // m = flip shape horizontally
  case 'm':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    float width = shape.getBottomRight().x;
    shape.scale(-1.0F, 1.0F);
    shape.translate(width, 0);
    state = STATE_PLOTTING_SCREEN;
    break;

  // M = flip shape vertically
  case 'M':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    shape.scale(1.0F, -1.0F);
    state = STATE_PLOTTING_SCREEN;
    break;

  // s = deny shape (?)
  case 's':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    moveShapeDenied();
    state = STATE_START;
    break;

  // g = toggle grid
  case 'g':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    drawGrid = !drawGrid;
    state = STATE_PLOTTING_SCREEN;
    break;

  // b = toggle bounding box
  case 'b':
    if (shape == null || state == STATE_PLOTTING) {
      return;
    }
    drawBoundingBox = !drawBoundingBox;
    state = STATE_PLOTTING_SCREEN;
    break;
  }
}

/**
 * Print a message to the console, along with the coordinates of the top
 * left and bottom right extends of the SVG shape
 * 
 * @param p
 *            RShape to acquire extents from
 * @param msg
 *            Message to print to console
 */
void print(RShape p, String msg) {
  RPoint p1 = p.getTopLeft();
  RPoint p2 = p.getBottomRight();
  System.out.println(msg + " (" + p1.x + ", " + p1.y + "), (" + p2.x + ", " + p2.y + ")");
}

/**
 * Move current SVG file to the folder specified by BUFFER_DONE_PATH
 */
void moveShapeDone() {
  System.out.println("moving file to " + BUFFER_DONE_PATH + currentFileName);
  File file = new File(dataPath("") + BUFFER_ACC_PATH + currentFileName);
  File newFile = new File(dataPath("") + BUFFER_DONE_PATH + currentFileName);
  file.renameTo(newFile);
}

/**
 * Move current SVG file to the folder specified by BUFFER_DENIED_PATH
 */
void moveShapeDenied() {
  System.out.println("moving file to " + BUFFER_DENIED_PATH + currentFileName);
  File file = new File(dataPath("") + BUFFER_ACC_PATH + currentFileName);
  File newFile = new File(dataPath("") + BUFFER_DENIED_PATH + currentFileName);
  file.renameTo(newFile);
}

/**
 * Loads the first SVG file from the BUFFER_ACC_PATH folder
 * 
 * @return RShape The SVG file contents, if it exists. Otherwise null.
 */
RShape loadNewShape(String filename) {
  System.out.println("loading " + filename);
  RShape shape = RG.loadShape(dataPath("") + BUFFER_ACC_PATH + filename);
  shape.scale(svgScale, shape.getCenter());
  print(shape, "loaded: ");
  return shape;
}

String[] getFiles() {
  // Get a list of all SVG files in the BUFFER_ACC_PATH folder
  File dir = new File(dataPath("") + BUFFER_ACC_PATH);
  println(dir);
  String[] listing = dir.list(new FilenameFilter() {
    public boolean accept(File file, String filename) {
      return filename.endsWith("svg");
    }
  });
  return listing;
}

/**
 * Run the PApplet when this file is run as an application
 * 
 * @param args
 */
//public static void main(String args[]) {
//  PApplet.main(new String[] { "com.tinkerlog.kritzler.Plotter" });
//}  

private class PathComparator implements Comparator<RPath> {

  //@Override
  public int compare(RPath path1, RPath path2) {
    RPoint p1 = path1.getPoints()[0];
    RPoint p2 = path2.getPoints()[0];
    float dx = p1.x - p2.x;
    float dy = p1.y - p2.y;
    if (abs(dy) < MAX_COMPARE_DELTA) {
      return p1.x > p2.x ? 1 : p1.x < p2.x ? -1 : 0;
    }
    return (dy > 0) ? 1 : -1;
  }
}

