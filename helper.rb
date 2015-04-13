#!/usr/bin/env ruby

$ABPP_PATH = File.expand_path(File.dirname(__FILE__))

require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: abpp [cmd] [options] [pkgname] [?patchname] [?outpath]\n\tcmd: [download/common/specific/custom]\n\toptions:\n\t--env=VALUE #VALUE can be a file path or a predefined name for build settings\n\t--patchdeps #Also patchs any non-installed deps"
end.parse!

#!TODO
=begin

require 'fileutils'
require File.join($ABPP_PATH, 'io.rb')
require File.join($ABPP_PATH, 'pkgmanagers/yaourt.rb')

$pkgmngr = ABPP::PkgMngr::Yaourt.new()
$pkgmngr.download_source(TEST_PKGNAME, TEST_INPATH)

test_pkg = ABPP::Package.new(TEST_INPATH)
patch = ABPP::LibFFIToAndroid.new(test_pkg)
patch.apply()

FileUtils.mkdir(TEST_OUTPATH) if !Dir.exists?(TEST_OUTPATH)
test_pkg.save_in(TEST_OUTPATH)
=end
