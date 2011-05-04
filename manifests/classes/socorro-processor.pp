
class socorro-processor inherits socorro-python {
    file {
        '/home/socorro/temp':
	    require => User[socorro],
            owner => socorro,
            group => socorro,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;

	 "/mnt/socorro":
	    ensure => directory;
	 "/mnt/socorro/symbols":
	    ensure => directory;
	}
# FIXME replace w/ supervisor
#    service {
#	"socorro-processor":
#            enable => false,
#            ensure => running,
#	    hasstatus => true,
#	    subscribe => File["etc-socorro"],
#            require => File["/etc/init.d/socorro-processor"];
#    }
    package { 
	"nfs-common": 
            require => Exec['apt-get-update'],
            ensure => "latest";
    }   

# FIXME
#    mount { 
#	"/mnt/socorro/symbols":
#	    device => $fqdn ? {
#		/nfs_server_here$/ => "nfs_server_ip_here:/vol/socorro/symbols",
#		default => "nfs_server_ip_here:/vol/pio_symbols",
#		},
#	    require => File['/mnt/socorro/symbols'],
#	    ensure => mounted,
#	    fstype => nfs,
#	    options => "ro,noatime,nolock,nfsvers=3,proto=tcp";
#    }
}
