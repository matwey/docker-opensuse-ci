#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader
import re
import os

class Image(object):
	def __init__(self, suseversion, compiler, qt, env={}, packages=[]):
		self.suseversion = suseversion
		self.compiler = compiler
		self.qt = qt
		self.env = env
		self.packages = []

	def gcc_repository(self):
		if self.suseversion == -1:
			return "http://download.opensuse.org/repositories/devel:/gcc/openSUSE_Factory/devel:gcc.repo"
		elif self.suseversion == 422:
			return "http://download.opensuse.org/repositories/devel:/gcc/openSUSE_Leap_42.2/devel:gcc.repo"
		else:
			raise NotImplementedError()

	def qt_repository(self):
		if self.suseversion == -1:
			return "http://download.opensuse.org/repositories/KDE:/Qt{0}/openSUSE_Tumbleweed/KDE:Qt{0}.repo".format(self.qt)
		elif self.suseversion == 422:
			return "http://download.opensuse.org/repositories/KDE:/Qt{0}/openSUSE_Leap_42.2/KDE:Qt{0}.repo".format(self.qt)
		else:
			raise NotImplementedError()

	def base_image(self):
		if self.suseversion == -1:
			return "opensuse:tumbleweed"
		elif self.suseversion == 422:
			return "opensuse:42.2"
		else:
			raise NotImplementedError()

	def output_file(self):
		return "{}{}/qt{}/Dockerfile".format(self.compiler[0],self.compiler[1],self.qt)

class Generator(object):
	def __init__(self):
		self.rules = {}

	def addRule(self, pattern, callback):
		self.rules[re.compile(pattern)] = callback

	def match(self, image, string):
		for (k,v) in self.rules.items():
			result = k.match(string)
			if result:
				v(image, result)

def generic_gcc(image, m):
	gcc_suffix = m.group(1)
	gcc_suffix_without_dot = gcc_suffix.replace(".","")
	qt_suffix = m.group(2)
	image.env['CC']  = 'gcc-' + gcc_suffix
	image.env['CXX'] = 'g++-' + gcc_suffix
	image.packages += ['cmake','make','libQt5Widgets-devel','libQt5Test-devel','libQt5Gui-devel','libQt5Core-devel']
	image.packages += ['gcc{}-c++'.format(gcc_suffix_without_dot),]

def requires_leap(image, m):
	if image.suseversion != 422:
		image.suseversion = 422

g = Generator()

g.addRule("gcc(.*?)-qt(.*)", generic_gcc)
g.addRule("gcc4.8-qt(.*)", requires_leap)
g.addRule("gcc(.*?)-qt5([67])", requires_leap)

env = Environment(loader=FileSystemLoader('.'),trim_blocks=True)
template = env.get_template('Dockerfile.Jinja2')

for (compiler,version) in [("gcc",7),("gcc",6),("gcc","4.8")]:
	for qt in [56,57,58,59]:
		im = Image(suseversion = -1, compiler = (compiler, version), qt = qt)
		g.match(im, "{}{}-qt{}".format(compiler,version,qt))
		#print(im.suseversion, im.compiler, im.qt, im.env, im.output_file(), im.packages)
		kwargs = {}
		kwargs['baseimage'] = im.base_image()
		kwargs['env']       = [{"key" : k, "value" : v} for (k,v) in im.env.items()]
		kwargs['repos']     = [{"value": im.gcc_repository()}, {"value": im.qt_repository()}]
		kwargs['packages']  = im.packages

		filename = im.output_file()
		if not os.path.exists(os.path.dirname(filename)):
			try:
				os.makedirs(os.path.dirname(filename))
			except OSError as exc:
				if exc.errno != errno.EEXIST:
					raise

		with open(filename, "w") as f:
			f.write(template.render(kwargs))

