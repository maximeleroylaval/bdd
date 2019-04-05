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
