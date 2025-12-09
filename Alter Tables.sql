BEGIN TRANSACTION;
-- Alter stationID
ALTER TABLE "Stations" ALTER COLUMN "stationID" TYPE NUMERIC(20, 0);

-- Alter trailblazerID
ALTER TABLE "TrailblazerDistances" DROP CONSTRAINT "TrailblazerDistances_trailblazerID_fkey";

ALTER TABLE "TrailblazerDistances" ALTER COLUMN "trailblazerID" TYPE NUMERIC(20, 0);

ALTER TABLE "TrailblazerMegaships" ALTER COLUMN "trailblazerID" TYPE NUMERIC(20, 0);

ALTER TABLE "TrailblazerDistances" ADD CONSTRAINT FOREIGN KEY ("trailblazerID") REFERENCES "TrailblazerMegaships"("trailblazerID") ON DELETE CASCADE;

COMMIT TRANSACTION;