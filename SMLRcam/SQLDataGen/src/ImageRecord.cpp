/*
 * ImageRecord.cpp
 *
 *  Created on: 2013-07-19
 *      Author: denis
 */

#include <iomanip>
#include <math.h>
#include "ImageRecord.h"

#define DEG2RAD(deg)  ((deg) * (M_PI / 180.0))
#define RAD2DEG(rad)  ((rad) * (180.0 / M_PI))

ImageRecord::ImageRecord()
{
  // TODO Auto-generated constructor stub
  user_id = 0;
  time_stamp = boost::posix_time::ptime();
  latitude = 0.0;
  longitude = 0.0;
  altitude = 0.0;
  yaw = 0.0;
  pitch = 0.0;
  roll = 0.0;
}

ImageRecord::ImageRecord(  uint64_t uid,
              boost::posix_time::ptime ts,
              double lat,
              double lon,
              double alt,
              double y,
              double p,
              double r )
{
  user_id = uid;
  time_stamp = ts;
  latitude = lat;
  longitude = lon;
  altitude = alt;
  yaw = y;
  pitch = p;
  roll = r;
}

ImageRecord::ImageRecord(  uint64_t uid,
                           boost::posix_time::ptime ts,
                           std::vector<double> *pos,
                           double y,
                           double p,
                           double r )
{
  user_id = uid;
  time_stamp = ts;
  latitude = (*pos)[0];
  longitude = (*pos)[1];
  altitude = (*pos)[2];
  yaw = y;
  pitch = p;
  roll = r;
}

ImageRecord::~ImageRecord()
{
  // TODO Auto-generated destructor stub
}

// dump to provided stream in following order:
//      user_id,time_stamp,latitude,longitude,altitude,yaw,pitch,roll;

bool ImageRecord::operator<(ImageRecord &ir)
{
  return (time_stamp < ir.time_stamp);
}

//bool ImageRecord::operator<(ImageRecord ir)
//{
//  return (time_stamp < ir.time_stamp);
//}

bool ImageRecord::operator<(ImageRecord *ir)
{
  return (time_stamp < ir->time_stamp);
}

bool ImageRecord::Compare(ImageRecord *ir2)
{
  return (time_stamp < ir2->time_stamp);
}

void ImageRecord::DumpToCSVStream(std::ostream &s, bool inRadians)
{
  s.setf(std::ios::fixed, std::ios::floatfield);

  double lat, lon;

  if (inRadians)
  {
    lat = DEG2RAD(latitude);
    lon = DEG2RAD(longitude);
  }
  else
  {
    lat = latitude;
    lon = longitude;
  }

  s << std::setw(7) << user_id << ", "
      << time_stamp << ", "
      << std::setprecision(9) << lat << ", "
      << std::setprecision(9) << lon << ", "
      << std::setprecision(7) << altitude << ", "
      << std::setprecision(7) << yaw << ", "
      << std::setprecision(7) << pitch << ", "
      << std::setprecision(7) << roll
      << std::endl;

}

