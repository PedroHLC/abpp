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
		
		build = pkgbuild.find_func('build').last
		confg = build.find_command_pertype(KnownCommands::Configure).first
		confg.enable('static')
		confg.disable('shared')
		confg.set_var('prefix','${ndk_sysroot}')
		confg.set_var('host','${ndk_target}')
		
		package = pkgbuild.find_func('package').last
		license_install = package.find_command('install').last
		license_install.arguments[2].sub!('"$pkgdir"', '"${pkgdir}/${ndk_sysroot}"')
	end
end

SPECIFICS['libffi'] = LibFFIToAndroid

end #namespace