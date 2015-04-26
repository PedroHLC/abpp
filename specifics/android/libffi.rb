#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../known_commands.rb'
require_relative '../../common/android/Autoconf.rb'

module ABPP

class LibFFIToAndroid < Patch
	DELETEDEPS = [$androidenv.pkgfullprefix+'glibc']
	
	def initialize(target)
		super(target)
		@depends = [AutoconfToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'] == nil
		@target.cache['libffi.install'] = :deleted
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.childs.delete_at(*pkgbuild.find_func_index('check'))
		pkgbuild.childs.delete_at(*pkgbuild.find_var_index('checkdepends'))
		pkgbuild.childs.delete_at(*pkgbuild.find_var_index('install'))
		
		pkgbuild.delete_depends(DELETEDEPS)
		
		package = pkgbuild.find_func('package').last
		license_install = package.find_command('install').last
		license_install.arguments[2].sub!('"$pkgdir"', '"${pkgdir}/${ndk_sysroot}"')
	end
end

@@LAST_ADDED = SPECIFICS['android/libffi'] = LibFFIToAndroid

end #namespace