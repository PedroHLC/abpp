# abpp
Universal patcher for ArchBuild-like source packages

## Test instructions
At this version, you still need to create a ruby file for testing it
```
#!/bin/ruby

require 'fileutils'
require_relative '../abpp/io.rb'
require_relative '../abpp/common/android/Autoconf.rb'
require_relative '../abpp/pkgmanagers/yaourt.rb'

TEST_PKGNAME = 'libffi'
TEST_INPATH = './'+TEST_PKGNAME
TEST_OUTPATH = './android-'+TEST_PKGNAME

$pkgmngr = ABPP::PkgMngr::Yaourt.new()
$pkgmngr.download_source(TEST_PKGNAME, TEST_INPATH)

$androidenv = ABPP::AndroidEnviroment.new('android', 9 ,'arm', 'arm-linux-androideabi', '4.8',
	'/opt/android-ndk/platforms/android-9/arch-arm',
	'/opt/android-ndk/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-${ndk_hostarch}'
)

test_pkg = ABPP::Package.new(TEST_INPATH)
patch = ABPP::AutoconfToAndroid.new(test_pkg)
patch.apply()

FileUtils.mkdir(TEST_OUTPATH) if !Dir.exists?(TEST_OUTPATH)
test_pkg.save_in(TEST_OUTPATH)
```
