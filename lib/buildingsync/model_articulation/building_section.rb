# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# BuildingSync(R), Copyright (c) 2015-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************
require 'openstudio-standards'

require 'buildingsync/constants'
require 'buildingsync/helpers/helper'

module BuildingSync
  # BuildingSection class
  class BuildingSection < SpatialElement
    include OpenstudioStandards
    include BuildingSync::Helper
    include BuildingSync::XmlGetSet
    # initialize
    # @param base_xml [REXML:Element] an element corresponding to a single auc:Section
    # @param bldgsync_occ_type [String] Office, Retail, etc.
    # @param bldg_total_floor_area [Float]
    # @param num_stories [Float]
    # @param ns [String] namespace, likely 'auc'
    def initialize(base_xml, bldgsync_occ_type, bldg_total_floor_area, num_stories, ns)
      super(base_xml, ns)
      @base_xml = base_xml
      @ns = ns

      help_element_class_type_check(base_xml, 'Section')
      @door_ids = []
      @wall_ids = []
      @window_ids = []
      @roof_ids = []
      @skylight_ids = []
      @exterior_floor_ids = []
      @foundation_ids = []

      # parameter to read and write.
      @fraction_area = nil
      @bldg_type = {}
      @standards_building_type = nil
      @occupancy_classification_original = nil
      @typical_occupant_usage_value_hours = nil
      @typical_occupant_usage_value_weeks = nil
      @occupant_quantity = nil
      @section_type = nil
      @footprint_shape = nil
      @principal_hvac_type = nil
      @principal_lighting_system_type = nil
      @miscellaneous_electric_load = nil
      @spaces_conditioned_percent = nil
      @dwelling_quantity = nil
      @dwellings_occupied_percent = nil
      @num_stories = num_stories

      # code to initialize
      read_xml(bldgsync_occ_type, bldg_total_floor_area)
    end

    # read xml
    # @param bldgsync_occ_type [String]
    # @param bldg_total_floor_area [Float]
    def read_xml(bldgsync_occ_type, bldg_total_floor_area)

      # floor areas
      @total_floor_area = read_floor_areas(bldg_total_floor_area)
      # based on the occupancy type set building type, system type and bar division method
      read_bldg_system_type_based_on_occupancy_type(bldgsync_occ_type)
      read_building_section_type
      read_building_section_other_detail
      read_footprint_shape
      read_principal_hvac_type
      read_construction_types

      if @base_xml.elements["#{@ns}:OccupancyLevels/#{@ns}:OccupancyLevel/#{@ns}:OccupantQuantity"]
        @occupant_quantity = @base_xml.elements["#{@ns}:OccupancyLevels/#{@ns}:OccupancyLevel/#{@ns}:OccupantQuantity"].text
      else
        @occupant_quantity = nil
      end
    end

    # read building system type based on occupancy type
    # @param bldgsync_occ_type [String]
    def read_bldg_system_type_based_on_occupancy_type(bldgsync_occ_type)
      @bldgsync_occupancy_type = read_bldgsync_occupancy_type(bldgsync_occ_type)
    end

    # read building section type
    def read_building_section_type
      if @base_xml.elements["#{@ns}:SectionType"]
        @section_type = @base_xml.elements["#{@ns}:SectionType"].text
      else
        @section_type = nil
      end
    end

    # read footprint shape
    def read_footprint_shape
      if @base_xml.elements["#{@ns}:FootprintShape"]
        @footprint_shape = @base_xml.elements["#{@ns}:FootprintShape"].text
      else
        @footprint_shape = nil
      end
    end

    # read building section other details
    def read_building_section_other_detail
      if @base_xml.elements["#{@ns}:TypicalOccupantUsages"]
        @base_xml.elements.each("#{@ns}:TypicalOccupantUsages/#{@ns}:TypicalOccupantUsage") do |occ_usage|
          if occ_usage.elements["#{@ns}:TypicalOccupantUsageUnits"].text == 'Hours per week'
            @typical_occupant_usage_value_hours = occ_usage.elements["#{@ns}:TypicalOccupantUsageValue"].text
          elsif occ_usage.elements["#{@ns}:TypicalOccupantUsageUnits"].text == 'Weeks per year'
            @typical_occupant_usage_value_weeks = occ_usage.elements["#{@ns}:TypicalOccupantUsageValue"].text
          end
        end
      end

      if @base_xml.elements["#{@ns}:OccupancyLevels"]
        @base_xml.elements.each("#{@ns}:OccupancyLevels/#{@ns}:OccupancyLevel") do |occ_level|
          if occ_level.elements["#{@ns}:OccupantQuantityType"].text == 'Peak total occupants'
            @occupant_quantity = occ_level.elements["#{@ns}:OccupantQuantity"].text
          end
        end
      end
    end

    # read principal hvac type
    def read_principal_hvac_type
      if @base_xml.elements["#{@ns}:UserDefinedFields"]
        @base_xml.elements.each("#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField") do |user_defined_field|
          if user_defined_field.elements["#{@ns}:FieldName"].text == 'Principal HVAC System Type'
            @principal_hvac_type = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Principal Lighting System Type'
            @principal_lighting_system_type = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Miscellaneous Electric Load'
            @miscellaneous_electric_load = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Original Occupancy Classification'
            @occupancy_classification_original = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Percentage Dwellings Occupied'
            @spaces_conditioned_percent = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Quantity Of Dwellings'
            @dwelling_quantity = user_defined_field.elements["#{@ns}:FieldValue"].text
          elsif user_defined_field.elements["#{@ns}:FieldName"].text == 'Percentage Dwellings Occupied'
            @dwellings_occupied_percent = user_defined_field.elements["#{@ns}:FieldValue"].text
          end
        end
      end
    end

    # read construction types
    def read_construction_types
      if @base_xml.elements["#{@ns}:Sides"]
        @base_xml.elements.each("#{@ns}:Sides/#{@ns}:Side/#{@ns}:DoorID") do |door|
          @door_ids.push(door.attributes['IDref'])
        end
        @base_xml.elements.each("#{@ns}:Sides/#{@ns}:Side/#{@ns}:WallID") do |wall|
          @wall_ids.push(wall.attributes['IDref'])
        end
        @base_xml.elements.each("#{@ns}:Sides/#{@ns}:Side/#{@ns}:WindowID") do |window|
          @window_ids.push(window.attributes['IDref'])
        end
      end
      if @base_xml.elements["#{@ns}:Roofs"]
        @base_xml.elements.each("#{@ns}:Roofs/#{@ns}:Roof/#{@ns}:RoofID") do |roof|
          @roof_ids.push(roof.attributes['IDref'])
        end
        @base_xml.elements.each("#{@ns}:Roofs/#{@ns}:Roof/#{@ns}:RoofID/#{@ns}:SkylightIDs/#{@ns}:SkylightID") do |skylight|
          @skylight_ids.push(skylight.attributes['IDref'])
        end
      end
      if @base_xml.elements["#{@ns}:ExteriorFloors"]
        @base_xml.elements.each("#{@ns}:ExteriorFloors/#{@ns}:ExteriorFloor/#{@ns}:ExteriorFloorID ") do |floor|
          @exterior_floor_ids.push(floor.attributes['IDref'])
        end
      end
      if @base_xml.elements["#{@ns}:Foundations"]
        @base_xml.elements.each("#{@ns}:Foundations/#{@ns}:Foundation/#{@ns}:FoundationID  ") do |foundation|
          @foundation_ids.push(foundation.attributes['IDref'])
        end
      end
    end

    # add principal hvac type
    def add_principal_hvac_type
      building_sections = building_section.parent
      building = building_sections.parent
      buildings = building.parent
      site = buildings.parent
      sites = site.parent
      facility = sites.parent

      if facility.elements["#{@ns}:Systems"].nil?
        systems = REXML::Element.new("#{@ns}:Systems")
        facility.add_element(systems)
      else
        systems = facility.elements["#{@ns}:Systems"]
      end

      if systems.elements["#{@ns}:HVACSystems"].nil?
        hvac_systems = REXML::Element.new("#{@ns}:HVACSystems")
        systems.add_element(hvac_systems)
      else
        hvac_systems = facility.elements["#{@ns}:HVACSystems"]
      end

      if hvac_systems.elements["#{@ns}:HVACSystem"].nil?
        hvac_system = BuildingSync::HVACSystem.new
      else
        hvac_system = facility.elements["#{@ns}:HVACSystem"]
      end

      hvac_system.add_principal_hvac_system_type(xget_id, @principal_hvac_type)
    end

    # add principal hvac type
    def prepare_final_xml
      @base_xml.elements["#{@ns}:fraction_area"].text = @fraction_area
      @base_xml.elements["#{@ns}:OriginalOccupancyClassification"].text = @occupancy_classification_original if !@occupancy_classification_original.nil?

      add_principal_hvac_type if !@principal_hvac_type.nil?

      @base_xml.elements["#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField/#{@ns}:FieldValue"].text = @principal_lighting_system_type if !@principal_lighting_system_type.nil?
      @base_xml.elements["#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField/#{@ns}:FieldValue"].text = @miscellaneous_electric_load if !@miscellaneous_electric_load.nil?
      @base_xml.elements["#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField/#{@ns}:FieldValue"].text = @spaces_conditioned_percent if !@spaces_conditioned_percent.nil?
      @base_xml.elements["#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField/#{@ns}:FieldValue"].text = @dwelling_quantity if !@dwelling_quantity.nil?
      @base_xml.elements["#{@ns}:UserDefinedFields/#{@ns}:UserDefinedField/#{@ns}:FieldValue"].text = @dwellings_occupied_percent if !@dwellings_occupied_percent.nil?
      @base_xml.elements["#{@ns}:TypicalOccupantUsages/#{@ns}:TypicalOccupantUsage/#{@ns}:TypicalOccupantUsageValue"].text = @typical_occupant_usage_value_hours if !@typical_occupant_usage_value_hours.nil?
      @base_xml.elements["#{@ns}:TypicalOccupantUsages/#{@ns}:TypicalOccupantUsage/#{@ns}:TypicalOccupantUsageValue"].text = @typical_occupant_usage_value_weeks if !@typical_occupant_usage_value_weeks.nil?
      @base_xml.elements["#{@ns}:OccupancyLevels/#{@ns}:OccupancyLevel/#{@ns}:OccupantQuantity"].text = @occupant_quantity if !@occupant_quantity.nil?
      @base_xml.elements["#{@ns}:FootprintShape"].text = @footprint_shape if !@footprint_shape.nil?
      @base_xml.elements["#{@ns}:SectionType"].text = @section_type if !@section_type.nil?

      # Add new element in the XML file
      add_user_defined_field_to_xml_file('BuildingType', @bldg_type)
      add_user_defined_field_to_xml_file('FractionArea', @fraction_area)

      prepare_final_xml_for_spatial_element
    end

    # set building and system type
    def set_bldg_and_system_type
      super(@bldgsync_occupancy_type, @total_floor_area, @number_floors, false)
    end

    # get peak occupancy
    # @return [String]
    def get_peak_occupancy
      return @occupant_quantity
    end

    # get floor area of this building section
    # @return [Float]
    def get_floor_area
      return @total_floor_area
    end

    attr_reader :bldg_type, :space_types_floor_area, :occupancy_classification, :typical_occupant_usage_value_weeks, :typical_occupant_usage_value_hours, :standards_building_type, :bldgsync_occupancy_type, :section_type, :id
    attr_accessor :fraction_area
  end
end
