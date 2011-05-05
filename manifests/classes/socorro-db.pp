class socorro-db inherits socorro-base {
    # FIXME upgrade to postgres 9
    package {
	'postgresql-8.4':
            alias => 'postgresql',
            require => Exec['apt-get-update'],
	    ensure => 'present';

	'postgresql-plperl-8.4':
            alias => 'postgresql-plperl',
            require => Package['postgresql'],
	    ensure => 'present';

	'postgresql-contrib':
            require => Package['postgresql'],
	    ensure => 'present';
    }

    exec {
        '/usr/bin/createdb breakpad':
            require => Package['postgresql'],
            unless => '/usr/bin/psql --list breakpad',
            alias => 'create-breakpad-db',
            user => 'postgres';
    }

    exec {
        '/usr/bin/psql -c "create role breakpad_rw login password \'aPassword\'"':
            alias => 'create-breakpad-role',
            refreshonly => true,
            user => 'postgres',
            require => Exec['create-breakpad-db'];
    }

    exec {
        '/usr/bin/psql -c "grant all on database breakpad to breakpad_rw"':
            alias => 'grant-breakpad-access',
            refreshonly => true,
            user => 'postgres',
            require => Exec['create-breakpad-role'];
    }

    exec {
        '/usr/bin/psql breakpad < /usr/share/postgresql/8.4/contrib/citext.sql':
            user => 'postgres',
            refreshonly => true,
            require => [Exec['create-breakpad-db'], Package['postgresql-contrib']];
    }

    exec {
        '/usr/bin/psql -c "create language plpgsql" breakpad':
            user => 'postgres',
            refreshonly => true,
            require => Exec['create-breakpad-db'];
    }

    exec {
        '/usr/bin/psql -c "create language plperl" breakpad':
            user => 'postgres',
            refreshonly => true,
            require => [Exec['create-breakpad-db'], Package['postgresql-plperl']];
    }

    exec {
        '/usr/bin/createdb test':
            require => Package['postgresql'],
            unless => '/usr/bin/psql --list test',
            alias => 'create-test-db',
            user => 'postgres';
    }

    exec {
        '/usr/bin/psql -c "create role test login password \'aPassword\'"':
            alias => 'create-test-role',
            user => 'postgres',
            refreshonly => true,
            require => Exec['create-test-db'];
    }

    exec {
        '/usr/bin/psql -c "grant all on database test to test"':
            alias => 'grant-test-access',
            user => 'postgres',
	    refreshonly => true,
            require => Exec['create-test-role'];
    }

    exec {
        '/usr/bin/psql test < /usr/share/postgresql/8.4/contrib/citext.sql':
            user => 'postgres',
	    refreshonly => true,
            require => [Exec['create-test-db'], Package['postgresql-contrib']];
    }

    exec {
        '/usr/bin/psql -c "create language plpgsql" test':
            user => 'postgres',
	    refreshonly => true,
            require => Exec['create-test-db'];
    }

    exec {
        '/usr/bin/psql -c "create language plperl" test':
            user => 'postgres',
	    refreshonly => true,
            require => [Exec['create-test-db'], Package['postgresql-plperl']];
    }

}
