/*
 * GlobalLocationFactory.h
 *
 *  Created on: 2013-07-23
 *      Author: denis
 */

#ifndef GLOBALLOCATIONFACTORY_H_
#define GLOBALLOCATIONFACTORY_H_

#include "LocationFactory.h"

class GlobalLocationFactory : public LocationFactory
{
 public:
  GlobalLocationFactory();
  virtual ~GlobalLocationFactory();

 protected:
  virtual double _makeLat();
  virtual double _makeLon();

};

#endif /* GLOBALLOCATIONFACTORY_H_ */
