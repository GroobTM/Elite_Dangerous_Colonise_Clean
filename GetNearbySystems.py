import csv
import numpy as np
from scipy.spatial import KDTree

def ListDictReader(csvFile):
    with open(csvFile, "r", encoding="utf-8-sig") as file:  # Notice the encoding!
        reader = csv.DictReader(file)
        return list(reader)

def ExtractCoordinates(systems):
    """ Extract coordinates and return a list of tuples for KDTree """
    return [(float(system["coordinateX"]), float(system["coordinateY"]), float(system["coordinateZ"])) for system in systems]

def FindSystemsInRangeKDTree(colonisedSystems, uncolonisedSystems, range_limit):
    """ Use KDTree to efficiently find systems within range """
    colonised_coords = ExtractCoordinates(colonisedSystems)
    uncolonised_coords = ExtractCoordinates(uncolonisedSystems)

    # Build KD-Tree for uncolonised systems
    kdtree = KDTree(uncolonised_coords)

    systemsInRange = [["colonisedSystem", "uncolonisedSystem"]]

    # Use tree query_ball_point for efficient range search
    for i, colonisedSystem in enumerate(colonisedSystems):
        nearby_indices = kdtree.query_ball_point(colonised_coords[i], range_limit)

        for index in nearby_indices:
            systemsInRange.append([colonisedSystem["systemID"], uncolonisedSystems[index]["systemID"]])

        if i % 1000 == 0:
            print(f"Processed {i} colonised systems")

    return systemsInRange

def WriteToCSV(outputFile, systemsInRange):
    with open(outputFile, "w", newline="") as file:
        writer = csv.writer(file)
        writer.writerows(systemsInRange)

RANGE = 15  # Range limit
COLONISED_FILE = "colonised.csv"
UNCOLONISED_FILE = "uncolonised.csv"
OUTPUT_FILE = "systemsInRange.csv"

# Read input files
colonisedSystems = ListDictReader(COLONISED_FILE)
uncolonisedSystems = ListDictReader(UNCOLONISED_FILE)

# Process with KDTree
systemsInRange = FindSystemsInRangeKDTree(colonisedSystems, uncolonisedSystems, RANGE)

# Write output
WriteToCSV(OUTPUT_FILE, systemsInRange)
print("Done!")
