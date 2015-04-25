#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../io.rb'
require_relative 'utils.rb'

module ABPP

class FixDepsToAndroid < Patch
	def initialize(target)
		AndroidEnviroment.check_loaded()
		super(target)
		if @target.cache['PKGBUILD'] == nil
			@target.cache['PKGBUILD'] = PKGBUILD.new (target)
		end
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		dependencies = pkgbuild.find_var('depends').last
		if !dependencies.nil? and !dependencies.value.nil? and !dependencies.value.empty?
			dependencies.value.each { |v|
				if v[0] == ?' or v[0] == ?"
					v.insert(1, $androidenv.pkgfullprefix)
				else
					v.insert(0, $androidenv.pkgfullprefix)
				end
			}
		end
	end
end

@@LAST_ADDED = COMMON['android/FixDeps'] = FixDepsToAndroid

end #namespace