/*
 * GlobalLocationFactory.cpp
 *
 *  Created on: 2013-07-23
 *      Author: denis
 */

#include "GlobalLocationFactory.h"

GlobalLocationFactory::GlobalLocationFactory() : LocationFactory()
{
  // TODO Auto-generated constructor stub

}

GlobalLocationFactory::~GlobalLocationFactory()
{
  // TODO Auto-generated destructor stub
}

double GlobalLocationFactory::_makeLat()
{
  // use base distribution to generate value between +-75
  return ((posGen->Generate() * 150.0) - 75.0);
}

double GlobalLocationFactory::_makeLon()
{
  // use base distribution to generate value between +-180
  return ((posGen->Generate() * 360.0) - 180.0);
}

