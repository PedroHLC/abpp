#!/usr/bin/env ruby

require_relative '../../main.rb'

module ABPP

class AndroidEnviroment
	attr_reader :pkgprefix, :platform, :arch, :sysroot, :target, :toolchainver, :toolchainroot
	
	def initialize (pkgprefix, platform, arch, target, toolchainver, sysroot, toolchainroot)
		@pkgprefix = pkgprefix
		@platform = platform
		@arch = arch
		@sysroot = sysroot
		@toolchainroot = toolchainroot
		@target = target
		@toolchainver = toolchainver
	end
	
	def self.check_loaded() 
		if $androidenv.nil?
			Utils.log('Android enviroment configuration was not loaded', :error)
			exit()
		end
	end
end

end