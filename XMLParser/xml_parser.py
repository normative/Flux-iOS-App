#!/usr/bin/env python

"""experiment_xml_to_kml.py: Convert a directory of XML files to KML.

experiment_xml_to_kml [path_to_xml_files (optional)] [kml_file_to_output (optional)]

Parses all XML files in a directory, extracting the 'Position' subtree.
Outputs the latitude and longitude of each location as a placemark in
a KML file with the date stamp as the name.

path_to_xml_files - path to folder of XML files
kml_file_to_output - KML filename to output in specified path
"""

import datetime
import os
import plistlib
import sys
from lxml import etree
from pykml.factory import KML_ElementMaker as KML

__author__ = "Ryan Martens"
__copyright__ = "Copyright 2013, SMLR"
__license__ = "None"
__version__ = "0.2"
__maintainer__ = "Ryan Martens"
__status__ = "Development"

class TestCases:
    start_times = {'1': datetime.datetime(2013, 07, 05, 17, 40),
                   '2': datetime.datetime(2013, 07, 05, 17, 42, 10),
                   '3': datetime.datetime(2013, 07, 05, 17, 46),
                   '4': datetime.datetime(2013, 07, 05, 17, 48),
                   '5': datetime.datetime(2013, 07, 05, 17, 51),
                   '6': datetime.datetime(2013, 07, 05, 17, 57),
                  }

def get_file_list(dirname):
    xml_files = []
    for file in os.listdir(dirname):
        if file.endswith(".xml"):
            xml_files.append(os.path.join(dirname,file))
    return xml_files

def parse_xml_file(xmlfilename):
    plist = plistlib.readPlist(xmlfilename)
    return plist["Position"]

def calculate_pm(date, position):
    pm_latlong = "%.15f, %.15f" % (-position["Longitude"], position["Latitude"],)
    #pm_name = position["DateStamp"]
    pm_name = string_to_date(date, True).strftime("%Y-%m-%d %H:%M:%S")
    pm = KML.Placemark(
            KML.name(pm_name),
            KML.Point(
                    KML.coordinates(pm_latlong)
            ))
    return pm

def create_xml_template():
    doc = KML.kml(
        etree.Comment(' required when using gx-prefixed elements '),
        KML.Document(
            KML.name("Experiments - Collection 1 - iPhone"),
        ))
    return doc

def string_to_date(str_date, short_format):
    if (short_format):
        year = int(str_date[:4])
        month = int(str_date[4:6])
        day = int(str_date[6:8])
        hour = int(str_date[8:10])
        minute = int(str_date[10:12])
        second = int(str_date[12:14])
    else:
        year = int(str_date[:4])
        month = int(str_date[5:7])
        day = int(str_date[8:10])
        hour = int(str_date[11:13])
        minute = int(str_date[14:16])
        second = int(str_date[17:19])

    return datetime.datetime(year, month, day, hour, minute, second)

def new_test_required(id, cur_idx):
    if (cur_idx == 0):
        new_test_req = True
        cur_idx = 1
    else:
        current_time = string_to_date(id["DateStamp"], False)
        next_idx = str(cur_idx + 1)

        if TestCases.start_times.has_key(next_idx) and (current_time >= TestCases.start_times[next_idx]):
            new_test_req = True
            cur_idx = int(next_idx)
        else:
            new_test_req = False
    
    return (new_test_req, cur_idx)

if __name__=="__main__":
    default_kml_filename = "Experiments_20130705.kml"
    if len(sys.argv) == 1:
        print "Usage:\n"
        print "experiment_xml_to_kml [path_to_xml_files (optional)] [kml_file_to_output (optional)]"
        sys.exit(0)
    elif len(sys.argv) == 2:
        dirname = str(sys.argv[1])
        kml_file = os.path.join(dirname, default_kml_filename)
    elif len(sys.argv) == 3:
        dirname = str(sys.argv[1])
        kml_file = os.path.join(dirname, str(sys.argv[2]))
    else:
        print "Invalid number of arguments!"
        sys.exit(1)

    # Dictionary to store all Position entries for each XML
    xml_all_results = {}

    xml_file_list = get_file_list(dirname)

    for file in xml_file_list:
        xml_position = parse_xml_file(file)
        base_file_name = os.path.splitext(os.path.split(file)[1])[0]
        xml_all_results[base_file_name] = xml_position

    doc = create_xml_template()

    cur_test = 0
    new_test_req = True
    fld = 0

    # This logic assumes that the list of keys are sorted to find
    # when we transition to a new test based on time
    for key, item in sorted(xml_all_results.items()):
        (new_test_req, cur_test) = new_test_required(item, cur_test);

        if (new_test_req == True):
            fld = KML.Folder(KML.name("Test #%d" %cur_test))
            doc.Document.append(fld)
        
        placemark = calculate_pm(key, item)
        fld.append(placemark)
        #doc.Document.Folder.append(placemark)

    file = open(kml_file,'w')
    file.write(etree.tostring(doc, pretty_print=True))
    file.close()
    print "Wrote KML data to file", kml_file
