#!/usr/bin/env ruby

require 'digest'

module ABPP

PathMngr.require :abpp, 'main.rb'
PathMngr.require :abpp, 'known_commands.rb'
PathMngr.require :common, 'android/Autoconf.rb'

class GetTextToAndroid < Patch
	DELETEDEPS = [
		$androidenv.pkgfullprefix+'gcc-libs',
		$androidenv.pkgfullprefix+'acl',
		$androidenv.pkgfullprefix+'sh',
		$androidenv.pkgfullprefix+'glib2',
		$androidenv.pkgfullprefix+'libunistring'
	]
	DEPS = [
		"'#{$androidenv.pkgfullprefix}libiconv'"
	]
	ASSETSPATH = File.join(File.expand_path(File.dirname(__FILE__)), 'assets', 'gettext')
	
	def initialize(target)
		super(target)
		@depends = [AutoconfToAndroid]
		@target.cache['PKGBUILD'] = PKGBUILD.new (target) if @target.cache['PKGBUILD'].nil?
		@target.cache['gettext.install'] = Install.new('gettext.install', target) if @target.cache['gettext.install'].nil?
		@target.cache['msginit_fix.patch'] = AssetDocument.new(ASSETSPATH, 'msginit_fix.patch') if @target.cache['msginit_fix.patch'].nil?
	end
	
	def apply()
		super()
		install = @target.cache['gettext.install']
		
		infodir = install.find_var('infodir').first
		infodir.set_value(File.join($androidenv.sysroot, infodir.value[0]))
		
		pkgbuild  = @target.cache['PKGBUILD']
		
		pkgbuild.deleteall_func('check')
		pkgbuild.delete_depends(DELETEDEPS)
		pkgbuild.append_depends(DEPS)
		
		pkgbuild.find_var('source').last.value.push 'msginit_fix.patch'
		
		build  = pkgbuild.find_func('build').last
		
		if (prepare = pkgbuild.find_func('prepare').last).nil?
			prepare = Function.new('prepare', [], pkgbuild)
			pkgbuild.childs.insert(pkgbuild.find_func_index('build').first, prepare)
		end
		prepare.childs.push(Command.new('cd', ['"${srcdir}/gettext-${pkgver}/gettext-tools/src/"'], prepare))
		prepare.childs.push(Command.new('patch', ['-i', '"${srcdir}/msginit_fix.patch"', '-p0'], prepare))
		
		config = build.find_command_pertype(KnownCommands::Configure).first
		
		#!TODO: Find a better fix :D
		config.set_var('host',$androidenv.target.gsub('androideabi','gnueabi'))
		
		config.set_var('cache-file','arm.cache')
		config.enable('threads')
		config.with('included-regex')
		config.with('included-libxml')
		
		#!TODO: Disable only what is really needed to
		config.disable('java')
		config.disable('openmp')
		config.without('libiconv-prefix')
		config.without('libintl-prefix')
		config.without('libglib-2.0-prefix')
		config.without('libcurses-prefix')
		config.without('libncurses-prefix')
		config.without('libcroco-0.6-prefix')
		config.without('libexpat-prefix')
		config.without('libtermcap-prefix')
		config.without('emacs')
		
		#!TODO: Disable CLI
		
		sums = pkgbuild.find_var('md5sums').last
		sums.value.push("'#{@target.cache['msginit_fix.patch'].sum(Digest::MD5)}'")
	end
end

@@LAST_ADDED = SPECIFICS['android/gettext'] = GetTextToAndroid

end #namespace