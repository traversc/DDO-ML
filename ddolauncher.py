#!/usr/bin/python

# Copyright 2012 - 2013 Florian Stinglmayr <fstinglmayr@gmail.com>
# Copyright 2013 Scott Winburn
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# o Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# o Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

from http.client import HTTPSConnection, HTTPConnection
from getopt import getopt, GetoptError
from sys import exit, argv
from os import chdir, spawnv, P_NOWAIT, system
from os.path import isfile
from getpass import getpass
from re import sub
from urllib.parse import urlparse, quote_plus
from time import sleep
import socket
import ssl
import xml.etree.ElementTree as ElementTree

# If we are using wine or not.
iswine = 0
# Output for DDO to use. DDO binds to this address so using the same port again
# will cause DDO to fail.
outport = 5201

# From: http://bugs.python.org/issue11220
class HTTPSConnectionV3(HTTPSConnection):
    def __init__(self, *args, **kwargs):
        HTTPSConnection.__init__(self, *args, **kwargs)

    def connect(self):
        sock = socket.create_connection((self.host, self.port), self.timeout)
        if self._tunnel_host:
            self.sock = sock
            self._tunnel()
        try:
            self.sock = ssl.wrap_socket(sock, self.key_file, self.cert_file, ssl_version=ssl.PROTOCOL_TLSv1)
        except ssl.SSLError as e:
            self.sock = ssl.wrap_socket(sock, self.key_file, self.cert_file, ssl_version=ssl.PROTOCOL_SSLv23)

def get_config_data(basepath):
    global iswine
    path = ""

    if iswine:
        path = basepath + "/TurbineLauncher.exe.config"
    else:
        path = basepath + "\\TurbineLauncher.exe.config"

    xml = ElementTree.parse(path).getroot()
    gls = xml.find("appSettings/*[@key='Launcher.DataCenterService.GLS']")
    gamename = xml.find("appSettings/*[@key='DataCenter.GameName']")
    return gls.get("value"), gamename.get("value")

def strip_namespaces(rdata):
    # remove the shitty namespaces which make using xml.etree complicated.
    rdata = sub(r'\sxmlns[^\=]*\=\"[^\"]+\"', "", rdata)
    rdata = sub(r'soap:', '', rdata)
    return rdata

def query_host(world):
    u = urlparse(world['status'])
    
    c = HTTPConnection(u.netloc, 80)
    c.putrequest("GET", u.path + '?' + u.query)
    c.putheader("Content-Type", "text/xml; charset=utf-8")
    c.endheaders()

    r = c.getresponse()
    if r.getcode() is not 200:
        raise RuntimeError("Failed to query information about the server.")
    
    rdata = r.read().decode("utf-8")

    if len(rdata) is 0:
        print("The given server appears to be down.")
        exit(0)

    xml = ElementTree.fromstring(rdata)
    loginserver = xml.find("loginservers").text
    loginservers = loginserver.split(';')
    worldqueue = xml.find("queueurls").text
    worldqueues = worldqueue.split(';')

    world['host'] = world['login'] = loginservers[0]
    world['queue'] = worldqueues[0]

    return world

def query_worlds(url, gamename):
    u = urlparse(url)

    xml = """<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<soap:Body>
<GetDatacenters xmlns="http://www.turbine.com/SE/GLS">
<game>%s</game>
</GetDatacenters>
</soap:Body>
</soap:Envelope>
""" % (gamename)

    c = HTTPConnection(u.netloc, 80)
    c.putrequest("POST", u.path)
    c.putheader("Content-Type", "text/xml; charset=utf-8")
    c.putheader("SOAPAction", "http://www.turbine.com/SE/GLS/GetDatacenters")
    c.putheader("Content-Length", str(len(xml)))
    c.endheaders()
    c.send(bytes(xml, "utf-8"))
    
    r = c.getresponse()
    if r.getcode() is not 200:
        raise RuntimeError("HTTP post failed.")

    rdata = r.read().decode("utf-8")
    rdata = strip_namespaces(rdata)

    xml = ElementTree.fromstring(rdata)

    datacenters = xml.findall("Body/GetDatacentersResponse/GetDatacentersResult/*")

    for dc in datacenters:
        authserver = dc.find('AuthServer').text
        patchserver = dc.find('PatchServer').text
        config = dc.find('LauncherConfigurationServer').text
        worlds = dc.findall("Worlds/*")

        w = []
        for world in worlds:
            neu = {"name": world.find("Name").text,
                   "login": world.find("LoginServerUrl").text,
                   "chat": world.find("ChatServerUrl").text,
                   "language": world.find("Language").text,
                   "status": world.find("StatusServerUrl").text}
            neu = query_host(neu)
            w.append(neu)

        return (w, authserver, patchserver, config)
    raise RuntimeError("Failed to parse response from login server.")

