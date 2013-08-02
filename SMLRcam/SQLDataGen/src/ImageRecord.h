/*
 * ImageRecord.h
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */

#ifndef IMAGERECORD_H_
#define IMAGERECORD_H_

#include "boost/date_time/posix_time/posix_time.hpp"
//#include "boost/date_time/gregorian/gregorian.hpp"

#include <iostream>
#include <stdint.h>
#include <vector>

class ImageRecord
{
 public:
  ImageRecord();
  ImageRecord(  uint64_t uid,
                boost::posix_time::ptime ts,
                double lat,
                double lon,
                double alt,
                double y,
                double p,
                double r );
  ImageRecord(  uint64_t uid,
                             boost::posix_time::ptime ts,
                             std::vector<double> *pos,
                             double y,
                             double p,
                             double r );
  virtual ~ImageRecord();

  bool operator<(ImageRecord &ir);
//  bool operator<(ImageRecord ir);
  bool operator<(ImageRecord *ir);

  bool Compare(ImageRecord *ir2);

  void DumpToCSVStream(std::ostream &s, bool inRadians=false);

 private:
  uint64_t user_id;
  boost::posix_time::ptime time_stamp;
  double latitude;
  double longitude;
  double altitude;
  double yaw;
  double pitch;
  double roll;

};

#endif /* IMAGERECORD_H_ */
