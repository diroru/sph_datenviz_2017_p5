PVector lngLatToXY(PVector f) {
  return lngLatToXY(f.x, f.y);
}

PVector lngLatToXY(float phi, float lambda) {
  return lngLatToXY(phi, lambda, PHI1, LAMBDA0, SCALE);
}

//source: http://mathworld.wolfram.com/LambertAzimuthalEqual-AreaProjection.html
//phi1 standard parallel
//lambda0 central longitude
PVector lngLatToXY(float phi, float lambda, float phi1, float lambda0, float scale) {
  float k = sqrt(2f / (1 + sin(phi1) * sin(phi) + cos(phi1) * cos(phi) * cos(lambda - lambda0)));
  //println(k);
  float x = k * cos(phi) * sin(lambda - lambda0);
  float y = k * (cos(phi1) * sin(phi) - sin(phi1) * cos(phi) * cos(lambda - lambda0));
  //return new PVector(x, y);
  return new PVector(x*width*0.25*scale + width*0.5, height*0.5 - y*height*0.25*scale);
}

PVector latlngToXYZ(PVector latlng) {
  float lat = radians(-latlng.x);
  float lng = radians(latlng.y);
  float x = cos(lng) * cos(lat);
  float z = sin(lng) * cos(lat);
  float y = sin(lat);
  return new PVector(x, y, z);
}

/*
PVector domeXYToLatlng(PVector xy, float aperture) {
 float x = xy.x - 0.5;
 float y = xy.y - 0.5;
 float lat = sqrt(x*x + y*y) * aperture;
 float lng = atan2(y,x);
 return new PVector(lat, lng);
 }
 */

void drawGeodetic(float lat0, float lng0, float lat1, float lng1, int res) {
  ArrayList<PVector> gs = getGeodetic(lat0, lng0, lat1, lng1, res);
  beginShape();
  for (PVector g : gs) {
    PVector v = lngLatToXY(g);
    vertex(v.x, v.y);
  }
  endShape();
}

void drawPoint(float lat, float lng) {
  PVector v = lngLatToXY(lat, lng);
  ellipseMode(RADIUS);
  ellipse(v.x, v.y, 5, 5);
}

PVector xyzToLatLng(PVector v) {
  float lambda = atan2(v.z, v.x);
  float mu = atan2(-v.y, sqrt(v.x*v.x  + v.z*v.z));
  return new PVector(degrees(mu), degrees(lambda));
}

ArrayList<PVector> getGeodetic(float lat0, float lng0, float lat1, float lng1, int res) {
  ArrayList<PVector> result = new ArrayList();
  //result.add(new PVector(lat0,lng0));
  PVector v0 = latlngToXYZ(new PVector(lat0, lng0));
  PVector v1 = latlngToXYZ(new PVector(lat1, lng1));
  for (int i = 0; i < res; i++) {
    float inc = i / float(res-1);
    //println(inc);
    PVector v = PVector.lerp(v0, v1, inc);
    sphericLerp(v0, v1, inc);
    result.add(xyzToLatLng(v));
  }
  //result.add(new PVector(lat1,lng1));
  return result;
}

PVector getGeodeticAtNormDist(float lat0, float lng0, float lat1, float lng1, float norm) {
  PVector v0 = latlngToXYZ(new PVector(lat0, lng0));
  PVector v1 = latlngToXYZ(new PVector(lat1, lng1));
  return xyzToLatLng(PVector.lerp(v0, v1, norm));
}

PVector sphericLerp(PVector v0, PVector v1, float f) {
  float angle =  PVector.angleBetween(v1, v0);
  PVector cx = v1.copy();
  PVector temp = v1.cross(v0);
  PVector cy = temp.cross(v1).setMag(v1.mag());
  float x = cx.x * cos(f * angle) + cy.x * sin(f * angle);
  float y = cx.y * cos(f * angle) + cy.y * sin(f * angle);
  float z = cx.z * cos(f * angle) + cy.z * sin(f * angle);
  return new PVector(x,y,z);
}

float getGeodeticDistance(float lat0, float lng0, float lat1, float lng1, int res) {
  //ArrayList<PVector> geodetic = getGeodetic(lat0, lng0, lat1, lng1, res);
  float result = 0;
  PVector v0 = latlngToXYZ(new PVector(lat0, lng0));
  PVector v1 = latlngToXYZ(new PVector(lat1, lng1));
  PVector p0 = v0.copy();
  for (int i = 1; i < res; i++) {
    float inc = i / float(res-1);
    //println(inc);
    PVector p1 = PVector.lerp(v0, v1, inc);
    result += PVector.dist(p0, p1);
    p0 = p1.copy();
  }
  return result;
}