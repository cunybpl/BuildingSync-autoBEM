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
  # Foundation System Type
  class FoundationSystemType
    # initialize a foundation system type given a ref
    # @param doc [REXML::Document]
    # @param ns [String]
    # @param ref [String]
    def initialize(doc, ns, ref)
      @id = nil
      XPath.match(doc.root,"//#{ns}:FoundationSystem").each do |foundation_system|
        if foundation_system.attributes['ID'] == ref
          self.read(foundation_system, ns)
        end
      end
    end

    # read
    # @param foundation_system [REXML:Element]
    # @param ns [String]
    def read(foundation_system, ns)
      puts "I'm in read func"
      # ID
      @id = foundation_system.attributes['ID'] if foundation_system.attributes['ID']

      puts @foundationgroundCoupling = XPath.first(foundation_system,".//#{ns}:GroundCoupling")[0].name.gsub("auc:","")

      
      xmlfoundationCrawlspaceVentilation = XPath.first(foundation_system,".//#{ns}:CrawlspaceVenting")[0].name.gsub("auc:","") if @foundationgroundCoupling == "CrawlspaceVenting"
      @foundationCrawlspaceVentilation =  case xmlfoundationCrawlspaceVentilation
                                          when "Ventilated"
                                            true
                                          when "Unventilated"
                                            false
                                          when nil
                                            nil
                                          end

      xmlfoundationRValue = case @foundationgroundCoupling
                            when "CrawlSpace"
                              XPath.first(foundation_system,".//#{ns}:FloorRValue")
                            when "SlabOnGrade"
                              XPath.first(foundation_system,".//#{ns}:SlabRValue")
                            when "Basement"
                              XPath.first(foundation_system,".//#{ns}:FoundationWallRValue")
                            end
      
      xmlfoundationThickness = XPath.first(foundation_system,".//#{ns}:SlabInsulationThickness") if @foundationgroundCoupling == "SlabOnGrade"

      @foundationRValue = help_get_text_value_as_float(xmlfoundationRValue) unless xmlfoundationRValue.nil?
      
      @foundationThickness = help_get_text_value_as_float(xmlfoundationThickness) if @foundationgroundCoupling == "SlabOnGrade" && !xmlfoundationThickness.nil?
    end
    attr_reader :id, :foundationgroundCoupling, :foundationCrawlspaceVentilation, :foundationRValue, :foundationThickness
  end
end
