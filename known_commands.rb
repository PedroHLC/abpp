#!/bin/ruby

require_relative 'main.rb'

module ABPP
KnownCommands = Module.new

class KnownCommands::Configure < Command
	def with (key)
		return if @arguments.include?("--with-#{key}")
		i = @arguments.index("--without-#{key}")
		if i.nil?
			@arguments << "--with-#{key}"
		else
			@arguments[i] = "--with-#{key}"
		end
	end
	
	def without (key)
		return if @arguments.include?("--without-#{key}")
		i = @arguments.index("--with-#{key}")
		if i.nil?
			@arguments << "--without-#{key}"
		else
			@arguments[i] = "--without-#{key}"
		end
	end
	
	def enable (key)
		return if @arguments.include?("--enable-#{key}")
		i = @arguments.index("--disable-#{key}")
		if i.nil?
			@arguments << "--enable-#{key}"
		else
			@arguments[i] = "--enable-#{key}"
		end
	end
	
	def disable (key)
		return if @arguments.include?("--disable-#{key}")
		i = @arguments.index("--enable-#{key}")
		if i.nil?
			@arguments << "--disable-#{key}"
		else
			@arguments[i] = "--disable-#{key}"
		end
	end
	
	def get_feature_state (key)
		return true if @arguments.include?("--enable-#{key}")
		return false if @arguments.include?("--disable-#{key}")
		return nil #not found
	end
	
	def get_package_state (key)
		return true if @arguments.include?("--with-#{key}")
		return false if @arguments.include?("--without-#{key}")
		return nil #not found
	end
end

end #namespace