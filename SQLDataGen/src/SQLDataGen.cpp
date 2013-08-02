//============================================================================
// Name        : SQLDataGen.cpp
// Author      : dsd
// Version     :
// Copyright   : Your copyright notice
// Description : Hello World in C++, Ansi-style
//============================================================================

#include <queue>
#include <iostream>
#include <fstream>
#include <random>
#include <chrono>


#include "ImageRecordFactory.h"
#include "LocationFactory.h"
#include "NormalRandomGenerator.h"
#include "UniformRandomGenerator.h"
#include "GlobalLocationFactory.h"

#include "boost/date_time/posix_time/posix_time.hpp"

using namespace std;

uint64_t const MAX_USERS = 131072;    // 128k users for now...

#define TORONTO
#define ROME
#define PARIS
#define GLOBAL

#define GEN_CSV

using namespace boost::gregorian;

const char *filename = "SQLTestData.csv";

// set seed to non-0 value to initialize a repeatable sequence of seeds for the generators.
// set to 0 to use a non-repeatable sequence of seeds (based on current time), different with each execution
static unsigned seed = 5;
static unsigned lastseed = 0;

unsigned GetSeed()
{
  // repeatable, controlled randomizing - all generators get new seeds but the seeds are repeatable between executions
  if ((seed == 0) || (lastseed != 0))
  {
    typedef std::chrono::high_resolution_clock myclock;
    myclock::time_point beginning = myclock::now();
    seed = beginning.time_since_epoch().count();

    if (seed <= lastseed)
      seed = lastseed + 1;

    lastseed = seed;
  }
  else
  {
    ++seed;
  }

  return seed;
}

bool compare_ImageRecord (ImageRecord *first, ImageRecord *second)
{
  return (*first) < (*second);
}

