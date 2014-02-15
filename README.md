#NOTES
Checkout the documentation on the wiki for a step by step intallation.  

https://github.com/schubergphilis/chef-monitor-cookbook/wiki  

You will need to have the following packages installed before the monitor can work:

* private-chef-11.0.2-1.el6.x86_64.rpm
* opscode-manage-1.1.0-1.el6.x86_64.rpm

#ATTRIBUTES

Attribute prefix is: `['chef_monitor']`

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['download_path']</tt></td>
    <td>string</td>
    <td>Download dir for storing the files</td>
    <td><tt>"/opt/chef-monitor/orgs"</tt></td>
  </tr>
  <tr>
    <td><tt>['install_dir']</tt></td>
    <td>string</td>
    <td>Install dir for the tools</td>
    <td><tt>"/opt/chef-monitor"</tt></td>
  </tr>
  <tr>
    <td><tt>['client_key']</tt></td>
    <td>string</td>
    <td>Path to client pem file for authentication</td>
    <td><tt>"/opt/chef-monitor/monitor.pem"</tt></td>
  </tr>
  <tr>
    <td><tt>['node_name']</tt></td>
    <td>string</td>
    <td>Client name for authentication</td>
    <td><tt>"monitor"</tt></td>
  </tr>
  <tr>
    <td><tt>['mq_server']</tt></td>
    <td>string</td>
    <td>IP address or name of the RabbitMQ Server</td>
    <td><tt>"127.0.0.1"</tt></td>
  </tr>
  <tr>
    <td><tt>['mq_queue']</tt></td>
    <td>string</td>
    <td>Queue name for the RabbitMQ Server</td>
    <td><tt>"chef_monitor_tasks"</tt></td>
  </tr>
  <tr>
    <td><tt>['mon_file']</tt></td>
    <td>string</td>
    <td>Path to the nginx access logfile to monitor</td>
    <td><tt>"/var/log/opscode/nginx/access.log"</tt></td>
  </tr>
  <tr>
    <td><tt>['chef_url']</tt></td>
    <td>string</td>
    <td>IP address or name of the chef server</td>
    <td><tt>"https://127.0.0.1"</tt></td>
  </tr>
  <tr>
    <td><tt>['log_dir']</tt></td>
    <td>string</td>
    <td>Directory for the log files</td>
    <td><tt>"/var/log/chef-monitor"</tt></td>
  </tr>
  <tr>
    <td><tt>['pid_dir']</tt></td>
    <td>string</td>
    <td>Directory for the pid files</td>
    <td><tt>"/var/run/chef-monitor"</tt></td>
  </tr>
  <tr>
    <td><tt>['emaildomain']</tt></td>
    <td>string</td>
    <td>Your domain name</td>
    <td><tt>"@your.domain.com"</tt></td>
  </tr>
  <tr>
    <td><tt>['project']</tt></td>
    <td>string</td>
    <td>Your project name, used in the emailsubject</td>
    <td><tt>"CHEF_PROD"</tt></td>
  </tr>
  <tr>
    <td><tt>['orgs']</tt></td>
    <td>hash</td>
    <td>Your organizations that you want to monitor</td>
    <td><tt>"{ "org": { "tag": "ORG", "mailinglist": "your-email@org.com" } }"</tt></td>
  </tr>

</table>

#USAGE

#### chef_monitor::frontend

This will install the chef-monitor gem and the needed configurations on the front-end (web) servers.

No real need to create a role for this, but if you want to do that and override the attributes then you can.

#### chef_monitor::backend

This will install the chef-monitor gem and the needed configurations on the back-end (database or monitoring) servers.

Create a role that contains the cookbook and the following attributes:

Role example:

```json
{
  "name": "chef_monitor",
  "json_class": "Chef::Role",
  "default_attributes": {
    "chef_monitor": {
      "orgs": {
        "acme": { 
          "tag": "ACME",
          "mailinglist": "your_email@acme.com"
        },
        "sushicorp": {
          "tag": "SUSHICORP",
          "mailinglist": "your_email@sushicorp.com"
      }
    }
  },
  "chef_type": "role",
  "run_list": [
    "recipe[chef_monitor::backend]"
  ]
}
```

#COOKBOOK

