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
            unless => '/usr/bin/psql -c "SELECT rolname from pg_roles where rolname = \'breakpad_rw\'" breakpad | grep breakpad_rw',
            user => 'postgres',
            require => Exec['create-breakpad-db'];
    }

    exec {
        '/usr/bin/psql -c "grant all on database breakpad to breakpad_rw"':
            alias => 'grant-breakpad-access',
            user => 'postgres',
            require => Exec['create-breakpad-role'];
    }

    exec {
        '/usr/bin/psql breakpad < /usr/share/postgresql/8.4/contrib/citext.sql':
            user => 'postgres',
            require => [Exec['create-breakpad-db'], Package['postgresql-contrib']];
    }

    exec {
        '/usr/bin/psql -c "create language plpgsql" breakpad':
            user => 'postgres',
            unless => '/usr/bin/psql -c "SELECT lanname from pg_language where lanname = \'plpgsql\'" breakpad | grep plpgsql',
            alias => 'create-language-plpgsql',
            require => Exec['create-breakpad-db'];
    }

    exec {
        '/usr/bin/psql -c "create language plperl" breakpad':
            user => 'postgres',
            unless => '/usr/bin/psql -c "SELECT lanname from pg_language where lanname = \'plperl\'" breakpad | grep plperl',
            alias => 'create-language-plperl',
            require => [Exec['create-language-plpgsql'], Package['postgresql-plperl']];
    }

    exec {
        '/usr/bin/psql -c "CREATE TABLE sessions ( session_id varchar(127) NOT NULL, last_activity integer NOT NULL, data text NOT NULL, CONSTRAINT session_id_pkey PRIMARY KEY (session_id), CONSTRAINT last_activity_check CHECK (last_activity >= 0))" breakpad':
            alias => 'create-sessions-table',
            user => 'postgres',
            unless => '/usr/bin/psql -c "SELECT relname from pg_class where relname = \'sessions\'" breakpad | grep sessions',
            require => Exec['create-language-plperl'];
    }

    exec {
        '/usr/bin/psql -c "ALTER TABLE sessions OWNER TO breakpad_rw" breakpad':
            alias => 'alter-sessions-table',
            user => 'postgres',
            require => [Exec['create-sessions-table'], Exec['create-breakpad-role']];
    }

    exec {
        '/usr/bin/psql -c "INSERT INTO productdims (product, version, branch) values (\'GenericProduct\', \'1.0\', \'1.0\')" breakpad':
            alias => 'insert-productdims',
            unless => '/usr/bin/psql -c "select id from productdims where id = \'1\'" breakpad | grep " 1"',
            user => 'postgres',
            require => Exec['setup-schema'];
    }

    exec {
        '/usr/bin/psql -c "INSERT INTO product_visibility (productdims_id, start_date, end_date, featured) VALUES (1, \'2010-11-05\', \'2015-02-05\', true)" breakpad':
            alias => 'insert-product_visibility',
            unless => '/usr/bin/psql -c "select productdims_id from product_visibility where productdims_id = \'1\'" breakpad | grep " 1"',
            user => 'postgres',
            require => Exec['insert-productdims'];
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
            unless => '/usr/bin/psql -c "SELECT rolname from pg_roles where rolname = \'test\'" test | grep test',
            user => 'postgres',
            require => Exec['create-test-db'];
    }

    exec {
        '/usr/bin/psql -c "grant all on database test to test"':
            alias => 'grant-test-access',
            user => 'postgres',
            require => Exec['create-test-role'];
    }

    exec {
        '/usr/bin/psql test < /usr/share/postgresql/8.4/contrib/citext.sql':
            user => 'postgres',
            require => [Exec['create-test-db'], Package['postgresql-contrib']];
    }

    exec {
        '/usr/bin/psql -c "create language plpgsql" test':
            user => 'postgres',
            unless => '/usr/bin/psql -c "SELECT lanname from pg_language where lanname = \'plpgsql\'" test | grep plpgsql',
            require => Exec['create-test-db'];
    }

    exec {
        '/usr/bin/psql -c "create language plperl" test':
            user => 'postgres',
            unless => '/usr/bin/psql -c "SELECT lanname from pg_language where lanname = \'plperl\'" test | grep plperl',
            require => [Exec['create-test-db'], Package['postgresql-plperl']];
    }

    service {
        'postgresql-8.4':
            enable => true,
            alias => postgresql,
            require => Package['postgresql'],
            ensure => running;
    }

}
