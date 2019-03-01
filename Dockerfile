FROM ubuntu:18.04

# set default build arguments
ARG ANDROID_TOOLS_VERSION=4333796
ENV NPM_CONFIG_LOGLEVEL info
ARG NODE_VERSION=10.15.0


# set default environment variables
ENV ADB_INSTALL_TIMEOUT=10
ENV PATH=${PATH}:/opt/buck/bin/
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_HOME=${ANDROID_HOME}
ENV PATH=${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs=\"-Xmx512m -XX:+HeapDumpOnOutOfMemoryError\""
ENV DEBIAN_FRONTEND=noninteractive

# install system dependencies
RUN apt-get update -y
RUN apt-get install -y \
		autoconf \
		automake \
		expect \
		curl \
		g++ \
		gcc \
		git \
		libqt5widgets5 \
		lib32z1 \
		lib32stdc++6 \
		make \
		maven \
		openjdk-8-jdk \
		python-dev \
		python3-dev \
		qml-module-qtquick-controls \
		qtdeclarative5-dev \
		unzip \
		xz-utils \
		locales \
        nodejs \
        npm \
	&& \
	rm -rf /var/lib/apt/lists/* && \
	apt-get autoremove -y && \
	apt-get clean && \
	echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf && sysctl -p --system

# fix crashing gradle because of non ascii characters in ENV variables: https://github.com/gradle/gradle/issues/3117
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# configure npm
RUN npm config set spin=false
RUN npm config set progress=false

RUN npm install -g \
    react-native-cli \
    yarn \
    react-scripts

# Full reference at https://dl.google.com/android/repository/repository2-1.xml
# download and unpack android
RUN mkdir -p /opt/android && mkdir -p /opt/tools
WORKDIR /opt/android
RUN curl --silent https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_TOOLS_VERSION}.zip > android.zip && \
	unzip android.zip && \
	rm android.zip

# copy tools folder
COPY tools/android-accept-licenses.sh /opt/tools/android-accept-licenses.sh

RUN chmod +x /opt/tools -R

ENV PATH ${PATH}:/opt/tools

RUN mkdir -p $ANDROID_HOME/licenses/ \
	&& echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > $ANDROID_HOME/licenses/android-sdk-license \
	&& echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_HOME/licenses/android-sdk-preview-license

ENV ANDROID_BUILD_TOOLS=28.0.2
ENV JAVA_OPTS='-XX:+IgnoreUnrecognizedVMOptions --add-modules java.se.ee'

# sdk
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

VOLUME ["/app"]
WORKDIR /app