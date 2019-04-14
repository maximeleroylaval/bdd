DROP DATABASE IF EXISTS soundhub;
DROP USER IF EXISTS 'soundhub'@'localhost';

CREATE DATABASE soundhub;

CREATE USER IF NOT EXISTS 'soundhub'@'localhost' IDENTIFIED BY 'soundhubpassword';
GRANT ALL ON *.* TO 'soundhub'@'localhost';