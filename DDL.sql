BEGIN TRANSACTION;

-- Creates the BodyType table
CREATE TABLE BodyType (
	typeID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the ReserveType table
CREATE TABLE ReserveType (
	typeID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the StationType table
CREATE TABLE StationType (
	typeID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the RingType table
CREATE TABLE RingType (
	typeID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
);

-- Creates the HotspotType table
CREATE TABLE HotspotType (
	typeID SMALLINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
);

-- Creates the Factions table
CREATE TABLE Factions (
	factionID INT PRIMARY KEY IDENTITY(1, 1),
	factionName VARCHAR(150) UNIQUE NOT NULL
);

-- Creates the SystemCoords table
CREATE TABLE SystemCoords (
	coordinateID INT PRIMARY KEY IDENTITY(1, 1),
	coordinateX DECIMAL(12, 6) NOT NULL,
	coordinateY DECIMAL(12, 6) NOT NULL,
	coordinateZ DECIMAL(12, 6) NOT NULL,
	UNIQUE(coordinateX, coordinateY, coordinateZ)
);

-- Creates the Systems table
CREATE TABLE Systems (
	systemID BIGINT PRIMARY KEY,
	systemName VARCHAR(150) NOT NULL,
	isColonised BIT NOT NULL,
	coordinates INT NOT NULL,
	FOREIGN KEY (coordinates) REFERENCES SystemCoords (coordinateID)
);

-- Creates the Stations table
CREATE TABLE Stations (
	stationID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	stationName VARCHAR(150) NOT NULL,
	stationType SMALLINT NOT NULL,
	controllingFaction INT NOT NULL,
	UNIQUE (systemID, stationName),
	FOREIGN KEY (systemID) REFERENCES Systems (systemID),
	FOREIGN KEY (stationType) REFERENCES StationType (typeID),
	FOREIGN KEY (controllingFaction) REFERENCES Factions (factionID)
);

-- Creates the Bodies table
CREATE TABLE Bodies (
	bodyID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	bodyName VARCHAR(150) NOT NULL,
	bodyType SMALLINT NOT NULL,
	isLandable BIT NOT NULL,
	reserveType SMALLINT,
	UNIQUE (systemID, bodyName),
	FOREIGN KEY (systemID) REFERENCES Systems (systemID),
	FOREIGN KEY (bodyType) REFERENCES BodyType (typeID),
	FOREIGN KEY (reserveType) REFERENCES ReserveType (typeID)
);

-- Creates the Rings table
CREATE TABLE Rings (
	ringID BIGINT,
	bodyID BIGINT,
	ringName VARCHAR(150) NOT NULL,
	ringType SMALLINT NOT NULL,
	PRIMARY KEY (ringID, bodyID),
	FOREIGN KEY (bodyID) REFERENCES Bodies (bodyID),
	FOREIGN KEY (ringType) REFERENCES RingType (typeID)
);

-- Creates the Hotspots table
CREATE TABLE Hotspots (
	ringID BIGINT,
	bodyID BIGINT,
	hotspotID SMALLINT,
	hotspotCount SMALLINT NOT NULL,
	PRIMARY KEY (ringID, bodyID, hotspotID),
	FOREIGN KEY (ringID) REFERENCES Rings (ringID, bodyID),
	FOREIGN KEY (hotspotID) REFERENCES HotspotType (typeID)
);

-- Creates indexes
CREATE INDEX idx_controllingFaction ON Stations(controllingFaction);
CREATE INDEX idx_bodyID ON Rings(bodyID);
CREATE INDEX idx_ringID ON Hotspots(ringID);
CREATE INDEX idx_coordinates ON Systems(coordinates);
CREATE INDEX idx_coordinateX ON SystemCoords(coordinateX);
CREATE INDEX idx_coordinateY ON SystemCoords(coordinateY);
CREATE INDEX idx_coordinateZ ON SystemCoords(coordinateZ);

-- Creates the HotspotsTable Type
CREATE TYPE HotspotsTable AS TABLE (
	ringID BIGINT,
	bodyID BIGINT,
	hotspotType VARCHAR(50),
	hotspotCount SMALLINT,
	PRIMARY KEY (ringID, bodyID, hotspotType)
);

-- Creates the BodiesTable Type
CREATE TYPE BodiesTable AS TABLE (
    bodyID BIGINT PRIMARY KEY,
    systemID BIGINT,
    bodyName VARCHAR(150),
    bodyType VARCHAR(50),
    isLandable BIT,
    reserveType VARCHAR(50)
);

-- Creates the RingsTable Type
CREATE TYPE RingsTable AS TABLE (
    ringID BIGINT,
    bodyID BIGINT,
    ringName VARCHAR(150),
    ringType VARCHAR(50),
	PRIMARY KEY (ringID, bodyID)
)

-- Creates the StationsTable Type
CREATE TYPE StationsTable AS TABLE (
    stationID BIGINT PRIMARY KEY,
    systemID BIGINT,
    stationName VARCHAR(150),
    stationType VARCHAR(50),
    controllingFaction VARCHAR(150)
);

-- Creates the SystemsTable Type
CREATE TYPE SystemsTable AS TABLE
(
    systemID BIGINT PRIMARY KEY,
    systemName VARCHAR(150),
    isColonised BIT,
    coordinateX DECIMAL(12, 6),
    coordinateY DECIMAL(12, 6),
    coordinateZ DECIMAL(12, 6)
);

COMMIT TRANSACTION;