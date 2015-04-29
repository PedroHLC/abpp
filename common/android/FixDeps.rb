#!/usr/bin/env ruby

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'io.rb'
PathMngr.require :common, 'android/utils.rb'

class FixDepsToAndroid < Patch
	IGNORE = ['cmake','make']
	
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
		
		alldepends = pkgbuild.find_multivar('depends')
		alldepends[:all].each { |depends|
			next if depends.value.empty?
			depends.value.each {|v|
				if IGNORE.include?(Utils.unquote(v))
					next
				elsif v[0] == ?' or v[0] == ?"
					v.insert(1, $androidenv.pkgfullprefix)
				else
					v.insert(0, $androidenv.pkgfullprefix)
				end
			}
		}
	end
end

@@LAST_ADDED = COMMON['android/FixDeps'] = FixDepsToAndroid

end #namespace