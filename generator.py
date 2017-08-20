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
		elif self.suseversion == 421:
			return "http://download.opensuse.org/repositories/devel:/gcc/openSUSE_Leap_42.1/devel:gcc.repo"
		else:
			raise NotImplementedError()

	def clang_repository(self):
		if self.suseversion == -1:
			return "http://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Factory/devel:tools:compiler.repo"
		elif self.suseversion == 422:
			return "http://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Leap_42.2/devel:tools:compiler.repo"
		else:
			raise NotImplementedError()

	def compiler_repository(self):
		if self.compiler[0] == 'gcc':
			return self.gcc_repository()
		elif self.compiler[0] == 'clang':
			return self.clang_repository()
		else:
			raise NotImplementedError()

	def qt_repository(self):
		factory_name = 'Tumbleweed'
		if self.qt == 55:
			factory_name = 'Factory'
		if self.suseversion == -1:
			return "http://download.opensuse.org/repositories/KDE:/Qt{0}/openSUSE_{1}/KDE:Qt{0}.repo".format(self.qt, factory_name)
		elif self.suseversion == 422:
			return "http://download.opensuse.org/repositories/KDE:/Qt{0}/openSUSE_Leap_42.2/KDE:Qt{0}.repo".format(self.qt)
		elif self.suseversion == 421:
			return "http://download.opensuse.org/repositories/KDE:/Qt{0}/openSUSE_Leap_42.1/KDE:Qt{0}.repo".format(self.qt)
		else:
			raise NotImplementedError()

	def base_image(self):
		if self.suseversion == -1:
			return "opensuse:tumbleweed"
		elif self.suseversion == 422:
			return "opensuse:42.2"
		elif self.suseversion == 421:
			return "opensuse:42.1"
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

def generic_clang(image, m):
	clang_suffix = m.group(1)
	clang_suffix_without_dot = clang_suffix.replace(".","")
	qt_suffix = m.group(2)
	image.env['CC']  = 'clang-' + clang_suffix
	image.env['CXX'] = 'clang++-' + clang_suffix
	image.packages += ['cmake','make','libQt5Widgets-devel','libQt5Test-devel','libQt5Gui-devel','libQt5Core-devel']
	image.packages += ['clang{}'.format(clang_suffix_without_dot),]

def requires_leap_422(image, m):
	if image.suseversion > 422 or image.suseversion == -1:
		image.suseversion = 422

def requires_leap_421(image, m):
	if image.suseversion > 421 or image.suseversion == -1:
		image.suseversion = 421

g = Generator()

g.addRule("gcc(.*?)-qt(.*)", generic_gcc)
g.addRule("clang(.*?)-qt(.*)", generic_clang)
g.addRule("gcc4.8-qt(.*)", requires_leap_422)
g.addRule("(.*?)-qt5([67])", requires_leap_422)
g.addRule("gcc4.8-qt55", requires_leap_421)

env = Environment(loader=FileSystemLoader('.'),trim_blocks=True)
template = env.get_template('Dockerfile.Jinja2')

for (compiler,version) in [("gcc",7),("gcc",6),("gcc","4.8"),("clang","4")]:
	for qt in [55,56,57,58,59]:
		im = Image(suseversion = -1, compiler = (compiler, version), qt = qt)
		g.match(im, "{}{}-qt{}".format(compiler,version,qt))
		#print(im.suseversion, im.compiler, im.qt, im.env, im.output_file(), im.packages)
		kwargs = {}
		kwargs['baseimage'] = im.base_image()
		kwargs['env']       = [{"key" : k, "value" : v} for (k,v) in im.env.items()]
		kwargs['repos']     = [{"value": im.compiler_repository()}, {"value": im.qt_repository()}]
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

