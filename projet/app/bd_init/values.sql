use soundhub;

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
    
    