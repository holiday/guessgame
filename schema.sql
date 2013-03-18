DROP TABLE IF EXISTS account CASCADE;
CREATE TABLE account(
	username VARCHAR(20) NOT NULL,
	password VARCHAR(32) NOT NULL,
	email VARCHAR(320) NOT NULL, --max size of email, according to RFC
	birthday DATE NOT NULL,
	register_date DATE DEFAULT current_date,
	PRIMARY KEY (username) --preserve unique usernames
);

DROP TABLE IF EXISTS score CASCADE;
CREATE TABLE score(
	username VARCHAR(20) REFERENCES account(username) ON UPDATE CASCADE ON DELETE CASCADE,
	score INTEGER NOT NULL DEFAULT 0 CHECK(score>=0),
	PRIMARY KEY (username, score) --so that users can have multiple highscores
);
