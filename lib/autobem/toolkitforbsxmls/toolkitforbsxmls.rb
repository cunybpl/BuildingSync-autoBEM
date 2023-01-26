require "fileutils"
require 'csv'
require 'json'
require 'require_all'

bldgsyncfilepath = File.expand_path("../../buildingsync",__dir__)
require_all "#{bldgsyncfilepath}"

include BuildingSync::Helper
include BuildingSync::XmlGetSet
include REXML

puts "\n\nAvailable non-helper functions:\n\nsum_BSXML_dataset_elements(bsxmlFolder)\nall_paths_in_BSXML_dataset(bsxmlFolder,csvwrite)\nunique_XPaths_of_two_BSXMLs(xpaths1,xpaths1name,xpaths2,xpaths2name,pathToSave)\nopen_bsxml_by_BIN(bsxmlFolder,bin)\nstore_BSXMLS_with_binORbbl(binORbbl,bsxmlFolder,saveFolderName,csvfile)\n\n"

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