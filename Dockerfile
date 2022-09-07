FROM debian

# Install environment dependencies
RUN apt-get update -y && apt-get install -y git curl nodejs npm zip wget gnupg software-properties-common postgresql htop
RUN git clone https://github.com/infracost/cloud-pricing-api.git && pwd
WORKDIR cloud-pricing-api

# Comment all CSPs in scraping logic except us-east-1
RUN sed -i -e '/us-east-1/b' -e '16,46s/^/\/\//' ./src/scrapers/awsBulk.ts

# Create local infracost api key
RUN cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 | tee random_str

# Downloads the CLI based on your OS/arch and puts it in /usr/local/bin
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Install infracost dependencies
RUN npm install && npm run build

# Configure postgresql to listen to localhost
RUN echo "listen_addresses='*'" | tee -a /etc/postgresql/13/main/postgresql.conf
RUN chmod -R u=rwx '/var/lib/postgresql/13/main/'
RUN chmod -R 0700 '/etc/postgresql/13/main'

# Configure infracost server
RUN echo "POSTGRES_HOST=localhost" | tee -a .env
RUN echo "POSTGRES_DB=cloud_pricing" | tee -a .env
RUN echo "POSTGRES_USER=postgres" | tee -a .env
RUN echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}" | tee -a .env
RUN echo "INFRACOST_TLS_INSECURE_SKIP_VERIFY=true" | tee -a .env
RUN echo "SELF_HOSTED_INFRACOST_API_KEY=`cat random_str`" | tee -a .env
RUN echo "INFRACOST_API_KEY=`cat random_str`" | tee -a .env
RUN echo "INFRACOST_PRICING_API_ENDPOINT=http://localhost:4000" | tee -a .env
RUN echo "INFRACOST_TLS_INSECURE_SKIP_VERIFY=true" | tee -a .env

# Run server and initial sample IAC project cost
ADD main.sh .
RUN chmod +x main.sh

VOLUME /terraform

CMD /bin/bash
ENTRYPOINT /cloud-pricing-api/main.sh
