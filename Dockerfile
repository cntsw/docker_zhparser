# Azurewind's PostgreSQL image with Chinese full text search
# build: docker build --force-rm -t chenxinaz/zhparser .
# run: docker run --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser
# run interactive: winpty docker run -it --name PostgreSQLcnFt -p 5432:5432 chenxinaz/zhparser --entrypoint bash chenxinaz/zhparser

FROM postgres:9.4

ARG CN_MIRROR=0

# Uncomment the following command if you have bad internet connection
# and first download the files into data directory
# COPY data/pg_jieba.zip /pg_jieba.zip

RUN if [ $CN_MIRROR = 1 ] ; then DEBIAN_VERSION=$(dpkg --status tzdata|grep Provides|cut -f2 -d'-') \
&& echo "using mirrors for $DEBIAN_VERSION" \
&& echo "deb http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION main non-free contrib \n\
deb http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION-updates main non-free contrib \n\
deb http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION-backports main non-free contrib \n\
deb http://ftp.cn.debian.org/debian-security/ $DEBIAN_VERSION/updates main non-free contrib \n\
deb-src http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION main non-free contrib \n\
deb-src http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION-updates main non-free contrib \n\
deb-src http://ftp.cn.debian.org/debian/ $DEBIAN_VERSION-backports main non-free contrib \n\
deb-src http://ftp.cn.debian.org/debian-security/ $DEBIAN_VERSION/updates main non-free contrib" > /etc/apt/sources.list; else echo "No mirror"; fi

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      gcc \
      make \
      libc-dev \
      postgresql-server-dev-$PG_MAJOR \
      wget \
      unzip \
      ca-certificates \
      openssl \
	&& rm -rf /var/lib/apt/lists/* \
  && wget -q -O - "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
  && wget -O zhparser-0.2.0.tar.gz "https://github.com/amutu/zhparser/archive/v0.2.0.tar.gz" \
  && tar -zxf zhparser-0.2.0.tar.gz \
  && cd scws-1.2.3 \
  && ./configure \
  && make install \
  && cd /zhparser-0.2.0 \
  && SCWS_HOME=/usr/local make && make install \
  # pg_trgm is recommend but not required.
  && echo "CREATE EXTENSION pg_trgm; \n\
CREATE EXTENSION zhparser; \n\
CREATE TEXT SEARCH CONFIGURATION chinese_zh (PARSER = zhparser); \n\
ALTER TEXT SEARCH CONFIGURATION chinese_zh ADD MAPPING FOR n,v,a,i,e,l,t WITH simple;" \
> /docker-entrypoint-initdb.d/init-zhparser.sql \
  && apt-get purge -y gcc make libc-dev postgresql-server-dev-$PG_MAJOR \
  && apt-get autoremove -y \
  && rm -rf \
    /zhparser-0.2.0 \
    /zhparser-0.2.0.tar.gz \
    /scws-1.2.3
