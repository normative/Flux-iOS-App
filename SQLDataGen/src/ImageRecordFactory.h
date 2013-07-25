/*
 * ImageRecordFactory.h
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */

#ifndef IMAGERECORDFACTORY_H_
#define IMAGERECORDFACTORY_H_

#include "boost/date_time/posix_time/posix_time.hpp"
#include "boost/date_time/gregorian/gregorian.hpp"

#include "LocationFactory.h"
#include "ImageRecord.h"

#include <random>
#include <list>

class ImageRecordFactory
{
 public:
  ImageRecordFactory();
  virtual ~ImageRecordFactory();

  void SetLocationFactory(LocationFactory *loc);
  ImageRecord *MakeNewImageRecord();
  void SetTimeRange(boost::gregorian::date start, boost::gregorian::date end);
  void GenerateRecords(std::list<ImageRecord *> &recList, int numRecs);

 private:
  LocationFactory *locFac;

  std::default_random_engine *userIDGen;
  std::exponential_distribution<double> *userIDDist;

  std::default_random_engine *timestampGen;
  std::uniform_real_distribution<double> *timestampDist;


  // manage dates...
  boost::gregorian::date startDay;
  boost::gregorian::days timeSpan;

  uint64_t _makeUserID();
  boost::posix_time::ptime _makeTimeStamp();
};

#endif /* IMAGERECORDFACTORY_H_ */
