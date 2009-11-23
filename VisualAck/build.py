#!/usr/bin/env python

# What: build VisualAck and (optionally) upload it to s3
# How:
#   * extract program version from .plist file
#   * build
#   * upload to s3 kjkpub bucket. Uploaded files:
#       vack/SumatraPDF-prerelase-<svnrev>.exe
#       vack/sumatralatest.js
#       vack/sumpdf-prerelease-latest.txt

# TODO:
#  - should also save every version of appcast and relnotes, so that it's
#    possible to rollback a bad update

import sys
import os
import os.path
import re
import time
import subprocess
import stat 
import shutil
import mimetypes
import relnotes

try:
    import boto.s3
    from boto.s3.key import Key
except:
    print("You need boto library (http://code.google.com/p/boto/)")
    print("svn checkout http://boto.googlecode.com/svn/trunk/ boto")
    print("cd boto; python setup.py install")
    raise

try:
    import awscreds
except:
    print "awscreds.py file needed with access and secret globals for aws access"
    sys.exit(1)

SRC_DIR = os.path.dirname(os.path.realpath(__file__))
RELEASE_BUILD_DIR = os.path.join(SRC_DIR, "build", "Release")
INFO_PLIST_PATH = os.path.realpath(os.path.join(SRC_DIR, "VisualAck-Info.plist"))
APP_CAST_PATH = os.path.join(SRC_DIR, "appcast_template.xml")
S3_APPCAST_NAME = "vack/appcast.xml"
S3_LATEST_VER_NAME = "vack/latestver.js"
S3_RELNOTES_PATH = "vack/relnotes.html"
S3_ATOM_PATH = "vack/relnotes.xml"

S3_BUCKET = "kjkpub"
g_s3conn = None

def s3connection():
  global g_s3conn
  if g_s3conn is None:
    g_s3conn = boto.s3.connection.S3Connection(awscreds.access, awscreds.secret, True)
  return g_s3conn

def s3PubBucket(): return s3connection().get_bucket(S3_BUCKET)

def ul_cb(sofar, total):
    if 0 ! = sofar:
        print("So far: %d, total: %d" % (sofar , total))

def s3UploadFilePublic(local_file_name, remote_file_name):
    print("Uploading public '%s' as '%s'" % (local_file_name, remote_file_name))
    bucket = s3PubBucket()
    k = Key(bucket)
    k.key = remote_file_name
    k.set_contents_from_filename(local_file_name, cb=ul_cb)
    k.make_public()

def s3UploadDataPublic(data, remote_file_name):
    print("Uploading public data as '%s'" % remote_file_name)
    bucket = s3PubBucket()
    k = Key(bucket)
    k.key = remote_file_name
    k.content_type = mimetypes.guess_type(remote_file_name)[0]
    k.set_contents_from_string(data, cb=ul_cb)
    k.make_public()

def s3Exists(key_name):
    bucket = s3PubBucket()
    key = bucket.get_key(key_name)
    return key != None

def s3relnotes_name(version):
    return "vack/relnotes-%s.html" % version

def s3zip_name(version):
    return "vack/VisualAck-%s.zip" % version

def exit_with_error(s):
    print(s)
    sys.exit(1)

def ensure_dir_exists(path):
    if not os.path.exists(path) or not os.path.isdir(path):
        exit_with_error("Directory '%s' desn't exist" % path)

def ensure_file_exists(path):
    if not os.path.exists(path) or not os.path.isfile(path):
        exit_with_error("File '%s' desn't exist" % path)

def ensure_file_doesnt_exist(path):
    if os.path.exists(path):
        exit_with_error("File '%s' already exists and shouldn't. Forgot to update version in Info.plist?" % path)

def ensure_s3_doesnt_exist(key_path):
    if s3Exists(key_path):
        exit_with_error("Url '%s' already exists" % key_path)

def readfile(path):
    fo = open(path)
    data = fo.read()
    fo.close()
    return data

def writefile(path, data):
    fo = open(path, "w")
    fo.write(data)
    fo.close()

def get_file_size(filename):
    st = os.stat(filename)
    return st[stat.ST_SIZE]

# like cmdrun() but throws an exception on failure
def run_cmd_throw(*args):
  cmd = " ".join(args)
  print("\nrun_cmd_throw: '%s'" % cmd)
  cmdproc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  res = cmdproc.communicate()
  errcode = cmdproc.returncode
  if 0 != errcode:
    print("Failed with error code %d" % errcode)
    print("Stdout:")
    print(res[0])
    print("Stderr:")
    print(res[1])
    raise Exception("'%s' failed with error code %d" % (cmd, errcode))
  return (res[0], res[1])

