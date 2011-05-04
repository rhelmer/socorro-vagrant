class socorro-monitor inherits socorro-python {

# FIXME replace w/ supervisor
#    file {
#	"/etc/init.d/socorro-monitor":
#	    ensure => link,
#            require => Exec['socorro-install'],
#	    target => "/data/socorro/application/scripts/init.d/socorro-monitor";
#    }

# FIXME replace w/ supervisor
#    service {
#	"socorro-monitor":
#            enable => false,
#            ensure => running,
#	    hasstatus => true,
#	    subscribe => File["etc-socorro"],
#            require => File["/etc/init.d/socorro-monitor"];
#    }

# TODO enable cronjobs

}
