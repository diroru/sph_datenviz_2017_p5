import java.util.*;
//import java.awt.event.*;
//import javax.swing.event.*;
//import java.awt.event.*;
import codeanticode.planetarium.*;
import controlP5.*;

Table countryData, flowData, populationData;

//GENERAL CONSTANTS
final int GPI_YEAR_START = 2008;
final int GPI_YEAR_END = 2016;
final int MIGRATION_YEAR_START = 1980;
final int MIGRATION_YEAR_END = 2013;
final int YEAR_START = 2008;
final int YEAR_END = 2013;
final int GPI_MIN = 1;
final int GPI_MAX = 5;
final int SET_START_POS = 0;
final int SET_END_POS = 1;

//SORTING TYPE CONSTANTS
final int SORT_BY_COUNTRY_NAME = 0;
final int SORT_BY_CONTINENT = 1;
final int SORT_BY_INDEX = 2; //needs an active year
final int SORT_BY_CONTINENT_THEN_INDEX = 3;
int currentSortingMethod = SORT_BY_CONTINENT_THEN_INDEX;

float TIME = 0;
float TIME_INC = 0.05;

//Layout globals
//float margin = 10;
float gap = 2;
Long POPULATION_MIN = Long.MAX_VALUE;
Long POPULATION_MAX = Long.MIN_VALUE;
Long POPULATION_CUTOFF = 50000L;
Long MIGRATION_FLOW_MAX = Long.MIN_VALUE;
Long MIGRATION_FLOW_MIN = Long.MAX_VALUE;
Long MIGRATION_FLOW_LOWER_LIMIT = 100L;

ArrayList<Country> countries = new ArrayList<Country>();
//Map of countries, labelled by names
HashMap<String, Country> countriesByName = new HashMap<String, Country>();

HashMap<Integer, ArrayList<MigrationFlow>> migrationFlows = new HashMap<Integer, ArrayList<MigrationFlow>>(); 

//lookup table for mismatched country names
HashMap<String, String> countryLookupTable = new HashMap<String, String>(); 
ArrayList<String> missingCountries = new ArrayList<String>();

int currentYear = 2013;

HashSet<Country> hoverCountries = new HashSet<Country>();
ArrayList<YearSelector> yearSelectors = new ArrayList<YearSelector>();

int MARGIN = 20;
LayoutInfo panelLayout, graphLayout, flowLayout, yearsLayout; 

DomeCamera dc;
ControlP5 cp5;

int gridMode = Dome.NORMAL;
ProjectionMesh mesh;
PGraphics canvas;

float xAngle = 0f;
float yAngle = 0f;
float zAngle = 0f;
float deltaX = 0f;
float deltaY = 0f;
float deltaZ = 0f;
int currentImage = 0;

PVector mappedMouse = new PVector();

void setup() {
  size(1024, 1024, Dome.RENDERER);
  //initial default camera, i.e. interface to interact with the renderer.
  dc = new DomeCamera(this);
  dc.setDomeAperture(1f);
  //we enable the sixth side, sothat we see what is happenning
  dc.setFaceDraw(DomeCamera.NEGATIVE_Z, true);
  canvas = createGraphics(2048, 1024, P3D);
  mesh = new ProjectionMesh(canvas);
  //mesh.toggleShape();
  //mesh.toggleGrid();
  float panelWidth = 200;
  float yearBarHeight = 30f;
  float graphHeight = (canvas.height - MARGIN * 3 - yearBarHeight) * 0.5;
  float graphWidth = canvas.width - MARGIN * 3 - panelWidth;
  panelLayout = new LayoutInfo(MARGIN, MARGIN, panelWidth, canvas.height - 2*MARGIN);
  graphLayout = new LayoutInfo(panelWidth + 2 * MARGIN, MARGIN + graphHeight, graphWidth, graphHeight);
  flowLayout = new LayoutInfo(panelWidth + 2 * MARGIN, MARGIN, graphWidth, graphHeight);
  graphLayout.gap = gap;

  //pixelDensity(2);
  ellipseMode(CORNER);
  textSize(20);
  loadData(false);

  //Example of animating between two layouts
  //first sort by one criterium, then set start layout
  makeLayout(graphLayout, countries, currentSortingMethod, SET_START_POS, currentYear);
  makeLayout(graphLayout, countries, currentSortingMethod, SET_END_POS, currentYear);

  //sort by other criterium, then set end layout
  println("Population MIN", POPULATION_MIN);
  println("Population MAX", POPULATION_MAX);
  //println(countries);

  int repeat = 3;
  int count = YEAR_END - YEAR_START + 1;
  for (int i = 0; i <= repeat * count; i++) {
    int year = i % count + YEAR_START;
    float dw = (canvas.width - panelWidth - 2*MARGIN) / (repeat * float(count));
    float y = canvas.height - MARGIN;
    float w = 50;
    float h  = 20;
    LayoutInfo yearLayout = new LayoutInfo(panelWidth + 2*MARGIN + dw * i, y, w, h);
    yearSelectors.add(new YearSelector(year, yearLayout, this));
  }
}

void pre() {
  mappedMouse = mapMouse(canvas, mouseX, mouseY);
}

void draw() {
  background(0);
  pushMatrix();

  translate(width/2, height/2, 0f);
  rotateX(radians(xAngle));
  rotateY(radians(yAngle));
  rotateZ(radians(zAngle));
  translate(deltaX, deltaY, deltaZ);
  mesh.display();
  popMatrix();
}

void post() {
  // The dome projection is centered at (0, 0), so the mouse coordinates
  // need to be offset by (width/2, height/2)
  canvas.beginDraw();
  //draw countries
  canvas.background(0);

  canvas.noStroke();
  canvas.fill(255);
  canvas.noStroke();
  for (Country theCountry : countries) {
    //println(theCountry.name);
    theCountry.update(TIME);
    theCountry.display(canvas);
  }

  TIME += TIME_INC;
  TIME = min(TIME, 1); 
  //println(TIME);

  displayFlows(canvas);
  for (YearSelector ys : yearSelectors) {
    ys.display(canvas);
  }

  canvas.fill(255, 255, 0, 127);
  canvas.ellipse(mappedMouse.x, mappedMouse.y, 10, 10);

  canvas.stroke(0, 255, 0);
  canvas.strokeWeight(2);
  for (int i = 0; i < 10; i++) {
    float y = graphLayout.y + graphLayout.h - constrainedLogScale(pow(10, i), graphLayout.h);
    canvas.line(0,y,canvas.width,y);
  }

  canvas.endDraw();
}

void displayFlows(PGraphics pg) {
  pg.noFill();
  String hoverCountry = null;

  if (hoverCountries.size() > 0) {
    Country hc = (Country)(hoverCountries.iterator().next());
    hoverCountry = hc.name;
  }

  for (MigrationFlow mf : migrationFlows.get(currentYear)) {
    if (hoverCountry == null) {
      pg.stroke(255, 31);
      pg.strokeWeight(2);
      if (mf.flow > MIGRATION_FLOW_LOWER_LIMIT) {
        mf.display(pg, height/2, MARGIN);
      }
    } else {
      if (mf.origin.name.equals(hoverCountry)) {
        pg.stroke(255, 0, 0, 63);
      } else if (mf.destination.name.equals(hoverCountry)) {
        pg.stroke(0, 0, 255, 63);
      } else {
        //stroke(255, 1);
        pg.noStroke();
      }
      if (mf.flow > MIGRATION_FLOW_LOWER_LIMIT) {
        mf.display(pg, height/2, MARGIN);
      }
    }
  }
}

void keyPressed() {
  canvas.save("test.png");
}