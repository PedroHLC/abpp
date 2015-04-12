#!/bin/ruby

require 'fileutils'
require_relative 'main.rb'
require_relative 'known_commands.rb'

module ABPP

module Utils
	DEBUG_ALLOW=[:error]
	REGEX_SHELLTOKEN_SCANNER = /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|\#.*\n|[^\s\=]*\$\{\S*\}\S*|\-\S*|(?<!\\)[\(\)\=\{\},\n]|[^\s#\(\)=\{\},\\]*/
	
	def self.list_shell_tokens (str)
		results = []
		str.scan(REGEX_SHELLTOKEN_SCANNER) {|match| results << match }
		return results
	end
	
	def self.debug (str, target=:info)
		puts str if (DEBUG_ALLOW.include?(target))
	end
	
	def self.next_util_token (token_list, ti)
		ti+=1
		while (token_list[ti] == "\n")
			ti+=1
		end
		return ti
	end
	
	def self.recursive_files (path)
		result = []
		remove = File.join(path,'z').size-1
		Dir.glob(File.join(path,'**', '*')) do |path|
			result << path[remove..path.size] unless FileTest.directory?(path)
		end
		return result
	end
end

module ErrorHander
	def self.unexpected_token (token, level, ti, trace)
		Utils.debug(sprintf('### Unexpected token(%d) founded: \'%s\' at %s through \'%s\'', ti, token, level, trace), :error)
		exit();
	end
end

class ShellDocument
	def initialize (filename, package)
		@childs = []
		@applied_patchs = []
		@package = package
		@beautify = true
		@filename = filename
		revert()
	end
	
	def interpret (token_list, ti, level)
		tl = token_list.size
		token = token_list[ti]
		while (ti < tl)
			if token[0] == ?#
				Utils.debug('< Comment: '+token)
				token = token_list[ti+=1]
				next
			elsif token[0] == ?} || token == nil #EOF
				level.pop
				return ti+1
			elsif token == "\n"
				Utils.debug('< Empty line', :flood)
				token = token_list[ti+=1]
				next
			elsif token.strip.size == 0
				Utils.debug('< Empty token', :flood)
				token = token_list[ti+=1]
			elsif
				token = token_list[ti+=1]
				if token[0] == ?(
					params = []
					key = token_list[ti-1]
					Utils.debug('? Function or command?: '+key)
					
					if token.size > 1 # Bug bypass
						if token[token.size-1] == ?)
							params << token[1..token.size-2]
						end
						params << token[1..token.size-1]
					end
					
					loop do
						token = token_list[ti+=1]
						return ti if (token == nil)
						if token[0] == ?)
							token = token_list[ti+=1]
							break;
						elsif token[0] == ?,
							Utils.debug('< Useless comma')
						elsif token.strip.size == 0
							Utils.debug('< Empty token', :flood)
						else
							Utils.debug('< Argument: '+token)
							params << token
						end
					end if token[token.size-1] != ?)
					
					loop do
						next_ti = Utils.next_util_token(token_list, ti)
						token = token_list[ti=next_ti] if token_list[next_ti][0] == ?{
						
						if token[0] == ?{
							Utils.debug('< Function: '+key)
							if token[0].size > 1
								Utils.debug('! Ignoring 1 token by accident, regex code maybe is needing a revision', :error)
							end
							token = token_list[ti+=1]
							
							#Add function
							if key.include?('/configure')
								func_final = KnownCommands::Configure(key, params, level.last) 
							else
								func_final = Function.new(key, params, level.last)
							end
							level.last.childs << func_final
							level << func_final
							ti = interpret(token_list, ti, level)
							
							Utils.debug('X Finished func: '+key)
							break
						elsif token == "\n" or token[0] == ?;
							Utils.debug('< Shell Command: '+key)
							token = token_list[ti+=1]
							command_final = Command.new(key, params, level.last, true)
							level.last.childs << command_final
							break
						elsif token.strip.size == 0
							Utils.debug('< Empty token', :flood)
						else
							ErrorHander.unexpected_token(token, level, ti, '?FunCmd');
						end
					end
				elsif token[0] == ?= and !token_list[ti-1].include?('$')
					var_name = token_list[ti-1]
					var_value = nil
					token = token_list[ti+=1]
					if token[0] == ?(
						var_value=[]
						if token.size > 1 # Bug bypass
							if token[token.size-1] == ?)
								var_value << token[1..token.size-2]
							end
							var_value << token[1..token.size-1]
						end
						loop do
							token = token_list[ti+=1]
							if token[0] == ?)
								token = token_list[ti+=1]
								break
							elsif token.strip.size == "\n"
								Utils.debug('< Empty line', :flood)
							elsif token.strip.size == 0
								Utils.debug('< Empty token', :flood)
							else
								var_value << token
							end
						end if token[token.size-1] != ?)
					else
						var_value = token
						
						loop do
							token = token_list[ti+=1]
							if token == "\n" or token[0] == ?;
								token = token_list[ti+=1]
								break
							elsif token.strip.size == 0
								Utils.debug('< Empty token', :flood)
							else
								break
							end
						end
					end
					Utils.debug('< Variable "'+var_name+'", value: '+var_value.to_s)
					
					var_final = Variable.new(var_name, var_value, level.last)
					level.last.childs << var_final
				elsif token == "\n"
					key = token_list[ti-1]
					Utils.debug('< Simple command: "'+key+'"')
					command_final = Command.new(key, nil, level.last)
					level.last.childs << command_final
					token = token_list[ti+=1]
				else
					key = token_list[ti-1]
					params = []
					
					loop do
						if token == "\n" or token[0] == ?;
							token = token_list[ti+=1]
							break
						elsif token.strip.size == 0
							Utils.debug('< Empty token', :flood)
						else
							params << token
						end
						token = token_list[ti+=1]
					end
					
					Utils.debug('< Complex command: "'+key+'", params:'+params.to_s)
					command_final = Command.new(key, params, level.last)
					level.last.childs << command_final
				end
			end
		end
		# Shouldn't happen at all...
		Utils.debug('< Probably overflowed', :warning)
		level.pop
		return ti
	end
	
	def revert #loads or undo any unsaved modification
		file = File.new(File.join(@package.path, @filename), 'rb')
		interpret(Utils.list_shell_tokens(file.read.to_s), 0, [self])
		file.close
	end
	
	def save_as (new_path)
		file = File.new(File.join(new_path, @filename), 'wb')
		dump(file, -1, @beautify)
		file.close
	end
end

class Package
	def save_in (new_path)
		@cache.each { |doc_path, doc_val| 
			doc_val.save_as(new_path) if !doc_val.nil?
		}
		file_list = Utils.recursive_files(@path)#Dir[ File.join(@path, '**', '*') ].reject { |p| File.directory? p }
		file_list.each { |filename|
			if @cache[filename].nil?
				dest = File.join(new_path, filename)
				if !File.exist?(dest)
					src = File.join(@path, filename)
					FileUtils.copy(src, dest)
				end
			end
		}
		@path = new_path
	end
end

end #namespace