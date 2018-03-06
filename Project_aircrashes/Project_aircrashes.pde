import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;

import java.util.*;

//.rotate([-25, -12])
boolean inDome = false;
PImage background;
float scaleFactor;
PFont corpusFont;
PFont corpusFontBold;
Table worstData;
Table unusualData;

Timeline timeline;
//float TIME_INC = 0.001; //used to be 0.00007
//float FLIGHT_TIME = 0;
//float FLIGHT_SHOW_TIME = 0;
//float FLIGHT_TIME_INC = 0.003;
//float SEEK_TIME = 1;
//float SEEK_INC = 0.005f;
//float SEEK_EPSILON = 0.001;
//float SEEK_DURATION = 100f;
float GLOW_DURATION = 0.01;
int YEAR_START = 1930;
int YEAR_END = 2015;
int REPEAT_COUNT = 2;
float SCALE = 0.76; //0.8125; //map scaling

//float PHI1 = radians(12);
//float LAMBDA0 = radians(25);
float ORIENTATION = 0;
float ORIENTATION_TRAJECTORY = radians(24);

ArrayList<Datum> data = new ArrayList<Datum>();
ArrayList<CrashDot> myDots = new ArrayList<CrashDot>();

final int STATE_PLAY = 0;
final int STATE_DISPLAY_FLIGHT = 1;
final int STATE_DISPLAY_FLIGHT_THEN_PAUSE = 2;
final int STATE_PAUSED = 3;
final int STATE_SEEK = 4;
int currentState = STATE_PLAY;

ArrayList<CrashFlight> myFlights = new ArrayList<CrashFlight>();

color GREEN = #1ce58e;
color RED = #e81a9a; 

int MIN_FATALITIES = Integer.MAX_VALUE;
int MAX_FATALITIES = Integer.MIN_VALUE;
int MIN_OCCUPANTS = Integer.MAX_VALUE;
int MAX_OCCUPANTS = Integer.MIN_VALUE;

HashSet<String> phaseCodes = new HashSet<String>();
HashMap<String, Float> phaseProgress = new HashMap<String, Float>();
HashMap<Datum, CrashFlight> flightsByDatum = new HashMap<Datum, CrashFlight>();
CrashFlight activeFlight;
PShape map, quad;
PGraphics mapContainer;
PShader shader;
//float deltaLat = PI, deltaLon = -PI, deltaLonPost = 0f, mapScale = 2.5;
float TARGET_SIZE;
float MIN_MAP_SCALE = 0.1;
float MAX_MAP_SCALE = 2.5;
float deltaLat = 0f, deltaLon = 0f, deltaLonPost = 0f, mapScale = MAX_MAP_SCALE;

float SPEED_FACTOR = 1;
float SEEK_DURATION = 6 * SPEED_FACTOR; // in seconds
float TRAJECTORY_SHOW_DURATION = 3 * SPEED_FACTOR; // in seconds
float CRASH_INFO_SHOW_DURATION = 3 * SPEED_FACTOR; // in seconds
float FADE_DURATION = 1 * SPEED_FACTOR; // in seconds

float TIME = 0;
float FADE_TIME = 0;
float TRAJECTORY_SHOW_TIME = 0;
float CRASH_INFO_SHOW_TIME = 0;

AniSequence globalAniSequence;

