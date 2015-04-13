#!/bin/ruby

require_relative 'main.rb'

module ABPP
KnownCommands = Module.new

class KnownCommands::Configure < Command
	def with (key)
		return if @arguments.include?("--with-#{key}")
		i = @arguments.index("--without-#{key}")
		set_argument(i, "--with-#{key}")
	end
	
	def without (key)
		return if @arguments.include?("--without-#{key}")
		i = @arguments.index("--with-#{key}")
		set_argument(i, "--without-#{key}")
	end
	
	def enable (key)
		return if @arguments.include?("--enable-#{key}")
		i = @arguments.index("--disable-#{key}")
		set_argument(i, "--enable-#{key}")
	end
	
	def disable (key)
		return if @arguments.include?("--disable-#{key}")
		i = @arguments.index("--enable-#{key}")
		set_argument(i, "--disable-#{key}")
	end
	
	def feature_state (key)
		return true if @arguments.include?("--enable-#{key}")
		return false if @arguments.include?("--disable-#{key}")
		return nil #not found
	end
	
	def package_state (key)
		return true if @arguments.include?("--with-#{key}")
		return false if @arguments.include?("--without-#{key}")
		return nil #not found
	end
	
	def set_var (key, value)
		z = '--'+key+'='
		@arguments.each_with_index {|arg,i|
			if arg.start_with?(z)
				@arguments[i] = z+value
				return
			end
		}
		@arguments << z+value
	end
end

#!TODO: Export

#!TODO: Make

end #namespace