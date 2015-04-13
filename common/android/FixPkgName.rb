#!/usr/bin/env ruby

require_relative '../../main.rb'
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
		pkgbuild.childs[original_pkgname_index].rename('pkgname'+SUFIX)
		
		new_pkgname = Variable.new('pkgname', "#{$androidenv.pkgprefix}-#{$androidenv.platform}-#{$androidenv.arch}-${pkgname#{SUFIX}}", pkgbuild)
		pkgbuild.childs.insert(original_pkgname_index+1, new_pkgname)
	end
end

end #namespace