#!/usr/bin/python3
# adapted from phusion/baseimage /sbin/my_init
# https://github.com/phusion/baseimage-docker/blob/master/image/bin/my_init
import os, re, tempfile

log_level = None

def export_envvars():
	shell_dump = ""
	for name, value in os.environ.items():
		if name in ['HOME', 'USER', 'GROUP', 'UID', 'GID', 'SHELL']:
			continue
		if is_env_shell_func(name):
			continue
		shell_dump += shquote(name) + "=" + shquote(value) + "\x00"
	shell_temp_handle, shell_temp = tempfile.mkstemp('', 'tmp', None, True)
	with open(shell_temp, "w") as f:
		f.write(shell_dump)
	return shell_temp

_find_unsafe = re.compile(r'[^\w@%+=:,./-]').search

def is_env_shell_func(name):
    return os.environ[name].startswith('() {')

def shquote(s):
	"""Return a shell-escaped version of the string *s*."""
	if not s:
		return "''"
	if _find_unsafe(s) is None:
		return s

	# use single quotes, and put single quotes into double quotes
	# the string $'b is then quoted as '$'"'"'b'
	return "'" + s.replace("'", "'\"'\"'") + "'"

print(export_envvars())
