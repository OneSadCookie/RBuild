#!/usr/bin/env ruby

require 'fileutils'

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
            
        puts(@message)
        command_output = `#{@command}`
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
    
end

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
                @targets[dependency] ||= BuildTarget.new(dependency)
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

end

build_environment = BuildEnvironment.new()

build_script_text = ''
File.open('build.rb', 'rb') do |file|
    build_script_text = file.read
end

build_environment.instance_eval(build_script_text,
                                File.expand_path('build.rb'))

begin
    if ARGV.include?('clean') then
        build_environment.clean()
    else
        build_environment.execute()
    end
rescue BuildFailedError => build_error
    puts("Build Failed: #{build_error}")
end