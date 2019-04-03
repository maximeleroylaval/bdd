CREATE DATABASE soundhub;

USE soundhub;

CREATE USER 'soundhub'@'localhost' IDENTIFIED BY 'soundhubpassword';
GRANT ALL ON *.* TO 'soundhub'@'localhost';

CREATE TABLE title (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	publication TIMESTAMP NOT NULL,
	url varchar(512) NOT NULL UNIQUE,
	album_id int,
	cover_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE album (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	publication TIMESTAMP NOT NULL,
	user_email varchar(255) NOT NULL,
	cover_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE user (
	email varchar(255) NOT NULL,
	name varchar(255) NOT NULL,
	password varchar(255) NOT NULL,
	birthdate TIMESTAMP NOT NULL,
	gender_name varchar(255) NOT NULL,
	PRIMARY KEY (email)
);

CREATE TABLE gender (
	name varchar(255) NOT NULL,
	PRIMARY KEY (name)
);

CREATE TABLE playlist (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	user_email varchar(255) NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE playlist_title (
	id int NOT NULL AUTO_INCREMENT,
	title_id int NOT NULL,
	playlist_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE cover (
	id int NOT NULL AUTO_INCREMENT,
	url varchar(512) NOT NULL UNIQUE,
	PRIMARY KEY (id)
);

ALTER TABLE title ADD CONSTRAINT title_fk0 FOREIGN KEY (album_id) REFERENCES album(id);

ALTER TABLE title ADD CONSTRAINT title_fk1 FOREIGN KEY (cover_id) REFERENCES cover(id);

ALTER TABLE album ADD CONSTRAINT album_fk0 FOREIGN KEY (user_email) REFERENCES user(email);

ALTER TABLE album ADD CONSTRAINT album_fk1 FOREIGN KEY (cover_id) REFERENCES cover(id);

ALTER TABLE user ADD CONSTRAINT user_fk0 FOREIGN KEY (gender_name) REFERENCES gender(name);

ALTER TABLE playlist ADD CONSTRAINT playlist_fk0 FOREIGN KEY (user_email) REFERENCES user(email);

ALTER TABLE playlist_title ADD CONSTRAINT playlist_title_fk0 FOREIGN KEY (title_id) REFERENCES title(id);

ALTER TABLE playlist_title ADD CONSTRAINT playlist_title_fk1 FOREIGN KEY (playlist_id) REFERENCES playlist(id);

INSERT INTO gender(name) VALUES
    ('Man'),
    ('Woman')
;