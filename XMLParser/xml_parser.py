#!/usr/bin/env python

"""experiment_xml_to_kml.py: Convert a directory of XML files to KML.

experiment_xml_to_kml [path_to_xml_files (optional)] [kml_file_to_output (optional)]

Parses all XML files in a directory, extracting the 'Position' subtree.
Outputs the latitude and longitude of each location as a placemark in
a KML file with the date stamp as the name.

path_to_xml_files - path to folder of XML files
kml_file_to_output - KML filename for output (with path, or current)
"""

import datetime
import os
import plistlib
import sys
from lxml import etree
from pykml.factory import KML_ElementMaker as KML
from math import radians, cos, sin, asin, sqrt

__author__ = "Ryan Martens"
__copyright__ = "Copyright 2013, SMLR"
__license__ = "None"
__version__ = "0.3-dev"
__maintainer__ = "Ryan Martens"
__status__ = "Development"

class TestCases:
#     start_times = {'1': datetime.datetime(2013, 7, 5, 17, 40),
#                    '2': datetime.datetime(2013, 7, 5, 17, 42, 10),
#                    '3': datetime.datetime(2013, 7, 5, 17, 46),
#                    '4': datetime.datetime(2013, 7, 5, 17, 48),
#                    '5': datetime.datetime(2013, 7, 5, 17, 51),
#                    '6': datetime.datetime(2013, 7, 5, 17, 57),
#                   }

    start_times = {'1': datetime.datetime(2013,8,21,17,26),
                   '2': datetime.datetime(2013,8,21,17,31,30),
                   '3': datetime.datetime(2013,8,21,17,35),
                   '6': datetime.datetime(2013,8,21,17,39),
                  }
        
    test6_ref_locations = [{'Latitude': 43.319865, 'Longitude': -79.799914},
                           {'Latitude': 43.320223, 'Longitude': -79.799548},
                           {'Latitude': 43.320444, 'Longitude': -79.799313},
                           {'Latitude': 43.320660, 'Longitude': -79.799085},
                           {'Latitude': 43.320876, 'Longitude': -79.798858},
                           {'Latitude': 43.321096, 'Longitude': -79.798626},
                           {'Latitude': 43.321310, 'Longitude': -79.798389},
                           {'Latitude': 43.321535, 'Longitude': -79.798153},
                           {'Latitude': 43.321755, 'Longitude': -79.797927},
                           {'Latitude': 43.321977, 'Longitude': -79.797685},
                           {'Latitude': 43.322213, 'Longitude': -79.797449},
                           {'Latitude': 43.322437, 'Longitude': -79.797211},
                           {'Latitude': 43.322843, 'Longitude': -79.796777},
                           {'Latitude': 43.323073, 'Longitude': -79.796543},
                           {'Latitude': 43.323300, 'Longitude': -79.796297},
                           {'Latitude': 43.323516, 'Longitude': -79.796069},
                           {'Latitude': 43.323733, 'Longitude': -79.795838}
                           ]

def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # haversine formula 
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    km = 6367 * c
    return km

def find_closest_point(point, references):
    """
    Returns the index in a list of points (references) of the closest point (point).
    Each point is a dictionary of 'Latitude' and 'Longitude'
    """
    min_distance = float('inf')
    min_idx = 0
    
    for pt_idx, pt_val in enumerate(references):
        distance = haversine(point['Longitude'], point['Latitude'], pt_val['Longitude'], pt_val['Latitude'])*1000.0
        if distance < min_distance:
            min_distance = distance
            min_idx = pt_idx

    return min_idx

def get_file_list(dirname):
    xml_files = []
    for curfile in os.listdir(dirname):
        if curfile.endswith(".xml"):
            xml_files.append(os.path.join(dirname,curfile))
    return xml_files

def parse_xml_file(xmlfilename):
    plist = plistlib.readPlist(xmlfilename)
    
    # Correct for negative Lat/Long here
    if plist["Position"]["LongitudeRef"] == 'W':
        plist["Position"]["Longitude"] = -plist["Position"]["Longitude"]
    if plist["Position"]["LatitudeRef"] == 'S':
        plist["Position"]["Latitude"] = -plist["Position"]["Latitude"]
        
    
    # Create new dictionary of subset of elements to return
    cur_elem = plist["Position"]
    cur_elem["EulerAngles"] = plist["Orientation"]["EulerAngles"]
    return cur_elem

def parse_directory(dirname, test_results):
    xml_file_list = get_file_list(dirname)

    for curfile in xml_file_list:
        xml_position = parse_xml_file(curfile)
        base_file_name = os.path.splitext(os.path.split(curfile)[1])[0]
        test_results[base_file_name] = xml_position

