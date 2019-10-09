# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# BuildingSync(R), Copyright (c) 2015-2019, Alliance for Sustainable Energy, LLC.
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
require_relative './../spec_helper'

require 'fileutils'
require 'parallel'

RSpec.describe 'BuildingSync' do
  it 'should parse and write building_151.xml (phase zero) with auc namespace for CAT24 and perform a baseline simulation' do
    osm_path = test_baseline_creation('building_151.xml', CA_TITLE24)

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')
  end

  it 'should parse and write building_151.xml (phase zero) with auc namespace for ASHRAE 90.1 and perform a baseline simulation' do
    osm_path = test_baseline_creation('building_151.xml', ASHRAE90_1)

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')
  end

  it 'should parse and write DC GSA Headquarters.xml (phase zero) with ASHRAE 90.1 and perform a baseline simulation' do
    osm_path = test_baseline_creation('DC GSA Headquarters.xml', ASHRAE90_1, 'CZ01RV2.epw')

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')
  end

  it 'should parse and write BuildingSync Website Valid Schema.xml (phase zero) with Title 24 and perform a baseline simulation' do
    osm_path = test_baseline_creation('BuildingSync Website Valid Schema.xml', CA_TITLE24, 'CZ01RV2.epw')

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')
  end

  it 'should parse and write BuildingSync Website Valid Schema.xml (phase zero) with ASHRAE 90.1 and perform a baseline simulation' do
    osm_path = test_baseline_creation('BuildingSync Website Valid Schema.xml', ASHRAE90_1, 'CZ01RV2.epw')

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')
  end

  it 'should parse and write Golden Test File.xml (phase zero) with  Title 24 and perform a baseline simulation' do
    begin
      osm_path = test_baseline_creation('Golden Test File.xml', CA_TITLE24, 'CZ01RV2.epw')

      run_baseline_simulation(osm_path, 'CZ01RV2.epw')
    rescue StandardError => e
      expect(e.message.include?('Error: There is more than one (2) building attached to this site in your BuildingSync file.')).to be true
    end
  end

  it 'should parse and write AT_example_property_report_25.xml (phase zero) with ASHRAE 90.1 and perform a baseline simulation' do
    begin
      osm_path = test_baseline_creation('AT_example_property_report_25.xml', ASHRAE90_1, 'CZ01RV2.epw')

      run_baseline_simulation(osm_path, 'CZ01RV2.epw')
    rescue StandardError => e
      expect(e.message.include?('Error: There is more than one (3) building attached to this site in your BuildingSync file.')).to be true
    end
  end

  it 'should parse and write AT_example_report_332.xml (phase zero) with ASHRAE 90.1 and perform a baseline simulation' do
    begin
      osm_path = test_baseline_creation('AT_example_report_332.xml', ASHRAE90_1, 'CZ01RV2.epw')

      run_baseline_simulation(osm_path, 'CZ01RV2.epw')
    rescue StandardError => e
      expect(e.message.include?('Occupancy type Food service is not available in the bldg_and_system_types.json dictionary')).to be true
    end
  end

  it 'should parse and write building_151.xml (phase zero) with auc namespace for CAT24, perform a baseline simulation and gather results' do
    xml_path = File.expand_path('./../files/building_151.xml', File.dirname(__FILE__))
    expect(File.exist?(xml_path)).to be true

    out_path = File.expand_path("./../output/#{File.basename(xml_path, File.extname(xml_path))}/", File.dirname(__FILE__))

    if File.exist?(out_path)
      FileUtils.rm_rf(out_path)
    end
    # expect(File.exist?(out_path)).not_to be true

    FileUtils.mkdir_p(out_path)
    expect(File.exist?(out_path)).to be true

    translator = BuildingSync::Translator.new(xml_path, out_path, nil, CA_TITLE24)
    translator.write_osm

    puts "Looking for the following OSM file: #{out_path}/in.osm"
    expect(File.exist?("#{out_path}/in.osm")).to be true
    osm_path = "#{out_path}/in.osm"

    run_baseline_simulation(osm_path, 'CZ01RV2.epw')

    translator.gather_results(out_path)
    translator.save_xml(File.join(out_path, 'results.xml'))

    # expect(translator.failed_scenarios.empty?).to be(true), "Scenarios #{translator.failed_scenarios.join(', ')} failed to run"
  end
end
