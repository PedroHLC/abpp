#!/usr/bin/env ruby

require_relative '../../main.rb'

module ABPP

class AndroidEnviroment
	attr_accessor :pkgprefix, :platform, :arch, :sysroot, :target, :toolchainver, :toolchainroot, :sysenv, :pkgfullprefix
	
	def initialize (pkgprefix, platform, arch, target, toolchainver, sysroot, toolchainroot, sysenv)
		@pkgprefix = pkgprefix
		@platform = platform
		@arch = arch
		@sysroot = sysroot
		@toolchainroot = toolchainroot
		@target = target
		@toolchainver = toolchainver
		@sysenv = sysenv
		@pkgfullprefix = "#{@pkgprefix}-#{@platform}-#{@arch}-"
	end
	
	def self.check_loaded() 
		if $androidenv.nil?
			Utils.log('Android enviroment configuration was not loaded', :error)
			exit()
		end
	end
end

end