ARG ROS_DISTRO=jazzy
ARG CARET_VERSION="main"

FROM ros:${ROS_DISTRO}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        locales \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TZ=Asia/Tokyo

# Do not use cache
ADD "https://www.random.org/sequences/?min=1&max=52&col=1&format=plain&rnd=new" /dev/null

RUN git clone https://github.com/xygyo77/caret.git /ros2_caret_ws && \
    cd /ros2_caret_ws && \
    git checkout ${CARET_VERSION}

# cspell: disable
RUN apt-get update && \
    apt-get install -y python3-pip python3-virtualenv && \
    virtualenv -p python3 --system-site-packages $HOME/venv/jazzy
# cspell: enable

# cspell: disable
RUN apt update && apt install -y git && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata
# cspell: enable

RUN echo "===== Setup CARET ====="
COPY caret.repos ros2_caret_ws/
RUN cd ros2_caret_ws && \
    mkdir src && \
    REPOS_FILE=caret.repos && \
    export PIP_BREAK_SYSTEM_PACKAGES=1 && \
    vcs import src < $REPOS_FILE && \
    . /opt/ros/"$ROS_DISTRO"/setup.sh && \
    . $HOME/venv/jazzy/bin/activate && \
    ./setup_caret.sh -c -d "$ROS_DISTRO"

RUN echo "===== Build CARET ====="
RUN cd ros2_caret_ws && \
    . /opt/ros/"$ROS_DISTRO"/setup.sh && \
    . $HOME/venv/jazzy/bin/activate && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_C_FLAGS="-std=c99"
