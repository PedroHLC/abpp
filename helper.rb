#!/usr/bin/env ruby

require_relative 'main.rb'

module ABPP

class Helper
	VERSION = "0.0.0"
	ABPP_PATH = File.expand_path(File.dirname(__FILE__))
	
	def self.autoselect_pkgmngr
		require 'mkmf'
		if !(yaourt = find_executable('yaourt')).nil?
			require File.join(ABPP_PATH, 'pkgmanagers/yaourt.rb')
			pkgmngr = ABPP::PkgMngr::Yaourt.new(yaourt)
		elsif !(pacman = find_executable('pacman')).nil?
			require File.join(ABPP_PATH, 'pkgmanagers/default.rb')
			pkgmngr = ABPP::PkgMngr::Default.new(find_executable('pacman'))
		else
			Utils.log('Either \'pacman\' or \'yaourt\' is required', :error)
			return nil
		end
		return pkgmngr
	end
	
	def parse_options (opts)
		opts.banner = "ABPP Helper\n"\
			"\tUsage: abpp [command] [options] [pkg] [?patch]\n"\
			"\tExample: abpp -DP --output='./output' xorg addstatic"
		
		opts.separator ''
		opts.separator 'Commands:'
		
		opts.on('-P', 'Patch a local folder', '([pkg] hast to be a path, unless used with \'-D\')') do |value|
			@options[:patch] = true
		end
		
		opts.on('-D', 'Downloads a package\'s source', '([pkg] hast to be a \'pkgname\')') do |value|
			@options[:download] = true
		end
		
		opts.on('-M', 'Make a package', '([pkg] hast to be a path, unless used with \'-D\')') do |value|
			@options[:make] = true
		end
		
		opts.on('-I', 'Install a package', '(Not implemented yet)') do |value| #[pkg] hast to be a file, unless used with \'-M\', forces \'-M\' when not used alone
			@options[:install] = true
		end
		
		opts.on('-U', 'Uninstall a package', '(Not implemented yet)') do |value| #[pkg] hast to be a \'pkgname\', forces \'-D\' when not used alone
			@options[:uninstall] = true
		end
		
		opts.separator ''
		opts.separator 'Specific @options:'
		
		opts.on('-oVALUE', '--output=VALUE', 'Output path', '(Does nothing with \'-M\')') do |value|
			@options[:output] = value;
		end
		
		opts.on('-eVALUE', '--env=VALUE', 'Build settings file or name') do |value|
			@options[:env] = value;
		end
		
		opts.on('-d', '--[no-]patchdeps', 'Also apply patch to all uninstalled dependencies' , ('Not implemented yet')) do |value|
			@options[:patchdeps] = value;
		end
		
		opts.separator ''
		opts.separator 'Common @options:'
		
		opts.on('-h', '--help', 'Displays this message and exit') do
			puts opts
			exit
		end
		
		opts.on('-v', '--version', 'Displays this program version and exit') do
			puts VERSION
			exit
		end
		
		opts.separator ''
		opts.separator '[patch] can be:'
		opts.separator " * Ruby Script that add a Patch class to ABPP.LAST_ADDED and ABPP::SPECIFIC[target/pkgname]."
		opts.separator " * \"Specific-type Patch\" name with pkgname. (e.g.: 'android/libffi')"
		opts.separator " * \"Specific-type Patch\" name whithout 'pkgname'. (with '-D' only, e.g.: 'android')"
		opts.separator " * \"Common-type Patch\" target and name. (e.g.: 'android/Autoconf')"
		opts.separator " * \"Custom Patch\" file."
		
		opts.separator ''
		opts.separator 'Tricks:'
		opts.separator " * More than one command can be used at once."
		opts.separator "\te.g.: abpp -DPM --output='./test' libffi genstatic"
		opts.separator "\tThis will:"
		opts.separator "\t1) Download 'libffi' in '/tmp/abpp/libffi'"
		opts.separator "\t2) Apply common patch 'genstatic'"
		opts.separator "\t3) Save output to './test'"
		opts.separator "\t4) Build package inside './test'."
	end
	
	def initialize
		@options = {}
		@arguments = []
		
		require 'optparse'
		@options_parser = OptionParser.new do |opts| parse_options (opts) end
		@options_parser.parse!
	end
	
	def run (argv)
		if argv.empty?
			puts @options_parser.help
			return 1
		end

		begin 
			$arguments = @options_parser.parse(argv)
		rescue OptionParser::InvalidOption => e
			Utils.log(e+"\n", :error)
			puts @options_parser.help
			return e
		end

		if @options[:patch].nil? and @options[:download].nil? and @options[:make].nil?
			Utils.log("No command option was founded.", :error)
			return 2
		end

		if !($arguments.size == 2 || ($arguments.size == 1 && (@options[:download] || @options[:make]) && !@options[:patch]))
			Utils.log("Wrong number of arguments.", :error)
			return 3
		end
		
		#!TODO: Uninstall
		
		download_path = nil
		if @options[:download]
			$pkgmngr = Helper.autoselect_pkgmngr if $pkgmngr.nil?
			
			if !@options[:output].nil? and @options[:patch].nil?
				download_path = @options[:output]
				FileUtils::mkdir_p(download_path)
			else
				download_path = File.join('/tmp/abpp/', $arguments[0])
				FileUtils::mkdir_p('/tmp/abpp/')
			end
			
			return 4 if !$pkgmngr.download_source($arguments[0], download_path)
		end
		
		patched_path = nil
		if @options[:patch]
			source_path = (!download_path.nil? ? download_path : $arguments[0])
			if !File.directory?(source_path)
				Utils.log("\"#{source_path}\" isn't a valid directory.", :error)
				return 5
			end
			
			target_patch_type = nil
			if File.exists?($arguments[1])
				require($arguments[1])
				target_patch_type = LAST_ADDED
			elsif File.exists?(patch_fname = File.join(ABPP_PATH, 'specifics', $arguments[1]+'.rb'))
				require(patch_fname)
				target_patch_type = SPECIFICS[$arguments[1]]
			elsif @options[:download] and File.exists?(patch_fname = File.join(ABPP_PATH, 'specifics', $arguments[1], $arguments[0]+'.rb'))
				require(patch_fname)
				target_patch_type = SPECIFICS[$arguments[1]+'/'+$arguments[0]]
			elsif File.exists?(File.join(ABPP_PATH, 'common', $arguments[1]+'.rb'))
				require(patch_fname)
				target_patch_type = COMMON[$arguments[1]]
			else
				Utils.log("\"#{$arguments[1]}\" isn't a valid patch.", :error)
				return 8
			end
			
			if !@options[:env].nil?
				if File.exists?(@options[:env])
					require(@options[:env])
				elsif File.exists?(env_fname = File.join(ABPP_PATH, 'env', @options[:env]+'.rb'))
					require(env_fname)
				else
					Utils.log("\"#{@options[:env]}\" isn't valid.", :error)
					return 9
				end
			end
			
			working_pkg = ABPP::Package.new(source_path)
			target_patch = target_patch_type.new(working_pkg)
			target_patch.apply()
			
			out_path = nil
			if !@options[:output].nil?
				patched_path = @options[:output]
				FileUtils::mkdir_p(patched_path)
			else
				patched_path = File.join(source_path, 'abpp_patched')
				Utils.log("Output not configured, saving in \"#{patched_path}\"", :error)
				FileUtils::mkdir_p(patched_path)
			end
			
			working_pkg.save_in(patched_path)
		end

		if @options[:make]
			if @options[:download] and !@options[:patch]
				source_path = download_path
			elsif @options[:patch]
				source_path = patched_path
			else
				source_path = $arguments[0]
			end
			
			if !File.directory?(source_path)
				Utils.log("\"#{source_path}\" isn't a valid directory.", :error)
				return 6
			end
			
			$pkgmngr = Helper.autoselect_pkgmngr if $pkgmngr.nil?
			
			return 7 if !$pkgmngr.make(source_path)
		end
		
		#!TODO: Install
		
		return true
	end
end

exit if Helper.new.run(ARGV) != true if __FILE__==$0

end #namespace