#!/usr/bin/env ruby

module ABPP
attr_accessor :LAST_ADDED

@@LAST_ADDED = nil
SPECIFICS = {}
COMMON = {}

module Utils
	DEBUG_ALLOW=[:error] #:error :warning :info :flood
	REGEX_BASHVAR_SCANNER = /\$\{(\w*)\}|\$(\w*)/
	
	def self.list_shell_varref (str)
		results = {}
		# TODO: Ignore Backslash
		str.scan(REGEX_BASHVAR_SCANNER).each {|var|
			result = nil
			if !var[0].nil? and !var[0].empty?
				result = var[0]
			elsif !var[1].nil? and !var[1].empty?
				result = var[1]
			end
			results[result] = result if !result.nil?
		}
		return results.values
	end
	
	def self.log (str, target=:info)
		puts str if (DEBUG_ALLOW.include?(target))
	end
	
	def self.unquote (str)
		match = /"(.*)"|'(.*)'/.match(str)
		if !match
			return str
		elsif !match[1].nil?
			return match[1]
		elsif !match[2].nil?
			return match[2]
		end
	end
end

PathMngr = Class.new do
	attr_reader :paths, :selfpath
	def initialize
		@selfpath = File.expand_path(File.dirname(__FILE__))
		@usrpath = File.join(Dir.home, '.local', 'share', 'abpp')
		
		common = [File.join(@selfpath, 'common'), File.join(@usrpath, 'common')]
		env = [File.join(@selfpath, 'env'), File.join(@usrpath, 'env')]
		specifics = [File.join(@selfpath, 'specifics'), File.join(@usrpath, 'specifics')]
		pkgmanagers = [File.join(@selfpath, 'pkgmanagers'), File.join(@usrpath, 'pkgmanagers')]
		
		common.push(*ENV['ABPP_COMMON_PATH'].split(';'))		if !ENV['ABPP_COMMON_PATH'].nil? and !ENV['ABPP_COMMON_PATH'].empty?
		env.push(*ENV['ABPP_ENV_PATH'].split(';'))				if !ENV['ABPP_ENV_PATH'].nil? and !ENV['ABPP_ENV_PATH'].empty?
		specifics.push(*ENV['ABPP_SPECIFICS_PATH'].split(';'))	if !ENV['ABPP_SPECIFICS_PATH'].nil? and !ENV['ABPP_SPECIFICS_PATH'].empty?
		pkgmanagers.push(*ENV['ABPP_PKGMNGR_PATH'].split(';'))	if !ENV['ABPP_PKGMNGR_PATH'].nil? and !ENV['ABPP_PKGMNGR_PATH'].empty?
		
		@paths = {
			:abpp => [@selfpath],
			:common => common,
			:env => env,
			:specifics => specifics,
			:pkgmanagers => pkgmanagers
		}
	end
	
	def require (source, filepathname)
		@paths[source].reverse_each { |basepath|
			trying = File.join(basepath, filepathname)
			if File.exist?(trying)
				Kernel.require(trying)
			end
		}
	end
end.new

