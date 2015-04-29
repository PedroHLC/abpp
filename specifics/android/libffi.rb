#!/usr/bin/env ruby

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'known_commands.rb'
PathMngr.require :common, 'android/Autoconf.rb'

class LibFFIToAndroid < Patch
	DELETEDEPS = [$androidenv.pkgfullprefix+'glibc']
	
	def initialize(target)
		super(target)
		@depends = [AutoconfToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'].nil?
		@target.cache['libffi.install'] = Install.new('libffi.install', target)	if @target.cache['libffi.install'].nil?
	end
	
	def apply()
		super()
		install = @target.cache['libffi.install']
		
		infodir = install.find_var('infodir').first
		infodir.set_value(File.join($androidenv.sysroot, infodir.value[0]))
		
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.deleteall_func('check')
		pkgbuild.deleteall_var('checkdepends')
		
		pkgbuild.delete_depends(DELETEDEPS)
		
		package = pkgbuild.find_func('package').last
		license_install = package.find_command('install').last
		license_install.arguments[2].sub!('"$pkgdir"', '"${pkgdir}/${ndk_sysroot}"')
	end
end

@@LAST_ADDED = SPECIFICS['android/libffi'] = LibFFIToAndroid

end #namespace