#
# defines the base classes that all servers share
#

class socorro-base {

    file {
	'/etc/hosts':
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    source => "/vagrant/files/hosts";

	'/data':
            owner => root,
            group => root,
            mode  => 755,
            ensure => directory;

        '/data/socorro':
            owner => socorro,
            group => socorro,
            mode  => 755,
	    recurse=> false,
	    ensure => directory;

        '/etc/socorro':
            owner => socorro,
            group => socorro,
            mode  => 755,
	    recurse=> false,
	    ensure => directory;

	 '/etc/socorro/socorrorc':
	    ensure => link,
            require => Exec['socorro-install'],
	    target=> "/data/socorro/application/scripts/crons/socorrorc";

	 'python-configs':
            path => "/data/socorro/application/scripts/config",
            owner => socorro,
            group => root,
            recurse => true,
            require => Exec['socorro-install'],
	    notify => Service[supervisor],
            source => "/vagrant/files/python-configs";

	 'php-configs':
            path => "/data/socorro/htdocs/application/config",
            owner => socorro,
            group => root,
            recurse => true,
            require => Exec['socorro-install'],
            source => "/vagrant/files/php-configs";

# FIXME break this out to separate classes
	 'etc_supervisor':
            path => "/etc/supervisor/conf.d/",
            recurse => true,
            require => [Package['supervisor'], Exec['socorro-install']],
            source => "/vagrant/files/etc_supervisor";

# FIXME
#	 'data-bin':
#	    path => "/data/bin/",
#	    recurse => true,
#	    ignore => [".svn"],
#	    source => "/vagrant/files/data-bin";

        '/var/log/socorro':
            mode  => 644,
	    recurse=> true,
	    ensure => directory;

	'/home/socorro/persistent':
	    owner => socorro,
	    group => socorro,
	    ensure => directory;

    }

    file {
        '/etc/apt/sources.list':
            ensure => file;
    }

    exec {
        '/usr/bin/apt-get update':
            alias => 'apt-get-update';
    }

    exec {
        '/usr/bin/sudo add-apt-repository "deb http://archive.canonical.com/ lucid partner"':
            alias => 'add-partner-repo',
            unless => '/bin/grep "^deb http://archive.canonical.com/ lucid partner" /etc/apt/sources.list',
            require => Package['python-software-properties'];
    }   

    exec {
        'update-partner-repo':
            require => Exec['add-partner-repo'],
            command => '/usr/bin/apt-get update';
    }

    exec {
        '/bin/echo sun-java6-jdk shared/accepted-sun-dlj-v1-1 boolean true | debconf-set-selections':
            alias => 'accept-java',
            require => Exec['update-partner-repo'];
    }

    package {
        'supervisor':
            ensure => present,
            require => Exec['apt-get-update'];

        'libcurl4-openssl-dev':
            require => Exec['apt-get-update'],
            ensure => present;

        'sun-java6-jdk':
            require => [Exec['apt-get-update'], Exec['accept-java']],
            ensure => present;

        'ant':
            require => Package['sun-java6-jdk'],
            ensure => present;

        'python-software-properties':
            require => Exec['apt-get-update'],
            ensure => 'present';
    }

    service {
        supervisor:
            enable => true,
            require => Package['supervisor'],
            ensure => running;
    }

}

class socorro-python inherits socorro-base {

    user { 'socorro':
	ensure => 'present',
	uid => '10000',
	shell => '/bin/bash',
	managehome => true;
    }

    file {
        '/home/socorro':
	    require => User[socorro],
            owner => socorro,
            group => socorro,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;
    }

    file {
        '/home/socorro/dev':
	    require => File['/home/socorro'],
            owner => socorro,
            group => socorro,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;
    }

# FIXME
#	'/home/socorro/.pgpass':
#	    require => User[socorro],
#            owner => socorro,
#            group => socorro,
#            mode  => 600,
#	    source => "puppet://$server/users/socorro/.pgpass";

# FIXME
#        '/etc/logrotate.d/socorro':
#            ensure => present,
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-logrotated/socorro",
#		default => "puppet://$server/modules/socorro/prod/etc-logrotated/socorro",
#		};
    package {
        'python-psycopg2':
            require => Exec['apt-get-update'],
            ensure => present;

	'python-simplejson':
            require => Exec['apt-get-update'],
            ensure => present;

	'subversion':
            require => Exec['apt-get-update'],
            ensure => present;

        'libpq-dev':
            require => Exec['apt-get-update'],
            ensure => 'present';

        'python-virtualenv':
            require => Exec['apt-get-update'],
            ensure => 'present';

        'python-dev':
            require => Exec['apt-get-update'],
            ensure => 'present';

    }

    exec {
        '/usr/bin/svn checkout http://socorro.googlecode.com/svn/trunk/':
            alias => 'socorro-checkout',
            cwd => '/home/socorro/dev',
            timeout => '3600',
            user => 'socorro',
            require => Package['subversion'],
            creates => '/home/socorro/dev/trunk';
    }

    exec {
        '/usr/bin/make install':
            alias => 'socorro-install',
            cwd => '/home/socorro/dev/trunk',
            timeout => '3600',
            require => [Package['libcurl4-openssl-dev'], Exec['socorro-checkout'], 
                        Package['ant'], File['/data/socorro']],
            user => 'socorro';
    }

