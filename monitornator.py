#!/usr/bin/env python3

agent_version="___AGENT_VERSION___"

from urllib.parse import urlencode
from urllib.request import Request, urlopen
from pathlib import Path
import argparse, sys
import datetime
import psutil
import time, threading
import configparser

config_file_path="/etc/monitornator/monitornator.config"

# Check if config file is present
config_file = Path(config_file_path)
if not config_file.is_file():
  print('Config file missing!')
  sys.exit(1)

config = configparser.ConfigParser()
config.read(config_file_path)

host=''
token=''
server_id=''

if config.has_option('monitornator', 'server_id'):
  server_id = config.get('monitornator', 'server_id')
if config.has_option('monitornator', 'token'):
  token = config.get('monitornator', 'token')
if config.has_option('monitornator', 'host'):
  host = config.get('monitornator', 'host')

StartTime=time.time()

if not host:
  host = 'https://collector.monitornator.io'

if not token:
  print('token is required in monitornator.config, see -h for more info')
  sys.exit(1)

if not server_id:
  print('server_id is required in monitornator.config, see -h for more info')
  sys.exit(1)

url = host + '/measurements'
headers = {'authorization': token }

def action() :
  post_fields = {
    'time': datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z',
    'load': psutil.cpu_percent(interval=1, percpu=False),
    'memory': psutil.virtual_memory().percent,
    'disk': psutil.disk_usage('/').percent,
    'agentVersion': agent_version,
    'serverId': server_id
  }

  request = Request(url, urlencode(post_fields).encode(), headers=headers)
  # TODO Handle errors
  json = urlopen(request).read().decode()
  print('update ! -> time : {:.1f}s'.format(time.time()-StartTime))

class setInterval :
  def __init__(self,interval,action) :
    self.interval=interval
    self.action=action
    self.stopEvent=threading.Event()
    thread=threading.Thread(target=self.__setInterval)
    thread.start()

  def __setInterval(self) :
    nextTime=time.time()+self.interval
    while not self.stopEvent.wait(nextTime-time.time()) :
      nextTime+=self.interval
      self.action()

  def cancel(self) :
    self.stopEvent.set()

inter=setInterval(10.0, action)
print('just after setInterval -> time : {:.1f}s'.format(time.time()-StartTime))
