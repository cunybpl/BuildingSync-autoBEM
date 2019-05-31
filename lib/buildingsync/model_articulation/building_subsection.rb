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
require 'openstudio/model_articulation/os_lib_model_generation_bricr'
require 'openstudio-standards'
module BuildingSync
  class BuildingSubsection < SpatialElement
    include OsLib_ModelGenerationBRICR
    include OpenstudioStandards

    # initialize
    def initialize(subsection_element, standard_template, occ_type, bldg_total_floor_area, ns)
      @subsection_element = nil
      @standard = nil
      @fraction_area = nil
      @bldg_type = {}
      # code to initialize
      read_xml(subsection_element, standard_template, occ_type, bldg_total_floor_area, ns)
    end

    def read_xml(subsection_element, standard_template, occ_type, bldg_total_floor_area, ns)
      # floor areas
      @total_floor_area = read_floor_areas(subsection_element, bldg_total_floor_area, ns)
      # based on the occupancy type set building type, system type and bar division method
      read_bldg_system_type_based_on_occupancy_type(subsection_element, occ_type, ns)

      @subsection_element = subsection_element

      # Make the standard applier
      @standard = Standard.build("#{standard_template}_#{@bldg_type}")
      OpenStudio.logFree(OpenStudio::Info, 'BuildingSync.BuildingSubsection.read_xml', "Building Standard with template: #{standard_template}_#{@bldg_type}")
    end

    def read_bldg_system_type_based_on_occupancy_type(subsection_element, occ_type, ns)
      @occupancy_type = read_occupancy_type(subsection_element, occ_type, ns)
      set_bldg_and_system_type(@occupancy_type, @total_floor_area, true)
    end

    attr_reader :bldg_type, :space_types_floor_area
    attr_accessor :fraction_area
  end
end
