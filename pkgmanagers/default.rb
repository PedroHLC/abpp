#!/bin/ruby

require_relative '../pkgmanager.rb'

module ABPP

class PkgMngr::Default < PkgMngr::Base
	SVN_REPO = 'svn://svn.archlinux.org'
	SILENT = ' >/dev/null'
	
	def initialize (pacman='pacman', makepkg='makepkg')
		@pacman = pacman
		@makepkg = makepkg
	end
	
	def which_repo?(pkgname)
		return `#{@pacman} -Si #{pkgname} 2>/dev/null | sed -n '/^Repo/{s/.*: \(.*\)/\1/p;q}'`
	end
	
	def download_source (pkgname, outpath)
		repo = which_repo? pkgname
		downrepo = ((repo == 'multilib' or repo == 'multilib') ?  'community' : 'packages')
		system("svn export '#{SVN_REPO}/#{downrepo}/#{pkgname}/trunk' #{outpath} --force" + SILENT)
	end
	
	def make (fpath)
		Dir.chdir(fpath){ system(@makepkg+' -sc'+SILENT) }
	end
	
	def install (file_or_pkg_name, asdeps=false)
		if File.exist?(file_or_pkg_name)
			system(@pacman + ' -U ' + file_or_pkg_name + (asdeps ? ' --asdeps' : '') + SILENT)
		else
			system(@pacman + ' -S ' + file_or_pkg_name + (asdeps ? ' --asdeps' : '') + SILENT)
		end
	end
	
	def uninstall (pkgname)
		system("#{@pacman} -Rsn #{pkgname}" + SILENT)
	end
end

end #namespace