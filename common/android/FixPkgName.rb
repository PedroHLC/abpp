#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../io.rb'
require_relative 'utils.rb'

module ABPP

class FixPkgNameToAndroid < Patch
	SUFIX = '_befdroid'
	
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
		
		original_pkgname_index = pkgbuild.find_var_index('pkgname').last
		original_pkgname = pkgbuild.childs[original_pkgname_index]
		original_pkgname.rename('pkgname'+SUFIX)
		
		if original_pkgname.value.size == 1
			new_pkgname = Variable.new('pkgname', "#{$androidenv.pkgfullprefix}${pkgname#{SUFIX}}", pkgbuild)
			pkgbuild.childs.insert(original_pkgname_index+1, new_pkgname)
		elsif original_pkgname.value.size > 1
			new_values = []
			original_pkgname.value.each { |v|
				if v[0] == ?' or v[0] == ?"
					v.insert(1, $androidenv.pkgfullprefix)
				else
					v.insert(0, $androidenv.pkgfullprefix)
				end
			}
		end
	end
end

@@LAST_ADDED = COMMON['android/FixPkgName'] = FixPkgNameToAndroid

end #namespace