# Use a base image with a package manager (e.g., Debian)
FROM debian:sid

# Set non-interactive mode for package installation
ARG DEBIAN_FRONTEND=noninteractive

# Set the locale to en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Install required packages
RUN apt-get update  && apt-get install -y --no-install-recommends ca-certificates  \ 
    build-essential \
    libldap2-dev \
    libsasl2-dev  \
    libnss3-dev \
    python3-dev \
    wget \
    unzip \ 
    pandoc \
    fontconfig \
    fonts-dejavu-mono \
    bash \
    xz-utils \
    imagemagick \
    ghostscript \
    libldap2 \
    libmagic1t64 \ 
    libsasl2-2 \
    libxi6 \
    libxslt1.1 \ 
    python3-venv \ 
    sqlite3 \
    libqt6webenginecore6 \
    locales-all \
    xdg-utils  && apt-get clean 

# Install pdfcpu
RUN wget https://github.com/pdfcpu/pdfcpu/releases/download/v0.9.1/pdfcpu_0.9.1_Linux_x86_64.tar.xz 
RUN tar xf pdfcpu_0.9.1_Linux_x86_64.tar.xz 
RUN mv pdfcpu_0.9.1_Linux_x86_64/pdfcpu /usr/local/bin/ 
RUN rm -rf pdfcpu_0.9.1_Linux_x86_64*

# Install ebook-converter (calibre)
RUN wget https://download.calibre-ebook.com/8.0.1/calibre-8.0.1-x86_64.txz \
    && mkdir /opt/calibre \
    && tar xf calibre-8.0.1-x86_64.txz  -C /opt/calibre \
    && rm -rf calibre-8.0.1-x86_64* \
    && ./opt/calibre/calibre_postinstall 

# Set the working directory
WORKDIR /app

# Create directories for volumes
RUN mkdir  build chapters  images

# Define volumes
VOLUME ["/app/build", "/app/chapters", "/app/images"]

# Install Bai Jamjuree font
ADD fonts/* /usr/share/fonts/truetype/ 
RUN fc-cache -f -v

COPY *.css /app/
COPY *.yaml /app/
COPY *.theme /app/

# Copy the gen.sh script into the image
COPY gen.sh /app/gen.sh

# Make the script executable
RUN chmod +x /app/gen.sh

# Default command (you can change this to your preferred command)
CMD ["bash"]