This cookbook will configure the chef monitoring tool on your back and frontend servers.  
The information here below is needed when you want to configure everything manually.

It has been tested on Centos 6.x

#CHEF-MONITOR

Chef monitor has two executables:
  - chef-logmon         (this will be activated on all frontend servers)
  - chef-worker         (this will be activated on your monitor/backend server)

#CHEF HA

When you have Chef in HA mode, your environment will look something like this:

    HA Setup

     public zone   |        dmz zone        |       db zone
    ---------------|------------------------|-----------------------
                   |                        |
                   |    frontend-server     |               backend-server
                   |    webserver01         |          /    dbserver01
                   |    10.1.1.10/24        |         /     10.1.5.110/24
                   |                        |        /
      internet     |                        |  vip  <
                   |                        |   ^    \
                   |    frontend-server     |   |     \     backend-server
                   |    webserver02         |   |      \    dbserver02
                   |    10.1.1.20/24        |   |           10.1.5.120/24
                                                |
                                                             ----------------
                                            10.1.5.90/24    | monitor-server |
                                            keepalived      | monserver01    |
                                                            | 10.1.5.130/24  |
                                                             ----------------

When running this environment, I suggest you configure the new monitor server.  
The Back-end server and monitor server can also be only one single server.  
If you don't have HA mode, then the environment will look something like this:  

    Single Setup
    
     public zone   |    cloud server        |
    ---------------|------------------------|
                   |                        |
                   |    chefserver          |
      internet     |    chefserver01        |
                   |    10.1.1.10/24        |
                   |                        |
  
  
#CHEF-LOGMON:

The logmon tool will run on every frontend server within your HA environment or on the  
chefserver in a more basic environment and is responsible for the following tasks:  
  
  - Tail your NGINX log and record all POST/PUTS/DELETES  
  - This information is sent to your Rabbit-MQ server (which comes default with chef)  
  
Basically every change that's being made to chef is registered within RabbitMQ.  
  
#CHEF-WORKER:

The worker tool will run on your monitor server within the HA environment or on the
chefserver in a more basic environment and is responsible for the following tasks:

  - Get the messages from RabbitMQ
  - Download the objects from chef that are changed
  - Commit the changes within a GIT repository

In this way every modified object is registered with a GIT commit and a POST-COMMIT script  
will email the differences to any configured email address. This POST-COMMIT part is not  
within the GEM, but comes with the chef-monitor chef cookbook.  
  
#CONFIGURATION:

In order to execute both tools, you will need the following configuration settings:

    chef_url       "https://10.1.5.90"
    node_name      "monitor"
    client_key     "/opt/chef-monitor/monitor.pem"
    mq_server      "10.1.5.90"
    mq_queue       "monitor_tasks"
    download_path  "/opt/chef-monitor/orgs"
    log_dir        "/var/log/chef-monitor"
    pid_dir        "/var/run/chef-monitor"
    mon_file       "/var/log/opscode/nginx/access.log"

Save these settings into /opt/chef-monitor/config.rb (the cookbook will do this for you)  
Make sure your monitor user is created on your chef server and has enough rights to download  
all objects within your organization that you want to monitor.  
  
Create a directory within your [download_path] with the same name as your organization.  
Initialize this directory with the following commands:  

    git init  
    touch dummy  
    git add .
    git commit -am "enable git control"

Add some git configuration settings for the POST-COMMIT script and chef-monitor tools.  

    git config hooks.mailinglist sander.botman@gmail.com
    git config hooks.emailprefix <YOUR_ORGANIZATION>
    git config hooks.emaildomain @your.domain.com

Set the project name within the gitrepo, so you can identify your chef environment.  

    echo MYCHEF > ./.git/description


#EXECUTION:
  
After these settings, you should be able to run the tools:  
On all your frontend servers:  

    chef-logmon run -- -C /opt/chef-monitor/config.rb     #<run interactive>
    chef-logmon start -- -C /opt/chef-monitor/config.rb   #<run as service>
    chef-logmon stop                                      #<stop service>

On your monitor server:

    chef-worker run -- -C /opt/chef-monitor/config.rb     #<run interactive>
    chef-worker start -- -C /opt/chef-monitor/config.rb   #<run as service>
    chef-worker stop                                      #<stop service>
