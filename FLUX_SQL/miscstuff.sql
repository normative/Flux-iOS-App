
INSERT INTO images (userid, categoryid, cameraid, time_stamp, description, raw_latitude, raw_longitude, raw_altitude, best_latitude, best_longitude, best_altitude, raw_yaw, raw_pitch, raw_roll, best_yaw, best_pitch, best_roll, heading) VALUES 
 (2, 1, 2, now(), 'a new image with #tag6 and #tag3', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);


-- select * from images

SELECT updatetags(2, 'this is the part that matters #tag1, #tag2, #tag3, #tag4');
SELECT updatetags(2, 'this is the part that matters');
SELECT * from tags;
SELECT * from image_tags
	WHERE imageid_images = 2

DELETE FROM image_tags where imageid_images = 2


--SELECT u.nickname, c.nickname, i.imageid, t.tagtext FROM tags t 
SELECT u.nickname AS "User", c.nickname AS "Camera", i.imageid as "Picture", COUNT(t.tagtext) AS "Tag Count"
	FROM tags t 
		JOIN image_tags it ON it.tagid_tags = t.tagid
		JOIN images i ON i.imageid = it.imageid_images
		JOIN cameras c ON i.cameraid = c.cameraid
		JOIN users u ON u.userid = i.userid
	--WHERE it.imageid_images = 1
	GROUP BY u.nickname, c.nickname, i.imageid
	ORDER BY i.imageid

-- trim_tag = substring(tag from 2 for (char_length(tag)-2));
--trim_tag = trim(both '{}' from raw_tag_rec.curly_tag);
DECLARE
SELECT btrim('{test1}', '{}');


SELECT curly_tag FROM regexp_matches('tag #text', '#([A-Za-z0-9\-&]+)', 'g') AS curly_tag;