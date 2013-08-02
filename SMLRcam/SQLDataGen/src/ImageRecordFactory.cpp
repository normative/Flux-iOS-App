/*
 * ImageRecordFactory.cpp
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */


#include "ImageRecordFactory.h"
#include <random>
#include <iostream>

extern unsigned GetSeed();

const uint64_t MAX_USERS = 131072;    // 128k users for now...

ImageRecordFactory::ImageRecordFactory()
{
  // TODO Auto-generated constructor stub

  locFac = 0;

  userIDGen = new std::default_random_engine(GetSeed());
  userIDDist = new std::exponential_distribution<double>(10.0);

  timestampGen = new std::default_random_engine(GetSeed());
  timestampDist = new std::uniform_real_distribution<double>(0.0, 1.0);
}

ImageRecordFactory::~ImageRecordFactory()
{
  // TODO Auto-generated destructor stub
}

void ImageRecordFactory::SetLocationFactory(LocationFactory *loc)
{
  locFac = loc;
}

ImageRecord *ImageRecordFactory::MakeNewImageRecord()
{
  // create the fields...
  ImageRecord *ir = new ImageRecord(_makeUserID(), _makeTimeStamp(), (*locFac)(), 0.0, 0.0, 0.0);

  return ir;
}

void ImageRecordFactory::SetTimeRange(boost::gregorian::date start, boost::gregorian::date end)
{
  startDay = start;
  timeSpan = end - start;

  std::cout << "start date: " << startDay << ", span: " << timeSpan << std::endl;
}

uint64_t ImageRecordFactory::_makeUserID()
{
  //uint64_t retval = 0;//
  uint64_t retval = (((uint64_t)((*userIDDist)((*userIDGen)) * (double)MAX_USERS)) % (uint64_t)MAX_USERS);
  return retval;
}

using namespace boost::posix_time;
using namespace boost::gregorian;

boost::posix_time::ptime ImageRecordFactory::_makeTimeStamp()
{
  ptime newTimeStamp;
  double random_val = 0.0;
  date offsetdate;
  time_duration td;

  random_val = (*timestampDist)((*timestampGen)) * timeSpan.days();   // stretch (0.0 <= value < 1.0) to span the full timespan
  //random_val *= timeSpan.days();

  offsetdate = startDay + days(random_val);

  random_val -= (int)random_val;
  seconds secoffset = seconds(random_val * 86400.0);   // convert fractional portion to seconds -> 86400 = 60 * 60 * 24
  newTimeStamp = ptime(offsetdate, secoffset);

  return newTimeStamp;
}

void ImageRecordFactory::GenerateRecords(std::list<ImageRecord *> &recList, int numRecs)
{
  ImageRecord *ir = 0;
  for (int x = 0; x < numRecs; x++)
  {
    ir = MakeNewImageRecord();
    if (ir != 0)
      recList.push_back(ir);
  }
}
