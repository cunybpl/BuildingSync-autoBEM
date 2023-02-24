# AutoGenerateBEM

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

The project's current prototype workflow leverages [existing building geometry data from NYC Office of Technology and Innovation](https://www.nyc.gov/content/oti/pages/#digital-tools) in addition to energy audit data available on the [Audit Template (AT) web-tool](https://www.energy.gov/eere/buildings/audit-template). Sample files are provided in the examples section (link to be added).

The current workflow processes building geometry data through a Rhino + Grasshopper + Lady Bug Tools workflow to create an OpenStudio model containing geometry (with placeholders for `.osm` integrity. The audit data from AT is exported in BuildingSync XML format and input to this gem.

## Usage

The following function is available
```ruby
autogenerateBEM(osmfolderorfile,bsxmlfolderorfile,bin)
```
* `osmfolderorfile`: (String) the path to your `.osm` file or its containing folder.
* `bsxmlfolderorfile`: (String) the path to your `.xml` file or its containing folder.
* `bin`: (Optional argument)(String) your NYC building identification number (BIN). If entered, the function will search through your provided directories to open the `.osm` with provided BIN in its name, and open the `.xml` with provided BIN as a building identifier element. 