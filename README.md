# AutoBEM-Gem

<!-- ![BuildingSync-gem](https://github.com/BuildingSync/BuildingSync-gem/actions/workflows/continuous_integration.yml/badge.svg?branch=develop) -->

This repository is created under the AutoBEM project and is home to tools useful in translating BuildingSync XML files to OpenStudio energy models. Namely:
* [generate](/lib/autobem/generate/): the auto-generate-BEM function
* [analyze](lib/autobem/analyze/): a BSXML analysis toolkit (for use with multiple files)
* [validate](lib/autobem/validate/): a BSXML validator interface

The AutoBEM project is a workflow for (semi-)automatic creation, simulation, and calibration of OpenStudio building energy models. This is accomplished by by merging building geometry data and BuildingSync XML files. The translation of BuildingSync XML elements to be merged with OpenStudio geometry (the main purpose of this repo) is a contribution to existing functionalities of [BuildingSync-Gem](https://github.com/BuildingSync/BuildingSync-gem). 

This workflow is prototyped by CUNY Building Performance Lab for the energy modeling of a large portfolio of municipal buildings managed by New York City's Department of Citywide Administrative Services (DCAS) Division of Energy Management (DEM).

## Installation
### Prerequisites
BuildingSync-autoBEM requires installation of Ruby and OpenStudio and currently uses Ruby 2.7.x and OpenStudio 3.5.x. Checking the [OpenStudio Compatibility Matrix](https://github.com/NREL/OpenStudio/wiki/OpenStudio-SDK-Version-Compatibility-Matrix) is recommended.

For MacOS, set your Terminal to use a bash shell, and to set the Ruby environment variable (telling Ruby where to find OpenStudio, this should be your OpenStudio installation path) by adding the following line to your `.bash_profile` file:
```
export RUBYLIB=/Applications/OpenStudio-3.5.1/Ruby
```
For Windows, this is achieved by running the following command
```
SETX PATH “%PATH%;C:\openstudio-3.5.1”
```
### AutoBEM
BuildingSync-autoBEM tools currently work as command line interfaces. Clone the repository to your device or download a copy. Thereafter, to access the functionalities of this repo, you can use an Interactive Ruby (irb) shell & copy the following command when :
```ruby
load 'path/to/BuildingSync-autoBEM/lib/autobem.rb'
```
For simplicity, AutoBEM can launch with a 'double click' if you use the `.command` or `.bat` files, for MacOS and Windows respectively.
To enable this on MacOS, navigate to the autobem subdirectory in Terminal and make the `useautobem` file executable by running:
```
chmod 755 useautobem.command
```

## Usage

As mentioned, using AutoBEM can be done with loading `autobem.rb` or 'double clicking' the executable files. To learn more about using the unique functionalities of the AutoBEM Gem, please visit the corresponding READMEs in [generate](/lib/autobem/generate/), [analyze](lib/autobem/analyze/), and [validate](lib/autobem/validate/) subdirectories.
