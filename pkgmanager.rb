#!/bin/ruby

require_relative 'main.rb'

module ABPP
PkgMngr = Module.new

class PkgMngr::Base
	def which_repo?(pkgname)
		return nil
	end
	
	def download_source (pkgname, outpath)
		return false
	end
	
	def make (fpath)
		return false
	end
	
	def install (file_or_pkg_name, asdeps=false)
		return false
	end
	
	def uninstall (pkgname)
		return false
	end
end

end #namespace