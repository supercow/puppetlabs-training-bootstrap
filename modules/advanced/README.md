#advanced module

This is the advanced module. It is used for the puppet advanced class to setup 3 different types of machines.  
    * `classroom.puppetlabs.vm` This system is the ca/puppetdb/report server for the classroom.  
    * `proxy.puppetlabs.vm` aka `irc.puppetlabs.vm` This server is used for haproxy and ircd.  
    * `yourname.puppetlabs.vm` For any system thats not the above, assume its a student system.  

The `advanced` class is used to lookup the system type based on its `$::hostname` fact.  
Each type of system will then have `advanced::classroom`,`advanced::proxy`,`advanced::agent` classified respectively. These classes then call classes in respective folders of the same name, i.e. The puppetdb setup for classroom can be found in `./manifests/classroom/puppetdb.pp` and is declared in `./manifests/classroom.pp`.

## Classroom (classroom.puppetlabs.vm)
1. Download a new centos 6+ virtual machine from [downloads](http://downloads.puppetlabs.vm)
2. Setup the hostname to `classroom.puppetlabs.vm` and add `/etc/hosts` entries respectively
3. Install puppet enteprise (standard master installation) PE 2.6.1+ on EL6.3+
4. Add the `advanced` class to the puppet enterprise console (ENC).
5. classify `advanced` on `classroom.puppetlabs.vm`
7. Add `fact_is_puppetmaster` parameter to default group and set to `false`
8. Add `fact_is_puppetmaster` paramter to `classroom.puppetlabs.vm` and set to `true`
9. Trigger an agent run using `puppet agent -t`
10. You should have a `puppetdb` environment with customized `auth.conf` and `site.pp`

Step 8 is currently automated with `advanced::mcollective` but 7 is manual due to missing rake api calls.

## Proxy (proxy.puppetlabs.vm)
1. Download a new debian virtual machine from [downloads](http://downloads.puppetlabs.vm)
2. Setup the hostname to `proxy.puppetlabs.vm` and add `/etc/hosts` entries respectively
3. Add a `/etc/hosts` entry for `classroom.puppetlabs.vm`
4. Install puppet enteprise (standard agent installation) PE 2.6.1+ on
5. Add the enterprise extras repo (currently requires internet access )
 * `wget http://apt-enterprise.puppetlabs.com/puppetlabs-enterprise-release-extras_1.0-2_all.deb`  
 * `sudo dpkg -i puppetlabs-enterprise-release-extras_1.0-2_all.deb`  
 * `sudo apt-get update`  
6. Trigger an agent run using `puppet agent -t`
7. You should have a `haproxy` service and be able to type `irssi` and connect to the course irc channel
8. You can login to haproxy with the following  `http://puppet:puppet@yourip:9090`

Step 5 should go away once the VM is pre built with this.

## Student (yourname.puppetlabs.vm)
1. Download a new Centos 6.3+ virtual machine from [downloads](http://downloads.puppetlabs.vm)
2. Follow the exercise and lab guide no prep is needed from the instructor.

Older 5.8 Virtual machines will not work with the `puppetdb` section.


## Technical Breakdown
***

#### Classroom (classroom.puppetlabs.vm) 
The following files are managed with this module
1. `/etc/puppetlabs/puppet/auth.conf`

We manage `auth.conf` because of the following modification  
`path ~ ^/facts/([^/]+)$
auth yes
method save
allow $1
`  

This allows for the first run of the students machines against `classroom.puppetlabs.vm` to work without having to add each hostname to this file (i.e.`allow yourname.puppetlabs.vm`). After their initial run they will be configured with `puppetdb::master::config` and this setting is moot as `inventory_server` in `puppet.conf` will be ignored.


2. `/etc/puppetlabs/puppet/manifests/site.pp`

We use `site.pp` in this course as the `default` PE/ENC group will not work for the classification timing we have. The students will only do 2 to 3 runs against `classroom.puppetlabs.vm`. In order to classify the `advanced` module we use site.pp so we don't have to run the rake task in a loop i.e.  
`while true ; do /opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile nodegroup:add_all_nodes group=default RAILS_ENV=production ; done`  

Using `site.pp` the `advanced` module is automatically classified during the first run. In addition as its not added to the PE Console/ENC, the students will not receive an error for the missing `advanced` class in their local `modulepath` when they do puppet runs against themselves ( using `classroom.puppetlabs.vm` as the `ENC`).

We automatically remove the `pe_mcollective` class from the ENC using the `advanced::mcollective` class. The `site.pp` file has conditional logic to check for the ENC fact "override" value of `fact_is_puppetmaster`. This will effectively configure the students master machines as if they were a agent only system. This should hopefully be fixed in `pe_mcollective` in the future but its related to the `ca_server` configuration we use in class not working as there is no logic in that modules for a distributed master setup.

Both files are created using the `advanced::template` class. This class is designed to replace the default files created by installation and then not manage them (idempotance is based on the .old file in the same directory). This allows you to be ready for class but also to modify these files during demos in class. We do also manage `autosign.conf` in addition but ensure its content FYI.

### Proxy (proxy.puppetlabs.vm)
Two main classes configure your proxy node. `advanced::proxy::haproxy` and `advanced::irc::server`. The system is debian based mainly out of convenience as all of the packages for `charybdis` are available out of the box (that may change). The haproxy configuration will collect all `haproxy::balancermember` that the students will create. The `advanced::proxy::haproxy` class creates a `haproxy::listen` resources for `puppet00`. This is listening on port 8140 ( this is an agent node so no port conflict or customization is required ). Students should be able to collect the exported resource declared in `advanced::proxy::hostname` to allow for automatic setup of both client and server. The `advanced::irc::client` class includes the `irssi` class for irssi client setup.

License
-------


Contact
-------
zack -@- puppetlabs.com

Support
-------

Please log tickets and issues at our [Projects site](http://projects.puppetlabs.com/projects/puppet-advanced/issues/new)