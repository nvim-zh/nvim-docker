# If you do not need to use cuda, you can start from official Ubuntu image,
# which can be found in https://hub.docker.com/_/ubuntu
FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

ARG HOME=/root
ARG CTAGS_DIR=$HOME/tools/ctags
ARG RIPGREP_DIR=$HOME/tools/ripgrep
ARG ANACONDA_DIR=$HOME/tools/anaconda
ARG NVIM_DIR=$HOME/tools/nvim
ARG NVIM_CONFIG_DIR=$HOME/.config/nvim

# Install common dev tools
RUN apt-get update --allow-unauthenticated \
    && apt-get install --allow-unauthenticated -y git curl autoconf pkg-config zsh locales

# Install Anaconda
# COPY ./packages/Anaconda3-2019.07-Linux-x86_64.sh /tmp/anaconda.sh
RUN curl -Lo /tmp/anaconda.sh https://repo.anaconda.com/archive/Anaconda3-2019.07-Linux-x86_64.sh
RUN chmod u+x /tmp/anaconda.sh \
    && bash /tmp/anaconda.sh -b -p ${ANACONDA_DIR} \
    && rm /tmp/anaconda.sh
ENV PATH=${ANACONDA_DIR}/bin:$PATH

# Python packages
RUN pip install pynvim jedi pylint flake8

# Compile ctags
RUN cd /tmp \
    && git clone https://github.com/universal-ctags/ctags.git \
    && cd ctags \
    && ./autogen.sh \
    && ./configure --prefix=${CTAGS_DIR} \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/ctags
ENV PATH=${CTAGS_DIR}/bin:$PATH

# Install ripgrep
RUN curl -Lo /tmp/ripgrep.tar.gz https://github.com/BurntSushi/ripgrep/releases/download/11.0.0/ripgrep-11.0.0-x86_64-unknown-linux-musl.tar.gz \
    && cd /tmp \
    && mkdir -p ${RIPGREP_DIR} \
    && tar zxf ripgrep.tar.gz -C ${RIPGREP_DIR} --strip-components=1 \
    && rm -rf /tmp/ripgrep.tar.gz
ENV PATH=${RIPGREP_DIR}:$PATH

# Install nvim
RUN curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz \
    && mkdir -p ${NVIM_DIR} \
    && tar zxf nvim-linux64.tar.gz -C ${NVIM_DIR} --strip-components=1 \
    && mkdir -p ${NVIM_CONFIG_DIR} \
    && git clone https://github.com/jdhao/nvim-config.git ${NVIM_CONFIG_DIR} \
    && ${NVIM_DIR}/bin/nvim +PlugInstall +qall \
    && rm nvim-linux64.tar.gz
ENV PATH=${NVIM_DIR}/bin:$PATH
ENV TERM=xterm-256color

# Set up locales
RUN locale-gen en_US.UTF-8
# we must change locale to UTF-8, or zplug install will fail
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y tzdata && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Install zplugin
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"

# Download rc files
RUN curl -Lo $HOME/.bash_profile https://raw.githubusercontent.com/jdhao/dotfiles/master/shell/.bash_profile \
    && curl -Lo $HOME/.zshrc https://raw.githubusercontent.com/jdhao/dotfiles/master/shell/.zshrc \
    && curl -Lo $HOME/.pylintrc https://raw.githubusercontent.com/jdhao/dotfiles/master/pylint/.pylintrc
RUN ["zsh", "-ic", "source $HOME/.zshrc"]

CMD ["bash", "-l"]
