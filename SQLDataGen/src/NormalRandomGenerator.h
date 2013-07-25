/*
 * NormalRandomGenerator.h
 *
 *  Created on: 2013-07-22
 *      Author: denis
 */

#ifndef NORMALRANDOMGENERATOR_H_
#define NORMALRANDOMGENERATOR_H_

#include "RandomGenerator.h"
#include <random>

class NormalRandomGenerator : public RandomGenerator
{
 public:
  NormalRandomGenerator();
  NormalRandomGenerator(double mean, double stddev);
  virtual ~NormalRandomGenerator();

  virtual double Generate();

 private:
  std::default_random_engine generator;
  std::normal_distribution<double> *distribution;

};

#endif /* NORMALRANDOMGENERATOR_H_ */
