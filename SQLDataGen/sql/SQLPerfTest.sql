-- uses metadata table defined in table_construction.sql
-- uses procs defined in sp_buildgeobits.sql

/*
TEST 1
   Execution:
	0. create database, table and load with sample data
	1. Run a SELECT INTO section for a specific column
	2. record execution time
	3. verify result value
	4. repeat from 2 five more times
		set of 6 times constitues a "set"
	5. repeat from 1 for each column (or column type) to query on
	6. create indicies and vacuum the table
	7. repeat steps 1 through 5
	8. discard highest value from each set (eliminates cache loading impacts)
	9. calculate average of remaining values for each set to give an everage execution time
	10. analyze results

*/

-- Test 1, geographyloc column
DROP TABLE bob;

SELECT image_id, geographyloc
INTO bob
--SELECT COUNT(image_id)
	FROM metadata
	WHERE ST_DWithin(buildgeogpoint(43.65331111111111111111, -79.40640555555555555556, 2.0), geographyloc, 10.0) 
	ORDER BY image_id;

SELECT count(DISTINCT image_id) from bob;

-- Test 1, geometryloc column
SELECT image_id, geometryloc
INTO bob2
--SELECT COUNT(image_id)
	FROM metadata m, (SELECT * FROM getangles(43.65331111111111111111, -79.40640555555555555556, 10.0)) angs
	WHERE ST_DWithin(buildgeompoint(43.65331111111111111111, -79.40640555555555555556, 2.0), m.geometryloc, 
			angs.lonangle)
	ORDER BY image_id;

SELECT count(DISTINCT image_id) from bob2;



-- Test 1, raw location columns (no GIS)
DROP TABLE bob3;

SELECT image_id, raw_latitude, raw_longitude, raw_altitude
INTO bob3
	FROM metadata m, (SELECT * FROM buildboundingbox(43.65331111111111111111, -79.40640555555555555556, 2.0, 10.0) 
					--(minlat  double precision, maxlat  double precision, minlon  double precision, maxlon  double precision)
					 FETCH FIRST 1 ROW ONLY) AS bb
	WHERE
	((m.raw_latitude > bb.minlat) AND (m.raw_latitude < bb.maxlat) AND
	 (m.raw_longitude > bb.minlon) AND (m.raw_longitude < bb.maxlon))
	ORDER BY image_id;

SELECT COUNT(DISTINCT image_id) from bob3