module Parent
	def on_obj_rename (old_name, new_name)
		@childs.each { |ch|
			if (ch.is_a?(ABPP::Variable)  && ch.depends.include?(old_name))
				ch.value.each { |val|
					val.gsub!(/\$\{#{old_name}\}|\$#{old_name}\b/, '${'+new_name+'}')
				}
			elsif (ch.is_a?(Command)  && !ch.depends.nil? && ch.depends.include?(old_name))	
				ch.key.gsub!(/\$\{#{old_name}\}|\$#{old_name}\b/, '${'+new_name+'}')
				ch.arguments.each { |arg|
					arg.gsub!(/\$\{#{old_name}\}|\$#{old_name}\b/, '${'+new_name+'}')
				}
			elsif ch.is_a?(Function)
				ch.on_obj_rename(old_name, new_name)
			end
		}
	end
	
	def append (another)
		another.childs.each {|ch|
			n = ch.dup
			n.on_newparent(self)
			@childs << n
		}
	end
	
	def dump (out, indent, beautiful)
		@childs.each { |ch|
			ch.dump(out, indent+1, beautiful)
		}
	end
	
	def find_regex_perkey (regex, allow=[:var, :func, :cmd, :others])
		result = {}
		@childs.each_with_index { |ch,i|
			next if (ch.is_a?(ABPP::Variable) and !(allow.include?(:var))) or
				(ch.is_a?(Command) and !(allow.include?(:cmd))) or
				(ch.is_a?(Variable) and !(allow.include?(:func))) or
			result[i] = ch if ch.key =~ regex
		}
		return result
	end
	
	def deleteall_pertype (type)
		@childs.delete_if { |ch| ch.is_a?(type) }
	end
end

class Variable
	attr_reader :key, :parent, :value, :depends
	
	def initialize (key, value, parent)
		@key = key
		@parent = parent
		self.set_value(value)
	end
	
	def set_value (new_value)
		if new_value.is_a?(Array)
			@value = new_value
			@depends = Utils.list_shell_varref(@value.join(' '))
		else
			@value = [new_value.to_s]
			@depends = Utils.list_shell_varref(new_value.to_s)
		end
	end
	
	def append_value (value)
		@value << value.to_s
		@depends = Utils.list_shell_varref(@value.join(' '))
	end
	
	def remove_value (value)
		@value.delete(value)
		@depends = Utils.list_shell_varref(@value.join(' '))
	end
	
	def rename (new_key, update_global=true)
		parent.on_obj_rename(@key, new_key) if update_global
		@key = new_key
	end
	
	def on_newparent (new_parent,new_key=nil)
		@parent = new_parent
		@key = new_key if !new_key.nil?
		# Says hello to your new father!
	end
	
	def dump (out, indent, beautiful)
		out.write ("\t"*indent) if beautiful
		out.write @key
		out.write '='
		 if @value.size > 1
			out.write '('
			out.write @value.join (' ')
			out.write ')'
		elsif @value.size == 1 and (val = @value[0])[0] != ?' and val =~ /[^$]{/
			out.write '('
			out.write val
			out.write ')'
		elsif @value.size == 0
			out.write '()' #Is this right??
		else
			out.write @value.join (' ')
		end
		out.write(beautiful ? "\n" : ';')
	end
end

module VariablesParent
	include Parent
	
	def find_var_index (key)
		results = []
		@childs.each_with_index { |ch,i|
			results << i if ch.key == key
		}
		return results
	end
	
	def find_var (key)
		results = []
		@childs.each { |ch|
			if ch.is_a?(Variable)
				results << ch if ch.key == key
			end
		}
		return results
	end
	
	def deleteall_var (key)
		@childs.delete_if { |ch| ch.is_a?(Variable) and ch.key == key }
	end
end

class Command
	attr_reader :key, :parent, :arguments, :depends
	attr_accessor :internal
	
	def initialize (key, arguments, parent, internal=false)
		@key = key
		set_arguments(arguments) #array please
		@parent = parent
		@internal = internal
	end
	
	def set_arguments(new_arguments)
		@arguments = new_arguments
		@depends = ((!new_arguments.nil? and !new_arguments.empty?) ? Utils.list_shell_varref(@key + ' ' + @arguments.join(' ')) : nil)
	end
	
	def set_argument(i, value)
		@arguments = [] if @arguments.nil?
		if i.nil?
			@arguments << value
		elsif @arguments[i].nil?
			@arguments.insert(i, value)
		else
			@arguments[i] = value
		end
		@depends = Utils.list_shell_varref(@key + ' ' + @arguments.join(' '))
	end
	
	def rename (new_key, update_global=true)
		parent.on_obj_rename(@key, new_key) if update_global
		@key = new_key
	end
	
	def on_newparent (new_parent,new_key=nil)
		@parent = new_parent
		@key = new_key if !new_key.nil?
		# Says hello to your new father!
	end
	
	def dump (out, indent, beautiful)
		out.write ("\t"*indent) if beautiful
		out.write @key
		out.write(internal ? '(' : ' ')
		out.write @arguments.join (' ') if !@arguments.nil? and !@arguments.empty?
		out.write ')' if internal
		out.write(beautiful ? "\n" : ';')
	end
end

module CommandsParent
	include Parent
	
	def find_command_index (key)
		results = []
		@childs.each_with_index { |ch,i|
			results << i if ch.key == key
		}
		return results
	end
	
	def find_command (key)
		results = []
		@childs.each { |ch|
			results << ch if ch.key == key
		}
		return results
	end
	
	def find_command_index_pertype (type)
		results = []
		@childs.each_with_index { |ch,i|
			results << i if ch.is_a?(type)
		}
		return results
	end
	
	def find_command_pertype (type)
		results = []
		@childs.each { |ch|
			results << ch if ch.is_a?(type)
		}
		return results
	end
	
	def deleteall_command (key)
		@childs.delete_if { |ch| ch.is_a?(Command) and ch.key == key }
	end
end

class Function
	include VariablesParent
	include CommandsParent
	
	attr_reader :key, :parent
	attr_accessor :parameters, :childs
	
	def initialize (key, parameters, parent)
		@key = key
		@parameters = parameters
		@childs = []
	end
	
	def rename (new_key, update_global=true)
		parent.on_obj_rename(@key, new_key) if update_global
		@key = new_key
	end
	
	def on_newparent (new_parent,new_key=nil)
		@parent = new_parent
		@key = new_key if !new_key.nil?
		# Says hello to your new father!
	end
	
	def depends
		results = []
		@childs.each { |ch|
			results.concat(ch.depends) if !ch.depends.nil?
		}
		return results.uniq
	end
	
	def split_target		
		return @key.rpartition('_')
	end
	
	def dump (out, indent, beautiful)
		out.write ("\t"*indent) if beautiful
		out.write @key
		out.write '('
		out.write @parameters.join (',')
		out.write ') {'
		out.write "\n" if beautiful
		super(out, indent, beautiful)
		out.write ("\t"*indent) if beautiful
		out.write '}'
		out.write "\n" if beautiful
	end
end

module FunctionsParent
	include Parent
	
	def find_func_index (key)
		results = []
		@childs.each_with_index { |ch,i|
			results << i if ch.key == key
		}
		return results
	end
	
	def find_func (key)
		results = []
		@childs.each { |ch|
			results << ch if ch.key == key
		}
		return results
	end
	
	def deleteall_func (key)
		@childs.delete_if { |ch| ch.is_a?(Function) and ch.key == key }
	end
end

class Document
	def revert
		# Please, implement!
	end
	def save_as (new_path)
		# Please, implement!
	end
end

class ShellDocument < Document
	include VariablesParent
	include FunctionsParent
	include CommandsParent
	
	attr_accessor :childs,:beautify
	
	def initialize (filename, package)
		@childs = []
		@package = package
		@beautify = true
	end
end

class PKGBUILD < ShellDocument
	def initialize(package)
		super('PKGBUILD', package)
	end
	
	def set_check_sum (i, sum)
		#TODO!
	end
	
	def set_pgpkey (i, key)
		#TODO!
	end
	
	def set_option (key, value) #value = true, false, nil
		options_var = find_var('options')
		new_value = (value ? "'#{key}'" : "'!#{key}'")
		if options_var.empty?
			options_var = Variable.new('options', new_value, self)
			@childs.insert(find_var_index('source').first, options_var)
		else
			options_var = options_var.last
			options_var.value.each { |val|
				if val.include?(key)
					val = new_value
					return
				end
			}
			options_var.value << new_value
		end
	end
	
	def find_multivar(key)
		result = {}
		result[:all] = []
		result[:main] = find_var(key)
		result[:all].push(*result[:main])
		subpkgs = find_regex_perkey(/package_/, :func)
		return result if subpkgs.empty?
		subpkgs.each { |sp|
			result[sp] = sp.find_var(key)
			result[:all].push(*result[sp])
		}
		return result
	end
	
	def delete_depends(list)
		alldependencies = find_multivar('depends')[:all]
		return if alldependencies.empty?
		alldependencies.each { |dependencies|
			if !dependencies.value.nil? and !dependencies.value.empty?
				dependencies.value.delete_if{ |v| list.include?(Utils.unquote(v)) }
			end
		}
	end
	
	def append_depends(list)
		alldepends = find_multivar('depends')
		if alldepends[:all].empty?
			dependencies = Variable.new('depends', list, self)
			@childs.insert(find_var_index('source').first, dependencies)
		else
			alldepends[:all].each {|dependencies| dependencies.value.push(*list) }
		end
	end
end

class Install < ShellDocument
end

class Package
	attr_accessor :cache, :path, :applied_patchs
	def initialize (path='.')
		@cache = {}
		@path = path
		@applied_patchs = []
	end
end

class Patch
	def initialize (target)
		@depends = [] #Insert classes
		@target = target
	end
	
	def apply_dependencies
		@depends.each { |d|
			if !@target.applied_patchs.include?(d)
				d.new(@target).apply
			end
		}
	end
	
	def apply
		self.apply_dependencies()
	end
end

end #namespace