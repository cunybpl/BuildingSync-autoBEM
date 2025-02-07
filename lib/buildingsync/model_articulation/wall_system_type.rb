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

module BuildingSync
  # Wall System Type
  ### Will need to make this take ExteriorWallConstruction & ExteriorWallFinish & WallInsulationRValue : NOW DONE JAN22
  class WallSystemType
    # initialize a specific floor system type given a ref
    # @param doc [REXML::Document]
    # @param ns [String]
    # @param ref [String]
    def initialize(doc, ns, ref)
      @id = nil
      XPath.match(doc.root,"//#{ns}:WallSystem").each do |wall_system|
        if wall_system.attributes['ID'] == ref
          self.read(wall_system, ns)
        end
      end
    end

    # read
    # @param wall_system [REXML:Element]
    # @param ns [String]
    def read(wall_system, ns)

      @id = wall_system.attributes['ID'] if wall_system.attributes['ID']
      
      xmlwallInsulationRValue = XPath.first(wall_system,".//#{ns}:WallInsulationRValue")
      xmlexteriorWallConstruction = XPath.first(wall_system,".//#{ns}:ExteriorWallConstruction")
      xmlexteriorWallFinish = XPath.first(wall_system,".//#{ns}:ExteriorWallFinish") 
      
      @wallInsulationRValue = help_get_text_value_as_float(xmlwallInsulationRValue) unless xmlwallInsulationRValue.nil?
      @exteriorWallConstruction = help_get_text_value(xmlexteriorWallConstruction) unless xmlexteriorWallConstruction.nil?
      @exteriorWallFinish = help_get_text_value(xmlexteriorWallFinish) unless xmlexteriorWallFinish.nil?
    end
    
    attr_reader :id, :wallInsulationRValue, :exteriorWallConstruction, :exteriorWallFinish
  end
end
