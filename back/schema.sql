
DROP TABLE IF EXISTS author CASCADE;

CREATE TABLE users
(
	uid serial NOT NULL,
	username VARCHAR(20) NOT NULL,
	password VARCHAR(32) NOT NULL,
	PRIMARY KEY (uid, username)
);