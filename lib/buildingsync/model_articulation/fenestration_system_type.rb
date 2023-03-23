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
  class FenestrationSystemType
    # initialize a specific fenestration system type given a ref
    # @param doc [REXML::Document]
    # @param ns [String]
    # @param ref [String]
    def initialize(doc, ns, ref)
      @id = nil
      XPath.match(doc.root,"//#{ns}:FenestrationSystem").each do |fenestration_system|
        if fenestration_system.attributes['ID'] == ref
          self.read(fenestration_system, ns)
        end
      end
    end

    # read
    # @param fenestration_system [REXML:Element]
    # @param ns [String]
    def read(fenestration_system, ns)

      @id = fenestration_system.attributes['ID'] if fenestration_system.attributes['ID']
      
      ### TEST SEPARATE --having multiple fenestration_system elements may mess us what you obtain from the #first method
      @fenestrationType = XPath.first(fenestration_system,".//#{ns}:FenestrationType")[0].name.gsub("auc:","")
      
      xmlfenestrationUFactor = XPath.first(fenestration_system,".//#{ns}:FenestrationUFactor")
      xmlfenestrationSolarHeatGainCoefficient = XPath.first(fenestration_system,".//#{ns}:SolarHeatGainCoefficient")
      xmlfenestrationVisibleTransmittance = XPath.first(fenestration_system,".//#{ns}:VisibleTransmittance")
      xmlfenestrationGlassLayers = XPath.first(fenestration_system,".//#{ns}:FenestrationGlassLayers")
      xmlfenestrationGasFill = XPath.first(fenestration_system,".//#{ns}:FenestrationGasFill")
      xmlfenestrationGlassType = XPath.first(fenestration_system,".//#{ns}:GlassType")
      xmlfenestrationTightnessFitCondition = XPath.first(fenestration_system,".//#{ns}:TightnessFitCondition")
      xmlfenestrationOperation = XPath.first(fenestration_system,".//#{ns}:FenestrationOperation")
      xmlfenestrationFrameMaterial = XPath.first(fenestration_system,".//#{ns}:FenestrationFrameMaterial")
      
      @fenestrationUFactor = help_get_text_value_as_float(xmlfenestrationUFactor) unless xmlfenestrationUFactor.nil?
      @fenestrationSHGC = help_get_text_value_as_float(xmlfenestrationSolarHeatGainCoefficient) unless xmlfenestrationSolarHeatGainCoefficient.nil?
      @fenestrationTvis = help_get_text_value_as_float(xmlfenestrationVisibleTransmittance) unless xmlfenestrationVisibleTransmittance.nil?
      @fenestrationGlassLayers = help_get_text_value(xmlfenestrationGlassLayers) unless xmlfenestrationGlassLayers.nil?
      @fenestrationGasFill = help_get_text_value(xmlfenestrationGasFill) unless xmlfenestrationGasFill.nil?
      @fenestrationGlassType = help_get_text_value(xmlfenestrationGlassType) unless xmlfenestrationGlassType.nil?
      @fenestrationTightnessFitCondition = help_get_text_value(xmlfenestrationTightnessFitCondition) unless xmlfenestrationTightnessFitCondition.nil?
      @fenestrationOperation = help_get_text_value(xmlfenestrationOperation) unless xmlfenestrationOperation.nil?
      @fenestrationFrameMaterial = help_get_text_value(xmlfenestrationFrameMaterial) unless xmlfenestrationFrameMaterial.nil?

    end
    
    attr_reader :id, :fenestrationType, :fenestrationUFactor, :fenestrationSHGC, :fenestrationTvis, :fenestrationGlassLayers, :fenestrationGasFill, :fenestrationGlassType, :fenestrationTightnessFitCondition, :fenestrationOperation, :fenestrationFrameMaterial
  end
end
