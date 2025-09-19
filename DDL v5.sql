BEGIN TRANSACTION;

CREATE TYPE "ReserveType" AS ENUM (
	'None',
	'Major',
	'Common',
	'Low',
	'Depleted',
	'Pristine'
);

CREATE TYPE "RingType" AS ENUM (
	'Rocky',
	'MetalRich',
	'Icy',
	'Metallic'
);

CREATE TYPE "HotspotType" AS ENUM (
	'Alexandrite',
	'Bauxite',
	'Benitoite',
	'Bromellite',
	'Cobalt',
	'Coltan',
	'Gallite',
	'Gold',
	'Grandidierite',
	'HydrogenPeroxide',
	'Indite',
	'Lepidolite',
	'LiquidOxygen',
	'LithiumHydroxide',
	'LowTemperatureDiamond',
	'MethaneClathrate',
	'MethanolMonohydrateCrystals',
	'Monazite',
	'Musgravite',
	'Opal',
	'Osmium',
	'Painite',
	'Palladium',
	'Platinum',
	'Praseodymium',
	'Rhodplumsite',
	'Rutile',
	'Samarium',
	'Serendibite',
	'Silver',
	'Tritium',
	'Uraninite',
	'Water'
);

CREATE TABLE "Factions" (
	"factionID" SERIAL PRIMARY KEY,
	"factionName" VARCHAR(75) UNIQUE NOT NULL
);

CREATE TABLE "StarSystems" (
	"systemID" BIGINT PRIMARY KEY,
	"systemName" VARCHAR(75) NOT NULL,
	"systemCoords" GEOMETRY(PointZ, 0) NOT NULL,
	"isColonised" BOOLEAN NOT NULL
);

CREATE TABLE "Stations" (
	"stationID" BIGINT PRIMARY KEY,
	"systemID" BIGINT NOT NULL,
	"stationName" VARCHAR(75) NOT NULL,
	"controllingFaction" INT NOT NULL,
	FOREIGN KEY ("systemID") REFERENCES "StarSystems"("systemID") ON DELETE CASCADE,
	FOREIGN KEY ("controllingFaction") REFERENCES "Factions"("factionID")
);

CREATE TABLE "UncolonisedStarSystems" (
	"systemID" BIGINT PRIMARY KEY,
	"lastUpdated" TIMESTAMP NOT NULL,
	"reserveLevel" "ReserveType" NOT NULL,
	"landableCount" SMALLINT NOT NULL,
	"walkableCount" SMALLINT NOT NULL,
	"distanceToSol" INT NOT NULL,
	"totalHotspots" SMALLINT NOT NULL,
	"systemValue" NUMERIC(5,2) NOT NULL,
	FOREIGN KEY ("systemID") REFERENCES "StarSystems"("systemID") ON DELETE CASCADE
);

CREATE TABLE "UncolonisedStarSystemsAvailability" (
	"systemID" BIGINT PRIMARY KEY,
	"isLocked" BOOLEAN NOT NULL,
	"isClaimed" BOOLEAN NOT NULL,
	"lockReportCount" SMALLINT NOT NULL,
	"claimReportCount" SMALLINT NOT NULL,
	"lockReportDate" TIMESTAMP,
	"claimReportDate" TIMESTAMP,
	FOREIGN KEY ("systemID") REFERENCES "StarSystems"("systemID") ON DELETE CASCADE
);

CREATE TABLE "ColonyOverrideCounts" (
	"systemID" BIGINT PRIMARY KEY,
	"blackHoleCount" SMALLINT NOT NULL,
	"neutronStarCount" SMALLINT NOT NULL,
	"whiteDwarves" SMALLINT NOT NULL,
	"otherStarCount" SMALLINT NOT NULL,
	"earthLikeCount" SMALLINT NOT NULL,
	"waterWorldCount" SMALLINT NOT NULL,
	"ammoniaWorldCount" SMALLINT NOT NULL,
	"gasGiantCount" SMALLINT NOT NULL,
	"highMetalContentCount" SMALLINT NOT NULL,
	"metalRichCount" SMALLINT NOT NULL,
	"rockyIceBodyCount" SMALLINT NOT NULL,
	"rockBodyCount" SMALLINT NOT NULL,
	"icyBodyCount" SMALLINT NOT NULL,
	"organicCount" SMALLINT NOT NULL,
	"geologicalsCount" SMALLINT NOT NULL,
	"ringCount" SMALLINT NOT NULL,
	FOREIGN KEY ("systemID") REFERENCES "UncolonisedStarSystems"("systemID") ON DELETE CASCADE
);

