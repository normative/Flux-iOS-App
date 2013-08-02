import xml_parser

def test_distance(pt1, pt2, expected, tol):
    distance = xml_parser.haversine(pt1['Longitude'], pt1['Latitude'], pt2['Longitude'], pt2['Latitude'])*1000.0
    print "From: %s\nTo:   %s\nDist: %3.12f m" % (pt1, pt2, distance)
    if abs(distance - expected) < tol:
        return True
    else:
        print "Fail"
        return False
    
def test_closest_pt(test_pt, expected_idx):
    idx = xml_parser.find_closest_point(test_pt, xml_parser.TestCases.test6_ref_locations)
    print "Closest point: %d, %s" % (idx, xml_parser.TestCases.test6_ref_locations[idx])
    return (idx == expected_idx)
    
if __name__ == "__main__":
    tolerance = 0.5
    success = True
    success = (test_distance(xml_parser.TestCases.test6_ref_locations[0],xml_parser.TestCases.test6_ref_locations[1], 49.6, tolerance) and success)
    success = (test_distance(xml_parser.TestCases.test6_ref_locations[0],xml_parser.TestCases.test6_ref_locations[-1], 542.0, tolerance) and success)
    success = (test_closest_pt({'Latitude': 43.321331, 'Longitude': -79.798363}, 7-1) and success)
    success = (test_closest_pt({'Latitude': 43.322680, 'Longitude': -79.797324},12-1) and success)
    print "Success: %d" %(success)