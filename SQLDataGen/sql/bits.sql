DROP INDEX "ImageIDIndex";
DROP INDEX "LatIndex";
DROP INDEX "LongIndex";
DROP INDEX "UserIndex";
DROP INDEX "TimeIndex";

COPY metadata (user_id, time_stamp, raw_latitude, raw_longitude, raw_altitude, raw_yaw, raw_pitch, raw_roll)
FROM '/home/denis/workspaces/SMLR/SQLDataGen/SQLTestData.csv'
WITH (FORMAT 'csv', HEADER false);

-- took 167s / 435s

CREATE INDEX "TimeIndex"
  ON metadata
  USING btree
  (time_stamp );
ALTER TABLE metadata CLUSTER ON "TimeIndex";

CREATE UNIQUE INDEX "ImageIDIndex"
  ON metadata
  USING btree
  (image_id );
  
CREATE INDEX "LatIndex"
  ON metadata
  USING btree
  (raw_latitude );

CREATE INDEX "LongIndex"
  ON metadata
  USING btree
  (raw_longitude );

CREATE INDEX "UserIndex"
  ON metadata
  USING btree
  (user_id );
  
-- took 113s / 165s

COPY metadata (image_id, user_id, time_stamp, raw_latitude, raw_longitude, raw_altitude, raw_yaw, raw_pitch, raw_roll)
FROM '/home/denis/testdata.csv'
WITH (FORMAT 'csv', HEADER true);

SELECT DropGeometryColumn ('metadata', 'geometryloc');
SELECT AddGeometryColumn ('metadata','geometryloc',4326,'POINT',3);

UPDATE metadata
SET geographyloc = ST_MakePoint(Raw_Longitude, Raw_Latitude, Raw_Altitude);

UPDATE metadata
SET geometryloc = ST_SetSRID(ST_MakePoint(Raw_Longitude, Raw_Latitude, Raw_Altitude), 4326);

SELECT ST_AsKML(location) from metadata;

/*
-- DROP SEQUENCE image_id_seq CASCADE;

CREATE SEQUENCE image_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

ALTER TABLE image_id_seq
  OWNER TO postgres;

--ALTER TABLE metadata
--	ALTER COLUMN image_id
--	SET DEFAULT nextval('image_id_seq');



-- Table: metadata

-- DROP TABLE metadata;

CREATE TABLE metadata
(
  image_id bigint NOT NULL DEFAULT nextval('image_id_seq'::regclass),
  user_id bigint,
  time_stamp timestamp without time zone,
  raw_latitude double precision,
  raw_longitude double precision,
  raw_altitude double precision,
  raw_yaw double precision,
  raw_pitch double precision,
  raw_roll double precision,
  geographyloc geography(PointZ,4326),
  geometryloc geometry(PointZ,4326),
  CONSTRAINT "Primary Key" PRIMARY KEY (image_id )
)
WITH (
  OIDS=FALSE
);
ALTER TABLE metadata
  OWNER TO postgres;

-- Index: "ImageIDIndex"

-- DROP INDEX "ImageIDIndex";

CREATE UNIQUE INDEX "ImageIDIndex"
  ON metadata
  USING btree
  (image_id );

-- Index: "LatIndex"

-- DROP INDEX "LatIndex";

CREATE INDEX "LatIndex"
  ON metadata
  USING btree
  (raw_latitude );

-- Index: "LongIndex"

-- DROP INDEX "LongIndex";

CREATE INDEX "LongIndex"
  ON metadata
  USING btree
  (raw_longitude );

-- Index: "TimeIndex"

-- DROP INDEX "TimeIndex";

CREATE INDEX "TimeIndex"
  ON metadata
  USING btree
  (time_stamp );
ALTER TABLE metadata CLUSTER ON "TimeIndex";

-- Index: "UserIndex"

-- DROP INDEX "UserIndex";

CREATE INDEX "UserIndex"
  ON metadata
  USING btree
  (user_id );


ALTER SEQUENCE image_id_seq OWNED BY metadata.image_id;

*/






--select min(image_id), max(image_id) from metadata;
--select ST_X(geometryloc) from metadata;

