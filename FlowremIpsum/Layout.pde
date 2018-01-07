void makeLayout(float x0, float y0, float layoutWidth, float layoutHeight, float gap, ArrayList<Country> theCountries, int thePosType, int theYear) {
  int countryCount = theCountries.size();
  float countryWidth = (layoutWidth - gap * (countryCount - 1)) / float(countryCount);
  float x = x0;  
  //this is the same
  //for (int i = 0; i < theCountries.size(); i++) {
  //Country theCountry = theCountries.get(i);
  for (Country theCountry : theCountries) {
    
    Float gpi = theCountry.getGPI(theYear);
    Long pop = theCountry.getPOP(theYear);
    if (pop == null) {
      pop = 0L;
    }
    //float gpi = 2f;
    float countryHeight = map(pop, POPULATION_MIN, POPULATION_MAX, 0, layoutHeight - 5) + 5;
    float gray = map(gpi, GPI_MIN, GPI_MAX, 255, 0);
    color theColor = color(gray, 0, 255);
    float y = layoutHeight - countryHeight + y0;

    //it is cleaner to say, but it needs to be implemented!
    //theCountry.setX(x);
    //we set the layout values for each country
    //setting start position
    if (thePosType == SET_START_POS) {
      theCountry.setStartX(x);
      theCountry.setStartY(y);
      //theCountry.setCurrentX(x);
      //theCountry.setCurrentY(y);
    } else {
      theCountry.setEndX(x);
      theCountry.setEndY(y);
      //Ani.to(this, 1.5, "theCountry.currentX", theCountry.endX, Ani.BOUNCE_OUT);
      //Ani.to(this, 1.5, "theCountry.currentY", theCountry.endY, Ani.BOUNCE_OUT);
    }
    theCountry.w = countryWidth;
    theCountry.h = countryHeight;
    theCountry.setColor(theColor);

    //x needs to be incremented for the next country / bar
    x = x + countryWidth + gap;
  }
}