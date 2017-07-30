FROM opensuse:tumbleweed
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

RUN zypper -n ar 'http://download.opensuse.org/repositories/devel:/gcc/openSUSE_Factory/devel:gcc.repo'
RUN zypper -n ar 'http://download.opensuse.org/repositories/KDE:/Qt59/openSUSE_Tumbleweed/KDE:Qt59.repo'
RUN zypper -n --gpg-auto-import-keys install --no-recommends cmake make gcc7-c++ libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel
