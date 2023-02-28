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

module BuildingSync
  module AutoGenerateBEM
    include BuildingSync::Helper
    include BuildingSync::ToolkitForBSXMLs
    include REXML

    # @param osmfolderorfile [String] : path to folder containing OSMs generated from geometry workflow
    # @param bsxmlfolderorfile [String] : path to folder containing BSXMLs of desired bldg portfolio
    # @param bin [String] : (Optional) Building Identification Number used to open the associated OSM & BSXML
    def autogenerateBEM(osmfolderorfile,bsxmlfolderorfile,bin="")
      
      # defined here as many methods take it as argument
      ns = "auc"
      
      # Hash that toggles what to modify based on info from BSXML (e.g., envelope systems, etc.)
      modhash = populatemodhash
      
      model = open_OSM_by_BIN(osmfolderorfile,bin) # @return OpenStudio::Model
      
      # @return REXML::Document
      bsxmldoc =  case bin
                  when bin.empty?
                    help_load_doc(bsxmlfolderorfile)
                  else
                    open_bsxml_by_BIN(bsxmlfolderorfile,bin)
                  end
      #
      
      workflow = BuildingSync::WorkflowMaker.new(bsxmldoc,ns)
      
      if modhash["envelope"]
        
        # Reading from BSXML
        # BuildingSync::WorkflowMaker initializes BuildingSync::Facility
        # BuildingSync::Facility initializes BuildingSync::Site
        # BuildingSync::Site initializes BuildingSync::Building
        # BuildingSync::Building initializes BuildingSync::BuildingSection
        
        # The #read_xml method appears in different BuildingSync classes & for some reason returns the defined child (e.g below)
        # BuildingSync::WorkflowMaker.get_facility -> BuildingSync::Facility.read_xml -> BuildingSync::Site.get_building_sections
        workflow.get_facility.read_xml
        sections = workflow.get_facility.site.get_building_sections
        
        
        
        # {section id => {envelope component => [envelope_component objects],…},…}
        sections_envelope_objs = {}
        # counter
        objs_built = 0 
        
        sections.each do |sec|
          # Hash to sort envelope objects
          section_envelope_objs_template = {
            "doors" => [],
            "walls" => [],
            "windows" => [],
            "roofs" => [],
            "foundations" => []
          }
          sections_envelope_objs.merge!({sec.id => section_envelope_objs_template})

          # Accessing ids of constructions in BuildingSync::BuildingSection objects defined from auc:Section elements
          section_envelope_ids = {}
          section_envelope_ids["doors"] = sec.door_ids # become BuildingSync::FenestrationSystemType
          section_envelope_ids["walls"] = sec.wall_ids # BuildingSync::WallSystemType
          section_envelope_ids["windows"] = sec.window_ids # become BuildingSync::FenestrationSystemType
          section_envelope_ids["roofs"] = sec.roof_ids # become BuildingSync::RoofSystemType
          section_envelope_ids["foundations"] = sec.foundation_ids # become BuildingSync::FoundationSystemType
          
          total_objs_to_build = 0
          section_envelope_ids.each {|k,v| total_objs_to_build += v.length}

          # Signal that this section has constructions. This will pass it to be used for BuildingSync::EnvelopeSystem.modify
          if total_objs_to_build > 0
            sec.has_constructions = true
          end

          puts "Your total objects to build in #{sec.id} are #{total_objs_to_build}"
        
          section_envelope_ids.each_key do |comp|
            unless section_envelope_ids[comp].empty?
              section_envelope_ids[comp].each do |id|
                
                # Building envelope components as BuildingSync Objects & adding to hash of Section
                built_object = build_envelope_object(bsxmldoc,ns,comp,id)
                sections_envelope_objs[sec.id][comp].concat([built_object])
                
                objs_built += 1
                puts "A total of #{objs_built} built so far."
              end
            end
          end

          # Adding built objects to BuildingSync::BuildingSection Objects
          sec.door_objs = sections_envelope_objs[sec.id]["doors"]
          sec.wall_objs = sections_envelope_objs[sec.id]["walls"]
          sec.window_objs = sections_envelope_objs[sec.id]["windows"]
          sec.roof_objs = sections_envelope_objs[sec.id]["roofs"]
          sec.foundation_objs = sections_envelope_objs[sec.id]["foundations"]
          
        end
        
        # Writing to OSM
        sections.each do |sec|
          unless sec.occupancy_classification.nil?
            sec.set_bldg_and_system_type
            primary_bldg_type = sec.standards_building_type
            # This is defined in BuildingSync::Facility
            # open_studio_system_standard is determined in BuildingSync::Facility.rb:307
            # open_studio_system_standard = determine_open_studio_system_standard
            # determine_open_studio_system_standard is a method in BuildingSync::Site which accesses methods in BuildingSync::Building
            # determine_open_studio_system_standard takes in standard_to_be_used which should be ASHRAE90_1
            # determine_open_studio_system_standard then needs building_type which needs standards_building_type from BuildingSync::BuildingSection
            workflow.get_facility.create_building_systems(autobem_inputmodel: model, autobem_primary_bldg_type: primary_bldg_type, add_space_type_loads: true, add_constructions: true, add_swh: true)
          end
        end
      end

      # Saving modified OSM
      basename = ""
      unless bin.empty?
        basename = "AutoBEM_modified_#{bin}"
      else
        basename = "AutoBEM_modified#{File.basename(osmfolderorfile)}"
      end
      model.save("#{osmfolderorfile}/#{basename}.osm",true)  
      
    end
    # END MODHASH[ENVELOPE]
    
    # @return modhash [Hash] : hash of boolean values to bldg component keys defining what available BSXML data will affect input OSM
    def populatemodhash
      modhash = {"envelope" => false, "hvacsystem" => false, "powergen" => false}
      
      puts "\nThe available building components to modify are #{modhash.keys}. Enter a string of #{modhash.keys.length} characters composed of 't' (true) & 'f' (false) based on components you wish to modify in the OSM based on the BSXMl.\n\n"
      
      modstring = gets.strip
      until modstring.length == modhash.keys.length
        puts "Please enter a string of #{modhash.keys.length} characters.\n\n"
        modstring = gets.strip
      end
      until modstring.chars.all? {|char| char == "t" || char == "f"} 
        puts "Please enter a string only containing 't' and 'f'.\n\n"
        modstring = gets.strip
      end
      
      modhash.each_key do |comp|
        comp_index = modhash.keys.find_index(comp)
        modhash[comp] = true if modstring[comp_index] == 't'
        modhash[comp] = false if modstring[comp_index] == 'f'
      end
      
      tochange = modhash.select {|k,v| v == true}
      nottochange = modhash.select {|k,v| v == false}
      puts "\nBuilding components to change are #{tochange.keys}\nBuilding components unchanged are #{nottochange.keys}.\n"
      
      return modhash
    end
    
    # @param component [String] the desired envelope category
    # @param id [String] the IDref in BSXML for object to be built
    def build_envelope_object(bsxmldoc,ns,component,id)
      case component
      when "doors"
        return object = BuildingSync::FenestrationSystemType.new(bsxmldoc,ns,id)
      when "walls"
        return object = BuildingSync::WallSystemType.new(bsxmldoc,ns,id)
      when "windows"
        return object = BuildingSync::FenestrationSystemType.new(bsxmldoc,ns,id)
      when "roofs"
        return object = BuildingSync::RoofSystemType.new(bsxmldoc,ns,id)
      when "foundations"
        return object = BuildingSync::FoundationSystemType.new(bsxmldoc,ns,id)
      end
    end
    
    # @param osmfolderorfile [String] : path to folder containing OSMs generated from geometry workflow
    ## filenames must contain BIN
    # @param bin [String] : (Optional) Building Identification Number used to open the associated OSM
    # @return model [OpenStudio::Model]
    def open_OSM_by_BIN(osmfolderorfile,bin="")
      path = ""
      if osmfolderorfile.include? ".osm"
        path = OpenStudio::Path.new(osmfolderorfile)
      else
        Dir.glob(["#{osmfolderorfile}/*.osm"]) do |osm|
          if File.basename(osm).include? bin
            path = OpenStudio::Path.new(osm)
          end
        end
      end
      translator = OpenStudio::OSVersion::VersionTranslator.new
      return model = translator.loadModel(path).get
    end
    
    
  end
end