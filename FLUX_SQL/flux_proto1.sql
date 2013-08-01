-- Database generated with pgModeler (PostgreSQL Database Modeler).
-- PostgreSQL version: 9.2
-- Project Site: pgmodeler.com.br
-- Model Author: ---

SET check_function_bodies = false;
-- ddl-end --


-- Database creation must be done outside an multicommand file.
-- These commands were put in this file only for convenience.
-- -- object: flux_proto1 | type: DATABASE --
-- CREATE DATABASE flux_proto1
-- ;
-- -- ddl-end --
-- 

-- object: public.imageid_seq | type: SEQUENCE --
CREATE SEQUENCE public.imageid_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 9223372036854775807
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
COMMENT ON SEQUENCE public.imageid_seq IS 'sequence to generate image IDs';
-- ddl-end --

-- object: public.userid_seq | type: SEQUENCE --
CREATE SEQUENCE public.userid_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 9223372036854775807
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
COMMENT ON SEQUENCE public.userid_seq IS 'sequence to generate user IDs';
-- ddl-end --

-- object: public.tagid_seq | type: SEQUENCE --
CREATE SEQUENCE public.tagid_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 9223372036854775807
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
COMMENT ON SEQUENCE public.tagid_seq IS 'sequence to generate tag IDs';
-- ddl-end --

-- object: public.catid_seq | type: SEQUENCE --
CREATE SEQUENCE public.catid_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 9223372036854775807
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
COMMENT ON SEQUENCE public.catid_seq IS 'sequence to generate category IDs';
-- ddl-end --

-- object: public.cameraid_seq | type: SEQUENCE --
CREATE SEQUENCE public.cameraid_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 9223372036854775807
	START WITH 1
	CACHE 1
	NO CYCLE
	OWNED BY NONE;
COMMENT ON SEQUENCE public.cameraid_seq IS 'sequence to generate camera IDs';
-- ddl-end --

-- object: public.users | type: TABLE --
CREATE TABLE public.users(
	userid bigint NOT NULL DEFAULT nextval('userid_seq'::regclass),
	firstname varchar(32),
	lastname varchar(64),
	privacy integer NOT NULL DEFAULT 0,
	nickname varchar(64),
	CONSTRAINT users_userid_cluster_idx PRIMARY KEY (userid)
);
-- ddl-end --

-- object: users_nickname_idx | type: INDEX --
CREATE INDEX users_nickname_idx ON public.users
	USING btree
	(
	  userid ASC NULLS LAST
	);
-- ddl-end --


COMMENT ON TABLE public.users IS 'Contains user-specific information';
COMMENT ON CONSTRAINT users_userid_cluster_idx ON public.users IS 'primary key for users';
-- Appended SQL commands --
ALTER TABLE users CLUSTER ON "users_userid_cluster_idx";
-- ddl-end --

-- object: public.categories | type: TABLE --
CREATE TABLE public.categories(
	categoryid bigint NOT NULL DEFAULT nextval('catid_seq'::regclass),
	cat_description varchar(128) NOT NULL,
	cat_text varchar(32) NOT NULL,
	CONSTRAINT categories_categoryid_cluster_idx PRIMARY KEY (categoryid)
);
-- ddl-end --

COMMENT ON TABLE public.categories IS 'contains category definitions';
COMMENT ON CONSTRAINT categories_categoryid_cluster_idx ON public.categories IS 'primary key for categories table';
-- Appended SQL commands --
ALTER TABLE categories CLUSTER ON "categories_categoryid_cluster_idx";
-- ddl-end --

-- object: public.tags | type: TABLE --
CREATE TABLE public.tags(
	tagid bigint NOT NULL DEFAULT nextval('tagid_seq'::regclass),
	tagtext varchar(32) NOT NULL,
	CONSTRAINT tags_tagid_idx PRIMARY KEY (tagid)
);
-- ddl-end --