void setup() {
  //size(1920, 1920, P3D);
  size(1000, 1000, P2D);
  Ani.init(this);
  Ani.setDefaultEasing(Ani.QUAD_IN_OUT);
  globalAniSequence = new AniSequence(this);
  pixelDensity(displayDensity());
  scaleFactor = width / 1920f;
  println(scaleFactor);
  TARGET_SIZE = 1000 * scaleFactor;
  background = loadImage("background_map.png");
  corpusFont = loadFont("SourceSansPro-Regular-44.vlw");
  corpusFontBold = loadFont("SourceSansPro-Bold-48.vlw");
  map = loadShape("EquirectangularMap.svg");
  mapContainer = createGraphics(4096, 2048, P2D);
  //mapContainer = createGraphics(1024,512,P2D);
  redrawMap();
  initShape();
  shader = loadShader("glsl/azimuthal.frag", "glsl/azimuthal.vert");
  shader.set("mapTexture", mapContainer);
  updateShader();

  //textSize(24);
  timeline = new Timeline((1920 - 390)/2 * scaleFactor, 35 * scaleFactor, HALF_PI, 110 * scaleFactor, YEAR_START, YEAR_END, REPEAT_COUNT, loadFont("SourceSansPro-SemiBold-40.vlw"), 40* scaleFactor, this);

  initData(timeline);
  initFlights(timeline);
  //activeFlight = myFlights.get(0);
  //setActiveFlight(myFlights.get(0));
  //updateSequence(getNextFlight(activeFlight));
  updateSequence(myFlights.get(20));
  //activeFlight = myFlights.get(49);
  initDots();
  hint(DISABLE_DEPTH_TEST);
}

void draw() {
  background(255, 0, 0);

  pushMatrix();
  translate(width*0.5, height*0.5);
  rotate(ORIENTATION);  
  translate(-width*0.5, -height*0.5);

  updateShader();
  shader(shader);
  shape(quad);
  resetShader();  

  drawMask(400*scaleFactor);

  drawLegend();
  timeline.display(TIME);
  for (CrashDot cd : myDots) {
    cd.display();
  }
  popMatrix();
  
  if (activeFlight != null) {
    activeFlight.display();
  }
  
  //updateState();
}

//just prevents clutter
void stuff() {
  // image(background, width*(1 - SCALE)*0.5, height*(1 - SCALE)*0.5, width*SCALE, height*SCALE);



  //s.rotate(phi);

  /*
  String d = "Hello World!!!&#*";
   fill(232,26,154);
   drawArcTextCentered(d, mouseX, mouseY);
   println((mouseX-width)/scaleFactor, (mouseY-height)/scaleFactor);
   */
  // fill(28,229,142,300);
  // drawArcTextCentered(d, mouseX, mouseY);

  //text("Hello", 0, 48);

  /*
  for (Datum d : data) {
   timeline.drawDate(d, 5 * scaleFactor, 40 * scaleFactor);
   }
   */
}

void drawMask(float s) {
  pushStyle();
  noFill();
  stroke(0);
  strokeWeight(s);
  ellipseMode(CORNER);
  ellipse(0, 0, width, height);
  popStyle();
}

void drawLegend() {
  textFont(corpusFont);
  String s = "100 worst and unusual Aircrashes   1933 – 2014";

  fill(255);

  textFont(corpusFontBold);
  textSize(30*scaleFactor);
  for (int i = 0; i < REPEAT_COUNT; i++) {
    pushMatrix();
    translate(width * 0.5, height * 0.5);
    rotate((i * TWO_PI) / REPEAT_COUNT);
    translate(-width * 0.5, -height * 0.5);
    drawArcTextCentered(s, width-1770*scaleFactor, height-1200*scaleFactor);
    popMatrix();
  }

  String s2= "  Fatalities             Total number of passangers";
  fill(255);
  textFont(corpusFont);
  textSize(30*scaleFactor);
  for (int i = 0; i < REPEAT_COUNT; i++) {
    pushMatrix();
    translate(width * 0.5, height * 0.5);
    rotate((i * TWO_PI) / REPEAT_COUNT);
    translate(-width * 0.5, -height * 0.5);
    drawArcTextCentered(s2, width-1810*scaleFactor, height-1228*scaleFactor);
    popMatrix();
  }



  fill(28, 229, 142);
  for (int i = 0; i < REPEAT_COUNT; i++) {
    pushMatrix();
    translate(width * 0.5, height * 0.5);
    rotate((i * TWO_PI) / REPEAT_COUNT);
    translate(-width * 0.5, -height * 0.5);
    ellipse (width-1763*scaleFactor, height-1331*scaleFactor, 15*scaleFactor, 15*scaleFactor);
    popMatrix();
  }

  fill(232, 26, 154);
  for (int i = 0; i < REPEAT_COUNT; i++) {
    pushMatrix();
    translate(width * 0.5, height * 0.5);
    rotate((i * TWO_PI) / REPEAT_COUNT);
    translate(-width * 0.5, -height * 0.5);
    ellipse (width-1654*scaleFactor, height-1507*scaleFactor, 15*scaleFactor, 15*scaleFactor);
    popMatrix();
  }
}

