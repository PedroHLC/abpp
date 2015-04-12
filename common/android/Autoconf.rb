#!/bin/ruby

require_relative '../../main.rb'
require_relative '../../known_commands.rb'
require_relative '../../io.rb'
require_relative 'FixPkgName.rb'

module ABPP

class AutoconfToAndroid < Patch
	def initialize(target)
		super(target)
		@depends = [FixPkgNameToAndroid]
	end
	
	def apply()
		super()
	end
end

end #namespace