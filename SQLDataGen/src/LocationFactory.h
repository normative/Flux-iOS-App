/*
 * LocationFactory.h
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */

#ifndef LOCATIONFACTORY_H_
#define LOCATIONFACTORY_H_

#include "RandomGenerator.h"
#include <random>
#include <vector>

class LocationFactory
{
 public:
  LocationFactory();
  virtual ~LocationFactory();

  void SetLocation(double lat, double lon);
  void SetAltitude(double minalt, double maxalt);
  void SetLocDistribution(RandomGenerator *gen, double splitpoint, double posrange);

  std::vector<double> *operator()();

 protected:
  RandomGenerator *posGen;

  double splitPoint;
  double posRange;
  double posBaseLat;
  double posBaseLon;

  std::default_random_engine altGenerator;
  std::uniform_real_distribution<double> *altDistribution;

  double oneMeterLat;
  double oneMeterLon;

  double _makeLatLon(double base, double oneMeter);
  double _makeAlt();
  virtual double _makeLat();
  virtual double _makeLon();

};

#endif /* LOCATIONFACTORY_H_ */
