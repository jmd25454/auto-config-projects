googlereviewsscrapping="git@github.com:jmd25454/google-reviews-scrapping.git@@main"
chaosawakensite="git@github.com:jmd25454/ChaosAwakenSite.git@@develop"
dbookstore="git@github.com:jmd25454/dbook-store.git@@master"

declare -A repolist
repolist[1]=$googlereviewsscrapping 
repolist[2]=$chaosawakensite
repolist[3]=$dbookstore

BLACK='\033[0;30m'
NC='\033[0m'
scriptloc=$(readlink -f "$0")

echo -e "${BLACK}##########${NC}REPOSITORIOS${BLACK}##########${NC} \
        \n${BLACK}#${NC} [1] google-reviews-scrapping ${BLACK}#${NC}\
        \n${BLACK}#${NC} [2] chaos-awakens-site       ${BLACK}#${NC}\
        \n${BLACK}#${NC} [3] dbook-store              ${BLACK}#${NC}\
        \n${BLACK}################################${NC}"
read -p "SELECIONE OS REPOSITORIOS A SEREM INSTALADOS (SEPARAR POR VIRGULAS): " yn
IFS=","
read -a strarr <<<"$yn"


if [ -z "$strarr" ]; then
    echo -e "${BLACK}####### ${NC}SELECIONE AO MENOS 1 REPOSITORIO ${BLACK}#######\n"
else
    echo -e "${BLACK}####### ${NC}DIGITE A SENHA DO SUPER USER ${BLACK}#######${NC}"
    read -s sudoPW
    if [ -x "$(command -v docker)" ]; then
        echo -e "${BLACK}####### ${NC}DOCKER JA INSTALADO E CONFIGURADO${BLACK}####### ${NC}"
    else
        echo -e "${BLACK}####### ${NC}VOCE NAO POSSUI DOCKER NA SUA MAQUINA${BLACK}####### ${NC}"
        echo -e "${BLACK}####### ${NC}GOSTARIA DE INSTALAR O DOCKER EM SUA MAQUINA? (s/n)${BLACK}#######${NC}"
        read docker
        case $docker in
            [sS]* )
            echo "${BLACK}####### ${NC}INICIANDO INSTALACAO DO DOCKER${BLACK}####### ${NC}"
            echo "${BLACK}####### ${NC}REMOVENDO CONFLITOS ENTRE SERVICOS${BLACK}####### ${NC}"
            echo $sudoPW | sudo -S systemctl stop apache2
            echo $sudoPW | sudo -S systemctl disable apache2
            echo $sudoPW | sudo -S systemctl stop mysql
            echo $sudoPW | sudo -S systemctl disable mysql
            echo $sudoPW | sudo -S systemctl stop redis-server
            echo $sudoPW | sudo -S systemctl disable redis-server
            echo "${BLACK}####### ${NC}REMOVIDO CONFLITOS ENTRE SERVICOS${BLACK}####### ${NC}"
            echo "${BLACK}####### ${NC}INSTALANDO DOCKER${BLACK}####### ${NC}"
            echo $sudoPW | sudo -S apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | echo $sudoPW | sudo -S apt-key add -
            echo $sudoPW | sudo -S add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu disco stable"
            echo $sudoPW | sudo -S apt-get update
            echo $sudoPW | sudo -S apt-get install docker-ce docker-ce-cli containerd.io
            echo $sudoPW | sudo -S systemctl enable docker.service
            echo $sudoPW | sudo -S usermod -aG docker $USER
            echo "${BLACK}####### ${NC}DOCKER INSTALADO${BLACK}####### ${NC}"
            echo "${BLACK}####### ${NC}INSTALANDO DOCKER SWARM${BLACK}####### ${NC}"
            docker swarm init --advertise-addr 127.0.0.1
            echo "${BLACK}####### ${NC}DEFININDO REDE PADRAO PARA OS SERVICOS${BLACK}####### ${NC}"
            docker network create -d overlay webproxy
            echo "${BLACK}####### ${NC}FINALIZADO PROCESSO DE INSTALACAO DO DOCKER${BLACK}####### ${NC}"
            echo "${BLACK}####### ${NC}REINICIANDO PROCESSO DE CONFIGURACAO DE AMBIENTE${BLACK}####### ${NC}"
            echo $yn | bash $scriptloc;;
        esac
    fi
    echo -e "${BLACK}####### ${NC}VERIFICANDO STATUS DA SUA CHAVE SSH${BLACK}####### ${NC}\n"
    ssh=/home/$USER/.ssh/id_ed25519.pub
    if [ -f $ssh ]; then
        echo -e "${BLACK}####### ${NC}CRIANDO PASTA DE PROJETOS${BLACK}####### ${NC}"
        mkdir workspace
        cd workspace
        if [[ -z "$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')" ]]; then
            echo -e "${BLACK}####### ${NC}INSTALANDO PYTHON3 ${BLACK}####### ${NC}"
            echo $sudoPW | sudo -S apt -y install python3
        fi
        if [[ -z "$(php -v | awk 'NR<=1{ print $2 }')" ]]; then
            echo -e "${BLACK}####### ${NC}INSTALANDO PHP${BLACK}####### ${NC}"
            echo $sudoPW | sudo -S apt -y install software-properties-common
            echo $sudoPW | sudo -S add-apt-repository ppa:ondrej/phpecho
            echo $sudoPW | sudo -S apt-get update
            echo $sudoPW | sudo -S apt -y install php
            echo $sudoPW | sudo -S apt-get install -y php-cli php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath php-dom php-ext
        fi
        if [[ -z "$(nvm --version)" ]]; then
            echo -e "${BLACK}####### ${NC}INSTALANDO NVM - 18-16-14${BLACK}####### ${NC}"
            echo $sudoPW | sudo -S apt install curl
            curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
            source ~/.nvm/nvm.sh
            nvm install 18
            nvm install 16
            nvm install 14
            nvm use 18
        fi

        echo -e "${BLACK}####### ${NC}RECEBENDO OS REPOSITORIOS${BLACK}####### ${NC}"
        for arr in "${strarr[@]}"; do
            _repoUrl="${repolist[$arr]%%@@*}"
            repoName="$(basename "$_repoUrl" ".${_repoUrl##*.}")"
            branchName="${repolist[$arr]##*@@}"
            echo -e "${BLACK}####### ${NC}CLONANDO REPOSITORIO: $repoName${BLACK}####### ${NC}"
            mkdir $repoName
            cd $repoName
            git clone -b $branchName $_repoUrl
            cd ..
            echo -e "${BLACK}####### ${NC}REPOSITORIO CLONADO: $repoName${BLACK}####### ${NC}"
        done
        echo -e "${BLACK}####### ${NC}PROCESSO DE CONFIGURACAO FINALIZADO${BLACK}####### ${NC}"
    else
        echo -e "${BLACK}####### ${NC}VOCE NAO POSSUI CHAVE SSH${BLACK}####### ${NC}"
        echo -e "${BLACK}####### ${NC}GERANDO CHAVE SSH${BLACK}####### ${NC}"
        echo "" | ssh-keygen -t ed25519 -C "SSH-KEY $(date +%F) - $USER" -f "/home/$USER/.ssh/id_ed25519"
        echo -e "\n${BLACK}####### ${NC} CONFIGURE A CHAVE ABAIXO NO SEU VERSIONADOR ${BLACK}####### ${NC}\n"
        cat $ssh
    fi
fi
