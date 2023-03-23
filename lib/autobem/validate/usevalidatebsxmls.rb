require 'json'
require_relative 'validatebsxmlsselectiontool'

module BuildingSync
  module ValidateBSXMLs
    
    def usevalidatebsxmls
      print "\nFor validating single file:\ntype 's'\nFor validating multiple files:\ntype 'm'\n\n"
      mode = gets.strip
      
      bsxmls =[]
      case mode
      when 's'
        print "Enter full path to xml with filename ending in '.xml':\n\n"
        bsxmls = [gets.strip]
      when 'm'
        print "Enter full path to folder containing BSXMLs you intend to validate:\n\n"
        bsxmlFolder = gets.strip
        bsxmls = Dir.glob(["#{bsxmlFolder}/*.xml"])
        bsxmls.each {|bsxml| bsxml = bsxmlFolder+"/"+bsxml}
      end
      
      print "Enter the version of files you'll validate (e.g. 2.2.0):\n\n"
      vers = gets.strip
      
      BuildingSync::ValidateBSXMLsSelectionTool.new(bsxmls,vers)
      
      # Code to create summary report of validation
      # {files with valid schema => [the file's valid use case]}
      schema_valid = {}
      if mode == 'm'
        Dir.glob(["#{bsxmlFolder}/*.json"]) do |rep|
          repJSON = JSON.parse(File.read(rep))
          if repJSON["validation_results"]["schema"]["valid"] == true
            repJSONsliced = File.basename(rep).gsub(/_ValidateBSXML_\d\d\d\dT\d\d\d\d\d\d.json/,"")
            schema_valid.store(repJSONsliced,[])
            use_cases = repJSON["validation_results"]["use_cases"]
            use_cases.values.each do |use_case|
              schema_valid[repJSONsliced] << use_cases.key(use_case) if use_case["valid"] == true
            end
          end    
        end
      end
      puts schema_valid
      puts "#{schema_valid.keys.size} files had valid schema out of #{Dir.glob(["#{bsxmlFolder}/*.json"]).size}"
      File.open("#{bsxmlFolder}/REPORT_bplValidateBSXML_#{File.basename(bsxmlFolder)}.json","w") do |f|
        f.write(JSON.pretty_generate(schema_valid))
      end
    end
  end
end