CREATE TABLE "Rings" (
	"ringID" SERIAL PRIMARY KEY,
	"systemID" BIGINT NOT NULL,
	"ringName" VARCHAR(75) NOT NULL,
	"ringType" "RingType" NOT NULL,
	UNIQUE ("systemID", "ringName"),
	FOREIGN KEY ("systemID") REFERENCES "UncolonisedStarSystems"("systemID") ON DELETE CASCADE
);

CREATE TABLE "Hotspots" (
	"ringID" INT,
	"hotspotType" "HotspotType",
	"hotspotCount" SMALLINT NOT NULL,
	PRIMARY KEY ("ringID", "hotspotType"),
	FOREIGN KEY ("ringID") REFERENCES "Rings"("ringID") ON DELETE CASCADE
);

CREATE TABLE "TrailblazerMegaships" (
	"trailblazerID" BIGINT PRIMARY KEY,
	"trailblazerName" VARCHAR(25) NOT NULL,
	"trailblazerCoords" GEOMETRY(PointZ, 0) NOT NULL,
	"lastUpdate" TIMESTAMP NOT NULL
);

CREATE TABLE "ColonisableStarSystems" (
	"colonisedSystemID" BIGINT,
	"uncolonisedSystemID" BIGINT,
	PRIMARY KEY ("colonisedSystemID", "uncolonisedSystemID"),
	FOREIGN KEY ("colonisedSystemID") REFERENCES "StarSystems"("systemID") ON DELETE CASCADE,
	FOREIGN KEY ("uncolonisedSystemID") REFERENCES "UncolonisedStarSystems"("systemID") ON DELETE CASCADE
);

CREATE TABLE "TrailblazerDistances" (
	"uncolonisedSystemID" BIGINT,
	"trailblazerID" BIGINT,
	"distanceBetween" INT NOT NULL,
	PRIMARY KEY ("uncolonisedSystemID", "trailblazerID"),
	FOREIGN KEY ("uncolonisedSystemID") REFERENCES "UncolonisedStarSystems"("systemID") ON DELETE CASCADE,
	FOREIGN KEY ("trailblazerID") REFERENCES "TrailblazerMegaships"("trailblazerID") ON DELETE CASCADE
);

CREATE INDEX "idx_F_factionName" ON "Factions"("factionName");
CREATE INDEX "idx_SS_systemName" ON "StarSystems"("systemName");
CREATE INDEX "idx_S_systemID" ON "Stations"("systemID");
CREATE INDEX "idx_S_controllingFaction" ON "Stations"("controllingFaction");
CREATE INDEX "idx_USS_lastUpdated" ON "UncolonisedStarSystems"("lastUpdated");
CREATE INDEX "idx_USS_landableCount" ON "UncolonisedStarSystems"("landableCount");
CREATE INDEX "idx_USS_walkableCount" ON "UncolonisedStarSystems"("walkableCount");
CREATE INDEX "idx_USS_distanceToSol" ON "UncolonisedStarSystems"("distanceToSol");
CREATE INDEX "idx_USS_totalHotspots" ON "UncolonisedStarSystems"("totalHotspots");
CREATE INDEX "idx_USS_systemValue" ON "UncolonisedStarSystems"("systemValue");
CREATE INDEX "idx_COC_blackHoleCount" ON "ColonyOverrideCounts"("blackHoleCount");
CREATE INDEX "idx_COC_neutronStarCount" ON "ColonyOverrideCounts"("neutronStarCount");
CREATE INDEX "idx_COC_whiteDwarves" ON "ColonyOverrideCounts"("whiteDwarves");
CREATE INDEX "idx_COC_otherStarCount" ON "ColonyOverrideCounts"("otherStarCount");
CREATE INDEX "idx_COC_earthLikeCount" ON "ColonyOverrideCounts"("earthLikeCount");
CREATE INDEX "idx_COC_waterWorldCount" ON "ColonyOverrideCounts"("waterWorldCount");
CREATE INDEX "idx_COC_ammoniaWorldCount" ON "ColonyOverrideCounts"("ammoniaWorldCount");
CREATE INDEX "idx_COC_gasGiantCount" ON "ColonyOverrideCounts"("gasGiantCount");
CREATE INDEX "idx_COC_highMetalContentCount" ON "ColonyOverrideCounts"("highMetalContentCount");
CREATE INDEX "idx_COC_metalRichCount" ON "ColonyOverrideCounts"("metalRichCount");
CREATE INDEX "idx_COC_rockyIceBodyCount" ON "ColonyOverrideCounts"("rockyIceBodyCount");
CREATE INDEX "idx_COC_rockBodyCount" ON "ColonyOverrideCounts"("rockBodyCount");
CREATE INDEX "idx_COC_icyBodyCount" ON "ColonyOverrideCounts"("icyBodyCount");
CREATE INDEX "idx_COC_organicCount" ON "ColonyOverrideCounts"("organicCount");
CREATE INDEX "idx_COC_geologicalsCount" ON "ColonyOverrideCounts"("geologicalsCount");
CREATE INDEX "idx_COC_ringCount" ON "ColonyOverrideCounts"("ringCount");
CREATE INDEX "idx_R_systemID" ON "Rings"("systemID");
CREATE INDEX "idx_H_ringID" ON "Hotspots"("ringID");
CREATE INDEX "idx_CSS_colonisedSystemID" ON "ColonisableStarSystems"("colonisedSystemID");
CREATE INDEX "idx_CSS_uncolonisedSystemID" ON "ColonisableStarSystems"("uncolonisedSystemID");
CREATE INDEX "idx_TD_trailblazerID" ON "TrailblazerDistances"("trailblazerID");
CREATE INDEX "idx_TD_distanceBetween" ON "TrailblazerDistances"("distanceBetween");

