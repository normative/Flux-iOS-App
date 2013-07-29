-- database creation

-- Database: "GISTest02"

-- DROP DATABASE "GISTest02";

CREATE DATABASE "GISTest02"
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'en_CA.UTF-8'
       LC_CTYPE = 'en_CA.UTF-8'
       CONNECTION LIMIT = -1;

-- Sequence: image_id_seq

-- DROP SEQUENCE image_id_seq;

CREATE SEQUENCE image_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 74786631
  CACHE 1;
ALTER TABLE image_id_seq
  OWNER TO postgres;

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
--  geometryloc geometry(PointZ,4326),
  CONSTRAINT "Primary Key" PRIMARY KEY (image_id )
)
WITH (
  OIDS=FALSE
);
ALTER TABLE metadata
  OWNER TO postgres;

-- Column "GeometryLoc"

-- DropGeometryColumn('metadata', 'geometryloc');

AddGeometryColumn('metadata', 'geometryloc', 4326, 'POINT', 3);

-- Index: "GeographyIndex"

-- DROP INDEX "GeographyIndex";

CREATE INDEX "GeographyIndex"
  ON metadata
  USING gist
  (geographyloc );

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

-- DROP INDEX "GeographyIndex"

CREATE INDEX "GeographyIndex" ON metadata USING GIST(geographyloc);

VACUUM ANALYZE metadata;



