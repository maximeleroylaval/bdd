DROP DATABASE IF EXISTS soundhub;
DROP USER IF EXISTS 'soundhub'@'localhost';

CREATE DATABASE soundhub;

CREATE USER IF NOT EXISTS 'soundhub'@'localhost' IDENTIFIED BY 'soundhubpassword';
GRANT ALL ON *.* TO 'soundhub'@'localhost';

USE soundhub;

CREATE TABLE commentary (
	id int NOT NULL AUTO_INCREMENT,
	description varchar(512) NOT NULL,
	user_email varchar(255) NOT NULL,
	title_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE title (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	publication TIMESTAMP NOT NULL,
	url varchar(512) NOT NULL UNIQUE,
	user_email varchar(255) NOT NULL,
	playlist_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE playlist (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	user_email varchar(255) NOT NULL,
    /* Default playlist picture */
    picture varchar(255) NOT NULL DEFAULT 'https://pbs.twimg.com/profile_images/1013450639215431680/qO1FApK4_400x400.jpg',
	PRIMARY KEY (id)
);

CREATE TABLE user (
	email varchar(255) NOT NULL,
	name varchar(255) NOT NULL,
	password varchar(255) NOT NULL,
	birthdate TIMESTAMP NOT NULL,
	gender_name varchar(255) NOT NULL,
    /* Default profile picture */
    picture varchar(255) NOT NULL DEFAULT 'https://www.watsonmartin.com/wp-content/uploads/2016/03/default-profile-picture.jpg',
	PRIMARY KEY (email)
);

CREATE TABLE gender (
	name varchar(255) NOT NULL,
	PRIMARY KEY (name)
);

CREATE TABLE token (
	token varchar(255) NOT NULL,
	user_email varchar(255) NOT NULL,
	PRIMARY KEY (token)
);

ALTER TABLE commentary ADD CONSTRAINT commentary_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE commentary ADD CONSTRAINT commentary_fk1 FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE;

ALTER TABLE title ADD CONSTRAINT title_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE title ADD CONSTRAINT title_fk1 FOREIGN KEY (playlist_id) REFERENCES playlist(id) ON DELETE CASCADE;

ALTER TABLE playlist ADD CONSTRAINT playlist_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE user ADD CONSTRAINT user_fk0 FOREIGN KEY (gender_name) REFERENCES gender(name) ON DELETE CASCADE;

ALTER TABLE token ADD CONSTRAINT token_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

INSERT INTO gender(name) VALUES
    ('Man'),
    ('Woman')
;

INSERT INTO user(email, name, password, birthdate, gender_name) VALUES
	('rap@rap.com', 'rap_lover', 'rap', '1990/01/01', 'Man'),
    ('metal@metal.com', 'metal_lover', 'metal', '1990/01/01' , 'Man'),
	('classic@classic.com', 'classic_lover', 'classic', '1990/01/01', 'Man'),
	('got@got.com', 'got', 'got', '1990/01/01', 'Man'),
	('ulaval@ulaval.com', 'ulaval', 'ulaval', '1990/01/01', 'Man'),
	('female@female.com', 'female', 'femalegender', '1990/01/01', 'Woman'),
	('google@google.com', 'google', 'google', '1990/01/01', 'Woman'),
	('420@420.com', '420_Bl4z3_1t', '420', '1990/01/01', 'Man')
    ;

INSERT INTO playlist(id, name, user_email) VALUES
	(1, 'rap 90s', 'rap@rap.com'),
    (2, 'Black Metal', 'metal@metal.com'),
    (3, 'Bethoveen', 'classic@classic.com'),
    (4, 'Bl4z3_1t', '420@420.com'),
    (5, 'rap Fr', 'rap@rap.com')
    ;

INSERT INTO title(id, name, publication, url, user_email, playlist_id) VALUES 
	(1, 'Notorious Big', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (2, 'ALL EYES ON ME', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (3, 'DEAR MAMA', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (4, 'The message-Nas', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (5, 'Affirmative Action', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1)
    ;