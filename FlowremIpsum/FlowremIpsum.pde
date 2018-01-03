import java.util.*;

//map of country objects, labelled by their iso3 code
HashMap<String, Country> countries = new HashMap<String, Country>();
Table countryData, flowData;

//GENERAL CONSTANTS
final int GPI_YEAR_START = 2008;
final int GPI_YEAR_END = 2016;
final int GPI_MIN = 1;
final int GPI_MAX = 5;

//SORTING TYPE CONSTANTS
final int SORT_BY_COUNTRY_NAME = 0;
final int SORT_BY_CONTINENT = 1;
final int SORT_BY_INDEX = 2; //needs an active year
final int SORT_BY_CONTINENT_THEN_INDEX = 3;


void setup() {
  size(1024, 512);
  //load tables
  countryData = loadTable("gpi_2008-2016_geocodes+continents_v4.csv", "header");
  flowData = loadTable("GlobalMigration.tsv", "header, tsv");
  //instantiate countries
  for (int i = 0; i < countryData.getRowCount(); i++) {
    TableRow row = countryData.getRow(i);
    String iso3 = row.getString("alpha-3");
    String name = row.getString("country");
    String region = row.getString("region");
    String subRegion = row.getString("sub-region");

    //make new country, only local
    Country theCountry = new Country(name, iso3, region, subRegion);

    //add to collection of countries
    countries.put(iso3, theCountry);

    //we add the gpi value for each year to country "theCountry"
    for (int year = GPI_YEAR_START; year <= GPI_YEAR_END; year++) {
      String yearString = "score_" + year; //building the right column name
      Float gpi = row.getFloat(yearString); //retrieving the value (a float number) for the given column (year)
      theCountry.setGPI(year, gpi); //putting the value into the country
    }
  }
  //print all keys
  println("KEYS:\n", countries.keySet());
  println("-----");
  //print all countries
  println("VALUES:\n", countries.values());
  println("-----");
  //showing the Iceland’s GPI for 2008
  println(countries.get("ISL").getGPI(2016));
}

void draw() {
  //draw countries
  background(0);
  noStroke();
  fill(255);

  //applying default sorting by countryName
  ArrayList<Country> countriesByRegionAndIndex = getSortedCountries(countries, SORT_BY_CONTINENT_THEN_INDEX, 2016);

  //make layout
  float margin = 10;
  float gap = 2;
  makeLayout(margin, margin, width - 2 * margin, height-2*margin, gap, countriesByRegionAndIndex, 2016);

  for (Country theCountry : countriesByRegionAndIndex) {
    //println(theCountry.name);
    theCountry.display();
  }
}