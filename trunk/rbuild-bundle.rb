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
</dict>
</plist>
END_OF_INFO_PLIST
end

def build_bundle(parameters)
    bundle_name = parameters[:bundle_name] ||
        raise(BuildFailedError, "Must specify :bundle_name")
    resources_directory = parameters[:resources_directory]
    application_signature = parameters[:application_signature] || '????'
    info_plist_file = parameters[:info_plist_file]
    executable_name = parameters[:executable_name] ||
        File.basename(bundle_name, '.app')
    
    build(:targets => [bundle_name,
                       bundle_name + '/Contents',
                       bundle_name + '/Contents/MacOS'],
          :command => "mkdir -p '#{bundle_name}/Contents/MacOS'",
          :message => "Creating Bundle Hierarchy #{bundle_name}")
          
    if resources_directory != nil then
        build(:targets => ["#{bundle_name}/Contents/Resources"],
              :dependencies => ["#{bundle_name}/Contents",
                                resources_directory],
              :command => "cp -r '#{resources_directory}' '#{bundle_name}'/Contents/",
              :message => "Copying Resources")
    end
    
    build(:targets => ["#{bundle_name}/Contents/PkgInfo"],
          :dependencies => ["#{bundle_name}/Contents"],
          :command => "echo 'APPL#{application_signature}' > '#{bundle_name}/Contents/PkgInfo'",
          :message => "Creating PkgInfo File #{bundle_name}/Contents/PkgInfo")

    if info_plist_file != nil then
        build(:targets => ["#{bundle_name}/Contents/Info.plist"],
              :dependencies => [info_plist_file,
                                "#{bundle_name}/Contents"],
              :command => "cp '#{info_plist_file}' '#{bundle_name}/Contents/'",
              :message => "Copying Info.plist File #{bundle_name}/Contents/Info.plist")
    else
        build(:targets => ["#{bundle_name}/Contents/Info.plist"],
              :dependencies => ["#{bundle_name}/Contents"],
              :command => "echo '#{info_plist_text(executable_name)}' > '#{bundle_name}/Contents/Info.plist'",
              :message => "Creating Info.plist File #{bundle_name}/Contents/Info.plist")
    end
end
