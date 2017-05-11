class lampmodule {

# Apache2 and userdir 
	
	exec {'apt-update':
		command => '/usr/bin/apt-get update',
	}

	package { 'apache2':
		ensure => 'installed',
		allowcdrom => 'true',
		require => Exec['apt-update'],
	}

	service { 'apache2':
		ensure => 'running',
		enable => 'true',
		require => Package['apache2'],
	}

	file { '/var/www/html/index.html':
		content => template('lampmodule/index.html.erb'),
	}

	file { '/home/xubuntu/public_html':
		ensure => 'directory',

	}

	exec { 'userdir':
		notify => Service['apache2'],
		command => '/usr/sbin/a2enmod userdir',
		require => Package['apache2'],
	}


# PHP

	package {'libapache2-mod-php':
		ensure => 'installed',
		notify => Service['apache2'],
		allowcdrom => 'true',
	}

	file { '/etc/apache2/mods-available/php7.0.conf':
		content => template('lampmodule/php7.0.conf.erb'),
		require => Package['libapache2-mod-php'],
		notify => Service['apache2'],
	}

# mySQL

	package {'mysql-server':
		ensure => 'installed',
		root => ['root_password' => 'auto'],
		allowcdrom => 'true',
	}

}
 
