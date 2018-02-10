//TODO: font settings

void drawArcTextCentered(String theText, PVector v) {  
  drawArcTextCentered(theText, v.x, v.y);
}

void drawArcTextCentered(String theText, float x0, float y0) {
  float theW = textWidth(theText);
  float rad = PVector.dist(new PVector(x0, y0), center());
  float phi = getPhiFromSides(theW, rad);
  PVector v = new PVector(x0, y0);
  v.sub(center());
  v.rotate(phi*0.5);
  v.add(center());
  drawArcText(theText, v.x, v.y);
}

void drawArcText(String theText, PVector v) {
  drawArcText(theText, v.x, v.y);
}

void drawArcText(String theText, float x0, float y0) {
  float dx = x0 - width*0.5;
  float dy = y0 - height*0.5;
  float x = x0;
  float y = y0;
  float radius = sqrt(dx * dx + dy * dy);
  char[] letters = theText.toCharArray();
  for (int i = 0; i < letters.length; i++) {
    char letter = letters[i];
    drawTangentialText(letter, x, y);

    float characterWidth = textWidth(letter);
    //applying sine theorem
    float theta = 2f * asin(characterWidth / radius * 0.5f);
    PVector nextCoords = new PVector(x, y);
    nextCoords.add(new PVector(-width*0.5, -height*0.5));
    nextCoords.rotate(-theta);
    nextCoords.add(new PVector(width*0.5, height*0.5));
    x = nextCoords.x;
    y = nextCoords.y;
  }
}

void drawTangentialTextPolar(String theText, float theta, float radius) {
  float x = width * 0.5 + cos(theta) * radius;
  float y = height * 0.5 + sin(theta) * radius;
  drawTangentialText(theText + "", x, y);
}

void drawTangentialText(String theText, PVector v) {
  drawTangentialText(theText + "", v.x, v.y);
}

void drawTangentialText(char theText, float x, float y) {
  drawTangentialText(theText + "", x, y);
}

void drawTangentialText(String[] theTextTokens, color[] colors, float x, float y) {
  drawTangentialText(theTextTokens, colors, 255, x, y);
}

void drawTangentialText(String[] theTextTokens, color[] colors, float alpha, float x, float y) {
  float dx = x - width*0.5;
  float dy = y - height*0.5;
  float angle = atan2(dy, dx) - HALF_PI;

  pushMatrix();
  translate(x, y);
  rotate(angle);
  for (int i = 0; i < theTextTokens.length; i++) {
    fill(colors[i], alpha);
    text(theTextTokens[i], 0, 0);
    translate(textWidth(theTextTokens[i]), 0);
  }
  popMatrix();
}

void drawTangentialTextPolar(String[] theTextTokens, color[] colors, float alpha, float theta, float radius) {
  float x = width*0.5 + cos(theta) * radius;
  float y = height*0.5 + sin(theta) * radius;
  drawTangentialText(theTextTokens, colors, alpha, x, y);
}

void drawTangentialText(String theText, float x, float y) {
  float dx = x - width*0.5;
  float dy = y - height*0.5;
  float angle = atan2(dy, dx) - HALF_PI;

  pushMatrix();
  translate(x, y);
  rotate(angle);
  text(theText, 0, 0);
  popMatrix();
}

PVector incrementRadially(PVector src, float delta) {
  PVector result = src.copy();
  result.sub(new PVector(width * 0.5, height * 0.5));
  float mag = result.mag();
  result.setMag(mag + delta);
  result.add(new PVector(width * 0.5, height * 0.5));
  return result;
}

PVector center() {
  return new PVector(width*0.5, height*0.5);
}

float getPhiFromSides(float base, float radius) {
  return asin(base * 0.5 / radius) * 2;
}

int signum(float f) {
  if (f >= 0) {
    return 1;
  }
  return -1;
}

void setActiveFlight(CrashFlight theFlight) {
  activeFlight = theFlight;
  activeFlight.finished = false;
  activeFlight.pausable = false;
  activeFlight.displayAll = false;
}