Vagrant::Config.run do |config|
  config.vm.box = "socorro-all"
  config.vm.network "33.33.33.10"
  # enable this to see the GUI if vagrant cannot connect
  #config.vm.boot_mode = :gui
  config.vm.provision :puppet do |puppet|
    puppet.manifest_file = "init.pp"
    puppet.options = "--verbose --debug"
  end
end
