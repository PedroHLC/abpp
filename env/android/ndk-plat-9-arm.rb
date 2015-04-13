#!/usr/bin/env ruby

require_relative '../../common/android/utils.rb'

$androidenv = ABPP::AndroidEnviroment.new(
	'android', #"pkgname" prefix
	9,'arm','arm-linux-androideabi', '4.8', #Platform number, cpu arch, target, toolchain version
	'/opt/android-ndk/platforms/android-9/arch-arm', #Sys root
	'/opt/android-ndk/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-${ndk_hostarch}' #Toolchain root
)