CREATE INDEX "idx_USSA_isLocked" ON "UncolonisedStarSystemsAvailability"("isLocked") WHERE "isLocked" = TRUE;
CREATE INDEX "idx_USSA_isClaimed" ON "UncolonisedStarSystemsAvailability"("isClaimed") WHERE "isClaimed" = TRUE;

CREATE INDEX "idx_SS_systemCoords" ON "StarSystems" USING GIST("systemCoords");
CREATE INDEX "idx_TM_trailblazerCoords" ON "TrailblazerMegaships" USING GIST("trailblazerCoords");

CREATE TYPE "StarSystemInsertType" AS (
    "systemID" BIGINT,
    "systemName" VARCHAR(75),
    "isColonised" BOOLEAN,
    "coordinateX" NUMERIC(11, 5),
    "coordinateY" NUMERIC(11, 5),
    "coordinateZ" NUMERIC(11, 5)
);

CREATE TYPE "StationInsertType" AS (
    "stationID" BIGINT,
    "systemID" BIGINT,
    "stationName" VARCHAR(75),
    "controllingFaction" VARCHAR(75)
);

CREATE TYPE "UncolonisedDetailsInsertType" AS (
	"systemID" BIGINT,
	"lastUpdated" TIMESTAMP,
	"reserveLevel" "ReserveType",
	"landableCount" SMALLINT,
	"walkableCount" SMALLINT,
	"distanceToSol" INT,
	"totalHotspots" SMALLINT,
	"systemValue" NUMERIC(5,2),
	"blackHoleCount" SMALLINT,
	"neutronStarCount" SMALLINT,
	"whiteDwarves" SMALLINT,
	"otherStarCount" SMALLINT,
	"earthLikeCount" SMALLINT,
	"waterWorldCount" SMALLINT,
	"ammoniaWorldCount" SMALLINT,
	"gasGiantCount" SMALLINT,
	"highMetalContentCount" SMALLINT,
	"metalRichCount" SMALLINT,
	"rockyIceBodyCount" SMALLINT,
	"rockBodyCount" SMALLINT,
	"icyBodyCount" SMALLINT,
	"organicCount" SMALLINT,
	"geologicalsCount" SMALLINT,
	"ringCount" SMALLINT
);

CREATE TYPE "RingInsertType" AS (
	"systemID" BIGINT,
	"ringName" VARCHAR(75),
	"ringType" "RingType"
);

CREATE TYPE "HotspotInsertType" AS (
	"systemID" BIGINT,
	"ringName" VARCHAR(75),
	"hotspotType" "HotspotType",
	"hotspotCount" SMALLINT
);

CREATE TYPE "ColonisableInsertType" AS (
	"colonisedSystemID" BIGINT,
	"uncolonisedSystemID" BIGINT
);

COMMIT TRANSACTION;