def join_queue(name, ticket, world):
    u = urlparse('https://gls.ddo.com/GLS.AuthServer/LoginQueue.aspx')
    params = "command=TakeANumber&subscription=%s&ticket=%s&ticket_type=GLS&queue_url=%s" % (name, quote_plus(ticket), quote_plus(world['queue']))

    done = 0

    while not done:
        c = HTTPSConnectionV3(u.netloc, 443)
        c.putrequest("POST", u.path)
        c.putheader("Content-Length", len(params))
        c.endheaders()
        c.send(bytes(params, "utf-8"))
        
        r = c.getresponse()
        if r.getcode() is not 200:
            raise RuntimeError("Failed to join the queue.")

        rdata = r.read().decode("utf-8")
        xml = ElementTree.fromstring(rdata)

        hresult = int(xml.find("HResult").text, 0)

        if hresult > 0:
            raise RuntimeError("World queue returned an error.")

        number = int(xml.find("QueueNumber").text, 0)
        nowserving = int(xml.find("NowServingNumber").text, 0)

        if number > nowserving:
            print(str(number) + " in queue, now serving: " + str(nowserving))
            sleep(2)
        else:
            done = 1

def login(authserver, world, username, password, subscription):
    xml = """<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<LoginAccount xmlns="http://www.turbine.com/SE/GLS">
<username>%s</username>
<password>%s</password>
<additionalInfo></additionalInfo>
</LoginAccount>
</soap:Body>
</soap:Envelope>
""" % (username, password)

    u = urlparse(authserver)
    c = HTTPSConnectionV3(u.netloc, 443)
    c.putrequest("POST", u.path)
    c.putheader("Content-type", "text/xml; charset=utf-8")
    c.putheader("SOAPAction", "http://www.turbine.com/SE/GLS/LoginAccount")
    c.putheader("Content-Length", str(len(xml)))
    c.endheaders()
    c.send(bytes(xml, "utf-8"))

    r = c.getresponse()
    if r.getcode() is not 200:
        raise RuntimeError("HTTP post failed.")

    rdata = r.read().decode("utf-8")
    rdata = strip_namespaces(rdata)
   
    xml = ElementTree.fromstring(rdata)
    ticket = xml.find('Body/LoginAccountResponse/LoginAccountResult')
    t = ticket.find('Ticket').text
    found_ddo = False
    found_name = False
    a = ""
    if subscription == "":
        for game_subs in ticket.findall('Subscriptions/GameSubscription'):
            for sub_info in game_subs.getchildren():
                if sub_info.tag == 'Game' and sub_info.text == 'DDO':
                    found_ddo = True
                if sub_info.tag == 'Name' and found_ddo == True:
                    a = sub_info.text
                    found_name = True
                    break
            if found_ddo == True:
                break
    else:
        for game_subs in ticket.findall('Subscriptions/GameSubscription'):
            for sub_info in game_subs.getchildren():
                if sub_info.tag == 'Description' and sub_info.text.lower() == subscription.lower():
                    found_ddo = True
                    break
                if sub_info.tag == 'Name':
                    a = sub_info.text
            if found_ddo == True:
                break

    if found_ddo == False:
        print("Unable to find a subscription on your account for DDO. Your LotrO account?")
        exit(2)
    
    # This runs until we are on!
    join_queue(a, t, world)

    return (a, t)
    
    return(subscription, subscription)

def usage():
    print("ddolauncher.py [options] -u account -a password]")
    print("")
    print("Options:")
    print(" -g --game-path Full absolute path to were DDO is. Default:")
    print(' C:\Program Files (x86)\Turbine\DDO Unlimited\ ')
    print(" -h --help (This)")
    print(" -l --list-servers List all servers and exit.")
    print(" -p --patch Runner DDO patcher.")
    print(" -s --server Specify server to login to, default Ghallanda.")
    print(" -z --subscription Specify subscription name, default to the first one")
    print(" -v --version Print version and author information.")
    print(" -w --wine Run wine instead of running natively.")
    exit(0)

def version():
    print("ddolauncher - An alternate DDO launcher v0.1")
    print("Original: Copyright 2012 by Florian Stinglmayr")
    print("Website: http://github/n0la/ddolauncher")
    print("Email: fstinglmayr@gmail.com")
    print("Modified by AtomicMew: accept command line password, multiple subscriptions and always output to stdout")
    exit(0)

