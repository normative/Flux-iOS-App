#!/usr/bin/env python

"""experiment_xml_to_kml.py: Convert a directory of XML files to KML.

experiment_xml_to_kml [path_to_xml_files (optional)] [kml_file_to_output (optional)]

Parses all XML files in a directory, extracting the 'Position' subtree.
Outputs the latitude and longitude of each location as a placemark in
a KML file with the date stamp as the name.

path_to_xml_files - path to folder of XML files
kml_file_to_output - KML filename to output in specified path
"""

import os
import plistlib
import sys
from lxml import etree
from pykml.factory import KML_ElementMaker as KML

__author__ = "Ryan Martens"
__copyright__ = "Copyright 2013, SMLR"
__license__ = "None"
__version__ = "0.1"
__maintainer__ = "Ryan Martens"
__status__ = "Development"

def get_file_list(dirname):
    xml_files = []
    for file in os.listdir(dirname):
        if file.endswith(".xml"):
            xml_files.append(os.path.join(dirname,file))
    return xml_files

def parse_xml_file(xmlfilename):
    plist = plistlib.readPlist(xmlfilename)
    return plist["Position"]

def calculate_pm(position):
    pm_latlong = "%.15f, %.15f" % (-position["Longitude"], position["Latitude"],)
    pm_name = position["DateStamp"]
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
        base_file_name = os.path.splitext(file)[0]
        xml_all_results[base_file_name] = xml_position

    doc = create_xml_template()

    for key, item in sorted(xml_all_results.items()):
        placemark = calculate_pm(item)
        doc.Document.append(placemark)

    file = open(kml_file,'w')
    file.write(etree.tostring(doc, pretty_print=True))
    file.close()
    print "Wrote KML data to file", kml_file
