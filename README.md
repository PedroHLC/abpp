# abpp
Universal patcher for ArchBuild-like source packages

## Test instructions
At this version, you still need to create a ruby file for testing it
```
#!/bin/ruby

require 'fileutils'
require_relative './abpp/main.rb'
require_relative './abpp/known_commands.rb'
require_relative './abpp/io.rb'
require_relative './abpp/common/android/Autoconf.rb'

test_pkg = ABPP::Package.new('./mesa')
patch = ABPP::AutoconfToAndroid.new(test_pkg)
patch.apply()

output_dir = './android-mesa'
FileUtils.mkdir(output_dir) if !Dir.exists?(output_dir)
test_pkg.save_in(output_dir)
```