void updateState() {
  switch(currentState) {
  case STATE_PLAY:
    /*
    boolean flightFound = false;
    if (activeFlight == null) {
      int i = 0;
      while (i < myFlights.size() && !flightFound) {
        CrashFlight cf = myFlights.get(i);
        if (cf.myDatum.normMoment > TIME) {
          setActiveFlight(cf);
          flightFound = true;
        }
        i++;
      }
    }
    if (aboutFlightTime(TIME, activeFlight)) {
      FLIGHT_TIME = 0;
      currentState = STATE_DISPLAY_FLIGHT;
      println("PLAY > STATE_DISPLAY_FLIGHT");
    } else {
      TIME += TIME_INC;
    }
    */
    break;
  case STATE_SEEK:
    /*
    TIME += SEEK_INC;
    FLIGHT_TIME = 0;
    if (abs(SEEK_TIME - TIME) < SEEK_EPSILON) {
      currentState = STATE_DISPLAY_FLIGHT_THEN_PAUSE;
      println("STATE_SEEK > STATE_DISPLAY_FLIGHT_THEN_PAUSE");
    }
    */
    break;
  case STATE_DISPLAY_FLIGHT:
    /*
    FLIGHT_TIME += FLIGHT_TIME_INC;
    activeFlight.display(FLIGHT_TIME);
    if (activeFlight.finished) {
      activeFlight = null;
      currentState = STATE_PLAY;
      println("STATE_DISPLAY_FLIGHT > STATE_PLAY");
      TIME += TIME_INC;
      FLIGHT_TIME = 0;
    }
    */
    break;
  case STATE_DISPLAY_FLIGHT_THEN_PAUSE:
    /*
    //TODO: »freeze« display
    FLIGHT_TIME += FLIGHT_TIME_INC;
    activeFlight.display(FLIGHT_TIME);
    if (activeFlight.pausable) {
      ////activeFlight = null;
      currentState = STATE_PAUSED;
      println("STATE_DISPLAY_FLIGHT_THEN_PAUSE > STATE_PAUSED");
    }
    */
    break;
  case STATE_PAUSED:
    /*
    if (activeFlight != null) {
      activeFlight.display(FLIGHT_TIME);
    }
    */
    break;
  }
}

void updateShader() {
  //deltaLat = 0;
  //deltaLon = 0;
  //deltaLonPost = 0;
  //mapScale = 2;
  shader.set("deltaLat", deltaLat);
  shader.set("deltaLon", deltaLon);
  shader.set("deltaLonPost", deltaLonPost); //TODO: +/-ORIENTATION?
  shader.set("scale", mapScale);
}

void redrawMap() {
  mapContainer.beginDraw();
  mapContainer.background(0);

  map.disableStyle();
  mapContainer.stroke(93);
  //mapContainer.strokeJoin(ROUND);
  //mapContainer.strokeCap(PROJECT);

  //mapContainer.strokeWeight(1f * sqrt(mapScale));
  mapContainer.strokeWeight(0.5f);
  mapContainer.fill(61);

  float s = 0.964;
  mapContainer.shape(map, 0, 0, mapContainer.width, mapContainer.height*s);
  mapContainer.endDraw();
}

void initShape() {
  quad = createShape();
  quad.beginShape();
  quad.fill(255, 255, 0);
  quad.textureMode(NORMAL);
  quad.noStroke();
  quad.vertex(0, 0, 0, 0, 0);
  quad.vertex(width, 0, 0, 1, 0);
  quad.vertex(width, height, 0, 1, 1);
  quad.vertex(0, height, 0, 0, 1);
  quad.endShape();
}

void keyPressed() {
}