/*
 * UniformRandomGenerator.h
 *
 *  Created on: 2013-07-23
 *      Author: denis
 */

#ifndef UNIFORMRANDOMGENERATOR_H_
#define UNIFORMRANDOMGENERATOR_H_

#include "RandomGenerator.h"
#include <random>

class UniformRandomGenerator : public RandomGenerator
{
 public:
  UniformRandomGenerator();
  UniformRandomGenerator(double minv, double maxv);
  virtual ~UniformRandomGenerator();

  virtual double Generate();

  private:
   std::default_random_engine generator;
   std::uniform_real_distribution<double> *distribution;


};

#endif /* UNIFORMRANDOMGENERATOR_H_ */
