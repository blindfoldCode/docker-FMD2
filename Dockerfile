FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble

ARG FMD2_VERSION="2.0.34.5"
ARG PYTHON_VERSION=3.7.5
ARG PYINSTALLER_VERSION=3.6

LABEL \
  maintainer="https://github.com/blindfoldCode"

ENV \
  WINEDLLOVERRIDES="mscoree,mshtml=" \
  WINEDEBUG="fixme-all"\
  HOME=/config \
  THRESHOLD_MINUTES=3 \
  TRANSFER_FILE_TYPE=.cbz \
  DISPLAY=:1


# Install Dependencies
RUN \
  apt update && \
  apt install -y dpkg && \
  dpkg --add-architecture i386 && \
  apt install -y wget p7zip-full curl git python3-pip rename python3-pyxdg inotify-tools rsync openbox &&\
  mkdir -pm755 /etc/apt/keyrings && \
  wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key - && \
  wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/noble/winehq-noble.sources && \
  apt update && \
  apt install -y --install-recommends wine-stable winetricks xvfb winbind cabextract

ENV WINEARCH=win64
ENV WINEDEBUG=fixme-all
ENV WINEPREFIX=/wine
ENV PYPI_URL=https://pypi.python.org/
ENV PYPI_INDEX_URL=https://pypi.python.org/simple

# install python in wine, using the msi packages to install, extracting
# the files directly, since installing isn't running correctly.
RUN set -x \
  && winetricks win10 \
  && for msifile in `echo core dev exe lib path pip tcltk tools`; do \
  wget -nv "https://www.python.org/ftp/python/$PYTHON_VERSION/amd64/${msifile}.msi"; \
  wine msiexec /i "${msifile}.msi" /qb TARGETDIR=C:/Python37; \
  rm ${msifile}.msi; \
  done \
  && cd /wine/drive_c/Python37 \
  && echo 'wine '\''C:\Python37\python.exe'\'' "$@"' > /usr/bin/python \
  && echo 'wine '\''C:\Python37\Scripts\easy_install.exe'\'' "$@"' > /usr/bin/easy_install \
  && echo 'wine '\''C:\Python37\Scripts\pip.exe'\'' "$@"' > /usr/bin/pip \
  && echo 'wine '\''C:\Python37\Scripts\pyinstaller.exe'\'' "$@"' > /usr/bin/pyinstaller \
  && echo 'wine '\''C:\Python37\Scripts\pyupdater.exe'\'' "$@"' > /usr/bin/pyupdater \
  && echo 'assoc .py=PythonScript' | wine cmd \
  && echo 'ftype PythonScript=c:\Python37\python.exe "%1" %*' | wine cmd \
  && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
  && chmod +x /usr/bin/python /usr/bin/easy_install /usr/bin/pip /usr/bin/pyinstaller /usr/bin/pyupdater \
  && (pip install -U pip || true) \
  && rm -rf /tmp/.wine-*

ENV W_DRIVE_C=/wine/drive_c
ENV W_WINDIR_UNIX="$W_DRIVE_C/windows"
ENV W_SYSTEM64_DLLS="$W_WINDIR_UNIX/system32"
ENV W_TMP="$W_DRIVE_C/windows/temp/_temp"

# install Microsoft Visual C++ Redistributable for Visual Studio 2017 dll files
RUN set -x \
  && rm -f "$W_TMP"/* \
  && wget -P "$W_TMP" https://download.visualstudio.microsoft.com/download/pr/11100230/15ccb3f02745c7b206ad10373cbca89b/VC_redist.x64.exe \
  && cabextract -q --directory="$W_TMP" "$W_TMP"/VC_redist.x64.exe \
  && cabextract -q --directory="$W_TMP" "$W_TMP/a10" \
  && cabextract -q --directory="$W_TMP" "$W_TMP/a11" \
  && cd "$W_TMP" \
  && rename 's/_/\-/g' *.dll \
  && cp "$W_TMP"/*.dll "$W_SYSTEM64_DLLS"/


# install pyinstaller
RUN /usr/bin/pip install pyinstaller==$PYINSTALLER_VERSION


# put the src folder inside wine
RUN mkdir /src/ && ln -s /src /wine/drive_c/src
RUN mkdir -p /wine/drive_c/tmp

# Install FMD2
RUN \
  curl -s https://api.github.com/repos/dazedcat19/FMD2/releases/tags/${FMD2_VERSION} | grep "browser_download_url.*download.*fmd.*x86_64.*.7z" | cut -d : -f 2,3 | tr -d '"' | wget -qi - -O FMD2.7z && \
  7z x FMD2.7z -o/app/FMD2 && \
  rm FMD2.7z && \
  apt autoremove -y p7zip-full wget curl --purge && \
  mkdir /downloads && \
  mkdir -p /app/FMD2/userdata && \
  mkdir -p /app/FMD2/downloads
# Copy my settings preset
COPY settings.json root /
ADD root /


VOLUME /config
EXPOSE 3000
