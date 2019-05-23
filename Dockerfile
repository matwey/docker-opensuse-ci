FROM opensuse/tumbleweed
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

ENV CC gcc-8
ENV CXX g++-8


RUN zypper -n ar -p 1 'https://download.opensuse.org/repositories/devel:/gcc/openSUSE_Factory/devel:gcc.repo'
RUN zypper -n ar -p 1 'https://download.opensuse.org/repositories/KDE:/Qt:/5.12/openSUSE_Tumbleweed/KDE:Qt:5.12.repo'


RUN zypper -n --gpg-auto-import-keys install --no-recommends --auto-agree-with-licenses --force-resolution gcc8-c++ libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel cmake make
