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
require "fileutils"
require 'csv'
require 'json'
require 'pp'

module BuildingSync
  module ToolkitForBSXMLs
    
    include BuildingSync::Helper
    include BuildingSync::XmlGetSet
    include REXML
    
    # puts "\n\nAvailable non-helper functions:\n\nsum_BSXML_dataset_elements(bsxmlFolder)\nall_paths_in_BSXML_dataset(bsxmlFolder,csvwrite)\nunique_XPaths_of_two_BSXMLs(xpaths1,xpaths1name,xpaths2,xpaths2name,pathToSave)\nopen_bsxml_by_BIN(bsxmlFolder,bin)\nstore_BSXMLS_with_binORbbl(binORbbl,bsxmlFolder,saveFolderName,csvfile)\n\n"
    
    # Analyze the whole set of BSXMLs to count element occurences & across how many files then save that in CSV
    # @param bsxmlFolder [String]
    def sum_BSXML_dataset_elements(bsxmlFolder)
      
      # MISSING FEATURES:
      ## 1. some elements may be nested under other elements but just for 'linking' purposes
      ## (eg the test file had 48 building elements) … probably should find a way to spot this?
      # 2. some elements are just a container of units (eg Buildings & Building) so I should probably find a way to exclude them
      # 3. probably should find a way to count how many files have an element in particular
      
      allFileElems = []
      allFileElemsPathsHash = {}
      allFileUserDefFields = []
      files_count = Dir.glob(["#{bsxmlFolder}/*.xml"]).size
      i = 1
      
      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        bsxml = help_load_doc(bsxmlinst)
        puts "loaded file #{File.basename(bsxmlinst)}"
        
        singleFileElems = {}
        singleFileElems.compare_by_identity
        userDefFieldsNames = []
        
        # iterate elements
        bsxml.root.each_recursive do |elem|
          elemPath = elem.parent.xpath
          elemPath.gsub!("auc:","")
          elemPath.gsub!(/\[\d+\]/,"")
          singleFileElems[elem.name] = elemPath
        end
        fileElemCounts = singleFileElems.keys.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
        
        puts "The file has #{singleFileElems.keys.size} elements, #{fileElemCounts.keys.size} of them unique."
        
        allFileElems.concat(singleFileElems.keys)
        allFileElemsPathsHash.merge!(singleFileElems)
        puts "allFileElems size is now #{allFileElems.size}"
        
        # add the UserDefinedField Names
        userDefFieldsFieldNames = XPath.match(bsxml.root,'//auc:UserDefinedField/auc:FieldName')
        userDefFieldsFieldNames.each {|elem| userDefFieldsNames << help_get_text_value(elem)}
        fileUserDefFieldsCounts = userDefFieldsNames.each_with_object(Hash.new(0)) {|word,counts| counts[word] += 1}
        
        puts "The file has #{userDefFieldsNames.size} user defined fields, #{fileUserDefFieldsCounts.keys.size} of them unique."
        
        allFileUserDefFields.concat(userDefFieldsNames)
        puts "allFileUserDefFields size is now #{allFileUserDefFields.size}\n\n"
        
        puts "Looked up in #{i} files from #{files_count}\n\n\n"
        i+=1
      end
      
      allFileElemsCounts = allFileElems.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
      puts "The BSXML collection has #{allFileElems.size} elements, #{allFileElemsCounts.keys.size} of them unique."
      allFileUserDefFieldsCounts = allFileUserDefFields.each_with_object(Hash.new(0)) {|word,counts| counts[word] += 1}
      puts "The BSXML collection has #{allFileUserDefFields.size} user defined fields, #{allFileUserDefFieldsCounts.keys.size} of them unique."
      
      # The CSV creation part
      col_names = ["Elements","ElementCounts","ElementPath","UserDefinedFields","UserDefinedFieldsCounts"]
      csv_name = "#{bsxmlFolder}/#{File.basename(bsxmlFolder)}_BSXML_element_summary3.csv"
      csvfile = CSV.open(csv_name, "w")
      csvfile << col_names
      i = 0
      until i == [allFileElemsCounts.size,allFileUserDefFieldsCounts.size].max
        arrayIn = []
        if i < allFileElemsCounts.size
          arrayIn.concat([allFileElemsCounts.keys[i],allFileElemsCounts.values[i],allFileElemsPathsHash[allFileElemsCounts.keys[i]]])
        else
          arrayIn.concat(["","",""])
        end
        if i < allFileUserDefFieldsCounts.size
          arrayIn.concat([allFileUserDefFieldsCounts.keys[i],allFileUserDefFieldsCounts.values[i]])
        else
          arrayIn.concat(["",""])
        end
        csvfile << arrayIn
        i += 1
      end
    end
    
    # Find all the unique xpaths in a set of BSXMLs & write to a CSV the number of files they occur in & the path as a group of cells
    # @param bsxmlFolder [String] : path to folder
    # @param csvwrite [Boolean] : whether to write the result to a file or not
    # @return allXPathsUniq [Array] : Array with unique xpaths (strings)
    def all_paths_in_BSXML_dataset(bsxmlFolder,csvwrite)
      
      files_count = Dir.glob(["#{bsxmlFolder}/*.xml"]).size
      i = 1
      
      allXPaths = []
      allXPathsFileCt = {}
      
      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        bsxml = help_load_doc(bsxmlinst)
        puts "loaded file #{File.basename(bsxmlinst)}"
        
        allFileXPaths = []
        
        # iterate elements
        bsxml.root.each_recursive do |elem|
          elemPath = elem.xpath
          elemPath.gsub!("auc:","")
          elemPath.gsub!(/\[\d+\]/,"")
          allFileXPaths << elemPath unless elemPath.include? "UserDefinedField"
        end
        
        allFileXPathsUniq = allFileXPaths.each_with_object(Hash.new(0)) { |xPath,counts| counts[xPath] += 1 }
        puts "The file has #{allFileXPaths.size} XPaths, #{allFileXPathsUniq.keys.size} of them unique."
        
        allXPaths.concat(allFileXPathsUniq.keys)
        allFileXPathsUniq.each_key do |xp|
          if allXPathsFileCt.keys.include? xp
            allXPathsFileCt[xp] += 1
          else
            allXPathsFileCt[xp] = 1
          end
        end
        
        puts "allXPaths size is now #{allXPaths.size}\n\n"
        puts "Looked up in #{i} files from #{files_count}\n\n\n"
        
        i+=1
      end
      
      allXPathsUniq = allXPaths.each_with_object(Hash.new(0)) { |xPath,counts| counts[xPath] += 1 }
      
      puts "The BSXML collection has #{allXPaths.size} XPaths, #{allXPathsUniq.keys.size} of them unique."
      
      if csvwrite
        # The CSV creation part
        csv_name = "#{bsxmlFolder}/#{File.basename(bsxmlFolder)}_BSXML_all_XPaths2.csv"
        csvfile = CSV.open(csv_name, "w")
        
        allXPathsUniq.each_key do |xp| 
          xpsplit = xp.sub("/","").split('/')
          csvfile << [allXPathsFileCt[xp]].concat(xpsplit)
        end 
      end
      return allXPathsUniq.keys
    end
    
    # List all variations of types that can be value of an array of elements (e.g. occupancy classification)
    # Will only work for 'leaf' nodes
    # For now this only outputs a hash
    def list_enumerations_in_BSXML_dataset(bsxmlFolder,element_types)

      elementValuesInFile = {}

      elementValuesUniq = {}
      collected_values = {}

      element_types.each do |element_type|
        
        elementValuesInFile.merge!({element_type => {}}) 
        collected_values.merge!({element_type => []})  
        elementValuesUniq.merge!({element_type => []})
        
        Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
          
          bsxml_inst_name = File.basename(bsxmlinst)

          elementValuesInFile[element_type].merge!({bsxml_inst_name => []})

          bsxml = help_load_doc(bsxmlinst)
          
          puts "loaded file #{bsxml_inst_name}"

          matching_elements = XPath.match(bsxml.root,"//auc:#{element_type}")
          matching_elements.each do |elem|
            if elem.has_elements?
              puts "Your element has children. Values will not be collected."
              return
            else
              collected_values[element_type] << elem.text
              elementValuesInFile[element_type][bsxml_inst_name] << elem.text
            end
          end
        end
        
        elementValuesUniq[element_type] = collected_values[element_type].each_with_object(Hash.new(0)) { |elemValue,counts| counts[elemValue] += 1 }
      end
      
      # puts elementValuesInFile
      
      puts "\n\n\n"

      elementValuesInFile.each do |elemtype,file|
        pp elementValuesInFile[elemtype].select {|file,values| values.length > 1}
      end
      puts "\n\n\n"
      pp elementValuesUniq
      
      # writing to .csv
      col_names = ["ElementType","Value","Occurrences"]
      
      csv_name = "#{bsxmlFolder}/#{File.basename(bsxmlFolder)}_BSXML_enumerations_of_elements.csv"
      
      csvfile = CSV.open(csv_name, "w")

      for i in 1..elementValuesUniq.length
        csvfile << col_names
      end

      elementValuesUniq.each do |element_type,counts_hash|
        counts_hash.each do |element_value,count|
          csvfile << [element_type,element_value,count]
        end
      end

    end

    # Same as above function but specifically for auc:Section elements to read occupancy classifications & floor areas
    def study_occ_class_and_floor_areas_in_BSXML_dataset(bsxmlFolder)

      # files_Sections = {
      #   "report.xml" => {
      #     "OccClass" => "Type",
      #     "FloorAreas" => {
      #       "Gross" => 123,
      #       "Total" => 123
      #     }
      #   }
      # }
      
      files_sections = {}

      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        
        bsxml_inst_name = File.basename(bsxmlinst)

        files_sections.merge!({bsxml_inst_name => {"OccClass" => [], "FloorAreas" => {}}})

        bsxml = help_load_doc(bsxmlinst)
        
        puts "loaded file #{bsxml_inst_name}"

        section_elements = XPath.match(bsxml.root,"//auc:Section")

        section_elements = section_elements.select {|sec_elem| !XPath.first(sec_elem,".//auc:OccupancyClassification").nil?}
        
        section_elements.each do |sec_elem|
          
          occupancy_classification = XPath.first(sec_elem,".//auc:OccupancyClassification")
          files_sections[bsxml_inst_name]["OccClass"] << occupancy_classification.text

          floor_areas_classification_string = occupancy_classification.text + sec_elem.attributes['ID']
          files_sections[bsxml_inst_name]["FloorAreas"].merge!({floor_areas_classification_string => {}})

          floor_areas = XPath.match(sec_elem,".//auc:FloorArea")
          floor_areas.each {|flr_area| files_sections[bsxml_inst_name]["FloorAreas"][floor_areas_classification_string].merge!({flr_area[0].text => flr_area[1].text})}
        end
      end
      
      puts "\n\n\n"
      pp files_sections
      puts "\n\n\n"

    end
    
    # Find the XPaths that exist in one file but not the other
    # @param xpaths1 [Array] : all xpaths of file (from all_paths_in_BSXML_dataset function)  
    # @param xpaths1name [String] :  desired name to distinguish file
    # @param xpaths2 [Array] : all xpaths of file (from all_paths_in_BSXML_dataset function) 
    # @param xpaths2name [String] :  desired name to distinguish file
    # @param pathToSave [String] : path to save the two CSVs containing unique xpaths of each file
    # @return resulthash [Hash] : hash with two pairs (the file name & its unique xpaths)
    def unique_XPaths_of_two_BSXMLs(xpaths1,xpaths1name,xpaths2,xpaths2name,pathToSave)
      
      puts "\n\n#{xpaths1name} has #{xpaths1.length} elements \n\n"
      puts "\n\n#{xpaths2name} has #{xpaths2.length} elements \n\n"
      
      common = xpaths1 & xpaths2 # find intersections
      puts "\n\nXpaths arrays have #{common.length} common elements \n\n"
      
      xpaths1uniq = xpaths1 - common
      puts "\n\n#{xpaths1name} has #{xpaths1uniq.length} unique elements \n\n"
      
      xpaths2uniq = xpaths2 - common 
      puts "\n\n#{xpaths2name} has #{xpaths2uniq.length} unique elements \n\n"
      
      csv1name = "#{pathToSave}/#{xpaths1name}_unique_XPaths.csv"
      csv1file = CSV.open(csv1name, "w")
      xpaths1uniq.each {|xpath| csv1file << [xpath] unless xpath.include? "UserDefinedField"};
      
      csv2name = "#{pathToSave}/#{xpaths2name}_unique_XPaths.csv"
      csv2file = CSV.open(csv2name, "w")
      xpaths2uniq.each {|xpath| csv2file << [xpath] unless xpath.include? "UserDefinedField"};
      
      resulthash = {xpaths1name => xpaths1uniq, xpaths2name => xpaths2uniq}
      return resulthash
    end
    
    # From a CSV source, find BSXMLs in a certain directory with specific BINs or BBLs & save them in a new folder
    # @param binORbbl [String]
    # @param bsxmlFolder [String]
    # @param saveFolderName [String]
    # @param csvfile [String]
    def store_BSXMLS_with_binORbbl(binORbbl,bsxmlFolder,saveFolderName,csvfile)
      
      # CSV COLUMN with bin or bbl to array
      csvFile = CSV.table(csvfile)
      
      binORbblArr = csvFile[:bin] if binORbbl.downcase == 'bin'
      binORbblArr = csvFile[:bbl] if binORbbl.downcase == 'bbl'
      binORbblArr.map!(&:to_s)
      puts "Total #{binORbbl.upcase}s provided = #{binORbblArr.length}\n\n"
      
      saveDir = "#{bsxmlFolder}/#{saveFolderName}"
      if Dir.exists?(saveDir)
        puts "Try again with unique saveFolderName. Name entered already existing."
        return
      end
      Dir.mkdir saveDir
      
      i = 1
      found = 0
      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        bsxml = help_load_doc(bsxmlinst)
        
        binORbblVal = help_get_BIN(bsxml) if binORbbl.downcase == 'bin'
        binORbblVal = help_get_bbl(bsxml) if binORbbl.downcase == 'bbl'
        puts "looking if #{binORbbl.upcase} ##{binORbblVal} has a match in file #{i}.\n\n"
        
        if binORbblArr.include? binORbblVal
          FileUtils.cp(bsxmlinst,saveDir)
          puts "copied #{File.basename(bsxmlinst)} just now \n\n"
          found += 1
        end
        i += 1
      end
      
      puts "Matches: #{found} from #{binORbblArr.length} #{binORbbl.upcase}s provided in #{i} BSXMLs\n\n"
      
      if Dir.empty?(saveDir)
        Dir.rmdir(saveDir)
        puts "No matches. Save directory deleted."
      end
    end
    
    # Pick BSXML based on BIN
    # @param bsxmlFolder [String]
    # @param BIN [String]
    # @return bsxml [REXML::Document]
    def open_bsxml_by_BIN(bsxmlFolder,bin)
      bsxml = nil
      foundBIN = nil
      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        bsxmldoc = help_load_doc(bsxmlinst)
        foundBIN = help_get_BIN(bsxmldoc)
        if foundBIN == bin
          bsxml = bsxmldoc
          puts "BSXML with BIN #{foundBIN} found in file named #{File.basename(bsxmlinst)}"
          puts "your BIN isn't 7 digits" if foundBIN.gsub(/\s+/, '').length != 7 # gsub here just removes whitespace
          return bsxml
        end
      end
      puts "Failed to find BSXML with requested BIN in provided folder" if bsxml == nil
    end
    
    
    
    ### This was only a temporary function --don't see much need for actual implementation
    ### Tried to make this write to csv file but the csv never wrote … odd
    # Get floor areas & floor counts for a set of BSXMLs in a folder
    def get_areas_and_floors(bsxmlFolder)
      i = 0
      datahash = {}
      Dir.glob(["#{bsxmlFolder}/*.xml"]) do |bsxmlinst|
        bsxml = help_load_doc(bsxmlinst)
        elems = bsxml.root
        bin = help_get_BIN(bsxml)
        puts "Looking in BSXML with BIN #{bin}"
        datahash.merge!({bin=>{}})
        
        datahash[bin]["cond_floors_abv_grd"] = help_get_text_value(XPath.first(elems,"//auc:ConditionedFloorsAboveGrade"))
        datahash[bin]["cond_floors_blw_grd"] = help_get_text_value(XPath.first(elems,"//auc:ConditionedFloorsBelowGrade"))
        datahash[bin]["cond_floors_total"] = (datahash[bin]["cond_floors_abv_grd"].to_i + datahash[bin]["cond_floors_blw_grd"].to_i).to_s
        
        xml_floorAreas = XPath.match(elems,"//auc:Building/auc:FloorAreas/auc:FloorArea")
        
        fileFlrAreas = {}
        xml_floorAreas.each do |flrArea|
          fileFlrAreas[help_get_text_value(flrArea[0])] = help_get_text_value(flrArea[1])
        end
        
        ["Cooled only","Heated only","Heated and Cooled","Gross"].each do |flrAreaType|
          unless fileFlrAreas.keys.include? flrAreaType
            fileFlrAreas[flrAreaType] = "N/A"
          end
        end
        
        fileFlrAreas = fileFlrAreas.sort_by { |key| key }.to_h
        
        datahash[bin].merge!(fileFlrAreas)
        
        i+=1
        puts "Obtained data from #{i} files.\n\n"
      end
      
      puts "\n\nHere is BIN"
      datahash.each_key {|bldg| puts bldg}
      puts "\n\nHere is Cond Floors Abv Grade"
      datahash.each_key {|bldg| puts datahash[bldg]["cond_floors_abv_grd"]}
      puts "\n\nHere is Cond Floors Blw Grade"
      datahash.each_key {|bldg| puts datahash[bldg]["cond_floors_blw_grd"]}
      puts "\n\nHere is Cond Floors Total"
      datahash.each_key {|bldg| puts datahash[bldg]["cond_floors_total"]}
      puts "\n\nHere is Gross Floor Area"
      datahash.each_key {|bldg| puts datahash[bldg]["Gross"]}
      puts "\n\nHere is Heated and Cooled Floor Area"
      datahash.each_key {|bldg| puts datahash[bldg]["Heated and Cooled"]}
      puts "\n\nHere is Cooled Only Floor Area"
      datahash.each_key {|bldg| puts datahash[bldg]["Cooled only"]}
      puts "\n\nHere is Heated Only Floor Area"
      datahash.each_key {|bldg| puts datahash[bldg]["Heated only"]}
      
    end
    
    
    # Get Building Identification Number
    # @param bsxml [REXML::Document]
    # @return bin [String]
    def help_get_BIN(bsxml)
      elems = bsxml.root.elements # @return [REXML::Elements]
      binElem = elems['//auc:PremisesIdentifier[auc:IdentifierCustomName="BIN"]/auc:IdentifierValue'] # REXML::Element
      bin = help_get_text_value(binElem)
      return bin
    end
    
    # Get Borough Block Lot number
    # @param bsxml [REXML::Document]
    # @return bbl [String]
    def help_get_bbl(bsxml)
      elems = bsxml.root.elements # @return [REXML::Elements]
      
      # Hash to map borough name to number
      boroNums = { 'Manhattan' => '1', 'Bronx' => '2', 'Brooklyn' => '3', 'Queens' => '4', 'Staten Island' => '5'}
      
      boroElem = elems['//auc:PremisesIdentifier[auc:IdentifierCustomName="Borough"]/auc:IdentifierValue'] # REXML::Element
      boroString = help_get_text_value(boroElem)
      boro = boroNums[boroString]
      puts "Borough is #{boroString} at ##{boro}"
      
      blockElem =elems['//auc:PremisesIdentifier[auc:IdentifierCustomName="Tax Block"]/auc:IdentifierValue']
      block = help_get_text_value(blockElem)
      puts "Block # is #{block}"
      
      lotElem =elems['//auc:PremisesIdentifier[auc:IdentifierCustomName="Tax Lot"]/auc:IdentifierValue']
      lot = help_get_text_value(lotElem)
      puts "Lot # is #{lot}"
      
      bbl = boro+block+lot
      puts "your bbl is not 10 digits" if bbl.length != 10
      return bbl
    end
  end
end