class socorro-api inherits socorro-web {
     file { 
        '/var/log/httpd/socorro-api':
            require => Package[apache2],
            owner => root,
            group => root,
            mode  => 755,
            ensure => directory;

        '/etc/apache2/sites-available/socorro-api':
            require => Package[apache2],
            alias => 'socorro-api-vhost',
            owner => root,
            group => root,
            mode  => 644,
            ensure => present,
	    notify => Service[apache2],
	    source => "/vagrant/files/etc_apache2_sites-available/socorro-api";

	'/var/run/wsgi':
	    ensure => directory;

    }

    exec {
        '/usr/sbin/a2ensite socorro-api':
            alias => 'enable-socorro-api-vhost',
            refreshonly => true,
            require => File['socorro-api-vhost'],
    }

    include socorro-python
}