SELECT ST_Covers(geog_poly, geog_pt) As poly_covers_pt, 
	ST_Covers(geog_buff, geog_pt) As buff_10m_covers_cent
	FROM (SELECT ST_Buffer(ST_GeogFromText('SRID=4326;POINT(-99.327 31.4821)'), 300) As geog_poly,
	buildgeogpoint(1.0, 2.0, 3.0) AS geog_pt,
	buildgeogbuffer(1.0, 2.0, 3.0, 5.0) AS geog_buff) As foo;


SELECT ST_Covers(geog_poly, geog_pt) As poly_covers_pt, 
	ST_Covers(geog_buff, geog_pt) As buff_10m_covers_cent
	FROM (SELECT ST_Buffer(ST_GeomFromText('SRID=4326;POINT(-99.327 31.4821)'), 300) As geog_poly,
	buildgeompoint(1.0, 2.0, 3.0) AS geog_pt,
	buildgeombuffer(1.0, 2.0, 3.0, 5.0) AS geog_buff) As foo;


SELECT image_id, ST_Covers(poly, geographyloc) AS covered
	FROM (  SELECT image_id, geographyloc,
		buildgeombuffer(1.0, 2.0, 3.0, 5.0) AS poly FROM metadata) 
			As foo;

SELECT * from buildpoint(1.0, 2.0, 3.0);

SELECT ST_SetSRID(ST_MakePoint(1.0, 2.0, 3.0), 4326);


--SELECT  image_id 
--FROM	metadata
--WHERE	ST_Covers(@poly, geographyloc);

--select ST_X(geographyloc::geography) from metadata;

--select count(image_id) from metadata;

-- a point with a 300 meter buffer compared to a point, a point and its 10 meter buffer





DROP TABLE bob;
SELECT image_id, geographyloc
INTO bob3
--SELECT COUNT(image_id)
	FROM (  SELECT image_id, geographyloc,
		buildgeogbuffer(43.65331111111111111111, -78.59359444444444444444, 2.0, 0.0000020) AS poly FROM metadata) 
			As foo
	WHERE ST_Covers(poly, geographyloc) = TRUE
	ORDER BY image_id;

SELECT count(DISTINCT image_id) from bob3

SELECT m1.image_id, m2.image_id, ST_Distance(m1.geographyloc, m2.geographyloc) 
	FROM bob m1, bob m2, buildgeogpoint(43.65331111111111111111, -78.59359444444444444444, 2.0) pt
	WHERE m1.image_id < m2.image_id
	ORDER by m1.image_id, m2.image_id

SELECT m1.image_id, ST_Distance(m1.geographyloc, pt) 
	FROM bob m1, buildgeogpoint(43.65331111111111111111, -78.59359444444444444444, 2.0) pt
	ORDER BY ST_Distance(m1.geographyloc, pt) ;

SELECT m1.image_id, ST_Distance(m1.geographyloc, pt) 
	FROM bob m1, buildgeogpoint(43.65331111111111111111, -78.59359444444444444444, 2.0) pt
	WHERE m1.image_id = 48537907 OR m1.image_id = 48538850
	


select * from bob where image_id not in (select image_id from bob2)

--	(SELECT geographyloc loc1, image_id image_id1
-- normative offices...
--SELECT ( 43.0 + (39.0 / 60.0) + (11.92 / 3600.0)) AS lat,
--	(-79.0 + (24.0 / 60.0) + (23.06 / 3600.0)) AS lon;

DROP TABLE bob



DROP TABLE bob;

SELECT image_id, geographyloc
INTO bob
--SELECT COUNT(image_id)
	FROM metadata
	WHERE ST_DWithin(buildgeogpoint(43.65331111111111111111, -79.40640555555555555556, 2.0), geographyloc, 10.0) 
	ORDER BY image_id;

SELECT count(DISTINCT image_id) from bob;

--SELECT (43.0 + (39.0 / 60.0) + (11.92 / 3600.0)) as lat, 
--	(79.0 + (24.0 / 60.0) + (23.06 / 3600.0)) as lon;

DROP TABLE bob2;

SELECT image_id, geometryloc
INTO bob2
--SELECT COUNT(image_id)
	FROM metadata
	WHERE ST_DWithin(buildgeompoint(43.65331111111111111111, -79.40640555555555555556, 2.0), geographyloc, 10.0)	-- yes this should be geographyloc 
	ORDER BY image_id;

SELECT count(DISTINCT image_id) from bob2;




