# abpp
Universal patcher for ArchBuild-like source packages

## Test instructions
Link 'helper.rb' as  'abpp' in any folder listed in your PATH envvar.

The following example will **D**ownload, **P**atch, save to './output', **M**ake and **I**nstall 'libffi' for Android (targeting ARMv5 using NDK Platform 9)
Run anywhere where you have write permissions:
```
abpphelper -DPMI --output=./output --env=android/ndk-plat-9/armv5 libffi android
```

For command options help, use:
```
abpphelper --help
```

## Custom patch create instructions
```
#!/usr/bin/env ruby

require 'abpp/main.rb'

class CustomPatchUniqueClass < ABPP::Patch
	def initialize(target)
		super(target)
		# Loads/Interprets file we want to patch which were not loaded yet
		if @target.cache['PKGBUILD'] == nil
			@target.cache['PKGBUILD'] = ABPP::PKGBUILD.new (target)
		end
	end
	
	def apply()
		super()
		# Alias
		pkgbuild  = @target.cache['PKGBUILD']
		
		# Search last occurence of 'pkgname' position
		original_pkgname_index = pkgbuild.find_var_index('pkgname').last
		
		# Rename that last occurence of 'pkgname'
		pkgbuild.childs[original_pkgname_index].rename('pkgname_example')
		
		# Creates a new variable
		example_var = Variable.new('somenewvariable', "${some_bash_env}", pkgbuild)
		
		# Add variable to file
		pkgbuild.childs.insert(original_pkgname_index+1, example_var)
	end
end

# Add patch as the specific one for some package
ABPP.LAST_ADDED = ABPP::SPECIFICS['patch/pkgname'] = CustomPatchUniqueClass

```
