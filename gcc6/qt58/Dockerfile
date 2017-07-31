FROM opensuse:tumbleweed
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

ENV CC gcc-6
ENV CXX g++-6

RUN zypper -n ar 'http://download.opensuse.org/repositories/devel:/gcc/openSUSE_Factory/devel:gcc.repo'
RUN zypper -n ar 'http://download.opensuse.org/repositories/KDE:/Qt58/openSUSE_Tumbleweed/KDE:Qt58.repo'

RUN zypper -n --gpg-auto-import-keys install --no-recommends --auto-agree-with-licenses --force-resolution cmake make libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel gcc6-c++