int main()
{
  std::list<ImageRecord *> recList;
  ImageRecordFactory irf;
  LocationFactory lf;
  double lat = 0.0, lon = 0.0;

  RandomGenerator *normalGen = new NormalRandomGenerator(0.5, 0.15);
  RandomGenerator *uniformGen = new UniformRandomGenerator(0.0, 1.0);

  irf.SetLocationFactory(&lf);
  irf.SetTimeRange(date(2004,01,01), date(2013,07,20));

  boost::posix_time::ptime startTime = boost::posix_time::second_clock::local_time();
  std::cout << startTime << ", starting..." << std:: endl;

  // Total Points:                            13121100
  // Toronto                          4121100
  //  CN Tower:               2010000
  //    base:     1000000
  //    main obs: 1000000
  //    spacedeck:  10000
  //  General:                1000000
  //  SkyDome:                1000000
  //  Nathan Philips Square:   100000
  //  ROM:                      10000
  //  Spadina & Dundas:          1000
  //  Normative Offices:          100
  //
  //  Rome                            3000000
  //  Trevi Fountain:         2000000
  //  General:                1000000
  //
  //  Paris                           4000000
  //  General:                1000000
  //  Eiffel Tower:           2000000
  //    base:     1000000
  //    obs deck: 1000000
  //  square:                 1000000
  //
  //  Global                          2000000

  // Toronto
  // CN Tower:
  //    43:38:33.36N, 79:23:13.56W
  //    base: 1000000     (ground)
  //    obs/rest: 1000000 (350m)
  //    space: 100000     (450m)
#ifdef TORONTO
  // CN tower base
  //    1000000 points, 150m diameter, split normal distribution
  lat =  (43.0 + (38.0 / 60.0) + (33.36 / 3600.0));
  lon = -(79.0 + (23.0 / 60.0) + (13.56 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 75.0, 150.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 1000000);

  // CN tower main observation
  //    1000000 points, 44m diameter, split normal distribution @ 350m
  lf.SetLocDistribution(normalGen, 22.0, 44.0);
  lf.SetAltitude(350.0, 353.0);
  irf.GenerateRecords(recList, 1000000);

  // CN tower spacedeck
  //    10000 points, 10m diameter, split normal distribution @ 450m
  lf.SetLocDistribution(normalGen, 5.0, 10.0);
  lf.SetAltitude(450.0, 453.0);
  irf.GenerateRecords(recList, 10000);

  // General:
  //    43:38:29.0N, 79:23:21W
  //    1000000 points, 250m diameter, uniform distribution @ ground
  lat =  (43.0 + (38.0 / 60.0) + (29.0 / 3600.0));
  lon = -(79.0 + (23.0 / 60.0) + (21.0 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( uniformGen, 125.0, 250.0);
  lf.SetAltitude(1.0, 30.0);
  irf.GenerateRecords(recList, 1000000);

  // SkyDome:
  //    43:38:29.0N, 79:23:21W
  //    1000000 points, 250m diameter, split normal distribution, 1-30m
  lat =  (43.0 + (38.0 / 60.0) + (29.0 / 3600.0));
  lon = -(79.0 + (23.0 / 60.0) + (21.0 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 125.0, 250.0);
  lf.SetAltitude(1.0, 30.0);
  irf.GenerateRecords(recList, 1000000);

  // Nathan Phillips Square:
  //    43:39:10.78N, 79:22:50.8W
  //    100000 points, 200m diameter, normal distribution @ ground
  lat =  (43.0 + (39.0 / 60.0) + (10.78 / 3600.0));
  lon = -(79.0 + (22.0 / 60.0) + (50.8 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 0.0, 200.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 100000);

  // ROM
  //    43:40:03.69, 79:23:41.54W
  //    10000 points, 100m diameter, normal distribution, 1-10m
  lat =  (43.0 + (40.0 / 60.0) + (3.69 / 3600.0));
  lon = -(79.0 + (23.0 / 60.0) + (41.54 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 0.0, 100.0);
  lf.SetAltitude(1.0, 10.0);
  irf.GenerateRecords(recList, 10000);
#endif
  // Spadina & Dundas
  //    43:39:10.51, 79:23:52.99W
  //    1000 points, 30m diameter, normal distribution @ ground
  lat =  (43.0 + (39.0 / 60.0) + (10.51 / 3600.0));
  lon = -(79.0 + (23.0 / 60.0) + (52.99 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 0.0, 30.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 1000);

  // Normative Offices
  //    43:39:11.92, 79:24:23.06W
  //    100 points, 20m diameter, normal distribution @ ground
  lat =  (43.0 + (39.0 / 60.0) + (11.92 / 3600.0));
  lon = -(79.0 + (24.0 / 60.0) + (23.06 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution( normalGen, 0.0, 20.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 100);


#ifdef ROME
  // Rome
  // General
  //    41:53:19.61N, 12:31:43.45E
  //    1000000 points, 20km diameter, uniform distribution, 1-30m
  lat = ( 41.0 + (53.0 / 60.0) + (19.61 / 3600.0));
  lon = ( 12.0 + (31.0 / 60.0) + (43.45 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution(uniformGen, 0.0, 20000.0);
  lf.SetAltitude(1.0, 30.0);
  irf.GenerateRecords(recList, 1000000);

  // Trevi Fountain
  //    41:54:03.061N, 12:29:00.10E
  //    2000000 points, 30m diameter, normal distribution, @ ground
  lat = ( 41.0 + (54.0 / 60.0) + ( 3.06 / 3600.0));
  lon = ( 12.0 + (29.0 / 60.0) + ( 0.10 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution(normalGen, 0.0, 30.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 2000000);
#endif
#ifdef PARIS
  // Paris
  // General
  //    48:51:43.41N, 2:19:37.84E
  //    1000000 points, 20km diameter, uniform distribution, 1-30m
  lat = ( 48.0 + (51.0 / 60.0) + (43.41 / 3600.0));
  lon = (  2.0 + (19.0 / 60.0) + (37.84 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution(uniformGen, 0.0, 20000.0);
  lf.SetAltitude(1.0, 30.0);
  irf.GenerateRecords(recList, 1000000);

  // Eiffel Tower base
  //    48:51:29.56N, 2:17:40.57E
  //    1000000 points, 200m diameter, split normal distribution, 1-3m
  lat = ( 48.0 + (51.0 / 60.0) + (29.56 / 3600.0));
  lon = (  2.0 + (17.0 / 60.0) + (40.57 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution(normalGen, 100.0, 200.0);
  lf.SetAltitude(1.0, 3.0);
  irf.GenerateRecords(recList, 1000000);

  // Eiffel Tower obs deck
  //    41:53:19.61N, 12:31:43.45E
  //    1000000 points, 10m diameter, uniform distribution, 273-276m
  lf.SetLocDistribution(normalGen, 5.0, 10.0);
  lf.SetAltitude(273.0, 276.0);
  irf.GenerateRecords(recList, 1000000);

  // Square
  //    48:51:40.20N, 2:17:23.94E
  //    1000000 points, 600m diameter, uniform distribution, 1-10m
  lat = ( 48.0 + (51.0 / 60.0) + (40.20 / 3600.0));
  lon = (  2.0 + (17.0 / 60.0) + (23.94 / 3600.0));
  lf.SetLocation(lat, lon);
  lf.SetLocDistribution(uniformGen, 0.0, 600.0);
  lf.SetAltitude(1.0, 10.0);
  irf.GenerateRecords(recList, 1000000);
#endif
#ifdef GLOBAL
  // Global General
  //    2000000 points, uniformly distributed globally (between +- 75deg lat)
  GlobalLocationFactory glf;
  glf.SetLocDistribution(uniformGen, 0.0, 0.0);
  irf.SetLocationFactory(&glf);
  irf.GenerateRecords(recList, 2000000);
#endif

  boost::posix_time::ptime genTime = boost::posix_time::second_clock::local_time();
  boost::posix_time::time_duration gtime = genTime - startTime;
  std::cout << genTime << ", generation elapsed: " << gtime << ". Done generating, sorting... " << std::endl;

  // sort in timestamp order (as clustered in db)
  recList.sort(compare_ImageRecord);

  boost::posix_time::ptime srtTime = boost::posix_time::second_clock::local_time();
  boost::posix_time::time_duration stime = srtTime - genTime;
  std::cout << srtTime << ", sort elapsed: " << stime << ". Done sorting, writing... " << std::endl;

#ifdef GEN_CSV

  // open the stream to dump the data to...
  ofstream outfile(filename, ios_base::trunc);

  std::list<ImageRecord *>::iterator it;
  ImageRecord *ir;

  for (it = recList.begin(); it != recList.end(); ++it)
  {
    ir = (*it);
    if ((ir) != 0)
    {
      ir->DumpToCSVStream(outfile, false);
      delete ir;
    }
  }

  outfile.close();

#endif

  recList.clear();

  boost::posix_time::ptime endTime = boost::posix_time::second_clock::local_time();
  boost::posix_time::time_duration etime = endTime - srtTime;
  boost::posix_time::time_duration ttime = endTime - startTime;
  std::cout << endTime << ", write elapsed: " << etime << ", Total elapsed: " << ttime << ". All Done!! " << std::endl;
  return 0;
}
