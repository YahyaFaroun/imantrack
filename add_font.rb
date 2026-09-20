require 'xcodeproj'
project_path = 'ImanTrack.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

fonts_group = project.main_group.find_subpath(File.join('ImanTrack', 'Fonts'), true)
font_path = 'ImanTrack/Fonts/KFGQPCUthmanTahaNaskh.ttf'

unless fonts_group.files.any? { |f| f.path == font_path.split('/').last }
  file_reference = fonts_group.new_reference(font_path.split('/').last)
  target.resources_build_phase.add_file_reference(file_reference, true)
  project.save
  puts "Added font to Xcode project."
else
  puts "Font already in Xcode project."
end
