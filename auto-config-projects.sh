workspace="git@git.vhsys.com.br:devops/workspace.git@@master"
vhsys="git@git.vhsys.com.br:vhsys/vhsys.git@@master"
app="git@git.vhsys.com.br:vhsys/front/app.git@@master"
checkout="git@git.vhsys.com.br:vhsys/checkout.git@@master"
systemcoreapi="git@git.vhsys.com.br:aws/aws-lambda-functions/system-core-api.git@@master"
apibackoffice="git@git.vhsys.com.br:aws/aws-lambda-functions/api-back-office.git@@master"

declare -A repolist=([0]=$workspace, [1]=$vhsys, [2]=$app, [3]=$checkout, [4]=$systemcoreapi, [5]=$apibackoffice)
BLACK='\033[0;30m'
NC='\033[0m'
echo -e "${BLACK}#####REPOSITORIOS##### ${NC} \
        \n${BLACK}#${NC}[1] vhsys-erp       ${BLACK}#${NC}\
        \n${BLACK}#${NC}[2] app-core        ${BLACK}#${NC}\
        \n${BLACK}#${NC}[3] checkout        ${BLACK}#${NC}\
        \n${BLACK}#${NC}[4] system-core-api ${BLACK}#${NC}\
        \n${BLACK}#${NC}[5] api-backoffice  ${BLACK}#${NC}\
        \n${BLACK}######################${NC}"
read -p "SELECIONE OS REPOSITORIOS A SEREM INSTALADOS (SEPARAR POR VIRGULAS): " yn
IFS=","
read -a strarr <<<"$yn"

if [ -z "$strarr" ]; then
    echo -e "###SELECIONE AO MENOS 1 REPOSITORIO###\n"
