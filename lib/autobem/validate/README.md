# ValidateBSXMLs

## Operation
The AutoGenerateBEM functionality currently ONLY supports model creation through:
  1. Taking following inputs for specified building:
     * Input of NYC Building Identification Number (BIN)
     * directory containing `.osm` file for said building
     * directory containing BuildingSync `.xml` file for said building
  1. Reading basic building information from `.xml` file.
  1. Applying building defaults for input `.osm` file using `openstudio-standards`.
  1. Applying available information from input `.xml` file in place of defaults from `openstudio-standards` (e.g. define Wall Insulation U-Value if available in BuildingSync XML).

The functionality to run simulations will be added in the future, with calibration capabilities to be implemented in later stages.

## Usage

The following function is available
```ruby
autogenerateBEM(osmfolderorfile,bsxmlfolderorfile,bin)
```