FROM opensuse:42.2
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

ENV CXX clang++
ENV CC clang

RUN zypper -n ar 'http://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Leap_42.2/devel:tools:compiler.repo'
RUN zypper -n ar 'http://download.opensuse.org/repositories/KDE:/Qt57/openSUSE_Leap_42.2/KDE:Qt57.repo'

RUN zypper -n --gpg-auto-import-keys install --no-recommends --auto-agree-with-licenses --force-resolution cmake make libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel clang4