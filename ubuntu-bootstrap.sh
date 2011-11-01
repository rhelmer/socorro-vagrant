#!/bin/bash
#
# Quick bootstrap script for an Ubuntu Lucid host
#
# This allows you to bootstrap any Lucid box (VM, physical hardware, etc)
# using Puppet and automatically install a full Socorro environment on it.
#

GIT_REPO_URL="git://github.com/rhelmer/socorro-vagrant.git"

# Clone the project from github
git clone $GIT_REPO_URL /vagrant
cd /vagrant

# Let puppet take it from here...
puppet /vagrant/manifests/*.pp

