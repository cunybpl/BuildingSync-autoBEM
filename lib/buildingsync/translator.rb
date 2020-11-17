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
require 'rexml/document'
require 'buildingsync/constants'

require_relative 'model_articulation/spatial_element'
require_relative 'makers/model_maker'
require_relative 'makers/workflow_maker'
require_relative 'selection_tool'
require_relative 'extension'


module BuildingSync
  # Translator class
  class Translator
    # load the building sync file and initiate the model maker and workflow makers
    # @param xml_file_path [String]
    # @param output_dir [String]
    # @param epw_file_path [String] if provided, full/path/to/my.epw
    # @param standard_to_be_used [String]
    # @param validate_xml_file_against_schema [Boolean]
    def initialize(xml_file_path, output_dir, epw_file_path = nil, standard_to_be_used = ASHRAE90_1, validate_xml_file_against_schema = true)
      @doc = nil
      @model_maker = nil
      @workflow_maker = nil
      @output_dir = output_dir
      @standard_to_be_used = standard_to_be_used
      @epw_path = epw_file_path
      @osm_baseline_file_path = nil

      # to further reduce the log messages we can change the log level with this command
      # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Error)
      # Open a log for the library
      log_file = OpenStudio::FileLogSink.new(OpenStudio::Path.new("#{output_dir}/in.log"))
      log_file.setLogLevel(OpenStudio::Info)

      # parse the xml
      if !File.exist?(xml_file_path)
        OpenStudio.logFree(OpenStudio::Error, 'BuildingSync.Translator.initialize', "File '#{xml_file_path}' does not exist")
        raise "File '#{xml_file_path}' does not exist" unless File.exist?(xml_file_path)
      end

      if validate_xml_file_against_schema
        # we wil try to validate the file, but if it fails, we will not cancel the process, but log an error
        begin
          selection_tool = BuildingSync::SelectionTool.new(xml_file_path)
          if !selection_tool.validate_schema
            raise "File '#{xml_file_path}' does not valid against the BuildingSync schema"
          else
            OpenStudio.logFree(OpenStudio::Info, 'BuildingSync.Translator.initialize', "File '#{xml_file_path}' is valid against the BuildingSync schema")
            puts "File '#{xml_file_path}' is valid against the BuildingSync schema"
          end
        rescue StandardError
          OpenStudio.logFree(OpenStudio::Error, 'BuildingSync.Translator.initialize', "File '#{xml_file_path}' does not valid against the BuildingSync schema")
        end
      else
        OpenStudio.logFree(OpenStudio::Info, 'BuildingSync.Translator.initialize', "File '#{xml_file_path}' was not validated against the BuildingSync schema")
        puts "File '#{xml_file_path}' was not validated against the BuildingSync schema"
      end

      @doc = BuildingSync::Helper.create_rexml_document_from_file_path(xml_file_path)

      # test for the namespace
      @ns = 'auc'
      @doc.root.namespaces.each_pair do |k, v|
        @ns = k if /bedes-auc/.match(v)
      end

      # we use only one model maker and one workflow maker that we set init here
      @model_maker = ModelMaker.new(@doc, @ns)
      @workflow_maker = WorkflowMaker.new(@doc, @ns)
    end

    # write osm - writing the model generated by the model maker in osm file format
    # @param ddy_file [String]
    def write_osm(ddy_file = nil)
      @model_maker.generate_baseline(@output_dir, @epw_path, @standard_to_be_used, ddy_file)
    end

    # gather results from simulated scenarios, for all or just the baseline scenario
    # @param dir [String] output_path where all scenarios are being run: i.e output_path/Baseline output_path/SR
    # @param year_val [Integer]
    # @param baseline_only [Boolean]
    def gather_results(dir, year_val = Date.today.year, baseline_only = false)
      children_dirs = Dir.glob("#{dir}/*").select {|f| File.directory? f }
      baseline_dir_found = false
      children_dirs.each do |child|
        if child.end_with?(BASELINE)
          baseline_dir_found = true
        end
      end
      OpenStudio.logFree(OpenStudio::Info, "BuildingSync.Translator.gather_results", "Children dirs: #{children_dirs}")
      if !baseline_dir_found
        OpenStudio.logFree(OpenStudio::Error, "BuildingSync.Translator.gather_results", "A Baseline directory was not found.  Will not gather_results.")
      end
      return @workflow_maker.gather_results(dir, year_val, baseline_only)
    end

    # save xml that includes the results
    # @param file_name [String]
    def save_xml(file_name)
      @workflow_maker.save_xml(file_name)
    end

    # write osws - write all workflows into osw files
    def write_osws
      @workflow_maker.write_osws(@model_maker.get_facility, @output_dir)
    end

    # clear all measures
    def clear_all_measures
      @workflow_maker.clear_all_measures
    end

    # add measure path
    # @param measure_path [String]
    def add_measure_path(measure_path)
      @workflow_maker.add_measure_path(measure_path)
    end

    # insert EnergyPlus measure
    # @param measure_dir [String]
    # @param position [Integer]
    # @param args_hash [hash]
    def insert_energyplus_measure(measure_dir, position = 0, args_hash = {})
      @workflow_maker.insert_energyplus_measure(measure_dir, position, args_hash)
    end

    # insert model measure
    # @param measure_dir [String]
    # @param position [Integer]
    # @param args_hash [hash]
    def insert_model_measure(measure_dir, position = 0, args_hash = {})
      @workflow_maker.insert_model_measure(measure_dir, position, args_hash)
    end

    # insert reporting measure
    # @param measure_dir [String]
    # @param position [Integer]
    # @param args_hash [hash]
    def insert_reporting_measure(measure_dir, position = 0, args_hash = {})
      @workflow_maker.insert_reporting_measure(measure_dir, position, args_hash)
    end

    # get xml document
    # @return [REXML::Document]
    def get_doc
      return @doc
    end

    # get workflow from workflow maker
    def get_workflow
      @workflow_maker.get_workflow
    end

    # get space types from model
    def get_space_types
      return @model_maker.get_space_types
    end

    # get model from model maker
    def get_model
      return @model_maker.get_model
    end

    # create an osw file for the baseline scenario and save it to disk
    # @param reporting [Boolean] true means openstudio_results will be added to the workflow
    # @return osw_path [String] full path to in.osw file
    def create_baseline_osw(reporting = true)
      workflow = OpenStudio::WorkflowJSON.new
      workflow.setSeedFile(@osm_baseline_file_path)
      workflow.setWeatherFile(@epw_file_path)

      osw_path = @osm_baseline_file_path.gsub('.osm', '.osw')
      workflow.saveAs(File.absolute_path(osw_path.to_s))

      if reporting
        json_workflow = nil
        File.open(osw_path, 'r') do |file|
          json_workflow = JSON.parse(file.read)
          new_step = {}
          new_step['measure_dir_name'] = 'openstudio_results'
          # new_step['arguments'] = args_hash
          json_workflow['steps'].insert(0, new_step)
        end
        File.open(osw_path, 'w') do |file|
          file << JSON.generate(json_workflow)
        end
        workflow = json_workflow
      end

      OpenStudio.logFree(OpenStudio::Info, "BuildingSync.Translator.create_baseline_osw", "WorkflowJSON: #{workflow.to_s}")
      OpenStudio.logFree(OpenStudio::Info, "BuildingSync.Translator.create_baseline_osw", "osw_path #{osw_path}")
      return osw_path
    end

    # run osm - running the baseline simulation
    # @param path_to_epw_file [String] if provided and file exists, overrides the attribute building.@epw_file_path
    # @param runner_options [hash]
    def run_baseline_osm(path_to_epw_file = nil, runner_options = {run_simulations: true, verbose: false, num_parallel: 1, max_to_run: Float::INFINITY})
      if !path_to_epw_file.nil? && File.exist?(path_to_epw_file) && File.to_s.end_with?('.epw')
        @epw_file_path = path_to_epw_file
        OpenStudio.logFree(OpenStudio::Info, "BuildingSync.Translator.run_baseline_osm", "EPW path updated to: #{path_to_epw_file}")
      else
        @epw_file_path = @model_maker.get_facility.get_epw_file_path
        OpenStudio.logFree(OpenStudio::Info, "BuildingSync.Translator.run_baseline_osm", "EPW path not updated.  Using: #{path_to_epw_file}")
      end
      file_name = 'in.osm'

      # Create a new baseline directory: dir/@output_dir/Baseline
      osm_baseline_dir = File.join(@output_dir, BASELINE)
      if !File.exist?(osm_baseline_dir)
        FileUtils.mkdir_p(osm_baseline_dir)
      end

      # Copy the osm file from dir/@output_dir/in.osm
      # to dir/@output_dir/Baseline/in.osm
      @osm_baseline_file_path = File.join(osm_baseline_dir, file_name)
      FileUtils.cp("#{@output_dir}/in.osm", osm_baseline_dir)
      osw_path = create_baseline_osw

      extension = OpenStudio::Extension::Extension.new
      runner = OpenStudio::Extension::Runner.new(extension.root_dir, nil, runner_options)
      return runner.run_osw(osw_path, osm_baseline_dir)
    end

    # run osws - running all scenario simulations
    # @param runner_options [hash]
    def run_osws(runner_options = {run_simulations: true, verbose: false, num_parallel: 7, max_to_run: Float::INFINITY})
      osw_files = []
      osw_sr_files = []
      Dir.glob("#{@output_dir}/**/in.osw") { |osw| osw_files << osw }
      Dir.glob("#{@output_dir}/SR/in.osw") { |osw| osw_sr_files << osw }

      runner = OpenStudio::Extension::Runner.new(dirname = Dir.pwd, bundle_without = [], options = runner_options)
      return runner.run_osws(osw_files - osw_sr_files)
    end

    # get failed scenarios
    def get_failed_scenarios
      return @workflow_maker.get_failed_scenarios
    end

    # write parameters to xml file
    # @param xml_file_path [String]
    def write_parameters_to_xml(xml_file_path = nil)
      @model_maker.write_parameters_to_xml
      save_xml(xml_file_path) if !xml_file_path.nil?
    end

    # osm file path of the baseline model
    attr_reader :osm_baseline_file_path
  end
end
