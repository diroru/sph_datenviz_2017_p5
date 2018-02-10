class CrashFlight {
  Datum myDatum;
  int geodeticRes = 100;
  float duration = 0.05;
  PVector dep, dst;
  boolean coordsValid;
  Timeline myTimeline;
  float myStartMoment, myEndMoment;
  float minRadius = 1, maxRadius = 50;
  float rOcc, rFat;
  Float progressTime;
  CrashFlight previousFlight = null, nextFlight = null;
  boolean finished = false, displayAll = false, pausable = false;
  float myTotalDuration;
  float FADE_IN_TIME = 0.2;
  float FADE_OUT_TIME = 0.2;
  float DISPLAY_TIME = 1.0;

  CrashFlight(Datum d, Timeline tl) {
    myDatum = d;
    coordsValid = d.coordsValid();
    dep = new PVector(radians(d.depLatLng[0]), radians(d.depLatLng[1]));
    dst = new PVector(radians(d.dstLatLng[0]), radians(d.dstLatLng[1]));
    myTimeline = tl;
    myStartMoment = getNormalizedMoment(d, tl);
    myEndMoment = constrain(myStartMoment + duration, 0, 1);
 //   rFat = map(sqrt(d.fatalities), sqrt(MIN_FATALITIES), sqrt(MAX_FATALITIES), minRadius, maxRadius);
  //  rOcc = map(sqrt(d.occupants), sqrt(MIN_OCCUPANTS), sqrt(MAX_OCCUPANTS), minRadius, maxRadius);
    rFat = map(sqrt(d.fatalities), sqrt(0), sqrt(MAX_OCCUPANTS), minRadius, maxRadius);
    rOcc = map(sqrt(d.occupants), sqrt(0), sqrt(MAX_OCCUPANTS), minRadius, maxRadius);

    try {
      progressTime = phaseProgress.get(d.phaseCode);
      //println(phaseProgress.get(d.phaseCode), d.phaseCode);
    } 
    catch (Exception e) {
      e.printStackTrace();
      progressTime = 0.5;
    }
    myTotalDuration = FADE_IN_TIME + progressTime + DISPLAY_TIME + FADE_OUT_TIME;
  }

  void update(float normTime) {
  }

  void display(float normTime) {

    //if (coordsValid && normTime >= myStartMoment && normTime <= myEndMoment) {

    //float progress = norm(normTime, myStartMoment, myEndMoment);
    float alpha = map(normTime, 0, FADE_IN_TIME, 0, 255);
    if (normTime >= myTotalDuration - FADE_OUT_TIME) {
      alpha = map(normTime, myTotalDuration - FADE_OUT_TIME, myTotalDuration, 255, 0);
    }
    alpha = constrain(alpha, 0, 255);
    //boolean showStats = false;
    if (normTime >= myTotalDuration - FADE_OUT_TIME - DISPLAY_TIME) {
      displayAll = true;
    }
    if (normTime >= myTotalDuration - FADE_OUT_TIME - DISPLAY_TIME * 0.2) {
      pausable = true;
    }
    if (normTime >= myTotalDuration) {
      finished = true;
    }
    float progress = constrain(normTime - FADE_IN_TIME, 0, progressTime);
    //println("progress", progress);
    PVector planePos = getGeodeticAtNormDist(dep, dst, progress);
    PVector planePosXY = lngLatToXY(planePos);
    noFill();
    strokeWeight(1 * scaleFactor);

    //drawGeodetic(dep, dst, geodeticRes);
    strokeWeight(2 * scaleFactor);
    //DEBUG
    //stroke(255, 0, 0);
    //drawGeodetic(dep, dst, geodeticRes);
    //
    stroke(255, alpha);
    if (myDatum.isUnusual) {
      drawDashedGeodetic(dep, dst, geodeticRes, 0.5 * scaleFactor, 7 * scaleFactor);
    } else {
      drawDashedGeodetic(dep, dst, geodeticRes, 10 * scaleFactor, 20 * scaleFactor);
    }


    strokeWeight(4 * scaleFactor);
    drawGeodetic(dep, planePos, geodeticRes);


    PVector depXY = lngLatToXY(dep);
    PVector dstXY = lngLatToXY(dst);
    noStroke();
    fill(255, alpha);
    pushStyle();
    textSize(18 * scaleFactor);
    //drawArcTextCentered(myDatum.depCountry, depXY);
    //drawArcTextCentered(myDatum.dstCountry, dstXY);
    //textAlign(CENTER, TOP);
    //drawTangentialText(myDatum.depCountry, depXY);
    float depAngle = atan2(depXY.y - height * 0.5, depXY.x - width * 0.5);
    float dstAngle = atan2(dstXY.y - height * 0.5, dstXY.x - width * 0.5);
    float planeAngle = atan2(planePosXY.y - height * 0.5, planePosXY.x - width * 0.5);

    float depRadius = PVector.dist(depXY, new PVector(width*0.5, height*0.5));
    float dstRadius = PVector.dist(dstXY, new PVector(width*0.5, height*0.5));
    float planeRadius = PVector.dist(planePosXY, new PVector(width*0.5, height*0.5)) - 15 * scaleFactor;
    
    int firstH = RIGHT;
    int secondH = LEFT;
    int firstV = BOTTOM;
    int secondV = TOP;
    float dAngle = radians(1);
    float dRadius = 5 * scaleFactor;

    if (depAngle < dstAngle) {
      firstH = LEFT;
      secondH = RIGHT;
      depAngle -= dAngle;
      dstAngle += dAngle;
    } else {
      depAngle += dAngle;
      dstAngle -= dAngle;
    }

    if (depRadius > dstRadius) {
      firstV = TOP;
      secondV = BOTTOM;
      depRadius += dRadius;
      dstRadius -= dRadius;
    } else {
      depRadius -= dRadius;
      dstRadius += dRadius;
    }
    textAlign(firstH, firstV);
    drawTangentialTextPolar(myDatum.depShort, depAngle, depRadius);
    textAlign(secondH, secondV);
    drawTangentialTextPolar(myDatum.dstShort, dstAngle, dstRadius);

    //drawTangentialText(myDatum.depShort, depXY);
    //textAlign(CENTER, BOTTOM);
    //drawTangentialText(myDatum.dstCountry, dstXY);
    //drawTangentialText(myDatum.dstShort, dstXY);
    ellipseMode(RADIUS);
    fill(255, alpha);
    noStroke();
    ellipse(depXY.x, depXY.y, 5*scaleFactor, 5*scaleFactor);
    ellipse(dstXY.x, dstXY.y, 5*scaleFactor, 5*scaleFactor);
    popStyle();

    //draw dot
    /*
      if (rOcc - rFat > 0) {
     stroke(GREEN,127);
     strokeWeight((rFat-rOcc) * scaleFactor);
     } else {
     noStroke();
     }
     */
    noStroke();
    fill(GREEN, alpha*0.4);
    ellipse(planePosXY.x, planePosXY.y, rOcc * scaleFactor, rOcc * scaleFactor);
    fill(RED, alpha*0.4);
    ellipse(planePosXY.x, planePosXY.y, rFat * scaleFactor, rFat * scaleFactor);
    
    if (displayAll) {
      pushStyle();
      textAlign(CENTER, BOTTOM);
      textFont(corpusFontBold);
      textSize(30 * scaleFactor);
      drawTangentialTextPolar(new String[]{myDatum.fatalities+ "/", myDatum.occupants + ""}, new color[]{color(RED), color(GREEN)}, alpha, planeAngle, planeRadius);
      //drawTangentialText(new String[]{myDatum.fatalities+ " / ", myDatum.occupants + ""}, new color[]{color(RED), color(GREEN)}, alpha, planePosXY.x, planePosXY.y);
      popStyle();
    }

    //}
  }
}