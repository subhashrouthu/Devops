FROM golang:1.15.6 as builder
# Install git + SSL ca certificates (to call HTTPS endpoints)
# For Alpine-RUN apk update && apk add --no-cache --upgrade git ca-certificates bash
RUN apt-get update

#creating and copying everything from current directory to devops folder in docker image
ADD . /Devops
#making devops/cmd/app as workdir(changing directory in image)
WORKDIR /Devops

#will download required repos from go.sum file which is faster method instead of go mod tidy
RUN go mod download

#changing working directory to place where main present
WORKDIR /Devops/cmd/app
RUN go build -o /main
# CMD ["/main"]


#Second Stage to generate image
FROM ubuntu:20.04
#while Installing wont give interactive terminal just install with default values
ENV DEBIAN_FRONTEND=noninteractive
#setting timezone and isntalling curl,tzdata and reconfiguring them and then telling not to install
#recomended packages even though they are dependencies just install asked packages 
#When you run sudo apt-get update (or use the Refresh button in a package manager), a list of packages
#will get downloaded from the Ubuntu servers. These files are then stored in /var/lib/apt/lists/
#You can safely remove the contents of that directory as it is recreated when you refresh the package lists
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update && apt-get install curl tzdata -y && dpkg-reconfigure -f noninteractive tzdata && date \
    && apt-get install -y --no-install-recommends software-properties-common telnet \
    iputils-ping net-tools procps wget curl vim unzip  mysql-client \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
#Copy the static executable
COPY --from=builder ./main ./main
CMD ["/app/main"]



