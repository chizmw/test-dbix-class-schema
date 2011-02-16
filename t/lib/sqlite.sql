-- lifted from DBIx::Class' t/lib/sqlite.sql

CREATE TABLE artist (
  artistid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100)
);

CREATE TABLE cd (
  cdid INTEGER PRIMARY KEY NOT NULL,
  artistid integer NOT NULL,
  title varchar(100) NOT NULL,
  year varchar(100) NOT NULL
);

CREATE TABLE track (
  trackid INTEGER PRIMARY KEY NOT NULL,
  cdid integer NOT NULL,
  position integer NOT NULL,
  title varchar(100) NOT NULL,
  last_updated_on datetime NULL
);

CREATE TABLE shop (
  shopid INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE cd_shop (
  cdid INTEGER NOT NULL,
  shopid INTEGER NOT NULL,
  PRIMARY KEY ( cdid, shopid )
);

CREATE TABLE audiophile (
  audiophileid INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(100)
);

CREATE TABLE cdshop_audiophile (
  cdid INTEGER NOT NULL,
  shopid INTEGER NOT NULL,
  audiophileid INTEGER NOT NULL,
  PRIMARY KEY ( cdid, shopid, audiophileid )
);
