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
        return if self.exists?
    
        if @command == nil then
            raise(BuildFailedError, "No rule to build #{@path}")
        end
    
        @dependencies.each_key do |dependency|
            if !dependency.exists? then
                dependency.execute()
            end
        end
    
        puts(@message)
        if !system(@command) then
            puts(@command)
            puts("Exited with status #{$?}")
            raise(BuildFailedError, "Failed to build #{@path}")
        end
    end
    
    def clean()
        if @command != nil && File.exists?(@path) then
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
#rescue => BuildFailedError
#    puts("Build Failed: ")
end