-- FUNCTION to parse the hash-tags and insert into appropriate tables:
--	parse tags out of the description, 
--	look up each, 
--	add to the tags list if not there
--	create a relation between the tag and the image

-- DROP FUNCTION updatetags(in_image_id bigint, description text);

CREATE OR REPLACE FUNCTION updatetags(in_image_id bigint, description text)
RETURNS void
AS $$
DECLARE 
	raw_tag text[];
	trim_tag text;
	tag_id bigint;
	ts timestamp;
BEGIN
	-- first, clear out any existing tags for this image...
	-- DELETE FROM images_tags i WHERE i.image_id = in_image_id;
	DELETE FROM image_tags i WHERE i.imageid_images = in_image_id;
	
	ts = now();
	FOR raw_tag IN SELECT curly_tag 
			FROM regexp_matches(description, '#([A-Za-z0-9\-&]+)', 'g') AS curly_tag
	LOOP
		trim_tag = raw_tag[1];	
		IF (trim_tag IS NOT NULL) THEN
			SELECT t.tagid INTO tag_id
				FROM tags t 
				WHERE t.tagtext = trim_tag;
				
			IF (tag_id IS NULL) THEN
				-- INSERT INTO tags (tagtext, created_at, updated_at) VALUES (trim_tag, ts, ts) RETURNING id INTO tag_id;
				INSERT INTO tags (tagtext) VALUES (trim_tag) RETURNING tagid INTO tag_id;
			END IF;

			-- INSERT INTO images_tags (image_id, tag_id, created_at, updated_at) VALUES (image_id, tag_id, ts, ts);
			INSERT INTO image_tags (imageid_images, tagid_tags) VALUES (in_image_id, tag_id);
		END IF;
			
	END LOOP;
	RETURN;

END;
$$ LANGUAGE plpgsql