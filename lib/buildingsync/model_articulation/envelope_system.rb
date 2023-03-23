# frozen_string_literal: true

# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
# BuildingSync(R), Copyright (c) 2015-2022, Alliance for Sustainable Energy, LLC.
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

require_relative 'building_system'
module BuildingSync
  # EnvelopeSystem class
  class EnvelopeSystem < BuildingSystem
    # initialize
    def initialize
      # code to initialize
    end

    # add internal loads from standard definitions
    # @param model [OpenStudio::Model]
    # @param standard [Standard]
    # @param primary_bldg_type [String]
    # @param lookup_building_type [String]
    # @param remove_objects [Boolean]
    # @return [Boolean]

    ### standard should be taken care of by default
    ### primary
    def create(model, standard, primary_bldg_type, lookup_building_type, remove_objects)
      # remove default construction sets
      if remove_objects
        model.getDefaultConstructionSets.each(&:remove)
      end

      # TODO: - allow building type and space type specific constructions set selection.
      if ['SmallHotel', 'LargeHotel', 'MidriseApartment', 'HighriseApartment'].include?(primary_bldg_type)
        is_residential = 'Yes'
      else
        is_residential = 'No'
      end
      ### Changed to proper function. Maybe because new version of openstudio-standards?
      ### This was old function: climate_zone = standard.model_get_building_climate_zone_and_building_type(model)['climate_zone']
      climate_zone = standard.model_get_building_properties(model)['climate_zone']
      OpenStudio.logFree(OpenStudio::Error, 'BuildingSync.Facility.create_building_system', 'Could not find climate zone in the model. Verify that the climate zone is set in the BuildingSync File or can be derived from other inputs.') if climate_zone.nil?
      bldg_def_const_set = standard.model_add_construction_set(model, climate_zone, lookup_building_type, nil, is_residential)
      if bldg_def_const_set.is_initialized
        bldg_def_const_set = bldg_def_const_set.get
        if is_residential then bldg_def_const_set.setName("Res #{bldg_def_const_set.name}") end
        model.getBuilding.setDefaultConstructionSet(bldg_def_const_set)
        OpenStudio.logFree(OpenStudio::Info, 'BuildingSync.Facility.create_building_system', "Adding default construction set named #{bldg_def_const_set.name}")
        puts "Adding default construction set named #{bldg_def_const_set.name} in climate zone #{climate_zone}"
      else
        OpenStudio.logFree(OpenStudio::Error, 'BuildingSync.Facility.create_building_system', "Could not create default construction set for the building type #{lookup_building_type} in climate zone #{climate_zone}.")
        return false
      end

      # address any adiabatic surfaces that don't have hard assigned constructions
      model.getSurfaces.each do |surface|
        next if surface.outsideBoundaryCondition != 'Adiabatic'
        next if surface.construction.is_initialized

        surface.setAdjacentSurface(surface)
        surface.setConstruction(surface.construction.get)
        surface.setOutsideBoundaryCondition('Adiabatic')
      end

      # Modify the infiltration rates
      if remove_objects
        model.getSpaceInfiltrationDesignFlowRates.each(&:remove)
      end
      standard.model_apply_infiltration_standard(model)
      standard.model_modify_infiltration_coefficients(model, primary_bldg_type, climate_zone)

      # set ground temperatures from DOE prototype buildings
      standard.model_add_ground_temperatures(model, primary_bldg_type, climate_zone)
    end


    ### This function will maintain that openstudio-standards is used to create & assign the default constructions
    ### and will add OpenStudio envelope objects when BuildingSync::Section objects have associated envelope objects
    ### (BuildingSync::WallSystemType + BuildingSync::RoofSystemType + BuildingSync::FenestrationSystemType + BuildingSync::FoundationSystemType)
    ### with defined (Insulation) R Values
    def create_bsxml_envelope(model,standard,section)
      
      puts "Now setting constructions thermal properties according to BSXML information.\n"
      puts "Keep in mind that currently only one envelope object (of a certain category (e.g. wall)) sets properties for the whole building."

      ### Doors
      ### Mar 23 : I realized Audit Template only sets door type when entering info for walls but never more info
      doors_with_defined_u_value = section.door_objs.select {|model_door| !model_door.fenestrationUFactor.nil?}
      unless doors_with_defined_u_value.empty?

        u_value = doors_with_defined_u_value.first.fenestrationUFactor
        
        model_doors = standard.model_find_constructions(model, "Outdoors", "ExteriorDoor")
        
        model_doors.each do |model_door|
          model_door = model_door.to_Construction.get
          
          ### I'm doing this because the usage in Standards.Construction.rb#construction_set_u_value is faulty
          insulation_layer = standard.find_and_set_insulation_layer(model_door).name
          standard.construction_set_glazing_u_value(model_door,u_value,insulation_layer_name=insulation_layer,false,false)
          puts "Your doors are being set to U Value of #{u_value} according to the BSXML object #{doors_with_defined_u_value.first.id}"
        end
      else
        puts "You have no BSXML door elements with defined Insulation R Values. No door insulation properties will be changed."
      end

      ### Walls
      walls_with_defined_insulation = section.wall_objs.select {|model_ext_wall| !model_ext_wall.wallInsulationRValue.nil?}
      unless walls_with_defined_insulation.empty?

        r_value = walls_with_defined_insulation.first.wallInsulationRValue
        u_value = 1/r_value # converting because Standards function takes u_value
        
        model_ext_walls = standard.model_find_constructions(model, "Outdoors", "ExteriorWall")
        
        model_ext_walls.each do |model_ext_wall|
          model_ext_wall = model_ext_wall.to_Construction.get
          model_ext_wall.setName("BSXML #{walls_with_defined_insulation.first.id}")
          
          ### I'm doing this because the usage in Standards.Construction.rb#construction_set_u_value is faulty
          insulation_layer = standard.find_and_set_insulation_layer(model_ext_wall).name
          standard.construction_set_u_value(model_ext_wall,u_value,insulation_layer_name=insulation_layer,false,false)
          puts "Your exterior walls are being set to R Value of #{r_value} according to the BSXML object #{walls_with_defined_insulation.first.id}"
        end
      else
        puts "You have no BSXML exterior wall elements with defined Insulation R Values. No wall insulation properties will be changed."
      end

      ### Windows
      windows_with_defined_relevant_values = section.window_objs.select {
        |model_window| 
        !model_window.fenestrationUFactor.nil? || !model_window.fenestrationSHGC.nil? || !model_window.fenestrationTvis.nil?
      }
      unless windows_with_defined_relevant_values.empty?

        u_value = windows_with_defined_relevant_values.first.fenestrationUFactor
        shgc = windows_with_defined_relevant_values.first.fenestrationSHGC
        tvis = windows_with_defined_relevant_values.first.fenestrationTvis
        
        model_windows = standard.model_find_constructions(model, "Outdoors", "ExteriorWindow")
        
        model_windows.each do |model_window|
          model_window = model_window.to_Construction.get
          model_window.setName("BSXML #{windows_with_defined_relevant_values.first.id}")
          
          unless u_value.nil?
            standard.construction_set_glazing_u_value(model_window,u_value,'ExteriorWall', false, false)
            puts "Your windows are being set to U Value of #{u_value} according to the BSXML object #{windows_with_defined_relevant_values.first.id}"
          end
          unless shgc.nil?
            standard.construction_set_glazing_shgc(model_window,shgc)
            puts "Your windows are being set to solar heat gain coefficient value of #{shgc} according to the BSXML object #{windows_with_defined_relevant_values.first.id}"
          end
          unless u_value.nil?
            standard.construction_set_glazing_tvis(model_window,tvis)
            puts "Your windows are being set to visible transmittance of #{u_value} according to the BSXML object #{windows_with_defined_relevant_values.first.id}"
          end

        end
      else
        puts "You have no BSXML window elements with defined U Values. No window U Value properties will be changed."
      end
        
      ### Roofs
      roofs_with_defined_insulation = section.roof_objs.select {|model_ext_roof| !model_ext_roof.roofInsulationRValue.nil?}
      unless roofs_with_defined_insulation.empty?

        r_value = roofs_with_defined_insulation.first.roofInsulationRValue
        u_value = 1/r_value # converting because Standards function takes u_value
        
        model_ext_roofs = standard.model_find_constructions(model, "Outdoors", "ExteriorRoof")
        
        model_ext_roofs.each do |model_ext_roof|
          model_ext_roof = model_ext_roof.to_Construction.get
          model_ext_roof.setName("BSXML #{roofs_with_defined_insulation.first.id}")
          
          ### I'm doing this because the usage in Standards.Construction.rb#construction_set_u_value is faulty
          insulation_layer = standard.find_and_set_insulation_layer(model_ext_roof).name
          standard.construction_set_u_value(model_ext_roof,u_value,insulation_layer_name=insulation_layer,false,false)
          puts "Your roofs are being set to R Value of #{r_value} according to the BSXML object #{roofs_with_defined_insulation.first.id}"

        end
      else
        puts "You have no BSXML roof elements with defined Insulation R Values. No roof insulation properties will be changed."
      end
      
      ### Skylights
      ### Support to be added in the future as they aren't required in Audit Template
        
      ### Foundations
      foundations_with_defined_r_value = section.foundation_objs.select {|model_ext_foundation| !model_ext_foundation.foundationRValue.nil?}
      unless foundations_with_defined_r_value.empty?

        r_value = foundations_with_defined_r_value.first.foundationRValue
        u_value = 1/r_value # converting because Standards function takes u_value
        
        model_foundations = standard.model_find_constructions(model, "Ground", "GroundContactFloor")
        
        model_foundations.each do |model_foundation|
          model_foundation = model_ext_foundation.to_Construction.get
          model_foundation.setName("BSXML #{foundations_with_defined_r_value.first.id}")
          
          ### I'm doing this because the usage in Standards.Construction.rb#construction_set_u_value is faulty at the moment
          insulation_layer = standard.find_and_set_insulation_layer(model_ext_foundation).name
          standard.construction_set_u_value(model_ext_foundation,u_value,insulation_layer_name=insulation_layer,false,false)
          puts "Your foundations are being set to R Value of #{r_value} according to the BSXML object #{foundations_with_defined_r_value.first.id}"
        end
      else
        puts "You have no BSXML foundation elements with defined Insulation R Values. No foundation insulation properties will be changed."
      end

    end

  end
end