    exec {
        '/usr/bin/python /data/socorro/application/scripts/setupDatabase.py':
            alias => 'setup-schema',
            environment => ["PYTHONPATH=/data/socorro/application:/data/socorro/thirdparty",
                            "databaseName=breakpad",
                            "databaseUserName=breakpad_rw",
                            "databasePassword=aPassword"],
            timeout => '3600',
            require => [File['python-configs'],
                        Exec['alter-sessions-table']],
            user => 'socorro';
    }
}

class socorro-web inherits socorro-base {

    file {
        '/var/log/httpd':
            owner => root,
            group => root,
            mode  => 755,
            recurse=> true,
            ensure => directory;

# FIXME
#        '/etc/httpd/conf.d/00-custom.conf':
#            require => Package[apache2],
#            owner => root,
#            group => root,
#            mode  => 644,
#            ensure => present,
#	    notify => Service[apache2],
#	    source => "/vagrant/files/etc-httpd-confd/00-custom.conf";

# FIXME 
#        '/etc/sysconfig/httpd':
#            require => Package[apache2],
#            owner => root,
#            group => root,
#            mode  => 644,
#            ensure => present,
#	    notify => Service[apache2],
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-sysconfig/httpd",
#		default => "puppet://$server/modules/socorro/prod/etc-sysconfig/httpd",
#		};
#	
    }

    package {
        'apache2':
            ensure => latest,
            require => [Exec['apt-get-update'], Exec['socorro-install']],
            notify => Service[apache2];

        'libapache2-mod-wsgi':
            require => Package[apache2],
            ensure => 'present';
    }

    service {
        apache2:
            enable => true,
            ensure => running,
            hasstatus => true,
            subscribe => File[python-configs],
            require => [Package[apache2], Exec[enable-mod-rewrite], 
                        Exec[enable-mod-headers], Exec[enable-mod-ssl],
                        File[python-configs], File[php-configs],
                        Package[php5]];
    }

}

class socorro-php inherits socorro-web {

     file { 
        '/var/log/httpd/crash-stats':
            require => Package[apache2],
            owner => root,
            group => root,
            mode  => 755,
            ensure => directory;

        '/etc/apache2/sites-available/crash-stats':
            require => Package[apache2],
            alias => 'crash-stats-vhost',
            owner => root,
            group => root,
            mode  => 644,
            ensure => present,
	    notify => Service[apache2],
	    source => "/vagrant/files/etc_apache2_sites-available/crash-stats";

        '/var/log/socorro/kohana':
            require => Package[apache2],
            owner => www-data,
            group => www-data,
            mode  => 755,
            ensure => directory;

	'/etc/php.ini':
            require => Package[apache2],
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    notify => Service[apache2],
	    source => "/vagrant/files/php.ini";

        '/data/socorro/htdocs/application/logs':
            require => Exec['socorro-install'],
            owner => socorro,
            group => www-data,
            mode => 664,
            ensure => directory;

# FIXME
#        '/etc/logrotate.d/kohana':
#            ensure => present,
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-logrotated/kohana",
#		default => "puppet://$server/modules/socorro/prod/etc-logrotated/kohana",
#		};

    }

    exec {
        '/usr/sbin/a2ensite crash-stats':
            alias => 'enable-crash-stats-vhost',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod rewrite':
            alias => 'enable-mod-rewrite',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod ssl':
            alias => 'enable-mod-ssl',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod headers':
            alias => 'enable-mod-headers',
            require => File['crash-stats-vhost'],
    }

    service {
        memcached:
            enable => true,
            require => Package['memcached'],
            ensure => running;
    }

    package {
        'memcached':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'libcrypt-ssleay-perl':
            require => Exec['apt-get-update'],
	    ensure => 'present';

        'php5-pgsql':
            require => Exec['apt-get-update'],
            ensure => 'present';

        'php5-curl':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-dev':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-tidy':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php-pear':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-common':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-cli':
            require => Exec['apt-get-update'],
            ensure => 'present';

# FIXME
#	'php-pdo':
#            ensure => 'present';
#
#	'php-mbstring':
#            ensure => 'present';

	'php5-memcache':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-gd':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-mysql':
            require => Exec['apt-get-update'],
            ensure => 'present';

	'php5-ldap':
            require => Exec['apt-get-update'],
            ensure => 'present';

# FIXME
#	'php-xml':
#            ensure => 'present';

        'phpunit':
            require => Exec['apt-get-update'],
            ensure => 'present';
    }
}

class socorro-admin inherits socorro-base {
    

# FIXME
#    file {
# FIXME
#	"/root/bin/":
#	    mode => 755,
#	    owner => root,
#	    group => root,
#	    recurse => true,
#	    ignore => [".svn"],
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/admin/scripts/",
#		default => "puppet://$server/modules/socorro/prod/admin/scripts/",
#		};

# FIXME
#	'/data/crash-data-tools/':
#	    recurse => true,
#	    ignore => [".svn"],
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/crash-data-tools/",
#		default => "puppet://$server/modules/socorro/prod/crash-data-tools/",
#		};

# FIXME
#	'/etc/cron.d/socorro':
#	    owner => root,
#	    group => root,
#	    mode => 644,
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-crond/socorro",
#		default => "puppet://$server/modules/socorro/prod/etc-crond/socorro",
#		};

#   }

}
