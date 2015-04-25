#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../known_commands.rb'
require_relative '../../common/android/Autoconf.rb'

module ABPP

class LibFFIToAndroid < Patch
	def initialize(target)
		super(target)
		@depends = [AutoconfToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'] == nil
		@target.cache['libffi.install'] = :deleted
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.childs.delete_at(pkgbuild.find_func_index('check').last)
		pkgbuild.childs.delete_at(pkgbuild.find_var_index('checkdepends').last)
		pkgbuild.childs.delete_at(pkgbuild.find_var_index('install').last)
		
		dependencies = pkgbuild.find_var('depends').last
		if !dependencies.nil? and !dependencies.value.nil? and !dependencies.value.empty?
			dependencies.value.each_with_index { |v,i|
				next if !v.include?('-glibc')
				dependencies.value.delete_at(i)
				break
			}
		end
		
		package = pkgbuild.find_func('package').last
		license_install = package.find_command('install').last
		license_install.arguments[2].sub!('"$pkgdir"', '"${pkgdir}/${ndk_sysroot}"')
	end
end

@@LAST_ADDED = SPECIFICS['android/libffi'] = LibFFIToAndroid

end #namespace