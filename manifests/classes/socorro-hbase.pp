class socorro-hbase {

    file {
	'/etc/apt/sources.list.d/cloudera.list':
            source => '/vagrant/files/etc_apt_sources.list.d/cloudera.list',
            require => Exec['add-cloudera-key'];
    }

    package {
        'hadoop-hbase':
            ensure => 'present',
            require => [Exec['apt-get-update-cloudera'], Package['sun-java6-jdk']];

        'hadoop-hbase-master':
            ensure => 'present',
            require => Package['hadoop-hbase'];

        'hadoop-hbase-thrift':
            ensure => 'present',
            require => Package['hadoop-hbase'];

        'curl':
            require => Exec['apt-get-update'],
            ensure => 'present';
    }

    exec { 
        'apt-get-update-cloudera':
            command => '/usr/bin/apt-get update',
            require => [Exec['update-partner-repo'],
                        File['/etc/apt/sources.list.d/cloudera.list']];
    }

    exec {
        '/usr/bin/curl -s http://archive.cloudera.com/debian/archive.key | /usr/bin/sudo /usr/bin/apt-key add -':
            alias => 'add-cloudera-key',
            require => Package['curl'];
    }

    service {
        hadoop-hbase-thrift:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => Service['hadoop-hbase-master'];

        hadoop-hbase-master:
            enable => true,
            ensure => running,
            hasstatus => true,
            require => Package['hadoop-hbase-master'];
    }

}

