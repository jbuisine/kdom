FROM mratin/maven-node-alpine

# you can specify python version during image build
ARG PYTHON_VERSION=2.7.9

# install build dependencies and needed tools
RUN apk add --update --no-cache \
    wget \
    gcc \
    g++ \
    make \
    zlib-dev \
    libffi-dev \
    openssl-dev \
    musl-dev

# Install python/pip
# download and extract python sources
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \                                              
    && tar xzf Python-${PYTHON_VERSION}.tgz

# build python and remove left-over sources
RUN cd /Python-${PYTHON_VERSION} \ 
    && ./configure --prefix=/usr --enable-optimizations --with-ensurepip=install \
    && make install \
    && rm /opt/Python-${PYTHON_VERSION}.tgz /opt/Python-${PYTHON_VERSION} -rf


WORKDIR /code

# Install the Angular tools
RUN npm install -g angular-cli

# Add scala source:
ADD pom.xml /code/pom.xml
RUN mvn dependency:resolve

WORKDIR /code/ui

ADD kdom-ui/angular-cli.json /code/ui/angular-cli.json
ADD kdom-ui/karma.conf.js /code/ui/karma.conf.js
ADD kdom-ui/package.json /code/ui/package.json
ADD kdom-ui/protractor.conf.js /code/ui/protractor.conf.js
ADD kdom-ui/tslint.json /code/ui/tslint.json
ADD kdom-ui/e2e /code/ui/e2e

# Install dependencies
RUN npm install

# Add source code
ADD src /code/src
ADD kdom-ui/src /code/ui/src

# Build the app
RUN node_modules/angular-cli/bin/ng build --prod --base-href /ui/

# Install the ui app
RUN mv dist/* /code/src/main/resources/public/ui/

WORKDIR /code

RUN mvn package

CMD ["java", "-Djetty.port=80", "-jar", "target/kdom-0.1-SNAPSHOT-jar-with-dependencies.jar"]
