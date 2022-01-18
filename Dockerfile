ARG TARGET="x86_64-elf"
FROM ubuntu:20.04 as build

ARG TARGET

ARG GCC_VERSION="11.2.0"
ARG BINUTILS_VERSION="2.37"

ARG DEBIAN_FRONTEND=noninteractive

ENV PATH="/opt/${TARGET}/bin:$PATH"

WORKDIR /build

RUN apt -y update \
    && apt --no-install-recommends -y install \
        bison build-essential ca-certificates curl flex \
        libgmp-dev libisl-dev libmpc-dev libmpfr-dev texinfo

RUN curl -fsSL -o "binutils-${BINUTILS_VERSION}.tar.xz" \
        "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz" \
    && tar -xf "binutils-${BINUTILS_VERSION}.tar.xz"

RUN mkdir "build-binutils-${BINUTILS_VERSION}" \
    && cd "build-binutils-${BINUTILS_VERSION}" \
    && "../binutils-${BINUTILS_VERSION}/configure" \
        --prefix="/opt/${TARGET}" --target="${TARGET}" \
        --disable-nls --disable-werror --with-sysroot \
    && make \
    && make install

RUN curl -fsSL -o "gcc-${GCC_VERSION}.tar.xz" \
        "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz" \
    && tar -xf "gcc-${GCC_VERSION}.tar.xz"

RUN mkdir "build-gcc-${GCC_VERSION}" \
    && cd "build-gcc-${GCC_VERSION}" \
    && "../gcc-${GCC_VERSION}/configure" \
        --prefix="/opt/${TARGET}" --target="${TARGET}" \
        --disable-nls --enable-languages=c,c++ --without-headers \
    && make all-gcc \
    && make install-gcc \
    && make all-target-libgcc \
    && make install-target-libgcc

FROM ubuntu:20.04 as runtime

ARG TARGET

ARG DEBIAN_FRONTEND=noninteractive

ENV PATH="/opt/${TARGET}/bin:$PATH"

RUN apt -y update \
    && apt --no-install-recommends -y install \
        grub-common libgmp10 libisl22 libmpc3 libmpfr6 make nasm xorriso \
    && rm -rf -- /var/lib/apt/lists/*

COPY --from=build "/opt/${TARGET}" "/opt/${TARGET}"
