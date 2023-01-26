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
  # Roof System Type
  class RoofSystemType
    # initialize a specific roof system type given a ref
    # @param doc [REXML::Document]
    # @param ns [String]
    # @param ref [String]
    def initialize(doc, ns, ref)
      @id = nil
      XPath.match(doc.root,"//#{ns}:RoofSystem").each do |roof_system|
        if roof_system.attributes['ID'] == ref
          self.read(roof_system, ns)
        end
      end
    end

    # read
    # @param roof_system [REXML:Element]
    # @param ns [String]
    def read(roof_system, ns)

      @id = roof_system.attributes['ID'] if roof_system.attributes['ID']
      
      xmlroofInsulationRValue = XPath.first(roof_system,".//#{ns}:RoofInsulationRValue")
      xmlroofConstruction = XPath.first(roof_system,".//#{ns}:RoofConstruction")
      xmldeckType = XPath.first(roof_system,".//#{ns}:DeckType")
      xmlblueRoof = XPath.first(roof_system,".//#{ns}:BlueRoof")
      xmlgreenRoof = XPath.first(roof_system,".//#{ns}:GreenRoof")
      xmlcoolRoof = XPath.first(roof_system,".//#{ns}:CoolRoof")
      
      @roofInsulationRValue = help_get_text_value_as_float(xmlroofInsulationRValue) unless xmlroofInsulationRValue.nil?
      @roofConstruction = help_get_text_value(xmlroofConstruction) unless xmlroofConstruction.nil?
      @deckType = help_get_text_value(xmldeckType) unless xmldeckType.nil?
      @blueRoof = help_get_text_value_as_bool(xmlblueRoof) unless xmlblueRoof.nil?
      @greenRoof = help_get_text_value_as_bool(xmlgreenRoof) unless xmlgreenRoof.nil?
      @coolRoof = help_get_text_value_as_bool(xmlcoolRoof) unless xmlcoolRoof.nil?
    end
    
    attr_reader :id, :roofInsulationRValue, :roofConstruction, :deckType, :blueRoof, :greenRoof , :coolRoof
  end
end
