CREATE OR REPLACE FUNCTION buildgeompoint(lat real, lon real, alt real) RETURNS GEOMETRY as $$
BEGIN
	RETURN ST_SetSRID(ST_MakePoint(lon, lat, alt), 4326);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildgeogpoint(lat real, lon real, alt real) RETURNS GEOGRAPHY as $$
BEGIN
	RETURN ST_SetSRID(ST_MakePoint(lon, lat, alt), 4326);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildgeombuffer(lat real, lon real, alt real, rad real) RETURNS GEOMETRY as $$
BEGIN
-- radius = 0.00015 = 15m 
RETURN ST_Buffer(ST_SetSRID(ST_MakePoint(lon, lat, alt), 4326), rad/1.0e-5);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildgeogbuffer(lat real, lon real, alt real, rad real) RETURNS GEOGRAPHY as $$
BEGIN
RETURN ST_Buffer(ST_SetSRID(ST_MakePoint(lon, lat, alt), 4326), rad);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildgeogbuffer(lat real, lon real, alt real, rad real) RETURNS GEOGRAPHY as $$
BEGIN
RETURN ST_Buffer(ST_SetSRID(ST_MakePoint(lon, lat, alt), 4326), rad);

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildboundingbox(lat double precision, lon double precision, alt double precision, radius double precision) --, OUT minlat real, OUT maxlat real, OUT minlon real, OUT maxlon real)
RETURNS TABLE (minlat  double precision, maxlat  double precision, minlon  double precision, maxlon  double precision)
AS $$
DECLARE
	lat0 double precision;
	a  double precision;
	f  double precision;
	e2  double precision;
	R1  double precision;
	R2  double precision;
	oneMeterLat  double precision;
	oneMeterLon  double precision;

BEGIN

  lat0 = lat / 180.0 * pi();	-- convert to radians

  a = 6378137.0;
--f = 1.0 / 298.257223563;
--e2 = f * (2.0 - f);
  e2 = 0.0066943799901413169964451404764132282816;

  --     R1 = a   ( 1  - e^2)/     (  1 - e^2*    (sin(lat0))^2)    ^(3/2)
  R1 = a * (1.0 - e2) / power((1.0 - e2 * power(sin(lat0), 2.0)), (3.0 / 2.0));
  --     R2 = a / sqrt(1 - e^2*    (sin(lat0))^2)
  R2 = a / sqrt(1 - e2 * power(sin(lat0), 2.0));

  -- calc dlat and dlon (in degrees) for dN = dE = 1m
  oneMeterLat = (1.0 / R1) * (180.0 / pi());
  oneMeterLon = (1.0 / (R2 * cos(lat0))) * (180.0 / pi());
	
RETURN QUERY
SELECT
	(lat - (oneMeterLat * radius)) as minlat,
	(lat + (oneMeterLat * radius)) as maxlat,
	(lon - (oneMeterLon * radius)) as minlon,
	(lon + (oneMeterLon * radius)) as maxlon; 

END;
$$ LANGUAGE plpgsql;

