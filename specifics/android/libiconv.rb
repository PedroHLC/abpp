#!/usr/bin/env ruby

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'known_commands.rb'
PathMngr.require :common, 'android/Autoconf.rb'

class LibIConvToAndroid < Patch
	def initialize(target)
		super(target)
		@depends = [AutoconfToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'].nil?
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		build_i = pkgbuild.find_func_index('build').last
		build  = pkgbuild.childs[build_i]
		
		#!TODO: Move instead of destroy and recreate
		build.deleteall_command('sed')
		build.childs.delete_at(build.find_command_index('cp').last)
		
		prepare = Function.new('prepare', [], pkgbuild)
		prepare.childs.push(Command.new('cd', ['"${srcdir}/${pkgname'+FixPkgNameToAndroid::SUFIX+'}-${pkgver}"'], prepare))
		prepare.childs.push(Command.new('sed', ['\'/LD_RUN_PATH/d\'', '-i','Makefile.in'], prepare))
		pkgbuild.childs.insert(build_i, prepare)
		build_i = nil
		
		confg_i = build.find_command_index_pertype(KnownCommands::Configure).first
		config  = build.childs[confg_i]
		
		#!TODO: Find a better fix :D
		config.set_var('host',$androidenv.target.gsub('androideabi','gnueabi'))
		
		#!TODO: Disable CLI
		
		build.childs.insert(confg_i, Command.new('cp', ['-f', '"${ndk_sysroot}/usr/include/stdio.h"', 'srclib/stdio.in.h'], build))
		confg_i = nil
		
		package = pkgbuild.find_func('package').last
		make_install = package.find_command('make').last
		make_install.arguments[1].sub!('/usr', '/${ndk_sysroot}/usr')
		package.find_command('mv').each { |mv_func|
			mv_func.arguments[0].gsub!('${pkgdir}', '"${pkgdir}/${ndk_sysroot}"')
		}
		
		# Let's make it compatible with glibc iconv, as Android doesn't use glibc at all #!SHOULDN'T BE REQUIRED AT ALL
		#package.childs.push(Command.new('ln', ['-s','"${pkgdir}/${ndk_sysroot}"/usr/include/{libiconv.h,iconv.h}'], prepare))
		#package.childs.push(Command.new('ln', ['-s','"${pkgdir}/${ndk_sysroot}"/usr/bin/{libiconv,iconv}'], prepare))
		config.arguments.delete_if{|a| a.start_with?('LIBDIR=') } if config.arguments.is_a?(Array)
		package.deleteall_command('mv')
	end
end

@@LAST_ADDED = SPECIFICS['android/libiconv'] = LibIConvToAndroid

end #namespace