/*
 * NormalRandomGenerator.cpp
 *
 *  Created on: 2013-07-22
 *      Author: denis
 */

#include "NormalRandomGenerator.h"

extern unsigned GetSeed();

NormalRandomGenerator::NormalRandomGenerator()
{
  // TODO Auto-generated constructor stub
  generator.seed(GetSeed());
  distribution = new std::normal_distribution<double>(0.5, 0.15);

}

NormalRandomGenerator::NormalRandomGenerator(double mean, double stddev)
{
  distribution = new std::normal_distribution<double>(mean, stddev);
}

NormalRandomGenerator::~NormalRandomGenerator()
{
  // TODO Auto-generated destructor stub
}

double NormalRandomGenerator::Generate()
{
  return (*distribution)(generator);
}

