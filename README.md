#CHEF-MONITOR

Chef monitor has two executables:
  - chef-logmon         (this will be activated on all frontend servers)
  - chef-worker         (this will be activated on your monitor/backend server)

#Chef HA configuration:

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
all objects within your organizaton that you want to monitor.  
  
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
