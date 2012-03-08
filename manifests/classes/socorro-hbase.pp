class socorro-hbase {

    file {
	'/etc/apt/sources.list.d/cloudera.list':
            source => '/vagrant/files/etc_apt_sources.list.d/cloudera.list',
            require => Exec['add-cloudera-key'];
    }

    package {
        'hadoop-hbase':
            ensure => 'present',
            require => [Exec['apt-get-update-cloudera']];

        'hadoop-hbase-master':
            ensure => 'present',
            require => Package['hadoop-hbase'];

        'hadoop-hbase-thrift':
            ensure => 'present',
            require => Package['hadoop-hbase'];

        'curl':
            require => Exec['apt-get-update'],
            ensure => 'present';

        'liblzo2-dev':
            ensure => 'present';
    }

    exec { 
        'apt-get-update-cloudera':
            command => '/usr/bin/apt-get update',
            require => [Exec['install-oracle-jdk'],
                        File['/etc/apt/sources.list.d/cloudera.list']];
    }

    exec {
        '/usr/bin/curl -s http://archive.cloudera.com/debian/archive.key | /usr/bin/sudo /usr/bin/apt-key add -':
            alias => 'add-cloudera-key',
            require => Package['curl'];
    }

    # FIXME add real LZO support, remove hack here
    exec {
        '/bin/cat /home/socorro/dev/socorro/analysis/hbase_schema | sed \'s/LZO/NONE/g\' | /usr/bin/hbase shell':
            alias => 'hbase-schema',
            unless => '/bin/echo "describe \'crash_reports\'" | /usr/bin/hbase shell  | grep "1 row"',
            require => Service['hadoop-hbase-master'];
    }

    service {
        hadoop-hbase-thrift:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => [Package['hadoop-hbase-thrift'], Service['hadoop-hbase-master']];

        hadoop-hbase-master:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => [Package['hadoop-hbase-master'], File['hbase-configs']];
    }

}

