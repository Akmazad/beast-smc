FROM ubuntu:16.04
MAINTAINER Aaron Darling <aaron.darling@uts.edu.au>

RUN apt-get update && apt-get install -y default-jre python3 python3-pip vim git curl libhmsbeagle1v5 libhmsbeagle-java && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir /app
RUN pip3 install numpy
ADD bin/ /app/beast-smc/bin/
RUN cd /app ; curl -s https://get.nextflow.io | bash

# RUN rm /usr/lib/x86_64-linux-gnu/libhmsbeagle-opencl.so.*

ENV PATH="/app/:/app/beast-smc/bin/:${PATH}"
ENV BEASTJAR="/app/beast-smc/bin/beast.jar"
CMD ["/app/beast-smc/bin/beast_smc_modular"]
