locals {
  # Atlas regions by GCP locations
  atlas_regions = {
    # NA
    "us-central1"             = "CENTRAL_US"
    "us-east1"                = "EASTERN_US"
    "us-east4"                = "US_EAST_4"
    "us-east5"                = "US_EAST_5"
    "northamerica-northeast1" = "NORTH_AMERICA_NORTHEAST_1"
    "northamerica-northeast2" = "NORTH_AMERICA_NORTHEAST_2"
    "southamerica-east1"      = "SOUTH_AMERICA_EAST_1"
    "southamerica-west1"      = "SOUTH_AMERICA_WEST_1"
    "us-west1"                = "WESTERN_US"
    "us-west2"                = "US_WEST_2"
    "us-west3"                = "US_WEST_3"
    "us-west4"                = "US_WEST_4"
    "us-south1"               = "US_SOUTH_1"

    # EU
    "europe-west1"      = "WESTERN_EUROPE"
    "europe-north1"     = "EUROPE_NORTH_1"
    "europe-west2"      = "EUROPE_WEST_2"
    "europe-west3"      = "EUROPE_WEST_3"
    "europe-west4"      = "EUROPE_WEST_4"
    "europe-west6"      = "EUROPE_WEST_6"
    "europe-west10"     = "EUROPE_WEST_10"
    "europe-central2"   = "EUROPE_CENTRAL_2"
    "europe-west8"      = "EUROPE_WEST_8"
    "europe-west9"      = "EUROPE_WEST_9"
    "europe-west12"     = "EUROPE_WEST_12"
    "europe-southwest1" = "EUROPE_SOUTHWEST_1"

    # APAC
    "asia-east1"           = "EASTERN_ASIA_PACIFIC"
    "asia-east2"           = "ASIA_EAST_2"
    "asia-northeast1"      = "NORTHEASTERN_ASIA_PACIFIC"
    "asia-northeast2"      = "ASIA_NORTHEAST_2"
    "asia-northeast3"      = "ASIA_NORTHEAST_3"
    "asia-southeast1"      = "SOUTHEASTERN_ASIA_PACIFIC"
    "asia-south1"          = "ASIA_SOUTH_1"
    "asia-south2"          = "ASIA_SOUTH_2"
    "australia-southeast1" = "AUSTRALIA_SOUTHEAST_1"
    "australia-southeast2" = "AUSTRALIA_SOUTHEAST_2"
    "asia-southeast2"      = "ASIA-SOUTHEAST_2"

    # ME
    "me-west1"    = "MIDDLE_EAST_WEST_1"
    "me-central1" = "MIDDLE_EAST_CENTRAL_1"
    "me-central2" = "MIDDLE_EAST_CENTRAL_2"
  }

  atlas_copy_regions = {
    # NA
    "CENTRAL_US"                = "EASTERN_US"
    "EASTERN_US"                = "CENTRAL_US"
    "US_EAST_5"                 = "US_EAST_4"
    "US_EAST_4"                 = "US_EAST_5"
    "NORTH_AMERICA_NORTHEAST_1" = "NORTH_AMERICA_NORTHEAST_2"
    "NORTH_AMERICA_NORTHEAST_2" = "NORTH_AMERICA_NORTHEAST_1"
    "SOUTH_AMERICA_EAST_1"      = "SOUTH_AMERICA_WEST_1"
    "SOUTH_AMERICA_WEST_1"      = "SOUTH_AMERICA_EAST_1"
    "WESTERN_US"                = "US_WEST_2"
    "US_WEST_2"                 = "US_WEST_3"
    "US_WEST_3"                 = "US_WEST_4"
    "US_WEST_4"                 = "US_WEST_3"
    "US_SOUTH_1"                = "EASTERN_US"

    # EU
    "WESTERN_EUROPE"     = "EUROPE_WEST_2"
    "EUROPE_NORTH_1"     = "WESTERN_EUROPE"
    "EUROPE_WEST_2"      = "WESTERN_EUROPE"
    "EUROPE_WEST_3"      = "EUROPE_WEST_4"
    "EUROPE_WEST_4"      = "EUROPE_WEST_3"
    "EUROPE_WEST_6"      = "EUROPE_WEST_10"
    "EUROPE_WEST_10"     = "EUROPE_WEST_6"
    "EUROPE_CENTRAL_2"   = "EUROPE_WEST_8"
    "EUROPE_WEST_8"      = "EUROPE_WEST_9"
    "EUROPE_WEST_9"      = "EUROPE_WEST_8"
    "EUROPE_WEST_12"     = "EUROPE_WEST_9"
    "EUROPE_SOUTHWEST_1" = "WESTERN_EUROPE"

    # APAC
    "EASTERN_ASIA_PACIFIC"      = "ASIA_EAST_2"
    "ASIA_EAST_2"               = "EASTERN_ASIA_PACIFIC"
    "NORTHEASTERN_ASIA_PACIFIC" = "ASIA_NORTHEAST_2"
    "ASIA_NORTHEAST_2"          = "NORTHEASTERN_ASIA_PACIFIC"
    "ASIA_NORTHEAST_3"          = "ASIA_NORTHEAST_2"
    "SOUTHEASTERN_ASIA_PACIFIC" = "ASIA_SOUTH_1"
    "ASIA_SOUTH_1"              = "ASIA_SOUTH_2"
    "ASIA_SOUTH_2"              = "ASIA_SOUTH_1"
    "ASIA_SOUTHEAST_2"          = "ASIA_SOUTH_1"
    "AUSTRALIA_SOUTHEAST_1"     = "AUSTRALIA_SOUTHEAST_2"
    "AUSTRALIA_SOUTHEAST_2"     = "AUSTRALIA_SOUTHEAST_1"

    # ME
    "MIDDLE_EAST_WEST_1"    = "MIDDLE_EAST_WEST_1"
    "MIDDLE_EAST_CENTRAL_1" = "MIDDLE_EAST_CENTRAL_1"
    "MIDDLE_EAST_CENTRAL_2" = "MIDDLE_EAST_CENTRAL_2"
  }
}
