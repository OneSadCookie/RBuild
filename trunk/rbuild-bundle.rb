def build_bundle(parameters)
    bundle_name = parameters[:bundle_name] ||
        raise(BuildFailedError, "Must specify :bundle_name")
    resources_directory = parameters[:resources_directory]
    application_signature = parameters[:application_signature] || '????'
    info_plist_file = parameters[:info_plist_file]
    
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
        raise(BuildFailedError,
              'Need to implement automatic Info.plist generation')
    end
end
