require 'find'

def info_plist_text(executable_name)
    <<END_OF_INFO_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>#{executable_name}</string>
	<key>CFBundleGetInfoString</key>
	<string>© 2003 Keith Bauer</string>
	<key>CFBundleIconFile</key>
	<string>#{executable_name}.icns</string>
	<key>CFBundleIdentifier</key>
	<string></string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>#{executable_name}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>© 2003 Keith Bauer</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>0.1</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
</dict>
</plist>
END_OF_INFO_PLIST
end

def build_bundle(parameters)
    bundle_name = parameters[:bundle_name] ||
        raise(BuildFailedError, "Must specify :bundle_name")
    resources_directories = parameters[:resources_directories]
    if resources_directories == nil then
        resources_directories = [parameters[:resources_directory]]
    end
    application_signature = parameters[:application_signature] || '????'
    info_plist_file = parameters[:info_plist_file]
    executable_name = parameters[:executable_name] ||
        File.basename(bundle_name, '.app')
    
    if resources_directories != nil then
        resources_directories.each do |resources_directory|
            Find.find(resources_directory) do |path|
                if File.basename(path) =~ /^\./ then
                    Find.prune
                end
            
                if FileTest.file?(path) then
                    source_path = path.sub(/^#{resources_directory}\//, '')
                    destination_path = "#{bundle_name}/Contents/Resources/#{source_path}"
                
                
                    build(:targets => [destination_path],
                          :dependencies => [path],
                          :command => "cp '#{path}' '#{destination_path}'",
                          :message => "Copying Resource #{source_path}")
                end
            end
        end
    end
    
    build(:targets => ["#{bundle_name}/Contents/PkgInfo"],
          :command => "echo 'APPL#{application_signature}' > '#{bundle_name}/Contents/PkgInfo'",
          :message => "Creating PkgInfo File #{bundle_name}/Contents/PkgInfo")

    if info_plist_file != nil then
        build(:targets => ["#{bundle_name}/Contents/Info.plist"],
              :dependencies => [info_plist_file],
              :command => "cp '#{info_plist_file}' '#{bundle_name}/Contents/Info.plist'",
              :message => "Copying Info.plist File #{bundle_name}/Contents/Info.plist")
    else
        build(:targets => ["#{bundle_name}/Contents/Info.plist"],
              :command => "echo '#{info_plist_text(executable_name)}' > '#{bundle_name}/Contents/Info.plist'",
              :message => "Creating Info.plist File #{bundle_name}/Contents/Info.plist")
    end
end
