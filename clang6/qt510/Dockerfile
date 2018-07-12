FROM opensuse:tumbleweed
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

ENV CC clang
ENV CXX clang++


RUN zypper -n ar -p 1 'https://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Factory/devel:tools:compiler.repo'
RUN zypper -n ar -p 1 'https://download.opensuse.org/repositories/KDE:/Qt:/5.10/openSUSE_Tumbleweed/KDE:Qt:5.10.repo'


RUN zypper -n --gpg-auto-import-keys install --no-recommends --auto-agree-with-licenses --force-resolution clang6 libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel cmake make
