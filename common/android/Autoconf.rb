#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../io.rb'
require_relative '../../known_commands.rb'
require_relative 'FixPkgName.rb'
require_relative 'GetNDKHostArch.rb'

module ABPP

class AutoconfToAndroid < Patch
	def initialize(target)
		super(target)
		@depends = [FixPkgNameToAndroid, GetNDKHostArch]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'] == nil
	end
	
	def apply()
		super()
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.find_var('arch').last.set_value('\'any\'')
		pkgbuild.set_option('strip', false)
		pkgbuild.set_option('buildflags', false)
		pkgbuild.set_option('makeflags', false)
		pkgbuild.set_option('libtool', false)
		pkgbuild.set_option('staticlibs', true)
		
		pkgbuild.childs.insert(0, Variable.new('ndk_target', $androidenv.target, pkgbuild))
		pkgbuild.childs.insert(1, Variable.new('ndk_sysroot', $androidenv.sysroot, pkgbuild))
		
		pkgbuild.find_var('depends').last.set_value(['\'android-ndk\''])  #!TODO: Add instead
		
		pkgdesc = pkgbuild.find_var('pkgdesc').last
		pkgdesc.set_value("\"#{Utils.unquote(pkgdesc.value[0])} (${_target})\"")
		
		build = pkgbuild.find_func('build').last
		build.childs.insert(1, Variable.new('ndk_toolchainroot', $androidenv.toolchainroot, build))
		build.childs.insert(2, Command.new('export', ['PKG_CONFIG_PATH="${ndk_sysroot}/usr/lib/pkgconfig"'], build))
		build.childs.insert(3, Command.new('export', ['CC="${ndk_toolchainroot}/bin/${ndk_target}-gcc --sysroot=${ndk_sysroot}"'], build))
		build.childs.insert(4, Command.new('export', ['STRIP="${ndk_toolchainroot}/bin/${ndk_target}-strip"'], build))
		build.childs.insert(5, Command.new('export', ['AR="${ndk_toolchainroot}/bin/${ndk_target}-ar"'], build))
		build.childs.insert(6, Command.new('export', ['LD="${ndk_toolchainroot}/bin/${ndk_target}-ld"'], build))
		build.childs.insert(7, Command.new('export', ['RANLIB="${ndk_toolchainroot}/bin/${ndk_target}-ranlib"'], build))
		
		confg = build.find_command_pertype(KnownCommands::Configure).first
		confg.enable('static')
		confg.disable('shared')
		confg.set_var('prefix','${ndk_sysroot}')
		confg.set_var('host','${ndk_target}')
	end
end

@@LAST_ADDED = COMMON['android/Autoconf'] = AutoconfToAndroid

end #namespace