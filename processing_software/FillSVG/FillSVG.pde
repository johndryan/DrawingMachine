import org.apache.batik.svggen.font.table.*;
import org.apache.batik.svggen.font.*;

import java.io.File;
import java.io.FilenameFilter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import geomerative.*;

String BUFFER_ACC_PATH = "buffer_acc/";
String BUFFER_NEW_PATH = "buffer_new/";
String BUFFER_DENIED_PATH = "buffer_denied/";
  
int MAX_X = 600;
int SCREEN_PADDING = 10;
int STEP_WIDTH = 10;
  
  
int STATE_START = 1;
int STATE_WAITING = 2;
int STATE_PLOTTING_SCREEN = 3;
int STATE_WAITING_INPUT = 4;
int state = STATE_START;
  
RShape shape;
RShape intersections;
long nextUpdate;
float stepWidth = STEP_WIDTH;
String currentFileName;
  
void setup() {    
  RG.init(this);        
  smooth();
  size(MAX_X + 2*SCREEN_PADDING, MAX_X + 2*SCREEN_PADDING);
  background(100);
}
  
void draw() {
  switch (state) {
  case 1: //STATE_START
    println("STATE_START");
    shape = null;
    translate(SCREEN_PADDING, SCREEN_PADDING);
    fill(255);
    rect(0, 0, MAX_X, MAX_X);      
    state = STATE_WAITING;
    break;
  case 2: //STATE_WAITING
    println("STATE_WAITING");
    if (shape == null && System.currentTimeMillis() > nextUpdate) {
      nextUpdate = System.currentTimeMillis() + 3000;
      shape = loadNewShape();
      if (shape != null) {
        state = STATE_PLOTTING_SCREEN;
      }
    }
    break;
  case 3: //STATE_PLOTTING_SCREEN
    println("STATE_PLOTTING_SCREEN");
    translate(SCREEN_PADDING, SCREEN_PADDING);
    rect(0, 0, MAX_X, MAX_X);
    drawShape(shape);
    if (intersections != null) {
      drawShape(intersections);
    }
    state = STATE_WAITING_INPUT;
    break;
  case 4: //STATE_WAITING_INPUT
    println("STATE_WAITING_INPUT");
    break;
  }       
}

void keyPressed() {
  switch (key) {
  case CODED:
    switch (keyCode) {
    case LEFT:
      System.out.println("left");
      stepWidth *= 0.95;
      intersections = computeIntersections(shape);
      state = STATE_PLOTTING_SCREEN;
      break;
    case RIGHT:
      System.out.println("left");
      stepWidth *= 1.05;
      intersections = computeIntersections(shape);
      state = STATE_PLOTTING_SCREEN;
      break;
    }
    break;
  case 'l':
    shape.scale(0.95F);
    if (intersections != null) {
      intersections.scale(0.95F);
    }
    print(shape, "l: ");
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'L':
    shape.scale(1.05F);
    if (intersections != null) {
      intersections.scale(1.05F);
    }
    print(shape, "L: ");
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'x':
    if (intersections == null) {
      intersections = computeIntersections(shape);
    }
    else {
      intersections = null;
    }
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'm':      
    float width = shape.getBottomRight().x;
    shape.scale(-1.0F, 1.0F);
    shape.translate(width, 0);
    if (intersections != null) {
      intersections.scale(-1.0F, 1.0F);
      intersections.translate(width, 0);
    }
    print(shape, "m3 : ");
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'M':
    shape.scale(1.0F, -1.0F);
    state = STATE_PLOTTING_SCREEN;
    break;
  case 'p':
    exportShape();
    state = STATE_START;
    break;
  case 's':
    moveShapeDenied();
    state = STATE_START;
    break;
  }    
}

void drawShape(RShape shape) {
  for (int i = 0; i < shape.countChildren(); i++) {
    RShape s = shape.children[i];
    drawShape(s);
  }
  for (int i = 0; i < shape.countPaths(); i++) {
    RPath p = shape.paths[i];
    RPoint[] points = p.getPoints();
    for (int k = 0; k < points.length-1; k++) {
      line(points[k].x, points[k].y, points[k+1].x, points[k+1].y);
    }
  }    
}

void exportShape() {
  intersections.addChild(shape);
  String name = currentFileName.substring(0, currentFileName.lastIndexOf('.')) + "_1.svg";
  RG.saveShape(dataPath("") + BUFFER_ACC_PATH + name, intersections);
  moveShapeDone();
}

RShape computeIntersections(RShape shape) {
  float x = 0;
  float y = 0;
  RShape allLines = new RShape();
  while (x < MAX_X*2 && y < MAX_X*2) {      
    RShape s = new RShape();
    s.addMoveTo(new RPoint(0, y));
    s.addLineTo(new RPoint(x, 0));
    RPoint[] points = shape.getIntersections(s);
    if (points != null) {
      List<MyPoint> pointsList = new ArrayList<MyPoint>();      
      for (RPoint p : points) {
        pointsList.add(new MyPoint(p));
      }
      Collections.sort(pointsList);
      if (pointsList.size() % 2 == 0) {
        int i = 0;
        while (i <  pointsList.size()) {
          RPoint p1 = pointsList.get(i++);
          RPoint p2 = pointsList.get(i++);
          RShape l = new RShape();
          l.addMoveTo(p1);
          l.addLineTo(p2);
          allLines.addChild(l);
        }
      }
      else if (points != null) {
        System.out.println("points: " + pointsList.size());
      }
    }
    x += stepWidth;
    y += stepWidth;
  }
  System.out.println("intersection lines: " + allLines.countChildren());
  return allLines;
}

void print(RShape p, String msg) {
  RPoint p1 = p.getTopLeft();
  RPoint p2 = p.getBottomRight();
  System.out.println(msg + " (" + p1.x + ", " + p1.y + "), (" + p2.x + ", " + p2.y + ")");
}

void moveShapeDone() {
  System.out.println("moving file to " + BUFFER_ACC_PATH + currentFileName);
  File file = new File(dataPath("") + BUFFER_NEW_PATH + currentFileName);
  File newFile = new File(dataPath("") + BUFFER_ACC_PATH + currentFileName);
  file.renameTo(newFile);
}

void moveShapeDenied() {
  System.out.println("moving file to " + BUFFER_DENIED_PATH + currentFileName);
  File file = new File(dataPath("") + BUFFER_NEW_PATH + currentFileName);
  File newFile = new File(dataPath("") + BUFFER_DENIED_PATH + currentFileName);
  file.renameTo(newFile);    
}

RShape loadNewShape() {
  File dir = new File(dataPath("") + BUFFER_NEW_PATH);
  println(dir);
  String[] listing = dir.list(new FilenameFilter() {
    public boolean accept(File file, String filename) {
      return filename.endsWith("svg");
    }
  });
  println(listing);
  if (listing != null && listing.length > 0) {
    for (int i = 0; i < listing.length; i++) {
      System.out.println("file: " + listing[i]);
    }
    currentFileName = listing[0];
    System.out.println("loading " + currentFileName);
    RShape shape = RG.loadShape(dataPath("") + BUFFER_NEW_PATH + currentFileName);
    //shape.scale(10.0F);
    print(shape, "loaded: ");
    return shape;
  }
  return null;
}

class MyPoint extends RPoint implements Comparable<MyPoint> {
  public MyPoint(RPoint p) {
    super(p);
  }
  public int compareTo(MyPoint other) {
    return (x < other.x) ? -1 : (x == other.x) ? 0 : 1;
  }     
}
