if RUBY_PLATFORM =~ /darwin/ then
    CCSUFFIX = '-4.0'
    CFLAGS = '-g -Os -Wall -W -Wno-unused-parameter -Wnewline-eof -Werror'
    ENV['MACOSX_DEPLOYMENT_TARGET'] = '10.3'
else
    CCSUFFIX = ''
    CFLAGS = '-g -Os -Wall -W -Wno-unused-parameter -Werror'
end
CC = "/usr/bin/gcc#{CCSUFFIX}"
CXX = "/usr/bin/g++#{CCSUFFIX}"

def which_compiler(source_file)
    extension = source_file.split(/\./)[-1]
    if ['cc', 'C', 'cxx', 'c++', 'cpp', 'mm'].include?(extension) then
        CXX
    else
        CC
    end
end

def dependencies(source_file, compiler)
    `#{compiler} -MM -P #{source_file}`.gsub(/\\/, '').split(' ')[1..-1] || [source_file, ALWAYS_BUILD]
end

DEFAULT_SOURCE_TO_OBJECT_NAME = Proc.new do |source_file|
    base_name = source_file.split(/\./)[0..-2].join('.')
    components = base_name.split(/\//)
    if components[0] =~ /(Source)|(src)/i then
        components[0] = 'Build'
    else
        components.unshift('Build')
    end
    components.join('/') + '.o'
end

def build_objects(parameters)
    sources = parameters[:sources] || return
    source_to_object_name = parameters[:source_to_object_name] ||
        DEFAULT_SOURCE_TO_OBJECT_NAME
    cflags = parameters[:cflags] || CFLAGS
    extra_cflags = parameters[:extra_cflags] || ''
    extra_dependencies = parameters[:extra_dependencies] || []
    
    sources.collect do |source_file|
        compiler = "#{which_compiler(source_file)} #{cflags} #{extra_cflags}"
        object_file = source_to_object_name.call(source_file)
        
        build(:targets => [object_file],
              :dependencies => dependencies(source_file, compiler) +
                               extra_dependencies,
              :command => "#{compiler} -c #{source_file} -o #{object_file}",
              :message => "Compiling #{source_file}")
              
        object_file
    end
end

def build_executable(parameters)
    executable = parameters[:executable] ||
        raise(BuildFailedError, 'build_executable requires an executable name')
    objects = parameters[:objects] || []
    archives = parameters[:archives] || []
    library_search_paths = parameters[:library_search_paths] || []
    libraries = parameters[:libraries] || []
    framework_search_paths = parameters[:framework_search_paths] || []
    frameworks = parameters[:frameworks] || []
    extra_linker_flags = parameters[:extra_linker_flags] || ''
    extra_dependencies = parameters[:extra_dependencies] || []
    
    build(:targets => [executable],
          :dependencies => objects + archives + extra_dependencies,
          :command => "#{CXX} #{extra_linker_flags} -o '#{executable}' #{objects.collect do |object| "'#{object}'" end.join(' ')} #{library_search_paths.collect do |path| "'-L#{path}'" end.join(' ')} #{framework_search_paths.collect do |path| "'-F#{path}'" end.join(' ')} #{archives.join(' ')} #{libraries.collect do |library| "'-l#{library}'" end.join(' ')} #{frameworks.collect do |framework| "-framework '#{framework}'" end.join(' ')}",
          :message => "Linking #{executable}")
end

def build_archive(parameters)
    archive = parameters[:archive] ||
        raise(BuildFailedError, 'build_archive requires an archive name')
    objects = parameters[:objects] || []
    extra_dependencies = parameters[:extra_dependencies] || []
    
    build(:targets => [archive],
          :dependencies => objects + extra_dependencies,
          :command => "ar cru '#{archive}' #{objects.collect do |object| "'#{object}'" end.join(' ')}; ranlib '#{archive}'",
          :message => "Creating Archive #{archive}")
end

def build_plugin(parameters)
    plugin = parameters[:plugin] ||
        raise(BuildFailedError, 'build_plugin requires a plugin name')
    objects = parameters[:objects] || []
    extra_dependencies = parameters[:extra_dependencies] || []
    
    if RUBY_PLATFORM =~ /darwin/ then
        plugin_name = if plugin =~ /\.bundle$/ then plugin else "#{plugin}.bundle" end
        command = "#{CXX} -undefined dynamic_lookup -bundle -o '#{plugin_name}' #{objects.collect do |object| "'#{object}'" end.join(' ')}"
    else
        plugin_name = if plugin =~ /\.so$/ then plugin else "#{plugin}.so" end
        command = "#{CXX} -fPIC -shared -o '#{plugin_name}' #{objects.collect do |object| "'#{object}'" end.join(' ')}"
    end
    
    build(:targets => [plugin_name],
          :dependencies => objects + extra_dependencies,
          :command => command,
          :message => "Creating Plug-In #{plugin}")
end
