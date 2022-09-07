echo "install terraform with tfenv"
git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
. ~/.bash_profile && tfenv install 0.14.11 && tfenv use 0.14.11

echo "start infracost server"
bash -c "set -a && source .env && set -a && env && npm run start" &

echo "start postgres server and configure for infracost"
runuser -u postgres -- bash -c "/usr/lib/postgresql/13/bin/postgres -D /var/lib/postgresql/13/main -c config_file=/etc/postgresql/13/main/postgresql.conf & " && \
  sleep 5 && \
  runuser -u postgres -- psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" && \
  runuser -u postgres -- createdb -O postgres cloud_pricing && \
  bash -c "set -a && source .env && set -a && env && DEBUG=* npm run db:setup"

echo "begin infracost csp price scraping"
bash -c "set -a && source .env && set -a && env && npm run data:scrape --only=[aws:bulk]" &

echo "naively wait several minutes for some prices to populate the database"
# TODO: make this more efficient. resume when prices processed.
sleep 600

echo "configure infracost to look at localhost postgres db and accumulate costs"
infracost configure set tls_insecure_skip_verify true
infracost configure set pricing_api_endpoint http://localhost:4000
infracost configure set api_key $(cat random_str)

ls /terraform
if [ -z "$(ls -A /terraform)" ] ; then
  echo "create terraform sample files"
  # sample.tf
  cat <<EOL | tee /terraform/sample.tf
resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  tags = {
    Name = "ExampleAppServerInstance"
  }
}
EOL
  # provider.tf
  cat <<EOL | tee /terraform/provider.tf
provider "aws" { }
EOL
fi

infracost breakdown --path /terraform | tee /terraform/iac-cost.txt

exec sh -c 'while true ;do wait ;done'
