class lampmodule {
	
	package { "apache2":
		ensure => "installed",
		allowcdrom => "true",
	}

	service { "apache2":
		ensure => "running",
		enable => "true",
		require => Package["apache2"],
	}

	file { "/var/www/html/index.html":
		content => template("lampmodule/index.html.erb"),
	}

	file { "/home/xubuntu/public_html/index.html":
		content => template("lampmodule/index.html.erb"),
		require => File["/home/xubuntu/public_html"],
	}

	file { "/home/xubuntu/public_html":
		ensure => "directory",

	}

	exec { "userdir":
		notify => Service["apache2"],
		command => "/usr/sbin/a2enmod userdir",
		require => Package["apache2"],
	}
}
