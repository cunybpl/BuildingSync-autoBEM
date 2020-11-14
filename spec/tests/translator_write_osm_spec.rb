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
RSpec.describe 'BuildingSync' do
  it 'building_151.xml CA_TITLE24 - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'building_151.xml'
    std = CA_TITLE24
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = nil

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'building_151.xml ASHRAE90_1 - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'building_151.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = nil

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'L100_Audit.xml ASHRAE90_1 CZ01RV2.epw - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'L100_Audit.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'building_151_n1.xml CA_TITLE24 ns: n1 - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'building_151_n1.xml'
    std = CA_TITLE24
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = nil

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'DC GSA Headquarters.xml CA_TITLE24 CZ01RV2.epw - should error' do
    # -- Setup
    file_name = 'DC GSA Headquarters.xml'
    std = CA_TITLE24
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    begin
      translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
    rescue StandardError => e
      puts "rescued StandardError: #{e.message}"
      expect(e.message.include?("Did not find a class called 'CBES Pre-1978_LargeOffice' to create in")).to be true
    end
  end

  it 'DC GSA Headquarters.xml ASHRAE90_1 CZ01RV2.epw - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'DC GSA Headquarters.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'DC GSA HeadquartersWithClimateZone.xml ASHRAE90_1 CZ01RV2.epw - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'DC GSA HeadquartersWithClimateZone.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'BuildingSync Website Valid Schema.xml CA_TITLE24 CZ01RV2.epw - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'BuildingSync Website Valid Schema.xml'
    std = CA_TITLE24
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'BuildingSync Website Valid Schema.xml ASHRAE90_1 CZ01RV2.epw - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'BuildingSync Website Valid Schema.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'Golden Test File.xml ASHRAE90_1 CZ01RV2.epw - should error since there are 2 buildings defined' do
    # -- Setup
    file_name = 'Golden Test File.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')

    begin
      # -- Assert
      translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
    rescue StandardError => e
      puts "StandardError occured #{e.message}"
      expect(e.message.include?('Error: There is more than one (2) building attached to this site in your BuildingSync file.')).to be true
    end
  end

  it 'AT_example_property_report_25.xml ASHRAE90_1 CZ01RV2.epw - should error since there are 3 buildings defined' do
    # -- Setup
    file_name = 'AT_example_property_report_25.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = File.join('../weather', 'CZ01RV2.epw')
    begin
      # -- Assert
      translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
    rescue StandardError => e
      expect(e.message.include?('Error: There is more than one (3) building attached to this site in your BuildingSync file.')).to be true
    end
  end

  it 'L000_OpenStudio_Pre-Simulation_02.xml ASHRAE90_1 - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'L000_OpenStudio_Pre-Simulation_02.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = nil

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  it 'L000_OpenStudio_Pre-Simulation_03.xml ASHRAE90_1 - perform a sizing run, and create an in.osm' do
    # -- Setup
    file_name = 'L000_OpenStudio_Pre-Simulation_03.xml'
    std = ASHRAE90_1
    xml_path, output_path = create_xml_path_and_output_path(file_name, std)
    epw_path = nil

    # -- Assert
    translator_write_osm_and_perform_checks(xml_path, output_path, epw_path, std)
  end

  def create_xml_path_and_output_path(file_name, std)
    xml_path = File.expand_path("../files/#{file_name}", File.dirname(__FILE__))

    # The output path will look something like:
    # to/spec/output/translator_baseline_generation_spec/building_151/Caliornia
    output_path = File.join("../output", "#{File.basename(__FILE__ , File.extname(__FILE__ ))}/#{File.basename(xml_path, File.extname(xml_path))}")
    output_path = File.expand_path(output_path, File.dirname(__FILE__))
    output_path = File.join(output_path, "#{std.split('.')[0]}")

    return xml_path, output_path
  end
end
