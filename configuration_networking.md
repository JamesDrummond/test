# *Configuration: Networking*

An administrator's guide to configuring Che in various networking scenarios.

* * *


Eclipse Che is making connections between three essential entities: the browser, the Che server, and a machine which is typically running a Docker container. There are configuration steps that you must take if these services are distributed, or you want to run them on IP addresses that do not have external public access.

Generally, if the browser client that is accessing Che and the workspaces that it are connecting to are both on`localhost`, then the Che startup scripts configure everything for the user. You will need to reconfigure Che with certain properties to support it running behind a firewall or in a hosted scenario.

This guide is a companion to [Configuration: Che as a Server](https://eclipse-che.readme.io/v4.5/docs/che-as-a-server) which walks through the items that you must configure step by step to verify Che operates in a hosted capacity.

This networking guide is provided as a specification. This page is a companion to the

## *Four Deployment Configurations*

* * *


There are four basic configurations in which you can deploy Che.

<table>
  <tr>
    <td><b>Che?
<br/><br/></b></td>
    <td><b>Workspaces?
<br/><br/></b></td>
    <td><b>OS
<br/><br/></b></td>
    <td><b>Description
<br/><br/></b></td>
  </tr>
  <tr>
    <td>Native Process
<br/><br/></td>
    <td>Native Docker
<br/><br/></td>
    <td>Linux
<br/><br/></td>
    <td>The Che app server runs as a native process on your node. Workspaces are generated as Docker containers. The Docker daemon is running on the same node. The Che app server and Docker container may have different IP addresses on the same node.
<br/><br/>
The default settings of the Che boot scripts on Linux assume this configuration.
<br/><br/></td>
  </tr>
  <tr>
    <td>Native Process
<br/><br/></td>
    <td>VM Docker
<br/><br/></td>
    <td>Any
<br/><br/></td>
    <td>Since Docker is not natively supported on many operating systems, you can launch a VM running a boot2docker ISO that provides an OS for Docker containers.
<br/><br/>
The Che app server runs as a native process on your node. Worskpaces are generated using Docker that is running inside a VM. There can be up to three IP addresses: the Che server, the VM, and the container.
<br/><br/>
The default settings of the Che boot scripts on Mac and Windows assume this configuration.
<br/><br/></td>
  </tr>
  <tr>
    <td>Native Docker
<br/><br/></td>
    <td>Native Docker
<br/><br/></td>
    <td>Linux
<br/><br/></td>
    <td>You can run Che inside of a Docker container, which itself is independently started and stopped. The workspaces created by Che are created using the same Docker daemon and created as sibling containers.
<br/><br/></td>
  </tr>
  <tr>
    <td>VM Docker
<br/><br/></td>
    <td>VM Docker
<br/><br/></td>
    <td>Any
<br/><br/></td>
    <td>Same as the previous configuration, but all Docker containers are created by the Docker daemon running within the VM.
<br/><br/></td>
  </tr>
</table>


## *Native Process for Che, Native Docker for Workspaces*

* * *


This is a Linux-only configuration. The Che scripts on Linux assume that this is the default configuration and do not require any command-line parameters to launch Che with this configuration.

![](https://files.readme.io/ZF7vFCWkRcmOKxL9mMCF_Capture.PNG)

The browser client initiates communication with the Che Server by connecting to `che-ip`. This IP address must be accessible by your browser clients. Internally, Che runs on Tomcat which is bound to port `8080`. This port can be altered by using the `--port:<port>` command line option.

At some point, a user creates a workspace, which will have Che connect to the Docker daemon at `docker-ip` and has that daemon launch a machine. The machine is bound to a Docker container running on some Docker-configured IP address, `workspace-ip`. The `workspace-ip` must also be reachable by your browser host.

>####  *IP Reachability*
>*If your browser clients cannot connect to both `che-ip` and `workspace-ip`, then you get errors from your browser when they either first connect to Che, or after a new workspace has been created by Che and when the browser requests to open the IDE for that workspace. We provide helpful error messages within the dashboard and workspace if we think this connectivity issue may be occurring.*

## *PORTS*

Inside of your workspace machine powered by Docker, Che launches and exposes an application server on port`4401` and `4403`. We also have our default Docker images configured to launch an SSH daemon on port `22`. The embedded JavaScript terminal which is reachable over Web sockets runs on port `4411`. Your custom stacks and images (configured in the dashboard) may expose additional services on different ports.

Docker uses ephemeral port mapping. The ports accessible to your clients start at port `32768` and go through a wide range. When we start services internal to Docker, they are mapped to one of these ports. It is these ports that the browser (or SSH) clients connect to, and would need to be opened if connecting through a firewall.

Additionally, if your users start services within their workspace that expose their own ports, then those ports need to have an `EXPOSE <port>` command added to the workspace image Dockerfile. As a courtesy, we expose port `80`and `8080` within the container for any users that want to launch services on those ports.

## *DOCKER CONNECTION*

There are multiple techniques for connecting to Docker including Unix sockets, localhost, and remote connections over TCP protocol. Depending upon the type of connection you require and the location of the machine node running Docker, we use different parameters.

#### _Che Connections_

<table>
  <tr>
    <td><b>>>>>>>>>>>>Connection>>>>>>>>>>
<br/><br/></b></td>
    <td><b>Linux
<br/><br/></b></td>
  </tr>
  <tr>
    <td><code>Che Server => Docker Daemon</code>
<br/><br/></td>
    <td><ul>1.  Use the value of <code>docker.client.daemon_url</code>.
<br/><br/>
2.  Else use the value of <code>DOCKER_HOST</code> environment variable. If<code>DOCKER_HOST</code> value is malformed, Che falls back to<code>unix:///var/run/docker.sock</code>.
<br/><br/>
3.  Else use Unix socket: <code>unix:///var/run/docker.sock</code>
<br/><br/></td>
  </tr>
  <tr>
    <td><code>Che Server => Workspace</code>
<br/><br/>
<code>Browser => Workspace</code>
<br/><br/></td>
    <td><ul>1.  Use the value of <code>machine.docker.local_node_host</code>.
<br/><br/>
2.  Else use the value of <code>CHE_DOCKER_MACHINE_HOST</code> environment variable.
<br/><br/>
3.  Else if server connects to Docker via Unix socket then use<code>localhost</code>.
<br/><br/>
4.  Else get value retrieved from URI that Che server uses to connect to Docker (<code>DOCKER_HOST</code>).
<br/><br/></td>
  </tr>
  <tr>
    <td><code>Workspace Agent => Che Server</code>
<br/><br/></td>
    <td>There's a mandatory property <code>machine.docker.che_api.endpoint</code> with a default value of <code>http://che-host:${SERVER_PORT}/wsmaster/api</code>. You can override <code>che-host</code> with your own IP address that points to the Che server.
<br/><br/>
<ul>1.  If <code>che-host</code> is not overridden, Che replaces <code>che-host</code> with the IP of<code>docker0</code> network interface.
<br/><br/>
2.  If <code>docker0</code> IP is unreachable, then <code>che-host</code> is replaced with<code>172.17.42.1</code>.
<br/><br/>
3.  Else, if there is a failure, we will print an HTTP connection exception with the reason for the failure.
<br/><br/></td>
  </tr>
</table>


You can set the `CHE_DOCKER_MACHINE_HOST` environment variable by exporting the variable in your Linux configuration or on the Che command line with `--remote:ip` option.

Properties are added and changed in `${CHE_LOCAL_CONF_DIR}/che.properties`

#### _Firewall_

On Linux, a firewall may block inbound connections from within Docker containers to your localhost network. As a result, the workspace agent is unable to ping the Che server. You can check for the firewall and then disable it.

*[Shell](https://eclipse-che.readme.io/docs/networking)*

``` bash
# Check firewall status
sudo ufw status

# Disable firewall
sudo ufw disable

# Allow 8080 port of Che server
sudo ufw allow 8080/tcp
```

## *Native Process for Che, VM Docker for Workspaces*

* * *


You can run Docker in a VM and enable Che to create workspaces using the embedded Docker daemon. If you are on Linux, this is optional. If you are on OSX or Windows, this is mandatory as Docker is not yet supported natively on those operating systems. We use VirtualBox to launch and manage VMs that run a special operating system optimized for executing Docker containers. This VM type is called `boot2docker` and it is maintained by the Docker community. `docker-machine` is a command line utility to simplify the creation and destruction of VMs that have`boot2docker`.

![](https://files.readme.io/PqblnAS2S4GOVu8vy6oJ_Capture.PNG)

This configuration introduces a third IP addresses, `vm-ip`, which is the externally accessible IP address of the VM that has the Docker daemon. Your browser clients communicate to `vm-ip` in this configuration, not `workspace-ip`.

On Windows and Mac, the default configuration of the Che startup scripts:

1. Uses `docker-machine` to create a VM named default.
2. Sets the `vm-ip` to your environment variables.
3. Launches Che with `CHE_DOCKER_MACHINE_HOST` set to `vm-ip`.

####_Che Connections_

<table>
  <tr>
    <td><b>>>>>>>>>>>>Connection>>>>>>>>>>
<br/><br/></b></td>
    <td><b>Windows / Mac with VM
<br/><br/></b></td>
  </tr>
  <tr>
    <td><code>Che_Server => Docker_Daemon</code>
<br/><br/></td>
    <td><ul>1.  Use the value of <code>docker.client.daemon_url</code>.
<br/><br/>
2.  Else use the <code>DOCKER_HOST</code> environment variable. If <code>DOCKER_HOST</code> value is malformed, catch <code>URISyntaxException</code> and use the default<code>https://192.168.99.100:2376</code>..
<br/><br/>
3.  Else uses default value: <code>https://192.168.99.100:2376</code>
<br/><br/></td>
  </tr>
  <tr>
    <td><code>Che_Server => Workspace</code>
<br/><br/>
<code>Browser => Workspace</code>
<br/><br/></td>
    <td><ul>1.  Use the value of <code>machine.docker.local_node_host</code>.
<br/><br/>
2.  Else if there is <code>CHE_DOCKER_MACHINE_HOST</code> use the provided value
<br/><br/>
3.  Else get value retrieved from URI that Che server uses to connect to Docker (<code>DOCKER_HOST</code>).
<br/><br/>
4.  Else if <code>DOCKER_HOST</code> has not been exported, then return IP address of VM running Docker.
<br/><br/></td>
  </tr>
  <tr>
    <td><code>Workspace_Agent --> Che_Server</code>
<br/><br/></td>
    <td>There's a mandatory property <code>machine.docker.che_api.endpoint</code> with a default value of <code>http://che-host:${SERVER_PORT}/wsmaster/api</code>. You can override <code>che-host</code> with your own IP address that points to the Che server.
<br/><br/>
<ul>1.  If <code>che-host</code> is not overridden, Che replaces <code>che-host</code> with the bridged IP address of the VM IP (using <code>DOCKER_HOST</code> environment variable).
<br/><br/>
2.  If this bridged IP is unavailable, then <code>che-host</code> is replaced with<code>192.168.99.1</code>.
<br/><br/>
3.  Else, if there is a failure, we will print an HTTP connection exception with the reason for the failure.
<br/><br/></td>
  </tr>
</table>


## *Native Docker for Che, Native Docker for Workspaces*

* * *


This is a Linux-only configuration. In this configuration, the Che server runs in its own Docker container and each workspace gets its own Docker container. All containers are managed by the same Docker daemon, making them siblings of each other. This configuration is largely identical to running Che natively on Linux.

![](https://files.readme.io/JYahQlET8StJXQ83AqUK_Capture.PNG)

## *VM Docker for Che, VM Docker for Workspaces*

* * *


This configuration will work for any operating system. This is the configuration that is mandatory if you want to run Che as a Docker container on Windows or MacOS. In this case, both Che and all workspaces are run as containers within a VM that is created by VirtualBox and `docker-machine`. Your browser clients initially connect to the `vm-ip`, but then the VM and Docker daemon are responsible for the rest of the routing configurations.

![](https://files.readme.io/74osKA8CRBidz1IPE6pj_Capture.PNG)

## *WebSockets*

* * *


Che heavily relies on WebSocket communications. When a browser client connects to a workspace, it connects to it through WebSockets. Inside the workspace, the workspace agent also uses WebSockets to connect back to the Che server.

If WebSockets are blocked or not supported in the network, the workspace startup will fail with an error.
