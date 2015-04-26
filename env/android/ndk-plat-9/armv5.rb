#!/usr/bin/env ruby

require_relative '../../../common/android/utils.rb'

ndk = '/opt/android-ndk'
ndk_target_platform = 9
ndk_target_arch = 'arm'
ndk_target_host = "#{ndk_target_arch}-linux-androideabi"
ndk_target_tc = ndk_target_host
ndk_target_tcver = '4.9'
ndk_target_tcdir = "#{ndk_target_tc}-#{ndk_target_tcver}"
ndk_target_cxxstldir = "gnu-libstdc++/#{ndk_target_tcver}"

ndk_sysroot = "#{ndk}/platforms/android-#{ndk_target_platform}/arch-arm"
ndk_toolchainroot = "#{ndk}/toolchains/#{ndk_target_tcdir}/prebuilt/linux-${ndk_hostarch}"
ndk_cxxstlroot = "#{ndk}/sources/cxx-stl/#{ndk_target_cxxstldir}"

$androidenv = ABPP::AndroidEnviroment.new(
	'android', #"pkgname" prefix
	ndk_target_platform,
	ndk_target_arch,
	ndk_target_host,
	ndk_target_tcver,
	ndk_sysroot,
	ndk_toolchainroot,
	{
		'CFLAGS'=>[:append_end, '-march=armv5'],
		'LDFLAGS'=>[:append_end,'-Wl,--fix-cortex-a8'],
		'CXXFLAGS'=>[:append_end,"-march=armv5 -I\\\"#{ndk_cxxstlroot}/include\\\" -I\\\"#{ndk_cxxstlroot}/libs/armeabi/include\\\" -L\\\"#{ndk_cxxstlroot}/libs/armeabi\\\""]
	} #Sys enviroments variables
)