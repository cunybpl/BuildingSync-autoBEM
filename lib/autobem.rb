require_relative 'autobem/requirebuildingsync.rb'

require_relative 'autobem/analyze/toolkitforbsxmls.rb'
require_relative 'autobem/generate/autogenerate.rb'
require_relative 'autobem/validate/usevalidatebsxmls.rb'

puts "\nWelcome.\nEnter 1 to use AutoGenerateBEM.\nEnter 2 to use ToolkitForBSXMLs\nEnter 3 to use ValidateBSXMLs."

choice = gets.strip
case choice.to_s
when "1"
    include BuildingSync::AutoGenerateBEM
    puts "\nThe available function is:\n\n"
    puts "autogenerateBEM(osmfolderorfile, bsxmlfolderorfile, bin)\n\n"
    puts "'bin' is optional if you enter paths directly to .osm & .xml\n\n"
when "2"
    include BuildingSync::ToolkitForBSXMLs
    puts "\nThe available functions are listed in documentation. Please visit README for 'analyze' folder."
when "3"
    include BuildingSync::ValidateBSXMLs
    puts "\nThe function will automatically run. Follow the instructions.\n"
    usevalidatebsxmls
end