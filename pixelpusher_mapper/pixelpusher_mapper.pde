/**

This sketch requires the PixelPusher library for Processing. The library is updated frequently
and can be found on the Heroic Robotics forums:

http://forum.heroicrobotics.com/

Usage:

1) Connect a PixelPusher to your network
2) Run this sketch
3) When your PixelPusher is detected, a line will appear for each LED strip
3) Drag the end points of the lines so they line up with the content as desired

*/

import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;
import java.util.*;

import processing.core.*;
import processing.video.*;

Movie movie;
PImage image;

PVector selectedPoint = null;
ArrayList<Segment> segments;

DeviceRegistry registry;
TestObserver testObserver;

void setup() {
  size(500, 500);

  registry = new DeviceRegistry();
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
 
  segments = new ArrayList<Segment>();

  // Load a test movie
  movie = new Movie(this, "tetrahedron.mov");
  movie.loop();
  
  // Load a test image
  // image = loadImage("spectrum.jpg");
  
  ellipseMode(CENTER);
}

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable reg, Object updatedDevice) {

    if(!this.hasStrips){
      PixelPusher pusher = (PixelPusher)updatedDevice;
      List<Strip> strips = pusher.getStrips();

      // add segments for any strips that have been discovered.
      for(int i = 0; i < strips.size(); i++){
        segments.add( new Segment(i * 20 + 20, 20, i * 20 + 20, 200, strips.get(i)) );
      } 

      this.hasStrips = true;
    }
  }
};

void mousePressed() {
  PVector mouse = new PVector(mouseX, mouseY);
  selectedPoint = null;
  
  for(Segment seg : segments){
    if(seg.sampleStart.dist(mouse) < 12){
      selectedPoint = seg.sampleStart;
      break;
    }else if(seg.sampleStop.dist(mouse) < 12){
      selectedPoint = seg.sampleStop;
      break;
    }
  }
}

void mouseDragged(){
  if(selectedPoint != null){
    selectedPoint.x = mouseX;
    selectedPoint.y = mouseY;
  }
}

void movieEvent(Movie m) {
  m.read();
}

void draw() {

   background(0);
   
   image(movie, 0, 0, width, height);
   //image(image, 0, 0, width, height);

   updatePixels();
   if (testObserver.hasStrips) {
      
      registry.setExtraDelay(0);
      registry.startPushing();

      for(Segment seg : segments){
        seg.samplePixels();
      }

      for(Segment seg : segments){
        seg.draw();
      }      
   } 
}



class Segment{
  
  PVector sampleStart;
  PVector sampleStop;
  Strip strip;
  int pixelOffset = 0;
  int pixelCount = 0;
  
  Segment(float startX, float startY, float stopX, float stopY, Strip strip, int pixelCount, int pixelOffset ){
    this( startX, startY, stopX, stopY, strip );
    this.pixelCount = pixelCount;
    this.pixelOffset = pixelOffset;
  }
  
  Segment(float startX, float startY, float stopX, float stopY, Strip strip ){
    this.sampleStart = new PVector(startX, startY);
    this.sampleStop = new PVector(stopX, stopY);
    this.strip = strip;
    this.pixelCount = strip.getLength();
    println("Pixels!!! : " + this.pixelCount);
  }
  
  // draw end points and sample points.
  public void draw() {
    stroke(255);
    noFill();
    
    // draw circles at the end points.
    ellipse(this.sampleStart.x, this.sampleStart.y, 8,8);
    ellipse(this.sampleStop.x, this.sampleStop.y, 8,8);
    
    PVector step = PVector.sub(this.sampleStop, this.sampleStart);
    step.div( this.pixelCount ); 
   
    PVector samplePos = new PVector();
    samplePos.set(this.sampleStart);

    noStroke();
    for(int i = 0; i < pixelCount; i++){
      fill(255, 100);
      ellipse(samplePos.x, samplePos.y, 3.5, 3.5);
      samplePos.add( step );
    }
  } 
  
  // sample pixels and push them to a strip.
  public void samplePixels() {
    
    PVector step = PVector.sub(this.sampleStop, this.sampleStart);
    step.div( this.pixelCount ); 
     
    PVector samplePos = new PVector();
    samplePos.set(this.sampleStart);
     
    for(int i = 0; i < this.pixelCount; i++) {
      this.strip.setPixel(get((int)samplePos.x, (int)samplePos.y), i + this.pixelOffset);
      samplePos.add(step);
    }     
  }
}