def run_ddo(gamedir, username, ticket, language, world):
    global iswine
    global outport
    chdir(gamedir)

    params = ["-h", world['host'],
              "-a", username,
              "--glsticketdirect", ticket,
              "--chatserver", '"' + world['chat'] + '"',
              "--language", language,
              "--rodat", "on",
              "--outport", str(outport),
              "--gametype", "DDO",
              "--supporturl", '"https://tss.turbine.com/TSSTrowser/trowser.aspx"',
              "--supportserviceurl", '"https://tss.turbine.com/TSSTrowser/SubmitTicket.asmx"',
              "--authserverurl", '"https://gls.ddo.com/GLS.AuthServer/Service.asmx"',
              "--glsticketlifetime", "21600"
              ]

    if iswine:
        exe = "wine dndclient.exe"
    else:
        exe = "dndclient.exe"
        params.insert(0, exe)

    print(' '.join(params))
    return

def patch_game(gamedir, patchserver, language, game):
    global iswine
    chdir(gamedir)
    prefix = ""
    if iswine:
        prefix = "wine "
    system(prefix + "rundll32.exe PatchClient.dll,Patch %s --highres --filesonly --language %s --productcode %s"
           % (patchserver, language, game)
           )
    system(prefix + "rundll32.exe PatchClient.dll,Patch %s --highres --dataonly --language %s --productcode %s"
           % (patchserver, language, game)
           )
    return

def main():
    try:
        global iswine
        server = "Ghallanda"
        language = "English"
        subscription = ""
        u=""
        p=""
        listservers = 0
        quiet = 0
        patch = 0
        dryrun = 0
        ddogamedir = "C:\\Program Files (x86)\\Turbine\\DDO Unlimited\\"

        opts, args = getopt(argv[1:], "g:hs:lpvwz:a:u:",
                            ["game-path="
                             "quiet", "help",
                             "server=", "list-servers",
                             "patch",
                             "version", "wine","pass","user"
                             ]
                           )
        for k, v in opts:
            if k in ("-g", "--game-path"):
                ddogamedir = v
            elif k in ("-s", "--server"):
                server = v
            elif k in ("-z", "--subscription"):
                subscription = v
            elif k in ("-u", "--user"):
                u = v
            elif k in ("-a", "--pass"):
                p = v
            elif k in ("-p", "--patch"):
                patch = 1
            elif k in ("-h", "--help"):
                usage()
            elif k in ("-l", "--list-servers"):
                listservers = 1
            elif k in ("-v", "--version"):
                version()
            elif k in ("-w", "--wine"):
                iswine = 1
			
        #if len(args) is 0 and patch != 1:
        #    print("You must provide at least one account to login with.")
        #    usage()

        if iswine:
            exe = ddogamedir + "/dndclient.exe"
        else:
            exe = ddogamedir + "\\dndclient.exe"

        if not isfile(exe):
            print('Your DDO game directory "' + ddogamedir + '" does not appear to be right.')
            print("Try specifying your full absolute path to DDO through the -g option.")
            exit(1)

        datacenter, gamename = get_config_data(ddogamedir)
        if datacenter is "" or gamename is "":
            raise RuntimeError("Failed to get data center!")

        (worlds, authserver, patchserver, config) = query_worlds(datacenter, gamename)
		
        if patch is 1:
            print("Checking for updates...")
            patch_game(ddogamedir, patchserver, language, gamename)
            exit(0)
            
        # list all worlds and exit
        if listservers is 1:
            print('Authentication server:', authserver)
            print('Patch server:', patchserver)
            for w in worlds:
                print("Server \"" + w["name"] + "\"")
                print(" Login server:", w["login"])
                print(" Chat server:", w["chat"])
                print(" Language:", w["language"])
            exit(0)

        selectedworlds = [w for w in worlds if
                          (server.lower() in w['name'].lower())
                          ]

        if len(selectedworlds) is 0:
            print('Your selected world does not exist.')
            exit(4)
        elif len(selectedworlds) > 1:
            print('Your server selection is not unique.')
            exit(5)

        # Select world and query additional information used for logging in
        w = selectedworlds[0]
        w = query_host(w)

        #u = args[0] #require switches for user and pass
        #p = args[1]
        try:
			#print("Logging in", u, "to world", w['name'] + "...")
            (account, ticket) = login(authserver, w, u, p, subscription)
            run_ddo(ddogamedir, account, ticket, language, w)
        except RuntimeError as re:
            print("Login of", u, "failed. Wrong password?")

    except GetoptError as args:
        print(str(args))
        exit(2)

    except RuntimeError as re:
        print("An error occured:", re)

    except KeyboardInterrupt:
        print("Aborting...")

if __name__ == '__main__':
    main()


