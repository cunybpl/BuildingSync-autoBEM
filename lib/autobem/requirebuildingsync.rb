require 'openstudio'

require 'fileutils'

# Simplify require statements
libfilepath = File.expand_path("../../lib",__dir__)
$LOAD_PATH.unshift(libfilepath)

require 'buildingsync/helpers/helper'
require 'buildingsync/helpers/xml_get_set'
require 'buildingsync/helpers/Model.hvac'

require 'buildingsync/makers/workflow_maker_base'

require 'buildingsync/translator'
require 'buildingsync/constants'
require 'buildingsync/version'
require 'buildingsync/extension'
require 'buildingsync/all_resource_total'
require 'buildingsync/audit_date'
require 'buildingsync/contact'
require 'buildingsync/selection_tool'
require 'buildingsync/time_series'
require 'buildingsync/utility'
require 'buildingsync/resource_use'
require 'buildingsync/get_bcl_weather_file'
require 'buildingsync/generator'
require 'buildingsync/scenario'
require 'buildingsync/report'

require 'buildingsync/model_articulation/spatial_element'
require 'buildingsync/model_articulation/building_section'
require 'buildingsync/model_articulation/location_element'
require 'buildingsync/model_articulation/measure'
require 'buildingsync/model_articulation/lighting_system'
require 'buildingsync/model_articulation/building_system'
require 'buildingsync/model_articulation/loads_system'
require 'buildingsync/model_articulation/hvac_system'
require 'buildingsync/model_articulation/service_hot_water_system'
require 'buildingsync/model_articulation/envelope_system'
require 'buildingsync/model_articulation/foundation_system_type'
require 'buildingsync/model_articulation/wall_system_type'
require 'buildingsync/model_articulation/fenestration_system_type'
require 'buildingsync/model_articulation/roof_system_type'
require 'buildingsync/model_articulation/exterior_floor_system_type'
require 'buildingsync/model_articulation/building'
require 'buildingsync/model_articulation/site'
require 'buildingsync/model_articulation/facility'

require 'buildingsync/makers/workflow_maker'