else
    read -s -p "###DIGITE A SENHA DO SUPER USER###" sudoPW
    if [ -x "$(command -v docker)" ]; then
        echo -e "###VERIFICANDO STATUS DA SUA CHAVE SSH###\n"
        ssh=/home/$USER/.ssh/id_ed25519.pub
        if [ -f $ssh ]; then
            echo "###REALOCANDO NA PASTA HOME###"
            cd ~
            if [ -d "workspace" ]; then
                echo "###PUXANDO PROJETO BASE###"
                git clone -b master git@git.vhsys.com.br:devops/workspace.git
                docker stack deploy -c docker/manager/traefik.vhsys.local/docker-stack.yml manager
                docker stack deploy -c docker/manager/portainer.vhsys.local/docker-stack.yml manager
                docker stack deploy -c docker/database/mysql.vhsys.local/docker-stack.yml mysql
                docker stack deploy -c docker/database/redis.vhsys.local/docker-stack.yml redis
            fi
            cd workspace/webprojects
            if [ -z $(which python) ]; then
                echo "###INSTALANDO PYTHON###"
                $sudoPW | sudo apt -y install python3.8
            fi
            if [ -z $(which php7.4) ]; then
                echo "###INSTALANDO PHP 7.4###"
                $sudoPW | sudo apt -y install software-properties-common
                $sudoPW | sudo add-apt-repository ppa:ondrej/phpecho
                $sudoPW | sudo apt-get update
                $sudoPW | sudo apt -y install php7.4
                $sudoPW | sudo apt-get install -y php7.4-cli php7.4-json php7.4-common php7.4-mysql php7.4-zip php7.4-gd php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-dom php7.4-ext
            fi
            if [ -d "${HOME}/.nvm/.git" ]; then
                echo "###INSTALANDO NVM - 18-16-14###"
                echo $sudoPW | sudo apt install curl
                curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
                nvm install 18
                nvm install 16
                nvm install 14
            fi

            echo "###RECEBENDO OS REPOSITORIOS###"
            for dir in "${!repolist[@]}"; do
                for arr in "${strarr[@]}"; do
                    if [ ${dir} == ${arr} ]; then
                        _repoUrl="${dir%%@@*}"
                        repoName="$(basename "$_repoUrl" ".${_repoUrl##*.}")"
                        branchName="${dir##*@@}"
                        echo "###CLONANDO REPOSITORIO: $repoName###"
                        case $repoName in
                        "checkout")
                            mkdir $repoName
                            cd $repoName
                            docker stack deploy -c docker-stack.yml front
                            git clone -b $branchName $_repoUrl
                            cd $repoName
                            cp .env.example .env
                            echo $sudoPW | sudo composer install
                            echo $sudoPW | sudo composer update
                            npm install
                            ;;
                        "app")
                            cd front/app-core
                            docker stack deploy -c docker-stack.yml front
                            echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 app.front.vhsys.local" >>/etc/hosts"
                            git clone -b $branchName $_repoUrl
                            cd $repoName
                            cp .env.example .env
                            nvm use 16
                            curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | echo $sudoPW | sudo apt-key add -
                            echo "deb https://dl.yarnpkg.com/debian/ stable main" | echo $sudoPW | sudo tee /etc/apt/sources.list.d/yarn.list
                            echo $sudoPW | sudo apt update
                            echo $sudoPW | sudo apt install yarn
                            npm config set -- '//git.vhsys.com.br/api/v4/projects/315/packages/npm/:_authToken' token
                            npm config set @front:registry https://git.vhsys.com.br/api/v4/projects/315/packages/npm/
                            yarn add @front/tictac
                            npm i
                            yarn install
                            ;;
                        "vhsys")
                            cd vhsys-erp
                            git clone -b $branchName $_repoUrl
                            docker stack deploy -c docker-stack.yml vhsys
                            dockerID=$(docker ps -aqf "name=vhsys_erp")
                            docker exec -ti -u root $dockerID composer update
                            cp .env.example .env
                            cd PDV2
                            npm install
                            ;;
                        "systemcoreapi")
                            mkdir $repoName
                            cd $repoName
                            git clone -b $branchName $_repoUrl
                            python3 -m venv .venv
                            source .venv/bin/activate
                            pip install -r requirements.txt
                            pip install -r requirements-dev.txt
                            ;;
                        "apibackoffice")
                            mkdir $repoName
                            cd $repoName
                            git clone -b $branchName $_repoUrl
                            python3 -m venv .venv
                            source .venv/bin/activate
                            pip install -r requirements.txt
                            pip install -r requirements-dev.txt
                            ;;
                        esac
                        echo "###REPOSITORIO CLONADO: $repoName###"
                    fi
                done
            done
            echo "###REINICIANDO A MAQUINA PARA FINALIZAR O PROCESSO DE CONFIGURACAO###"
            echo $sudoPW | sudo reboot
        else
            echo "###VOCE NAO POSSUI CHAVE SSH###"
            echo "###GERANDO CHAVE SSH###"
            echo "" | ssh-keygen -t ed25519 -C "SSH-KEY GitLab - $USER" -f "/home/$USER/.ssh/id_ed25519"
            echo -e "\n###UTILIZE A CHAVE ABAIXO NO LINK: https://git.vhsys.com.br/-/profile/keys ###\n"
            cat $ssh
        fi
    else
        echo -e "###VOCE NAO POSSUI DOCKER NA SUA MAQUINA###"
        echo "###INICIANDO INSTALACAO DO DOCKER###"
        echo "###REMOVENDO CONFLITOS ENTRE SERVICOS###"
        echo $sudoPW | sudo systemctl stop apache2
        echo $sudoPW | sudo systemctl disable apache2
        echo $sudoPW | sudo systemctl stop mysql
        echo $sudoPW | sudo systemctl disable mysql
        echo $sudoPW | sudo systemctl stop redis-server
        echo $sudoPW | sudo systemctl disable redis-server
        echo "###REMOVIDO CONFLITOS ENTRE SERVICOS###"
        echo "###INSTALANDO DOCKER###"
        echo $sudoPW | sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | echo $sudoPW | sudo apt-key add -
        echo $sudoPW | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu disco stable"
        echo $sudoPW | sudo apt-get update
        echo $sudoPW | sudo apt-get install docker-ce docker-ce-cli containerd.io
        echo $sudoPW | sudo systemctl enable docker.service
        echo $sudoPW | sudo usermod -aG docker $USER
        echo "###DOCKER INSTALADO###"
        echo "###INSTALANDO DOCKER SWARM###"
        docker swarm init --advertise-addr 127.0.0.1
        echo "###DEFININDO REDE PADRAO PARA OS SERVICOS###"
        docker network create -d overlay webproxy
        echo "###PUXANDO IMAGENS DO DOCKER###"
        printf '%s\n%s\n' vhsysdev vhsys@2019 | docker login
        echo $sudoPW | sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
        echo $sudoPW | sudo chmod g+rwx "$HOME/.docker" -R
        docker pull vhsys/php:api-php72-nginx114-nrs-composer-2.0
        docker pull vhsys/php:app-php72-apache241-composer2.0
        docker pull traefik:v1.7
        docker pull redis:5.0.6
        docker pull mysql:5.7
        echo "###CONFIGURANDO HOSTS DOS SERVICOS###"
        echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 traefik.vhsys.local" >>/etc/hosts"
        echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 portainer.vhsys.local" >>/etc/hosts"
        echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 mysql.vhsys.local" >>/etc/hosts"
        echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 redis.vhsys.local" >>/etc/hosts"
        echo $sudoPW | sudo -- sh -c "echo "127.0.0.1 erp.vhsys.local" >>/etc/hosts"
        echo "###FINALIZADO PROCESSO DE INSTALACAO DO DOCKER###"
        echo "###REINICIANDO PROCESSO DE CONFIGURACAO DE AMBIENTE###"
        echo $yn | bash teste.sh
    fi
fi
