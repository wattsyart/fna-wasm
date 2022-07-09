# See: https://gist.github.com/TheSpydog/e94c8c23c01615a5a3b2cc1a0857415c

FROM ubuntu:18.04 AS fna-wasm-build

RUN apt-get update --fix-missing

# Install dependencies
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y python3
RUN apt-get install -y make
RUN apt-get install -y cmake
RUN apt-get install -y nodejs
RUN apt-get install -y npm
RUN npm install -g live-server

# Install mono (required by Uno.Wasm.Bootstrap)
RUN apt install -y gnupg ca-certificates
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt update
RUN apt install -y mono-devel

# See: https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#1804
RUN wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-5.0
RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-runtime-5.0

# See: https://emscripten.org/docs/getting_started/downloads.html
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR /emsdk
RUN ./emsdk install latest
RUN ./emsdk activate latest

# For some reason, using bash 'source' or sh '.' has no impact when setting PATH,
# so we have to do it manually by copying out the text and running it with ENV
# here.
#
# RUN ./emsdk construct_env > vars.sh
# RUN . ./vars.sh
ENV PATH="/emsdk:/emsdk/upstream/emscripten:/emsdk/node/14.18.2_64bit/bin:${PATH}"
ENV EMSDK="/emsdk"
ENV EM_CONFIG="/emsdk/.emscripten"
ENV EMSDK_NODE="/emsdk/node/14.18.2_64bit/bin/node"

WORKDIR /
RUN mkdir fnalibs
WORKDIR /fnalibs

# SDL2
RUN git clone https://github.com/libsdl-org/SDL
WORKDIR /fnalibs/SDL
RUN mkdir emscripten-build
WORKDIR /fnalibs/SDL/emscripten-build
RUN emconfigure ../configure --host=wasm32-unknown-emscripten --disable-assembly --disable-threads --disable-cpuinfo CFLAGS="-O2 -Wno-warn-absolute-paths -Wdeclaration-after-statement -Werror=declaration-after-statement" --prefix="$PWD/emscripten-sdl2-installed"
RUN emmake make
RUN emmake make install
WORKDIR /fnalibs

# FNA3D
RUN git clone --recursive https://github.com/FNA-XNA/FNA3D
WORKDIR /fnalibs/FNA3D
RUN mkdir build
WORKDIR /fnalibs/FNA3D/build
RUN emcmake cmake .. -DSDL2_INCLUDE_DIRS=/fnalibs/SDL/include -DSDL2_LIBRARIES=/fnalibs/SDL/emscripten-build/emscripten-sdl2-installed/lib/libSDL2.a
RUN emmake make
WORKDIR /fnalibs

# FAudio
RUN git clone https://github.com/FNA-XNA/FAudio
WORKDIR /fnalibs/FAudio
RUN mkdir build
WORKDIR /fnalibs/FAudio/build
RUN emcmake cmake .. -DSDL2_INCLUDE_DIRS=/fnalibs/SDL/include -DSDL2_LIBRARIES=/fnalibs/SDL/emscripten-build/emscripten-sdl2-installed/lib/libSDL2.a
RUN emmake make

# Copy artifacts to output
WORKDIR /
RUN mkdir -p /var/output
RUN cp /fnalibs/SDL/emscripten-build/emscripten-sdl2-installed/lib/libSDL2.a /var/output/SDL2.a
RUN cp /fnalibs/FNA3D/build/libFNA3D.a /var/output/FNA3D.a
RUN cp /fnalibs/FNA3D/build/libmojoshader.a /var/output/libmojoshader.a
RUN cp /fnalibs/FAudio/build/libFAudio.a /var/output/FAudio.a

# Copy game source to output
RUN mkdir -p /var/lib/fna
COPY ./bootstrap /var/output
COPY ./src/FnaWasm /var/output
COPY ./lib/FNA /var/lib/FNA

# Ensure output directory is usable by Uno.Wasm.Bootstrap
RUN /bin/bash -c 'chmod -R 777 /var/lib/fna'
RUN /bin/bash -c 'chmod -R 777 /var/output'

# Build game
RUN dotnet build /var/output/WasmBuild.csproj -c Release

EXPOSE 8080
CMD ["live-server"]
