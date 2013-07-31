/*
 * RandomGenerator.h
 *
 *  Created on: 2013-07-22
 *      Author: denis
 */

#ifndef RANDOMGENERATOR_H_
#define RANDOMGENERATOR_H_

class RandomGenerator
{
 public:
  RandomGenerator();
  virtual ~RandomGenerator();

  virtual double Generate() = 0;
};

#endif /* RANDOMGENERATOR_H_ */
