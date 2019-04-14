USE soundhub;

CREATE TABLE commentary (
	id int NOT NULL AUTO_INCREMENT,
	description varchar(1024) NOT NULL,
	publication TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	user_email varchar(255) NOT NULL,
	title_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE title (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
	url varchar(512) NOT NULL,
	publication TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	user_email varchar(255) NOT NULL,
	playlist_id int NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE playlist (
	id int NOT NULL AUTO_INCREMENT,
	name varchar(255) NOT NULL,
    picture varchar(255) NOT NULL DEFAULT 'https://pbs.twimg.com/profile_images/1013450639215431680/qO1FApK4_400x400.jpg',
    description varchar(1024),
	publication TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	user_email varchar(255) NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE user (
	email varchar(255) NOT NULL,
	name varchar(255) NOT NULL,
	password varchar(255) NOT NULL,
	birthdate TIMESTAMP NOT NULL,
    picture varchar(255) NOT NULL DEFAULT 'https://www.watsonmartin.com/wp-content/uploads/2016/03/default-profile-picture.jpg',
	publication TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	gender_name varchar(255) NOT NULL,
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

CREATE TABLE followed_playlist (
	id int NOT NULL AUTO_INCREMENT,
    user_email varchar(255) NOT NULL,
    playlist_id int NOT NULL,
    primary key (id)
);

CREATE TABLE followed_user (
	id int NOT NULL auto_increment,
    user_email varchar(255) NOT NULL,
    follow_email varchar (255) NOT NULL,
    primary key(id)
); 

ALTER TABLE commentary ADD CONSTRAINT commentary_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE commentary ADD CONSTRAINT commentary_fk1 FOREIGN KEY (title_id) REFERENCES title(id) ON DELETE CASCADE;

ALTER TABLE title ADD CONSTRAINT title_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE title ADD CONSTRAINT title_fk1 FOREIGN KEY (playlist_id) REFERENCES playlist(id) ON DELETE CASCADE;

ALTER TABLE playlist ADD CONSTRAINT playlist_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE user ADD CONSTRAINT user_fk0 FOREIGN KEY (gender_name) REFERENCES gender(name) ON DELETE CASCADE;

ALTER TABLE token ADD CONSTRAINT token_fk0 FOREIGN KEY (user_email) REFERENCES user(email) ON DELETE CASCADE;

ALTER TABLE followed_playlist ADD constraint followed_playlist_fk0 foreign key (user_email) references user(email) ON DELETE cascade;

ALTER TABLE followed_playlist ADD constraint followed_playlist_fk1 foreign key (playlist_id) references playlist(id) ON DELETE cascade;

ALTER TABLE followed_user ADD constraint followed_user_fk0 foreign key (user_email) references user(email) ON DELETE cascade;

ALTER TABLE followed_user ADD constraint followed_user_fk1 foreign key (follow_email) references user(email) ON DELETE cascade;

DELIMITER //
CREATE FUNCTION is_valid_url (url VARCHAR(255))
RETURNS INT
READS SQL DATA
BEGIN
    IF url REGEXP "^(https?://|www\\.)[\.A-Za-z0-9\-]+\\.[a-zA-Z]{2,4}" <> 1 THEN
        RETURN 0;
    END IF;

    RETURN 1;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION is_valid_media_url (url VARCHAR(255))
RETURNS INT
READS SQL DATA
BEGIN
	IF url REGEXP "^(https?\:\/\/)?((www|m)\.)?(youtube\.com|youtu\.?be)\/.+$" <> 1 THEN
		RETURN 0;
	END IF;

	IF url NOT LIKE '%watch?v=___________' AND url NOT LIKE '%/___________' THEN
		RETURN 0;
	END IF;

    RETURN 1;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION convert_media_url (url VARCHAR(255))
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
	DECLARE media_url VARCHAR(255);
	SET media_url = REPLACE(url, 'youtu.be/', 'youtube.com/embed/');
	SET media_url = REPLACE(media_url, 'watch?v=', 'embed/');
    RETURN media_url;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER user_before_insert
    BEFORE INSERT ON `user`
    FOR EACH ROW
BEGIN
    CALL procedure_user_checks(NEW.email, NEW.name, NEW.password, NEW.birthdate, NEW.picture);
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER user_before_update
    BEFORE UPDATE ON `user`
    FOR EACH ROW
BEGIN
	IF is_valid_url(NEW.picture) <> 1 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'url de la photo invalide';
	END IF;
    CALL procedure_user_checks(NEW.email, NEW.name, NEW.password, NEW.birthdate, NEW.picture);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE procedure_user_checks(IN email VARCHAR(255), IN name VARCHAR(255), IN password VARCHAR(255), IN birthdate TIMESTAMP, IN picture VARCHAR(255))
READS SQL DATA
BEGIN
    IF TIMESTAMPDIFF(YEAR, birthdate, CURRENT_TIMESTAMP) < 13 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'vous devez avoir plus de 13 ans';
	ELSEIF email NOT LIKE '%_@_%._%' THEN
		SIGNAL SQLSTATE '45001'
			SET MESSAGE_TEXT = 'email invalide';
	ELSEIF CHAR_LENGTH(name) <= 0 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'le nom ne peut pas etre vide';
	ELSEIF CHAR_LENGTH(password) <= 0 THEN
		SIGNAL SQLSTATE '45003'
			SET MESSAGE_TEXT = 'le mot de passe ne doit pas etre vide';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER playlist_before_insert
    BEFORE INSERT ON `playlist`
    FOR EACH ROW
BEGIN
	IF CHAR_LENGTH(NEW.name) <= 0 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'le nom ne peut pas etre vide';
	END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER playlist_before_update
    BEFORE UPDATE ON `playlist`
    FOR EACH ROW
BEGIN
	IF is_valid_url(NEW.picture) <> 1 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'url de la photo invalide';
	ELSEIF CHAR_LENGTH(NEW.name) <= 0 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'le nom ne peut pas etre vide';
	END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER title_before_insert
    BEFORE INSERT ON `title`
    FOR EACH ROW
BEGIN
	CALL procedure_title_checks(NEW.name, NEW.url);
	SET NEW.url = convert_media_url(NEW.url);
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER title_before_update
    BEFORE UPDATE ON `title`
    FOR EACH ROW
BEGIN
	CALL procedure_title_checks(NEW.name, NEW.url);
	SET NEW.url = convert_media_url(NEW.url);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE procedure_title_checks(IN name VARCHAR(255), IN url VARCHAR(255))
READS SQL DATA
BEGIN
	IF CHAR_LENGTH(name) <= 0 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'le nom ne peut pas etre vide';
	ELSEIF is_valid_media_url(url) <> 1 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'url du titre invalide';
	END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER commentary_before_insert
    BEFORE INSERT ON `commentary`
    FOR EACH ROW
BEGIN
	CALL procedure_commentary_checks(NEW.description);
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER commentary_before_update
    BEFORE UPDATE ON `commentary`
    FOR EACH ROW
BEGIN
	CALL procedure_commentary_checks(NEW.description);
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE procedure_commentary_checks(IN description VARCHAR(1024))
READS SQL DATA
BEGIN
	IF CHAR_LENGTH(description) <= 0 THEN
		SIGNAL SQLSTATE '45002'
			SET MESSAGE_TEXT = 'la description ne peut pas etre vide';
	END IF;
END//
DELIMITER ;

# TUPLE VALUES
INSERT INTO gender(name) VALUES
    ('Man'),
    ('Woman')
;

INSERT INTO user(email, name, password, birthdate, gender_name) VALUES
	('rap@rap.com', 'rap_lover', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('metal@metal.com', 'metal_lover', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01' , 'Man'),
	('classic@classic.com', 'classic_lover', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('got@got.com', 'got', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('ulaval@ulaval.com', 'ulaval', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('female@female.com', 'female', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
	('fb@gfb.com', 'fb', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('twitter@twitter.com', 'twitter', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('potc@potc.com', 'potc', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lotr@lotr.com', 'lotr', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('ff@ff.com', 'ff', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('mako@reactor.com', 'mako_reactor', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('cosmo@canyon.com', 'cosmo_canyon', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('cod@cod.com', 'cod', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('fifa@fifa.com', 'fifa', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lol@lol.com', 'lol', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('dota@dota.com', 'dota', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('hans@zimmer.com', 'hans_zimmer', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('wc3@wc3.com', 'wc3', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('arthas@menethil.com', 'Prince of Lordearon', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('jaina@portvaillant.com', 'Leader of the Kirin Tor', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('thrall@doomhammer.com', 'True Warchief', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('pikachu@pikachu.com', 'Pikachu', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('salameche@salameche.com', 'Salameche', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('gg@gg.com', 'good game', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('pnl@pnl.com', 'pnl', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('monk@monk.com', 'Moine', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('henri@henri.com', 'Riton', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1993/08/13', 'Man'),
    ('maxime@maxime.com', 'Max', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1997/12/19', 'Man'),
    ('nyc@nyc.com', 'New York City', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lumber@lumber.com', 'LumberJack', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('biggie@biggie.com', 'Biggie', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('2pac@2pac.com', '2Pac', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('a@a.com', 'a', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('z@z.com', 'z', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('e@e.com', 'e', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('r@r.com', 'r', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('t@t.com', 't', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('y@y.com', 'y', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('u@u.com', 'u', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('i@i.com', 'i', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('o@o.com', 'o', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('p@p.com', 'p', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('q@q.com', 'q', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('s@s.com', 's', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('d@d.com', 'd', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('f@f.com', 'f', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('g@g.com', 'g', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('h@h.com', 'h', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('j@j.com', 'k', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('l@l.com', 'l', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('m@m.com', 'm', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('w@w.com', 'w', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('k@k.com', 'k', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('x@x.com', 'x', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('c@c.com', 'c', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('v@v.com', 'v', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('b@b.com', 'b', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
	('n@n.com', 'n', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('twittertwitter@twitter.com', 'twitter twitter', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('potc2@potc2.com', 'potc2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lotr2@lotr2.com', 'lotr2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('ff2@ff2.com', 'ff2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('mako2@reactor2.com', 'mako_reactor2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('cosmo2@canyon2.com', 'cosmo_canyon2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('cod2@cod2.com', 'cod2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('fifa2@fifa2.com', 'fifa2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lol2@lol2.com', 'lol2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('dota2@dota2.com', 'dota2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('hans2@zimmer2.com', 'hans_zimmer2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('wc32@wc32.com', 'wc32', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('arthas2@menethil2.com', 'Prince of Lordearon 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('jaina2@portvaillant2.com', 'Leader of the Kirin Tor 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('thrall2@doomhammer2.com', 'True Warchief 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('pikachu2@pikachu2.com', 'Pikachu 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('salameche2@salameche2.com', 'Salameche 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('gg2@gg2.com', 'good game 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('pnl2@pnl2.com', 'pnl 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('monk2@monk2.com', 'Moine 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('henri2@henri2.com', 'Riton 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1993/08/13', 'Man'),
    ('maxime2@maxime2.com', 'Max 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1997/12/19', 'Man'),
    ('nyc2@nyc2.com', 'New York City 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Woman'),
    ('lumber2@lumber2.com', 'LumberJack 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('biggie2@biggie2.com', 'Biggie 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('2pac2@2pac2.com', '2Pac 2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('a2@a2.com', 'a2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('z2@z2.com', 'z2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('e2@e2.com', 'e2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('r2@r2.com', 'r2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('t2@t2.com', 't2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('y2@y2.com', 'y2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('u2@u2.com', 'u2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('i2@i2.com', 'i', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('o2@o2.com', 'o2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('p2@p2.com', 'p2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('q2@q2.com', 'q2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('s2@s2.com', 's2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('d2@d2.com', 'd2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('f2@f2.com', 'f2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('g2@g2.com', 'g2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('h2@h2.com', 'h2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('j2@j2.com', 'k2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
    ('l2@l2.com', 'l2', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('420@420.com', '420_Bl4z3_1t', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man'),
	('google@google.com', 'google', '$2a$10$9qrnXaGcC8Y6HxXSJdSAY.7wWIky2CkdIWQs1NOVCAqGnrq7jibmy', '1990/01/01', 'Man')
    ;

INSERT INTO playlist(id, name, user_email, description) VALUES
	(1, 'rap 90s', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (2, 'Black Metal', 'metal@metal.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (3, 'Bethoveen', 'classic@classic.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (4, 'Bl4z3_1t', '420@420.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (5, 'rap Fr', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(6, 'Deux frères', 'pnl@pnl.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (7, 'GOT OST Saison 6', 'got@got.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (8, 'Invincible PlayList', 'arthas@menethil.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (9, 'My themes', 'jaina@portvaillant.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (10, 'RPG musics', 'ff@ff.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (11, 'Calm mind', 'monk@monk.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (12, 'the dark knight', 'hans@zimmer.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (13, 'playlist1', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (14, 'playlist2', 'b@b.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (15, 'playlist3', 'c@c.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(16, 'playlist4', 'd@d.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (17, 'playlsit5', 'e@e.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (18, 'playlist6', 'f@f.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (19, 'playlist7', 'g@g.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (20, 'playlist8', 'h@h.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (21, 'playlist9', 'i@i.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (22, 'playlist10', 'j@j.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (23, 'playlist11', 'k@k.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (24, 'playlist12', 'l@l.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (25, 'playlist13', 'm@m.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(26, 'playlist14', 'n@n.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (27, 'playlist15', 'o@o.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (28, 'playlist16', 'p@p.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (29, 'playlist17', 'q@q.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (30, 'playlist18', 'r@r.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (31, 'playlist19', 's@s.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (32, 'playlist20', 't@t.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (33, 'playlist21', 'u@u.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (34, 'playlist22', 'v@v.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (35, 'playlist23', 'w@w.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(36, 'playlist24', 'x@x.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (37, 'playlist25', 'y@y.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (38, 'playlist26', 'z@z.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (39, 'playlist27', 'fifa@fifa.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (40, 'playlist28', 'cod@cod.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (41, 'playlist29', 'maxime@maxime.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (42, 'playlist30', 'henri@henri.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (43, 'playlist31', 'henri@henri.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (44, 'playlist32', 'ulaval@ulaval.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (45, 'playlsit33', 'pikachu@pikachu.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(46, 'playlist34', 'salameche@salameche.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (47, 'COSMO CANYON', 'cosmo@canyon.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (48, 'MAKO REACTOR', 'mako@reactor.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (49, 'True Rohirim Musics', 'lotr@lotr.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (50, 'playlist35', 'a2@a2.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (51, 'playlist36', 'z2@z2.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (52, 'playlist37', 'metal@metal.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (53, 'playlist38', 'classic@classic.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (54, 'Bl4z3_1t 5', '420@420.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (55, 'playlist39', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(56, 'playlist40', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (57, 'playlist41', 'metal@metal.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (58, 'playlist42', 'twitter@twitter.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (59, 'Bl4z3_1t 2', '420@420.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (60, 'rap Fr 90s', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (61, 'rap US', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (62, 'Hard Metal', 'metal@metal.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (63, 'Mozart', 'classic@classic.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (64, 'Bl4z3_1t 3', '420@420.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (65, 'Cloud Rap', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(66, 'playlist43', 'pikachu@pikachu.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (67, 'playlist44', 'salameche@salameche.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (68, 'Till the world end', 'potc@potc.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (69, 'Bl4z3_1t 4', '420@420.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (70, 'kraken', 'potc@potc.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (71, 'playlist45', 'b@b.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (72, 'playlist46', 'v@v.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (73, 'playlist47', 'classic@classic.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (74, 'playlist48', 'f@f.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (75, 'playlist49', 'f@f.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(76, 'Tuturu', 'ff@ff.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (77, 'playlist50', 'ff@ff.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (78, 'playlist51', 'ulaval@ulaval.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (79, 'playlist52', 'cod@cod.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (80, 'playlist53', 'rap@rap.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (81, 'playlist54', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (82, 'playlist55', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (83, 'playlist56', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (84, 'playlist57', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (85, 'playlist58', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(86, 'playlist59', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (87, 'playlist60', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (88, 'playlist61', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (89, 'playlist62', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (90, 'playlist63', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (91, 'playlist64', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (92, 'playlist65', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (93, 'playlist66', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (94, 'playlist67', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (95, 'playlist68', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
	(96, 'playlist69', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (97, 'Richard', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (98, 'playlist70', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (99, 'playlist71', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (100, 'playlist72', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.'),
    (101, 'playlist73', 'a@a.com', 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero.')
    ;

INSERT INTO title(id, name, publication, url, user_email, playlist_id) VALUES
	(1, 'Notorious Big', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (2, 'ALL EYES ON ME', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (3, 'DEAR MAMA', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (4, 'The message-Nas', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (5, 'Affirmative Action', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (6, 'Titre2', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (7, 'Rick Rolled', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(8, 'Le mia', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(9, 'AU DD', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (10, 'Lumière des 7', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (11, 'TADADADADA', '2019/01/01', 'https://youtu.be/4n6WP9qHyRM', 'arthas@menethil.com', 8),
    (12, 'La fille du vent salé', '2019/01/01', 'https://youtu.be/Fo7XPvwRgG8', 'jaina@portvaillant.com', 9),
    (13, '5.1 was a good time', '2019/01/01', 'https://youtu.be/cGiQjZ1-9FI', 'female@female.com', 9),
    (14, 'Fanfare FF', '2019/01/01', 'https://youtu.be/kHx5hCVN26E', 'ff@ff.com', 10),
    (15, 'Playlist-ception', '2019/01/01', 'https://youtu.be/RSa1OUhsEnc', 'ff@ff.com', 10),
    (16, 'Windwalker', '2019/01/01', 'https://youtu.be/Q9VVCdDq03w', 'monk@monk.com', 11),
    (17, 'Mistweaver', '2019/01/01', 'https://youtu.be/lVKeZJ1IYJU', 'monk@monk.com', 11),
	(18, 'Why so serious ?', '2019/01/01', 'https://youtu.be/94TAFSMdkvk', 'hans@zimmer.com', 12),
	(19, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (20, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (21, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (22, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (23, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (24, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (25, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (26, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (27, 'Rick Rolled', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(28, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(29, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (30, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (31, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (32, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (33, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (34, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (35, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (36, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (37, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(38, 'Le spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(39, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (40, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (41, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (42, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (43, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (44, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (45, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (46, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (47, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(48, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(49, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (50, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (51, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (52, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (53, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (54, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (55, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (56, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (57, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(58, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(59, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (60, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (61, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (62, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (63, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (64, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (65, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (66, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (67, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(68, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(69, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (70, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (71, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (72, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (73, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (74, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (75, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (76, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (77, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(78, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(79, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (80, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (81, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (82, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (83, 'spammerino', '2019/01/01', 'https://youtu.be/Mb1ZvUDvLDY', 'female@female.com', 1),
    (84, 'spammerino', '2019/01/01', 'https://youtu.be/qh9TIYXKSFk', 'google@google.com', 1),
    (85, 'spammerino', '2019/01/01', 'https://youtu.be/9wZ7qXhbvxE', 'rap@rap.com', 1),
    (86, 'spammerino', '2019/01/01', 'https://youtu.be/sOOebk_dKFo', 'metal@metal.com', 2),
    (87, 'spammerino', '2019/01/01', 'https://youtu.be/dQw4w9WgXcQ', '420@420.com', 4),
	(88, 'spammerino', '2019/01/01', 'https://youtu.be/7ceNf9qJjgc', 'rap@rap.com', 5),
	(89, 'spammerino', '2019/01/01', 'https://youtu.be/BtyHYIpykN0', 'rap@rap.com', 6),
    (90, 'spammerino', '2019/01/01', 'https://youtu.be/pS-gbqbVd8c', 'got@got.com', 7),
    (91, 'spammerino', '2019/01/01', 'https://youtu.be/_JZom_gVfuw', 'rap@rap.com', 1),
    (92, 'spammerino', '2019/01/01', 'https://youtu.be/zSzaplTFagQ', 'female@female.com', 1),
    (93, 'LAUNCH ULTIMA AND SURVIVE', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (94, '3..2..1', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (95, 'ULTIMA DROPPED', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (96, 'RUN RUN RUN', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (97, 'SHOOT BAHAMUT', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
	(98, 'LAAAAAAAAASERS', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
	(99, 'SHOOT SEPHIROTH', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (100, 'SOLO !', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48),
    (101, 'wp boss', '2019/01/01', 'https://youtu.be/Mkf4g1Kj2W0', 'mako@reactor.com', 48)
    ;
    
INSERT INTO commentary(user_email, title_id, description) VALUES
	('rap@rap.com', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 2, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 3, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 1, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 5, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 4, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 6, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 7, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 8, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 9, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 10, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 11, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 12, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 13, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 14, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 15, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 16, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 17, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 18, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 19, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 20, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 21, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 22, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 23, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 24, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 25, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 26, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 27, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 28, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 29, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 30, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 31, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 32, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 33, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 34, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 35, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 36, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 37, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 38, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 39, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 40, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 41, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 42, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 43, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 44, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 45, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 46, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 47, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 48, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 49, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 50, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 51, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 52, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 53, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 54, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 55, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 56, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 57, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 58, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 59, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 60, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 61, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 62, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 63, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 64, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 65, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 66, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 67, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 68, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 69, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 70, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 71, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 72, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 73, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 74, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 75, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 76, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 77, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 78, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 79, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 80, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 81, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 82, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 83, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 84, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 85, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 86, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 87, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 88, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 89, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 90, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 91, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 92, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 93, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 94, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 95, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 96, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
    ('rap@rap.com', 97, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 98, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('rap@rap.com', 99, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 100, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('metal@metal.com', 101, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),    
	('metal@metal.com', 101, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('female@female.com', 101, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et aliquam neque. Maecenas leo felis, tincidunt at est a, congue maximus ex. Aliquam sit amet nunc tortor. Nullam vel egestas nunc. In quis rhoncus urna. Morbi a magna sit amet leo convallis laoreet non et elit. Donec ac justo id lectus feugiat lobortis. Vivamus eu congue libero'),
	('mako@reactor.com', 94, 'that pleasure when ultima drop at the end...')
    ;

 INSERT INTO followed_playlist(user_email, playlist_id) VALUES
	('rap@rap.com', 48),
    ('metal@metal.com', 48),
	('classic@classic.com',48),
	('got@got.com', 48),
	('ulaval@ulaval.com', 48),
	('female@female.com', 48),
	('fb@gfb.com', 48),
    ('twitter@twitter.com', 48),
    ('potc@potc.com', 48),
    ('lotr@lotr.com', 48),
    ('ff@ff.com', 48),
    ('mako@reactor.com', 48),
    ('cosmo@canyon.com', 48),
    ('cod@cod.com', 48),
    ('fifa@fifa.com', 48),
    ('lol@lol.com', 48),
    ('dota@dota.com', 48),
    ('hans@zimmer.com', 48),
    ('wc3@wc3.com', 48),
    ('arthas@menethil.com', 48),
    ('jaina@portvaillant.com', 48),
    ('thrall@doomhammer.com', 48),
    ('pikachu@pikachu.com', 48),
    ('salameche@salameche.com', 48),
    ('gg@gg.com', 48),
    ('pnl@pnl.com', 48),
    ('monk@monk.com', 48),
    ('henri@henri.com', 48),
    ('maxime@maxime.com', 48),
    ('nyc@nyc.com', 48),
    ('lumber@lumber.com', 48),
    ('biggie@biggie.com', 48),
    ('2pac@2pac.com', 48),
    ('a@a.com', 48),
    ('z@z.com', 48),
    ('e@e.com', 48),
    ('r@r.com', 48),
    ('t@t.com', 48),
    ('y@y.com', 48),
    ('u@u.com', 48),
    ('i@i.com', 48),
    ('o@o.com', 48),
    ('p@p.com', 48),
    ('q@q.com', 48),
    ('s@s.com', 48),
    ('d@d.com', 48),
    ('f@f.com', 48),
    ('g@g.com', 48),
    ('h@h.com', 48),
    ('j@j.com', 48),
    ('l@l.com', 48),
    ('m@m.com', 48),
    ('w@w.com', 48),
	('x@x.com', 48),
	('c@c.com', 48),
	('v@v.com', 48),
	('b@b.com', 48),
	('n@n.com', 48),
    ('twittertwitter@twitter.com', 48),
    ('potc2@potc2.com', 48),
    ('lotr2@lotr2.com', 48),
    ('ff2@ff2.com', 48),
    ('mako2@reactor2.com', 48),
    ('cosmo2@canyon2.com', 48),
    ('cod2@cod2.com', 48),
    ('fifa2@fifa2.com', 48),
    ('lol2@lol2.com', 48),
    ('dota2@dota2.com', 48),
    ('hans2@zimmer2.com', 48),
    ('wc32@wc32.com', 48),
    ('arthas2@menethil2.com', 48),
    ('jaina2@portvaillant2.com', 48),
    ('thrall2@doomhammer2.com', 48),
    ('pikachu2@pikachu2.com', 48),
    ('salameche2@salameche2.com', 48),
    ('gg2@gg2.com', 48),
    ('pnl2@pnl2.com', 48),
    ('monk2@monk2.com', 48),
    ('henri2@henri2.com', 48),
    ('maxime2@maxime2.com', 48),
    ('nyc2@nyc2.com', 48),
    ('lumber2@lumber2.com', 48),
    ('biggie2@biggie2.com', 48),
    ('2pac2@2pac2.com', 48),
    ('a2@a2.com', 48),
    ('z2@z2.com', 48),
    ('e2@e2.com', 48),
    ('r2@r2.com', 48),
    ('t2@t2.com', 48),
    ('y2@y2.com', 48),
    ('u2@u2.com', 48),
    ('i2@i2.com', 48),
    ('o2@o2.com', 48),
    ('p2@p2.com', 48),
    ('q2@q2.com', 48),
    ('s2@s2.com', 48),
    ('d2@d2.com', 48),
    ('f2@f2.com', 48),
    ('g2@g2.com', 48),
    ('h2@h2.com', 48),
    ('j2@j2.com', 48),
    ('l2@l2.com', 48),
	('420@420.com', 48)
    ;
    
INSERT INTO followed_user(user_email, follow_email) VALUES
	('rap@rap.com', 'mako@reactor.com'),
    ('metal@metal.com', 'mako@reactor.com'),
	('classic@classic.com','mako@reactor.com'),
	('got@got.com', 'mako@reactor.com'),
	('ulaval@ulaval.com', 'mako@reactor.com'),
	('female@female.com', 'mako@reactor.com'),
	('fb@gfb.com', 'mako@reactor.com'),
    ('twitter@twitter.com', 'mako@reactor.com'),
    ('potc@potc.com', 'mako@reactor.com'),
    ('lotr@lotr.com', 'mako@reactor.com'),
    ('ff@ff.com', 'mako@reactor.com'),
    ('mako@reactor.com', 'mako2@reactor2.com'),
    ('cosmo@canyon.com', 'mako@reactor.com'),
    ('cod@cod.com', 'mako@reactor.com'),
    ('fifa@fifa.com', 'mako@reactor.com'),
    ('lol@lol.com', 'mako@reactor.com'),
    ('dota@dota.com', 'mako@reactor.com'),
    ('hans@zimmer.com', 'mako@reactor.com'),
    ('wc3@wc3.com', 'mako@reactor.com'),
    ('arthas@menethil.com', 'mako@reactor.com'),
    ('jaina@portvaillant.com', 'mako@reactor.com'),
    ('thrall@doomhammer.com', 'mako@reactor.com'),
    ('pikachu@pikachu.com', 'mako@reactor.com'),
    ('salameche@salameche.com', 'mako@reactor.com'),
    ('gg@gg.com', 'mako@reactor.com'),
    ('pnl@pnl.com', 'mako@reactor.com'),
    ('monk@monk.com', 'mako@reactor.com'),
    ('henri@henri.com', 'mako@reactor.com'),
    ('maxime@maxime.com', 'mako@reactor.com'),
    ('nyc@nyc.com', 'mako@reactor.com'),
    ('lumber@lumber.com', 'mako@reactor.com'),
    ('biggie@biggie.com', 'mako@reactor.com'),
    ('2pac@2pac.com', 'mako@reactor.com'),
    ('a@a.com', 'mako@reactor.com'),
    ('z@z.com', 'mako@reactor.com'),
    ('e@e.com', 'mako@reactor.com'),
    ('r@r.com', 'mako@reactor.com'),
    ('t@t.com', 'mako@reactor.com'),
    ('y@y.com', 'mako@reactor.com'),
    ('u@u.com', 'mako@reactor.com'),
    ('i@i.com', 'mako@reactor.com'),
    ('o@o.com', 'mako@reactor.com'),
    ('p@p.com', 'mako@reactor.com'),
    ('q@q.com', 'mako@reactor.com'),
    ('s@s.com', 'mako@reactor.com'),
    ('d@d.com', 'mako@reactor.com'),
    ('f@f.com', 'mako@reactor.com'),
    ('g@g.com', 'mako@reactor.com'),
    ('h@h.com', 'mako@reactor.com'),
    ('j@j.com', 'mako@reactor.com'),
    ('l@l.com', 'mako@reactor.com'),
    ('m@m.com', 'mako@reactor.com'),
    ('w@w.com', 'mako@reactor.com'),
	('x@x.com', 'mako@reactor.com'),
	('c@c.com', 'mako@reactor.com'),
	('v@v.com', 'mako@reactor.com'),
	('b@b.com', 'mako@reactor.com'),
	('n@n.com', 'mako@reactor.com'),
    ('twittertwitter@twitter.com', 'mako@reactor.com'),
    ('potc2@potc2.com', 'mako@reactor.com'),
    ('lotr2@lotr2.com', 'mako@reactor.com'),
    ('ff2@ff2.com', 'mako@reactor.com'),
    ('mako2@reactor2.com', 'mako@reactor.com'),
    ('cosmo2@canyon2.com', 'mako@reactor.com'),
    ('cod2@cod2.com', 'mako@reactor.com'),
    ('fifa2@fifa2.com', 'mako@reactor.com'),
    ('lol2@lol2.com', 'mako@reactor.com'),
    ('dota2@dota2.com', 'mako@reactor.com'),
    ('hans2@zimmer2.com', 'mako@reactor.com'),
    ('wc32@wc32.com', 'mako@reactor.com'),
    ('arthas2@menethil2.com', 'mako@reactor.com'),
    ('jaina2@portvaillant2.com', 'mako@reactor.com'),
    ('thrall2@doomhammer2.com', 'mako@reactor.com'),
    ('pikachu2@pikachu2.com', 'mako@reactor.com'),
    ('salameche2@salameche2.com', 'mako@reactor.com'),
    ('gg2@gg2.com', 'mako@reactor.com'),
    ('pnl2@pnl2.com', 'mako@reactor.com'),
    ('monk2@monk2.com', 'mako@reactor.com'),
    ('henri2@henri2.com', 'mako@reactor.com'),
    ('maxime2@maxime2.com', 'mako@reactor.com'),
    ('nyc2@nyc2.com', 'mako@reactor.com'),
    ('lumber2@lumber2.com', 'mako@reactor.com'),
    ('biggie2@biggie2.com', 'mako@reactor.com'),
    ('2pac2@2pac2.com', 'mako@reactor.com'),
    ('a2@a2.com', 'mako@reactor.com'),
    ('z2@z2.com', 'mako@reactor.com'),
    ('e2@e2.com', 'mako@reactor.com'),
    ('r2@r2.com', 'mako@reactor.com'),
    ('t2@t2.com', 'mako@reactor.com'),
    ('y2@y2.com', 'mako@reactor.com'),
    ('u2@u2.com', 'mako@reactor.com'),
    ('i2@i2.com', 'mako@reactor.com'),
    ('o2@o2.com', 'mako@reactor.com'),
    ('p2@p2.com', 'mako@reactor.com'),
    ('q2@q2.com', 'mako@reactor.com'),
    ('s2@s2.com', 'mako@reactor.com'),
    ('d2@d2.com', 'mako@reactor.com'),
    ('f2@f2.com', 'mako@reactor.com'),
    ('g2@g2.com', 'mako@reactor.com'),
    ('h2@h2.com', 'mako@reactor.com'),
    ('j2@j2.com', 'mako@reactor.com'),
    ('l2@l2.com', 'mako@reactor.com'),
	('420@420.com', 'mako@reactor.com')
    ;