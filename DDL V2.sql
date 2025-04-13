BEGIN TRANSACTION;

-- Creates the BodyType table
CREATE TABLE BodyType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the ReserveType table
CREATE TABLE ReserveType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the RingType table
CREATE TABLE RingType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(10) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the HotspotType table
CREATE TABLE HotspotType (
	typeID TINYINT PRIMARY KEY IDENTITY(1, 1),
	typeName VARCHAR(50) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Factions table
CREATE TABLE Factions (
	factionID INT PRIMARY KEY IDENTITY(1, 1),
	factionName VARCHAR(75) UNIQUE NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the SystemCoords table
CREATE TABLE SystemCoords (
	systemID BIGINT PRIMARY KEY,
	coordinateX DECIMAL(10, 5) NOT NULL,
	coordinateY DECIMAL(10, 5) NOT NULL,
	coordinateZ DECIMAL(10, 5) NOT NULL
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the StarSystems table
CREATE TABLE StarSystems (
	systemID BIGINT PRIMARY KEY,
	systemName VARCHAR(75) NOT NULL,
	isColonised BIT NOT NULL,
	lastColonisingUpdate DATE,
	FOREIGN KEY (systemID) REFERENCES SystemCoords (systemID) ON DELETE CASCADE
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Stations table
CREATE TABLE Stations (
	stationID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	stationName VARCHAR(75) NOT NULL,
	controllingFaction INT NOT NULL,
	FOREIGN KEY (systemID) REFERENCES StarSystems (systemID) ON DELETE CASCADE,
	FOREIGN KEY (controllingFaction) REFERENCES Factions (factionID)
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Bodies table
CREATE TABLE Bodies (
	bodyID BIGINT PRIMARY KEY,
	systemID BIGINT NOT NULL,
	bodyName VARCHAR(75) NOT NULL,
	bodyType TINYINT NOT NULL,
	isLandable BIT NOT NULL,
	reserveType TINYINT NOT NULL,
	FOREIGN KEY (systemID) REFERENCES StarSystems (systemID) ON DELETE CASCADE,
	FOREIGN KEY (bodyType) REFERENCES BodyType (typeID),
	FOREIGN KEY (reserveType) REFERENCES ReserveType (typeID)
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Rings table
CREATE TABLE Rings (
	ringID INT PRIMARY KEY,
	bodyID BIGINT NOT NULL,
	ringName VARCHAR(75) NOT NULL,
	ringType TINYINT NOT NULL,
	FOREIGN KEY (bodyID) REFERENCES Bodies (bodyID) ON DELETE CASCADE,
	FOREIGN KEY (ringType) REFERENCES RingType (typeID)
) WITH (DATA_COMPRESSION = PAGE);

-- Creates the Hotspots table
CREATE TABLE Hotspots (
	ringID INT,
	hotspotID TINYINT,
	hotspotCount TINYINT NOT NULL,
	PRIMARY KEY (ringID, hotspotID),
	FOREIGN KEY (ringID) REFERENCES Rings (ringID) ON DELETE CASCADE,
	FOREIGN KEY (hotspotID) REFERENCES HotspotType (typeID)
) WITH (DATA_COMPRESSION = PAGE);

-- Creates indexes
CREATE INDEX idx_systemName ON StarSystems(systemName);
CREATE INDEX idx_controllingFaction ON Stations(controllingFaction);
CREATE INDEX idx_systemID ON Stations(systemID);
CREATE INDEX idx_systemID ON Bodies(systemID)
CREATE INDEX idx_bodyID ON Rings(bodyID);
CREATE INDEX idx_ringID ON Hotspots(ringID);
CREATE INDEX idx_coordinateX ON SystemCoords(coordinateX);
CREATE INDEX idx_coordinateY ON SystemCoords(coordinateY);
CREATE INDEX idx_coordinateZ ON SystemCoords(coordinateZ);

COMMIT TRANSACTION;