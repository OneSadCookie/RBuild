#!/usr/bin/env ruby

require 'fileutils'

$: << File.dirname($0)

$verbose = ARGV.include?('--verbose') || ARGV.include?('-v')

def backtrace
    begin
        raise 'no error'
    rescue => e
        trace = e.backtrace
        trace.shift
        return trace
    end
end

class BuildFailedError < Exception
end

class BuildTarget

    def initialize(path)
        @path = path
        @command = nil
        @message = nil
        @dependencies = {}
    end
    
    def set_command(command, message=nil)
        if @command != nil && command != @command then
            raise(BuildFailedError, "Multiple commands to build #{@path}")
        end
    
        @command = command
        @message = message || command
    end
    
    def add_dependency(dependency)
        @dependencies[dependency] = true
    end
    
    def exists?()
        return File.exists?(@path)
    end
    
    def execute()    
        if @command == nil then
            if self.exists? then
                return File.mtime(@path)
            else
                raise(BuildFailedError, "No rule to build #{@path}")
            end
        end
    
        newest_dependency_time = Time.at(0)
        @dependencies.each_key do |dependency|
            dependency_time = dependency.execute()
            newest_dependency_time =
                dependency_time if dependency_time > newest_dependency_time
        end
        
        if self.exists? then
            my_time = File.mtime(@path)
            if my_time >= newest_dependency_time then
                return my_time
            end
        end
        
        FileUtils::mkdir_p(File.dirname(@path))
        
        puts(if $verbose then @command else @message end)
        command_output = _run(@command)
        if $? != 0 then
            puts(@command)
            puts(command_output)
            puts("Exited with status #{$? >> 8}")
            raise(BuildFailedError, "Failed to build #{@path}")
        end
        
        return newest_dependency_time
    end
    
    def clean()
        if @command != nil && File.exists?(@path) then
            puts("Removing #{@path}")
            FileUtils::rm_rf(@path)
        end
    end
    
    def dump()
        puts "#{@path} : #{@command} ( #{@dependencies.keys.collect { |dependency| dependency.path }.join(',')} )"
    end
    
    if RUBY_PLATFORM =~ /mswin32/ then
        def _escape(command)
            command.gsub(/"/, '\"')
        end
        
        def _run(command)
            # how to find out where MSYS is?
            `c:\\Devel\\MSYS\\1.0\\bin\\sh.exe -c "#{_escape(@command)}"`
        end
    else
        def _run(command)
            `#{@command}`
        end
    end
    
    attr_reader :path
    protected :path
    
end

class AlwaysBuildTarget

    def exists?()
        true
    end
    
    def execute()
        Time.now() + (60 * 60 * 24 * 7)
    end
    
    def clean()
    end
    
    def path()
    	'<Always Build>'
    end
    
    def dump()
        puts "always build"
    end

end

ALWAYS_BUILD = AlwaysBuildTarget.new

class BuildEnvironment

    def initialize()
        @targets = {}
    end

    def build(parameters)
        targets = parameters[:targets] || []
        dependencies = parameters[:dependencies] || []
        command = parameters[:command] ||
            raise(BuildFailedError, "No command to build #{targets}")
        message = parameters[:message]
        
        targets.each do |target|
            @targets[target] ||= BuildTarget.new(target)
            @targets[target].set_command(command, message)
            
            dependencies.each do |dependency|
                if dependency.kind_of?(AlwaysBuildTarget) then
                    @targets[dependency] = dependency
                else
                    @targets[dependency] ||= BuildTarget.new(dependency)
                end
                @targets[target].add_dependency(@targets[dependency])
            end
        end
    end
    
    def execute()
        @targets.each_value do |target|
            target.execute()
        end
    end
    
    def clean()
        @targets.each_value do |target|
            target.clean()
        end
    end
    
    def dump()
        @targets.each do |product, target|
            target.dump
        end
    end

end

build_environment = BuildEnvironment.new()

build_script_text = ''
File.open('build.rb', 'rb') do |file|
    build_script_text = file.read
end

build_environment.instance_eval(build_script_text,
                                File.expand_path('build.rb'))

#build_environment.dump if $verbose

begin
    if ARGV.include?('clean') then
        build_environment.clean()
    else
        build_environment.execute()
    end
rescue BuildFailedError => build_error
    puts("Build Failed: #{build_error}")
    exit(1)
end
