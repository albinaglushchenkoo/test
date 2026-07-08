FROM ubuntu:22.04

ENV SOFT=/soft

#Установка неспециализированных программ
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    autoconf  \
    automake \
    make \
    gcc \
    perl \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    libncurses5-dev \
    libgsl0-dev \
    cmake \
    wget \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

#Установка libdeflate-1.25 (01.11.25)
RUN wget https://github.com/ebiggers/libdeflate/releases/download/v1.25/libdeflate-1.25.tar.gz && \
    tar -xzf libdeflate-1.25.tar.gz && \
    cd libdeflate-1.25 && \
    cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate-1.25 -DCMAKE_INSTALL_LIBDIR=lib && \
    cmake --build build && \
    cmake --install build && \
    cd .. && \
    rm -rf libdeflate-1.25 libdeflate-1.25.tar.gz

#Установка htslib-1.23.1 (18.03.26)
RUN wget https://github.com/samtools/htslib/releases/download/1.23.1/htslib-1.23.1.tar.bz2 && \
    tar -xjf htslib-1.23.1.tar.bz2 && \
    cd htslib-1.23.1 && \
    ./configure --prefix=$SOFT/htslib-1.23.1 --with-libdeflate CPPFLAGS="-I$SOFT/libdeflate-1.25/include" \
    LDFLAGS="-L$SOFT/libdeflate-1.25/lib" && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf htslib-1.23.1 htslib-1.23.1.tar.bz2

#Установка samtools-1.23.1 (18.03.26)
RUN wget https://github.com/samtools/samtools/releases/download/1.23.1/samtools-1.23.1.tar.bz2 && \
    tar -xjf samtools-1.23.1.tar.bz2 && \
    cd samtools-1.23.1 && \
    ./configure --prefix=$SOFT/samtools-1.23.1 --with-htslib=$SOFT/htslib-1.23.1 && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf samtools-1.23.1.tar.bz2 samtools-1.23.1 

#Установка bcftools-1.23.1 (18.03.26)
RUN wget https://github.com/samtools/bcftools/releases/download/1.23.1/bcftools-1.23.1.tar.bz2 && \
    tar -xjf bcftools-1.23.1.tar.bz2 && \
    cd bcftools-1.23.1 && \
    ./configure --prefix=$SOFT/bcftools-1.23.1 --with-htslib=$SOFT/htslib-1.23.1 && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf bcftools-1.23.1.tar.bz2 bcftools-1.23.1 

#Установка vcftools-0.1.17 (15.05.25)
RUN wget https://github.com/vcftools/vcftools/releases/download/v0.1.17/vcftools-0.1.17.tar.gz && \
    tar -xzf vcftools-0.1.17.tar.gz && \
    cd vcftools-0.1.17 && \
    ./configure --prefix=$SOFT/vcftools-0.1.17 && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf vcftools-0.1.17.tar.gz vcftools-0.1.17 

#Прописываем полные пути до директорий в PATH
ENV PATH=$SOFT/samtools-1.23.1/bin:$SOFT/htslib-1.23.1/bin:$SOFT/bcftools-1.23.1/bin:$SOFT/vcftools-0.1.17/bin:$PATH
ENV LD_LIBRARY_PATH=$SOFT/libdeflate-1.25/lib:$SOFT/htslib-1.23.1/lib
# Новые переменные окружения
ENV VCFTOOLS=$SOFT/vcftools-0.1.17/bin/vcftools
ENV BCFTOOLS=$SOFT/bcftools-1.23.1/bin/bcftools
ENV SAMTOOLS=$SOFT/samtools-1.23.1/bin/samtools
ENV BGZIP=$SOFT/htslib-1.23.1/bin/bgzip
ENV TABIX=$SOFT/htslib-1.23.1/bin/tabix

#Для python скрипта из задания 3.
WORKDIR /python_script

RUN pip3 install -U numpy pandas pysam
COPY reformat_script.py .
RUN mkdir -p /python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/ /python_script/data/

CMD ["/bin/bash"]
