#!/usr/bin/python
"""
Retreives EAD's from ArchivesSpace

Usage:
  ./archivesspace_ead.py [username] [password] [resource url]
    Gets EAD for given resource url. Passing ArchivesSpace front page url will create EAD for all finding aids.
  
@author Sean Watkins <slwatkins@uh.edu>
"""

import sys
import urllib2, urllib, base64
import xml.dom.minidom
from urlparse import urlparse
import re
import json
import time
import os


def main(username, password, url):
  """
  Main function to run the script and start the download
  @param String username The username to ArchivesSpace
  @param String password The password to ArchivesSpace
  @param String url The url to the finding aid
  """
  global _ENDPOINT
  _ENDPOINT = urlparse(url).scheme + '://' + urlparse(url).netloc + ':8089'

  startSession(username, password)
  
  uri = urlparse(url).path
  if uri != '' and uri != '/':
    downloadEad(fetch(urlparse(url).path))
  else:
    downloadAllEads()

def startSession(username, password):
  """
  Starts a API Session with ArchivesSpace
  @return List containing session id and session expiration time
  """
  global _TOKEN, _ENDPOINT

  auth_url = _ENDPOINT + '/users/' + username + '/login'
  print auth_url
  print password
  print "starting new session"
  try:
    data = urllib.urlencode({'password': password})
    request = urllib2.Request(auth_url, data)
    response = urllib2.urlopen(request)
    data = json.loads(response.read())
  except urllib2.HTTPError as e:
    if e.code == 403:
      print '\033[91m' +"Bad username or password" + '\033[0m'
    else:
      print '\033[91m' +"Unable to start session: {0}".format(e) + '\033[0m'
    sys.exit(0)
  except Exception as e:
    print '\033[91m' +"Unable to start session: {0}".format(e) + '\033[0m'
    sys.exit(0)

  _TOKEN = {'session': data['session'], 'expires_at': int(time.time()) + 3600}

  return _TOKEN
  

def fetch(uri, returnjson=True):
  """
  Makes and call to ArchivesSpace and returns the response
  @param String uri The API URI to call
  @param Boolean returnjson True if you want to return as a JSON object. Otherwise returns response string
  @return Mixed
  """
  global _TOKEN, _ENDPOINT

  if int(time.time()) >= _TOKEN['expires_at']:
    _TOKEN = startSession(sys.argv[1], sys.argv[2])

  request = urllib2.Request(_ENDPOINT + uri)
  request.add_header("X-ArchivesSpace-Session", _TOKEN['session'])
  
  try:
    result = urllib2.urlopen(request, timeout=600)
    if returnjson:
      data = json.loads(result.read())
    else:
      data = result.read()
  except urllib2.HTTPError as e:
    print '\033[91m' + str(e.code) + '\033[0m'
    data = None
  except socket.timeout as e:
    print '\033[91m' + 'Server response timed out' + '\033[0m'
    data = None
  except ValueError:
    data = None

  return data

def downloadEad(resource):
  """
  Gets the EAD from ArchivesSpace and saves it to a file
  @param Dictionary resource The JSON object of a resource from ArchivesSpace
  """
  print 'Fetching EAD for "' + resource['title'] + '"...'

  filename = 'ead/' + re.sub('[^a-z_0-9]', '', resource['title'].lower().replace(' ', '_')) + '.xml'
  if os.path.isfile(filename):
    print '\033[93m' + 'Skipping since EAD file already exists: ' + filename + '\033[0m'
    return
  if not os.path.exists(os.path.dirname(filename)):
    os.makedirs(os.path.dirname(filename))

  uri = resource['repository']['ref'] + '/resource_descriptions/' + resource['uri'].rsplit('/', 1).pop() + '.xml'
  
  ead = fetch(uri, False)
  if ead is None:
    print '\033[91m' + 'FAILED on "' + resource['title'] + '" because no EAD data returned' + '\033[0m'
    return
  elif len(ead) == 0:
    print '\033[91m' + 'FAILED because "' + resource['title'] + "\" does not have a EAD"  + '\033[0m'
    return

  print '\033[94m' + "Writing EAD to " + filename + '...' + '\033[0m'
  writeEad(filename, resource, ead)
  time.sleep(2)


def downloadAllEads():
  """
  Gets the list of collections and downloads all the EADs
  """
  print "Download All"
  collections = getCollections()
  for i,c in enumerate(collections):
    print 'Resource ' + str(i+1) + ' of ' + str(len(collections))
    downloadEad(fetch(c["id"]))
  
def getCollections():
  """
  Returns a list of collections in ArchivesSpace
  @return List
  """
  print '\033[92m' + "Getting collection list..." + '\033[0m'
  results = fetch('/search?type[]=resource&page=1&page_size=50')
  cols = results['results']
  for page in range(2, results['last_page'] + 1):
    d = fetch('/search?type[]=resource&page=' + str(page) + '&page_size=50')
    cols = cols + d['results']

  return cols


def writeEad(filename, resource, ead):
  """
  Writes the given EAD to a file
  @param String filename The filename to save the EAD as
  @param Dictionary resource The JSON object of a resource from ArchivesSpace
  @param String ead The EAD to write
  """
  try:
    fp = open(filename, 'w')
    fp.write(xml.dom.minidom.parseString(ead).toprettyxml().encode('utf-8'))
    fp.close()
  except xml.parsers.expat.ExpatError as e:
    fp.close()
    os.remove(filename)
    print '\033[93m' + 'FIXING EAD on "' + resource['title'] + "\" because it doesn't appear to be valid"  + '\033[0m'
    ead = fixEad(ead)
    if ead is None:
      print '\033[91m' + 'FAILED to fix EAD on "' + resource['title'] + "\""  + '\033[0m'
    else:
      writeEad(filename, resource, ead)

def fixEad(ead):
  """
  Returns a fixed EAD with a bad <extref> tag
  @param String ead The ead to fix
  @return String
  """
  if ead.find("<extref='mailto:") == -1:
    return None

  return ead.replace("<extref='mailto:", "<a href='")

def usage():
  """
  Output the usage text
  """
  print "Usage: archivesspace_ead.py [USERNAME] [PASSWORD] [URL]\n"
  print "Url can be to a ArchivesSpace resouce or the homepage to retrieve all finding aids."
  print "User must be in ArchivesSpace with proper permissions to retrieve EAD information.\n"

if __name__ == "__main__":
  if len(sys.argv) == 4:
    main(sys.argv[1], sys.argv[2], sys.argv[3])
  else:
    usage()