# a really ugly way to extract version from Info.plist
def extract_version_from_plist(plist_path):
    plist = readfile(plist_path)
    #print(plist)
    regex = re.compile("CFBundleVersion</key>(.+?)<key>", re.DOTALL | re.MULTILINE)
    m = regex.search(plist)
    version_element = m.group(1)
    #print("version_element: '%s'" % version_element)
    regex2 = re.compile("<string>(.+?)</string>")
    m = regex2.search(version_element)
    version = m.group(1)
    version = version.strip()
    #print("version: '%s'" % version)
    return version

# build version is either x.y or x.y.z
def ensure_valid_version(version):
    m = re.match("\d+\.\d+", version)
    if m: return
    m = re.match("\d+\.\d+\.\d+", version)
    if m: return
    print("version ('%s') should be in format: x.y or x.y.z" % version)
    sys.exit(1)

def zip_name(version):
    return "VisualAck-%s.zip" % version

def zip_path(version):
    return os.path.join(RELEASE_BUILD_DIR, zip_name(version))

def zip_url(version):
    return "https://kjkpub.s3.amazonaws.com/vack/" + zip_name(version)

def build_and_zip(version):
    #os.chdir(SRC_DIR)
    print("Cleaning release target...")
    xcodeproj = "VisualAck.xcodeproj"
    run_cmd_throw("xcodebuild", "-project", xcodeproj, "-configuration", "Release", "clean");
    print("Building release target...")
    (out, err) = run_cmd_throw("xcodebuild", "-project", xcodeproj, "-configuration", "Release", "-target", "VisualAck")
    ensure_dir_exists(RELEASE_BUILD_DIR)
    os.chdir(RELEASE_BUILD_DIR)
    (out, err) = run_cmd_throw("zip", "-9", "-r", zip_name(version), "VisualAck.app")

def latest_js(version):
    return """
var vackLatestUrl = "%s";
var vackLatestName = "%s";
var vackBuiltOn = "%s";
""" % (zip_url(version), zip_name(version), time.strftime("%Y-%m-%d"))

def get_appcast(path, version, length):
    appcast = readfile(path)

    newver = 'sparkle:version="%s"' % version
    appcast = re.sub("sparkle:version=\"[^\"]*\"", newver, appcast)

    newshortver = 'sparkle:shortVersionString="%s"' % version
    appcast = re.sub("sparkle:shortVersionString=\"[^\"]*\"", newshortver, appcast)

    newpubdate = "<pubDate>%s</pubDate>" % time.strftime("%a, %d %b %y %H:%M:%S %z", time.gmtime())
    prevappcast = appcast
    #appcast = re.sub('<pubDate>.?</pubDate>', newpubdate, appcast)
    appcast = re.sub('<pubDate>.*</pubDate>', newpubdate, appcast)
    if appcast == prevappcast:
        exit_with_error("pubDate didn't got updated")

    newlen = 'length="%d"' % length
    appcast = re.sub("length=\"[^\"]*\"", newlen, appcast)
    writefile(path, appcast)

    newurl = 'url="%s"' % zip_url(version)
    appcast = re.sub('url="[^\"]*"', newurl, appcast)
    return appcast

def main():
    upload = "-upload" in sys.argv or "--upload" in sys.argv
    if upload:
        print("Building and uploading VisualAck")
    else:
        print("Building but not uploading VisualAck")
    ensure_file_exists(INFO_PLIST_PATH)
    ensure_file_exists(APP_CAST_PATH)
    version = extract_version_from_plist(INFO_PLIST_PATH)
    ensure_valid_version(version)
    relnotes.validate_relnotes(version)
    relnotes_html = relnotes.relnotes_html()
    relnotes_atom = relnotes.relnotes_atom()

    ensure_s3_doesnt_exist(s3relnotes_name(version))
    ensure_s3_doesnt_exist(s3zip_name(version))

    build_and_zip(version)
    ensure_file_exists(zip_path(version))
    length = get_file_size(zip_path(version))
    appcast = get_appcast(APP_CAST_PATH, version, length)

    if upload:
        s3UploadDataPublic(appcast, S3_APPCAST_NAME)
        s3UploadDataPublic(latest_js(version), S3_LATEST_VER_NAME)
        s3UploadFilePublic(zip_path(version), s3zip_name(version))
        s3UploadDataPublic(relnotes_html, S3_RELNOTES_PATH)
        s3UploadDataPublic(relnotes_atom, S3_ATOM_PATH)

if __name__ == "__main__":
    main()