def calculate_pm(date, position):
    pm_latlong = "%.15f, %.15f" % (position["Longitude"], position["Latitude"],)
    #pm_name = position["DateStamp"]
    pm_name = string_to_date(date, False).strftime("%Y-%m-%d %H:%M:%S")
    pm = KML.Placemark(
            KML.name(pm_name),
            KML.styleUrl("#pushpin-ylw"),
            KML.Point(
                    KML.coordinates(pm_latlong)
            ))
    return pm

def create_xml_template():
    doc = KML.kml(
        etree.Comment(' required when using gx-prefixed elements '),
        KML.Document(
            KML.name("Experiments - Collection 2 - iPhone"),
            KML.Style(KML.IconStyle(KML.scale(1.0),
                                    KML.Icon(KML.href("http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png"),),
                                    id="mystyle"),id="pushpin-ylw"),
            KML.Style(KML.IconStyle(KML.scale(1.0),
                                    KML.Icon(KML.href("http://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png"),),
                                    id="mystyle"),id="pushpin-red"),
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

def new_test_required(cur_id, cur_test_key):
    new_test_req = False
    
    if (cur_test_key == None):
        new_test_req = True
        cur_test_key = sorted(TestCases.start_times.keys())[0]
    else:
        current_time = string_to_date(cur_id["DateStamp"], False)
        sorted_keys = sorted(TestCases.start_times.keys())
        cur_idx = sorted_keys.index(cur_test_key)
        if (cur_idx < len(sorted_keys) - 1):
            next_key = sorted_keys[cur_idx + 1]
            if (current_time >= TestCases.start_times[next_key]):
                new_test_req = True
                cur_test_key = next_key
        else:
            new_test_req = False

    return (new_test_req, cur_test_key)

def add_test_placemarks(doc, test_results):
    cur_test = None
    new_test_req = True
    fld = 0

    # This logic assumes that the list of keys are sorted to find
    # when we transition to a new test based on time
    for key, item in sorted(test_results.items()):
        (new_test_req, cur_test) = new_test_required(item, cur_test);

        if (new_test_req == True):
            fld = KML.Folder(KML.name("Test #%s" %cur_test))
            doc.Document.append(fld)
        
        placemark = calculate_pm(key, item)
        fld.append(placemark)
        #doc.Document.Folder.append(placemark)

def add_test6_reference(doc):
    fld = KML.Folder(KML.name("Test #6 - Reference"))
    doc.Document.append(fld)
    i = 0
    for pos_item in TestCases.test6_ref_locations:
        i += 1
        pm_latlong = "%.15f, %.15f" % (pos_item["Longitude"], pos_item["Latitude"],)
        fld.append(KML.Placemark(KML.name("Point %d" %i),
                                 KML.styleUrl("#pushpin-red"),
                                 KML.Point(KML.coordinates(pm_latlong))
        ))

def write_kml(doc, filename):
    outfile = open(filename,'w')
    outfile.write(etree.tostring(doc, pretty_print=True))
    outfile.close()

def generate_kml(kml_file, xml_all_results):
    # Create the basic template and header
    doc = create_xml_template()

    # Output placemarks from all tests
    add_test_placemarks(doc, xml_all_results)
    
    # Add reference cases for Test 6
    add_test6_reference(doc)
    
    # Write KML file
    write_kml(doc, kml_file)
    print "Wrote KML data to file", kml_file
    
def calc_position_errors(test_results):
    for idx, val in sorted(test_results.items()):
        close_pt_idx = find_closest_point(val, TestCases.test6_ref_locations)
        pt1 = val
        pt2 = TestCases.test6_ref_locations[close_pt_idx]
        distance = haversine(pt1['Longitude'], pt1['Latitude'], pt2['Longitude'], pt2['Latitude'])*1000.0
        print "%s, %f" %(idx, distance,)

if __name__=="__main__":
    default_kml_filename = "Experiments_20130705.kml"
    if len(sys.argv) == 1:
        print "Usage:\n"
        print "experiment_xml_to_kml [path_to_xml_files (optional)] [kml_file_to_output (optional)]"
        sys.exit(0)
    elif len(sys.argv) == 2:
        dirname = str(sys.argv[1])
        #kml_file = os.path.join(dirname, default_kml_filename)
        kml_file = default_kml_filename
    elif len(sys.argv) == 3:
        dirname = str(sys.argv[1])
        #kml_file = os.path.join(dirname, str(sys.argv[2]))
        kml_file = str(sys.argv[2])
    else:
        print "Invalid number of arguments!"
        sys.exit(1)

    # Dictionary to store all Position entries for each XML
    xml_all_results = {}

    # Parse XML files in entire folder
    parse_directory(dirname, xml_all_results)
    
    # Create KML file
    generate_kml(kml_file, xml_all_results)
    
    # Perform additional analysis
    
    # Calculate position errors
    calc_position_errors(xml_all_results)