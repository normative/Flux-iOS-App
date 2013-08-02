/*
 * LocationFactory.cpp
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */

#include "LocationFactory.h"
#include <math.h>
#include <stdlib.h>
#include <vector>
#include <iostream>
#include <iomanip>

extern unsigned GetSeed();

#define DEG2RAD(deg)  ((deg) * (M_PI / 180.0))
#define RAD2DEG(rad)  ((rad) * (180.0 / M_PI))

LocationFactory::LocationFactory()
{
  // TODO Auto-generated constructor stub
  posGen = 0;

  splitPoint = 0.0;
  posRange = 0.0;

  posBaseLat = 0.0;
  posBaseLon = 0.0;

  oneMeterLat = 0.0;
  oneMeterLon = 0.0;

  altGenerator.seed(GetSeed());
  //altDistribution = new uniform_real_distribution<double>(0.0, 1.0);
  altDistribution = 0;

  SetAltitude(1.0, 3.0);
}

LocationFactory::~LocationFactory()
{
  // TODO Auto-generated destructor stub
}

void LocationFactory::SetLocation(double lat, double lon)
{
  posBaseLat = lat;
  posBaseLon = lon;

  // TODO: calculate number of degrees (lat and lon) in 1m at this latitude...

  double lat0 = DEG2RAD(lat); // / 180.0 * M_PI;

  double const a = 6378137.0; // 6378.137000km
  double const f = 1.0 / 298.257223563;
  double const e2 = f * (2.0 - f);

  //     R1 = a   ( 1  - e^2)/     (  1 - e^2*    (sin(lat0))^2)    ^(3/2)
  double R1 = a * (1.0 - e2) / pow((1.0 - e2 * pow(sin(lat0), 2.0)), (3.0 / 2.0));
  //     R2 = a / sqrt(1 - e^2*    (sin(lat0))^2)
  double R2 = a / sqrt(1 - e2 * pow(sin(lat0), 2.0));

  //double dlat = 0.00001;
  //double dlon = 0.00001;

  //double dN = R1 * dlat;
  //double dE = R2 * cos(lat0) * dlon;

  // calc dlat and dlon (in degrees) for dN = dE = 1m
  oneMeterLat = RAD2DEG(1.0 / R1);  // * (180.0 / M_PI);
  oneMeterLon = RAD2DEG(1.0 / (R2 * cos(lat0)));  // * (180.0 / M_PI);

  //std::cout << "At " << std::setprecision(9) << lat << "," << std::setprecision(9) << lon << " OM Lat = " << std::setprecision(9) << oneMeterLat << ", OM Long = " << std::setprecision(9) << oneMeterLon << std::endl;
  //std::cout << "R1: " << R1 << " R2: " << R2 << " lat0: " << lat0 << std::endl;
}

void LocationFactory::SetAltitude(double minalt, double maxalt)
{
  if (altDistribution != 0)
    delete altDistribution;

  altDistribution = new std::uniform_real_distribution<double>(minalt, maxalt);
}

void LocationFactory::SetLocDistribution(RandomGenerator *gen, double splitpoint, double posrange)
{
  posGen = gen;
  //posGenerator = gen;
  //posDistribution = dist;
  splitPoint = splitpoint;
  posRange = posrange;
}

std::vector<double> *LocationFactory::operator()()
{
  std::vector<double> *result = new std::vector<double>(3); //_makeLat(), _makeLon(), _makeAlt());
  (*result)[0] = _makeLat();
  (*result)[1] = _makeLon();
  (*result)[2] = _makeAlt();

  return result;
}

// do prelim value calcs in meters, then convert to angle based on oneMeter factor
double LocationFactory::_makeLatLon(double base, double oneMeter)
{
  double retval = 0.0;

  retval = posGen->Generate() * posRange;
  if (splitPoint > 0.0)
  {
    if (retval > splitPoint)
    {
      retval -= splitPoint;
    }
    retval += (posRange - splitPoint);
  }

  return (base + ((retval - (posRange / 2.0)) * oneMeter));
}

double LocationFactory::_makeLat()
{
  return _makeLatLon(posBaseLat, oneMeterLat);
}

double LocationFactory::_makeLon()
{
  return _makeLatLon(posBaseLon, oneMeterLon);
}

// uniform distribution starting at altBase going to altRange
double LocationFactory::_makeAlt()
{
  return (*altDistribution)(altGenerator);
  //return altBase + ((*altDistribution)(altGenerator) * altRange);
  //return 0.0;
}

