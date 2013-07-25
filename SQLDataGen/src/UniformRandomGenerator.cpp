/*
 * UniformRandomGenerator.cpp
 *
 *  Created on: 2013-07-23
 *      Author: denis
 */

#include "UniformRandomGenerator.h"

extern unsigned GetSeed();

UniformRandomGenerator::UniformRandomGenerator()
{
  // TODO Auto-generated constructor stub
  generator.seed(GetSeed());
  distribution = new std::uniform_real_distribution<double>(0.0, 1.0);

}

UniformRandomGenerator::UniformRandomGenerator(double minv, double maxv)
{
  distribution = new std::uniform_real_distribution<double>(minv, maxv);

}

UniformRandomGenerator::~UniformRandomGenerator()
{
  // TODO Auto-generated destructor stub
}

double UniformRandomGenerator::Generate()
{
  return (*distribution)(generator);
}
