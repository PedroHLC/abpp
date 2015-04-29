#!/usr/bin/env ruby

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'io.rb'
PathMngr.require :abpp, 'known_commands.rb'
PathMngr.require :common, 'android/GetNDKHostArch.rb'
PathMngr.require :common, 'android/FixPkgName.rb'
PathMngr.require :common, 'android/FixDeps.rb'

class AutoconfToAndroid < Patch
	DEPS = ['\'android-ndk\'']
	BIN = "${ndk_toolchainroot}/bin/${ndk_target}-"
	SYSENVS = {
		'PKG_CONFIG_PATH' => [:replace, '${ndk_sysroot}/usr/lib/pkgconfig'],
		'CC' => [:replace, "#{BIN}gcc --sysroot=${ndk_sysroot}"],
		'CXX' => [:replace, "#{BIN}g++ --sysroot=${ndk_sysroot}"],
		'AR' => [:replace, "#{BIN}ar"],
		'LD' => [:replace, "#{BIN}ld"],
		'RANLIB' => [:replace, "#{BIN}ranlib"]
	}
	
	def initialize(target)
		super(target)
		@depends = [GetNDKHostArch, FixPkgNameToAndroid, FixDepsToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'] == nil
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.find_var('arch').last.set_value('\'any\'')
		pkgbuild.set_option('strip', false)
		pkgbuild.set_option('buildflags', false)
		pkgbuild.set_option('makeflags', false)
		pkgbuild.set_option('staticlibs', true)
		
		pkgbuild.childs.insert(0, Variable.new('ndk_target', $androidenv.target, pkgbuild))
		pkgbuild.childs.insert(1, Variable.new('ndk_sysroot', $androidenv.sysroot, pkgbuild))
		
		pkgbuild.append_depends(DEPS)
		
		pkgdescs = pkgbuild.find_multivar('pkgdesc')
		pkgdescs[:all].each {|pkgdesc|
			pkgdesc.set_value("\"#{Utils.unquote(pkgdesc.value[0])} (${ndk_target})\"")
		}
		
		build = pkgbuild.find_func('build').last
		new_i = build.find_var_index('cd').first
		build.childs.insert(new_i+=1, Variable.new('ndk_toolchainroot', $androidenv.toolchainroot, build))
		build.childs.insert(new_i+=1, *Utils.virtualenv_to_bash(SYSENVS.merge($androidenv.sysenv), build))
		
		confg = build.find_command_pertype(KnownCommands::Configure).first
		confg.enable('static')
		confg.disable('shared')
		confg.set_var('prefix','${ndk_sysroot}/usr')
		confg.set_var('host','${ndk_target}')
	end
end

@@LAST_ADDED = COMMON['android/Autoconf'] = AutoconfToAndroid

end #namespace