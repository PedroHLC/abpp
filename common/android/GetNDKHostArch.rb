#!/usr/bin/env ruby

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'io.rb'
PathMngr.require :common, 'android/utils.rb'

class GetNDKHostArch < Patch
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
		
		default_hostarch = Variable.new('ndk_hostarch', '"$CARCH"', pkgbuild)
		special_hostarch = Command.new('[ $CARCH == i686 ]', ['&&','ndk_hostarch="x86"'], pkgbuild) #!TODO: Handle this one better and beautier
		
		pkgbuild.childs.insert(0, default_hostarch)
		pkgbuild.childs.insert(1, special_hostarch)
	end
end

@@LAST_ADDED = COMMON['android/GetNDKHostArch'] = GetNDKHostArch

end #namespace