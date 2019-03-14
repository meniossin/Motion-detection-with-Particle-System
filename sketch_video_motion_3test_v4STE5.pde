/**
*This code is a combination and a restructure from parts and concepts 
*in Daniel Shiffman's youtube tutorials and his book "Nature of code".
*
*/

import processing.video.*;
import java.util.Iterator;

Capture video;
ParticleSystem ps;

// Previous Frame
PImage prevFrame;

float threshold; // degree of sensitivity to motion detection. 

 float avgX = 0; //average horizontal position of tracked pixels
 float avgY = 0; // average vertical position of tracked pixels
 
 float motionX = 0;
 float motionY = 0;
 int count = 0; // counter for total number of tracked pixels in the current frame

void captureEvent(Capture video){
  // Save previous frame for motion detection!!
  prevFrame.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height); // Before we read the new frame, we always save the previous frame for comparison!
  prevFrame.updatePixels();  
  
  if(video.available()){
    video.read();
  }
}

void setup() {  
  size(640,480); // set up dimensions of screen 
  pixelDensity(displayDensity()); // Pulling the display's density dynamically
  
  video = new Capture(this, width, height); //set up video
  video.start();
  
  ps = new ParticleSystem(new PVector(width, height-60)); //create the particle system
  prevFrame = createImage(video.width, video.height, RGB); // create the image of the previous frame
}

void draw(){
  video.loadPixels();
  prevFrame.loadPixels();
  
  image(video, 0, 0);
  
  count = 1;
  avgX = 0;
  avgY = 0;
  threshold = 97;
  
  // Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x = x + 4 ) { // every how many actual pixels, a motion pixel should be calculated and particle added.
    for (int y = 0 ; y < video.height; y = y + 5 ) { //the lower the number, the more actual pixels taken into accoutn and the more particles are created.

      int loc = x + y*video.width;            // Step 1, what is the 1D pixel location
      color current = video.pixels[loc];      // Step 2, what is the current color
      color previous = prevFrame.pixels[loc]; // Step 3, what is the previous color
      
      // Step 4, compare colors (previous vs. current)
      float r1 = red(current); 
      float g1 = green(current); 
      float b1 = blue(current);
      float r2 = red(previous); 
      float g2 = green(previous); 
      float b2 = blue(previous);
      float diff = dist(r1, g1, b1, r2, g2, b2);

      // Step 5, How different are the colors?
      // If the color at that pixel has changed by %, then there is motion at that pixel.
      if (diff > threshold && x % 8 == 0 && y % 20 == 0) {  //the bigger % the less sensitivity to motion and less particles created
          avgX += x;
          avgY += y;
          count++;
          PVector position = new PVector(x, y);           
          ps.addParticle(position, previous); //add a particle for this pixel
      }
    }
  }
  
  // This threshold of 30 is arbitrary and you can adjust this number depending on how accurate you require the tracking to be.
  if (count > 30) {
    motionX = avgX / count;
    motionY = avgY / count;
   
     float dx = map(motionX, 0, width, -1.5, 1.5); //scale the vector of the tracked average motion in the X axis
     PVector wind = new PVector(dx, 0); //create the wind vector
     ps.applyForce(wind);  //apply wind force to particles
  }
 
  PVector gravity = new PVector(0,0.02); // create the gravity vector
  ps.applyForce(gravity); //apply gravity force to particles

  ps.run(); // run the particle system
  
  smooth();  //  Draws all geometry with smooth (anti-aliased) edges
  noStroke();  //Disables drawing the stroke (outline)
  updatePixels();
}

// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

class ParticleSystem {
  ArrayList<Particle> particles; //list of particles
  PVector origin; //original position of the vector

  ParticleSystem(PVector position) {
    origin = position.copy();
    particles = new ArrayList<Particle>();
  }

  void addParticle(PVector pos, color currentPartColor) {
    particles.add(new Particle(pos, currentPartColor));
  }
  
  
  void applyForce(PVector force) {
    for(Particle p: particles){
        p.applyForce(force);
    }
  }
  
  void run() {
    
   Iterator<Particle> it = particles.iterator();
  // Using an Iterator object instead of counting with int i
   while (it.hasNext()) {
      Particle p = it.next();
      p.run();
      if (p.isDead()) {
        it.remove();
      }
    }
  }
}


// A simple Particle class

class Particle {
  PVector position; 
  PVector velocity; 
  PVector acceleration;
  float decay;
  color currentCol;
  float mass = 1;  
 
  Particle(PVector currentPos, color currentPartColor) {
    acceleration = new PVector(2, 0.0); //setup acceleration for the particle
    position = currentPos.copy(); //setup position for the particle
    decay = 43.0; //setup decay
    currentCol = currentPartColor; //setup current particle color
    velocity = new PVector(random(-1,1), random(-0.5, 0.5)); //setup velocity for the particle
  }

  void run() {
    update();
    display();
  }
   
    // Newton's 2nd law: F = M * A
   // or A = F / M
   void applyForce(PVector force) {
    PVector f = force;
    f.div(mass); // Divide by mass 
    acceleration.add(f); // Accumulate all forces in acceleration

  }
  
  
  // Method to update position
  void update() {   
    velocity.add(acceleration);  // Velocity changes according to acceleration
    position.add(velocity); // position changes by velocity
    acceleration.mult(0);  // We must clear acceleration for each frame
    decay -= 0.3; //change the decay for each frame
  }

  // Method to display the particle
  void display() {
      fill(currentCol, decay); //fill
      ellipse(position.x, position.y, 7, 7); //draw the shape of the particle
  }

  // Is the particle still useful?
  boolean isDead() {
    if (decay < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}
