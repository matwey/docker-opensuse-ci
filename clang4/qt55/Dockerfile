FROM opensuse:tumbleweed
MAINTAINER Matwey V. Kornilov <matwey.kornilov@gmail.com>

ENV CXX clang++-4
ENV CC clang-4

RUN zypper -n ar 'http://download.opensuse.org/repositories/devel:/tools:/compiler/openSUSE_Factory/devel:tools:compiler.repo'
RUN zypper -n ar 'http://download.opensuse.org/repositories/KDE:/Qt55/openSUSE_Factory/KDE:Qt55.repo'

RUN zypper -n --gpg-auto-import-keys install --no-recommends --auto-agree-with-licenses --force-resolution cmake make libQt5Widgets-devel libQt5Test-devel libQt5Gui-devel libQt5Core-devel clang4