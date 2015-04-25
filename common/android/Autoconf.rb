#!/usr/bin/env ruby

require_relative '../../main.rb'
require_relative '../../io.rb'
require_relative '../../known_commands.rb'
require_relative 'GetNDKHostArch.rb'
require_relative 'FixPkgName.rb'
require_relative 'FixDeps.rb'

module ABPP

class AutoconfToAndroid < Patch
	DEPS = ['\'android-ndk\'']
	
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
		pkgbuild.set_option('libtool', false)
		pkgbuild.set_option('staticlibs', true)
		
		pkgbuild.childs.insert(0, Variable.new('ndk_target', $androidenv.target, pkgbuild))
		pkgbuild.childs.insert(1, Variable.new('ndk_sysroot', $androidenv.sysroot, pkgbuild))
		
		alldepends = pkgbuild.find_multivar('depends')
		if alldepends[:all].empty?
			dependencies = Variable.new('depends', DEPS, pkgbuild)
			pkgbuild.childs.insert(pkgbuild.find_var_index('source').first, dependencies)
		else
			alldepends[:all].each {|dependencies| dependencies.value.push(*DEPS) }
		end
		
		
		pkgdescs = pkgbuild.find_multivar('pkgdesc')
		pkgdescs[:all].each {|pkgdesc|
			pkgdesc.set_value("\"#{Utils.unquote(pkgdesc.value[0])} (${ndk_target})\"")
		}
		
		build = pkgbuild.find_func('build').last
		build.childs.insert(1, Variable.new('ndk_toolchainroot', $androidenv.toolchainroot, build))
		build.childs.insert(2, Command.new('export', ['PKG_CONFIG_PATH="${ndk_sysroot}/usr/lib/pkgconfig"'], build))
		toolchain_bin_prefix = "${ndk_toolchainroot}/bin/${ndk_target}-"
		build.childs.insert(3, Command.new('export', ['CC="'+toolchain_bin_prefix+'gcc --sysroot=${ndk_sysroot}"'], build))
		build.childs.insert(4, Command.new('export', ['AR="'+toolchain_bin_prefix+'ar"'], build))
		build.childs.insert(5, Command.new('export', ['LD="'+toolchain_bin_prefix+'ld"'], build))
		build.childs.insert(6, Command.new('export', ['RANLIB="'+toolchain_bin_prefix+'ranlib"'], build))
		build.childs.insert(7, *Utils.virtualenv_to_bash($androidenv.sysenv, build))
		
		confg = build.find_command_pertype(KnownCommands::Configure).first
		confg.enable('static')
		confg.disable('shared')
		confg.set_var('prefix','${ndk_sysroot}/usr')
		confg.set_var('host','${ndk_target}')
	end
end

@@LAST_ADDED = COMMON['android/Autoconf'] = AutoconfToAndroid

end #namespace