-- object: tags_tagtext_cluster_idx | type: INDEX --
CREATE UNIQUE INDEX tags_tagtext_cluster_idx ON public.tags
	USING btree
	(
	  tagtext ASC NULLS LAST
	);
COMMENT ON INDEX tags_tagtext_cluster_idx IS 'clustering index on tag text';
-- ddl-end --


COMMENT ON TABLE public.tags IS 'table to contain tag definitions';
COMMENT ON CONSTRAINT tags_tagid_idx ON public.tags IS 'primary key for tags table';
-- Appended SQL commands --
ALTER TABLE tags CLUSTER ON "tags_tagtext_cluster_idx";
-- ddl-end --

-- object: public.cameras | type: TABLE --
CREATE TABLE public.cameras(
	cameraid bigint NOT NULL DEFAULT nextval('cameraid_seq'::regclass),
	userid bigint NOT NULL,
	model varchar(32),
	deviceid varchar(32) NOT NULL,
	description varchar(256),
	nickname varchar(64),
	CONSTRAINT cameras_cameraid_idx PRIMARY KEY (cameraid),
	CONSTRAINT userid_users FOREIGN KEY (cameraid)
	REFERENCES public.users (userid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- ddl-end --

-- object: cameras_deviceid_cluster_idx | type: INDEX --
CREATE UNIQUE INDEX cameras_deviceid_cluster_idx ON public.cameras
	USING btree
	(
	  cameraid ASC NULLS LAST
	);
COMMENT ON INDEX cameras_deviceid_cluster_idx IS 'clustering index on deviceid';
-- ddl-end --


COMMENT ON TABLE public.cameras IS 'contains camera details';
COMMENT ON COLUMN public.cameras.userid IS 'user that owns this camera';
COMMENT ON COLUMN public.cameras.model IS 'type of camera';
COMMENT ON COLUMN public.cameras.deviceid IS 'unique identifier for device (typically GUID)';
COMMENT ON COLUMN public.cameras.description IS 'text description of the camera';
COMMENT ON COLUMN public.cameras.nickname IS 'short name used for camera';
COMMENT ON CONSTRAINT cameras_cameraid_idx ON public.cameras IS 'primary key for camera table';
-- Appended SQL commands --
ALTER TABLE cameras CLUSTER ON "cameras_deviceid_cluster_idx";
-- ddl-end --

-- object: public.images | type: TABLE --
CREATE TABLE public.images(
	imageid bigint NOT NULL DEFAULT nextval('imageid_seq'::regclass),
	raw_latitude double precision NOT NULL,
	raw_longitude double precision NOT NULL,
	raw_altitude double precision NOT NULL,
	best_latitude double precision,
	best_longitude double precision,
	best_altitude double precision,
	raw_yaw double precision NOT NULL,
	raw_pitch double precision NOT NULL,
	raw_roll double precision NOT NULL,
	best_yaw double precision,
	best_pitch double precision,
	best_roll double precision,
	time_stamp timestamp NOT NULL,
	description varchar(256),
	categoryid bigint NOT NULL DEFAULT 0,
	userid bigint NOT NULL DEFAULT 0,
	cameraid bigint NOT NULL DEFAULT 0,
	CONSTRAINT image_imageid_idx PRIMARY KEY (imageid),
	CONSTRAINT userid_users FOREIGN KEY (userid)
	REFERENCES public.users (userid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
	CONSTRAINT cameraid_cameras FOREIGN KEY (cameraid)
	REFERENCES public.cameras (cameraid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
	CONSTRAINT categoryid_categories FOREIGN KEY (categoryid)
	REFERENCES public.categories (categoryid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- ddl-end --

-- object: image_time_stamp_cluster_idx | type: INDEX --
CREATE INDEX image_time_stamp_cluster_idx ON public.images
	USING btree
	(
	  time_stamp ASC NULLS LAST
	);
COMMENT ON INDEX image_time_stamp_cluster_idx IS 'cluster the images table based on timestamp';
-- ddl-end --

-- object: image_latitude_idx | type: INDEX --
CREATE INDEX image_latitude_idx ON public.images
	USING btree
	(
	  best_latitude ASC NULLS LAST
	);
-- ddl-end --

-- object: image_longitude_idx | type: INDEX --
CREATE INDEX image_longitude_idx ON public.images
	USING btree
	(
	  best_longitude ASC NULLS LAST
	);
-- ddl-end --

-- object: image_userid_idx | type: INDEX --
CREATE INDEX image_userid_idx ON public.images
	USING btree
	(
	  userid ASC NULLS LAST
	);
-- ddl-end --

-- object: image_categoryid | type: INDEX --
CREATE INDEX image_categoryid ON public.images
	USING btree
	(
	  categoryid ASC NULLS LAST
	);
-- ddl-end --

-- object: image_cameraid_idx | type: INDEX --
CREATE INDEX image_cameraid_idx ON public.images
	USING btree
	(
	  categoryid ASC NULLS LAST
	);
-- ddl-end --


COMMENT ON TABLE public.images IS 'Contains image-specific data including positional metadata';
COMMENT ON COLUMN public.images.imageid IS 'unique identifier for image';
COMMENT ON CONSTRAINT image_imageid_idx ON public.images IS 'primary key for images';
-- Appended SQL commands --
ALTER TABLE images CLUSTER ON "image_time_stamp_cluster_idx";
-- ddl-end --

-- object: public.friends | type: TABLE --
CREATE TABLE public.friends(
	userid bigint NOT NULL,
	friendid bigint NOT NULL,
	CONSTRAINT userid_users FOREIGN KEY (userid)
	REFERENCES public.users (userid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
	CONSTRAINT friendid_users FOREIGN KEY (friendid)
	REFERENCES public.users (userid) MATCH FULL
	ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- ddl-end --

-- object: friends_userid_cluster_idx | type: INDEX --
CREATE INDEX friends_userid_cluster_idx ON public.friends
	USING btree
	(
	  userid ASC NULLS LAST
	);
COMMENT ON INDEX friends_userid_cluster_idx IS 'clustering index on userID';
-- ddl-end --

-- object: friends_friendid_idx | type: INDEX --
CREATE INDEX friends_friendid_idx ON public.friends
	USING btree
	(
	  friendid ASC NULLS LAST
	);
-- ddl-end --


COMMENT ON TABLE public.friends IS 'contains user-user friend relationships (one way)';
COMMENT ON COLUMN public.friends.userid IS 'user with friends';
COMMENT ON COLUMN public.friends.friendid IS 'userid of friend';
-- Appended SQL commands --
ALTER TABLE friends CLUSTER ON "friends_userid_cluster_idx";
-- ddl-end --

-- object: public.image_tags | type: TABLE --
CREATE TABLE public.image_tags(
	imageid_images bigint DEFAULT nextval('imageid_seq'::regclass),
	tagid_tags bigint DEFAULT nextval('tagid_seq'::regclass),
	CONSTRAINT image_tags_pk PRIMARY KEY (imageid_images,tagid_tags)
);
-- ddl-end --

COMMENT ON COLUMN public.image_tags.imageid_images IS 'unique identifier for image';
-- ddl-end --

-- object: images_fk | type: CONSTRAINT --
ALTER TABLE public.image_tags ADD CONSTRAINT images_fk FOREIGN KEY (imageid_images)
REFERENCES public.images (imageid) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE NOT DEFERRABLE;
-- ddl-end --


-- object: tags_fk | type: CONSTRAINT --
ALTER TABLE public.image_tags ADD CONSTRAINT tags_fk FOREIGN KEY (tagid_tags)
REFERENCES public.tags (tagid) MATCH FULL
ON DELETE RESTRICT ON UPDATE CASCADE NOT DEFERRABLE;
-- ddl-end --



