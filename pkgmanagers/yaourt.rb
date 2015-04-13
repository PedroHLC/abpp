#!/bin/ruby

require_relative 'default.rb'

module ABPP

class PkgMngr::Yaourt < PkgMngr::Default
	def initialize (bin='yaourt', makepkg='makepkg')
		super(bin, makepkg)
	end
	
	def install (file_or_pkg_name, asdeps=false)
		if File.exist?(file_or_pkg_name)
			system(@pacman + ' -U ' + file_or_pkg_name + (asdeps ? ' --asdeps' : '') + SILENT)
		else
			system(@pacman + ' -Sa ' + file_or_pkg_name + (asdeps ? ' --asdeps' : '') + SILENT)
		end
	end
	
	def download_source (pkgname, outpath)
		if !outpath.end_with?('/'+pkgname)
			System.log('Outpath rename not supported yet in Yaourt', :error)
			exit()
		end
		path = outpath.rpartition('/').first
		Dir.chdir(path){ system(@pacman + ' -G ' + pkgname + SILENT) }
	end
end

end #namespace