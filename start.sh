




#export KUBECONFIG=your-kubeconfig.yml;




# atualiza imagem 
# start.sh  update_imagem --IMAGE image_name  --VERSAO 'Versao id'
export GRUPO_HEML='LOCAL'
if [ "$2" == "--IMAGE" ]; then
 export    IMAGE=$3
fi 

if [ "$4" == "--VERSAO" ]; then
 export    VERSAO=$5
fi 



############################################


if [ "$2" == "--teste" ]; then
   export    STACK="prod" # branch
   export    NAMESPACE="metabase"
   export    NAME_APLICACAO="bi-metabase" # homolog-indicadores-cicd brach-nomeprojeto
   export    PASTA_HELM="."
   export    VALUE_YML="value.yaml"
fi




#############
NOME_APLICACAO="AMBIENTE DE DEPLOY KUBE-HELM"
VERSAO_SCRIPT="V1.0"
DATA=$(date +"%d-%m-%Y %M:%S")
FILTER=".items[] | select(.spec.template.spec.containers[].image | startswith(\"${IMAGE}\")).metadata.name"
FILTER_PODS_NAMESPACE=".items[]| select(.metadata.namespace | startswith(\"${NAMESPACE}\")).metadata.name "


###################################################valida ###########################
function valida_NAME_APLICACAO(){
           if [ "$NAME_APLICACAO" == "" ] ; then
                  echo "FALTA NAME_APLICACAO=$NAME_APLICACAO"
                  exit 1
           fi
            export NAME_APLICACAO=${NAME_APLICACAO,,} # converte para minuscula
            echo "OK NAME_APLICACAO=$NAME_APLICACAO"
}

function valida_HELM(){
           if [ "$HELM" == "" ] ; then
                  echo "FALTA PASTA_HELM=$HELM"
                  exit 1
           fi
           echo "OK PASTA_HELM=$HELM"
}
function valida_VALUE_YML(){
            if   [ "$VALUE_YML" == "" ] ; then
                  echo "FALTA VALUE_YML=$VALUE_YML"
                  exit 1
           fi
           echo "OK VALUE_YML=$VALUE_YML"
}

function valida_NAMESPACE(){
            if   [ "$NAMESPACE" == "" ] ; then
                  echo "FALTA NAMESPACE=$NAMESPACE"
                  exit 1
           fi
        export NAMESPACE=${NAMESPACE,,}  # converte para minuscula
           echo "OK  NAMESPACE=$NAMESPACE"
}

function valida_IMAGE(){
            if   [ "$IMAGE" == "" ] ; then
                  echo "FALTA IMAGE=$IMAGE"
                  exit 1
           fi
           echo "OK IMAGE=$IMAGE"
}

function valida_VERSAO(){
            if   [ "$VERSAO" == "" ] ; then
                  echo "FALTA VERSAO=$VERSAO"
                  exit 1
           fi
         echo "OK VERSAO=$VERSAO"
}

function valida_HELM_USER(){
            if   [ "$HELM_USER" == "" ] ; then
                  echo "FALTA HELM_USER=$HELM_USER"
                  exit 1
           fi
            echo "OK  HELM_USER=$HELM_USER"
}

function valida_HELM_PASS(){
            if   [ "$HELM_PASS" == "" ] ; then
                  echo "FALTA HELM_PASS=$HELM_PASS"
                  exit 1
           fi
           echo "OK HELM_PASS=HELM_PASS"
}

function valida_HELM_URL(){
            if   [ "$HELM_URL" == "" ] ; then
                  echo "FALTA HELM_URL=$HELM_URL"
                  exit 1
           fi
            echo "OK HELM_URL=$HELM_URL"
}
###################################################valida ###########################

function get_all(){
      echo  "kubectl get pods -A"
      kubectl get pods -A
}

function teste_templete(){
         valida_NAME_APLICACAO
         valida_HELM
         valida_VALUE_YML
         echo "helm  template  $NAME_APLICACAO  $GRUPO_HEML/$HELM  -f $VALUE_YML"
                        helm  template  $NAME_APLICACAO  $HELM  -f $VALUE_YML
            
}

function  teste_deploy(){
        valida_NAME_APLICACAO
        valida_VALUE_YML
        valida_NAMESPACE
        echo "helm  upgrade  $NAME_APLICACAO $GRUPO_HEML/$HELM   -f $VALUE_YML  --install  -n  $NAMESPACE  --dry-run"
              helm  upgrade  $NAME_APLICACAO $GRUPO_HEML/$HELM   -f $VALUE_YML  --install  -n  $NAMESPACE  --dry-run
}

function delete_namespace(){
      valida_NAMESPACE
      echo " kubectl delete namespace $NAMESPACE"
             kubectl delete namespace $NAMESPACE
}


function create_namepace(){
      valida_NAMESPACE
      NS=$(kubectl get namespace $NAMESPACE --ignore-not-found);
      if [[ "$NS" ]]; then
        echo "Skipping creation of namespace $NAMESPACE - already exists";
      else
        echo "Creating namespace $NAMESPACE";
        kubectl create namespace $NAMESPACE
      fi;
}


function uninstall(){
    valida_NAME_APLICACAO 
    valida_NAMESPACE
    echo "helm  uninstall   $NAME_APLICACAO    -n  $NAMESPACE "
          helm  uninstall   $NAME_APLICACAO    -n  $NAMESPACE 
}


function add_repo_helm () {
    valida_HELM
    valida_HELM_PASS
    valida_HELM_URL
    valida_HELM_USER


  
    echo   "   helm repo add $GRUPO_HEML $HELM_URL --username $HELM_USER --password <HELM_PASS>"
               helm repo add $GRUPO_HEML $HELM_URL --username $HELM_USER --password $HELM_PASS
               helm repo list 
               helm search repo $GRUPO_HEML
}



function install_update () {
    add_repo_helm
    
    valida_NAME_APLICACAO
    valida_HELM
    valida_VALUE_YML
    valida_NAMESPACE
    create_namepace
    echo "helm  upgrade  $NAME_APLICACAO $GRUPO_HEML/$HELM   -f $VALUE_YML  --install  -n  $NAMESPACE"
          helm  upgrade  $NAME_APLICACAO $GRUPO_HEML/$HELM   -f $VALUE_YML  --install  -n  $NAMESPACE 
}



function update_imagem(){
      valida_NAMESPACE
      valida_IMAGE
      valida_VERSAO
      for i in $( kubectl  get deployments --all-namespaces --output=json | jq -r "${FILTER}" )
       do
          echo "kubectl set image deployment $i  $i=$IMAGE:$VERSAO -n $NAMESPACE "
                kubectl set image deployment $i  $i=$IMAGE:$VERSAO -n $NAMESPACE
       done
}

function rollback_imagem(){
      valida_NAMESPACE
      for i in $( kubectl  get deployments --all-namespaces --output=json | jq -r "${FILTER}" )
       do
          echo "kubectl rollout  undo  deployment $i -n $NAMESPACE "
                kubectl rollout  undo  deployment $i -n $NAMESPACE 
       done
}


function rollback_helm(){
      valida_NAMESPACE
       echo "helm rollout  $NAME_APLICACAO -n  $NAMESPACE"
        helm rollout undo $NAME_APLICACAO -n  $NAMESPACE 
       
}

function Menu(){
        #Menu de opções inicial

        echo -e "|-----------------------------------------------------------------------------------------------|"
        echo -e "                                        \033[1;34m$NOME_APLICACAO\033[0m                         "
        echo -e "|-----------------------------------------------------------------------------------------------|"
        echo -e "\033[1;34m Versão do script: \033[0m  \033[1;32m  $VERSAO_SCRIPT\033[0m                          "
        echo -e "\033[1;34m Raíz da aplicação: \033[0m  \033[1;32m  $LOCAL_RAIZ\033[0m                            "
        echo -e "\033[1;34m Branch: \033[0m  \033[1;32m  $BRANCH\033[0m                                           "
        echo -e "\033[1;33m Mantenha o arquivo de variáveis de ambiente sempre atualizado !!!\033[0m              "
        echo -e "\033[1;33m Para usar variaveis pre-configuras use ./start.sh xxx --teste !!!\033[0m              "
        echo -e "|-----------------------------------------------------------------------------------------------|"
        echo -e "|                                     Opções disponíveis:                                       |"
        echo -e "|-----------------------------------------------------------------------------------------------|"
        echo -e "| 1)   ./start.sh teste_templete     -> Teste templete helm                                     |" 
        echo -e "| 2)   ./start.sh teste_deploy       -> Teste  helm  antes do deploy                            |" 
        echo -e "| 3)   ./start.sh delete_namespace   -> deleta namesmace do projeto                             |"
        echo -e "| 4)   ./start.sh create_namepace    -> cria namespace                                          |" 
        echo -e "| 5)   ./start.sh uninstall          -> desistala projeto via helm                              |" 
        echo -e "| 6)   ./start.sh install_update     -> instala e atualiza projeto com suas variaveis           |"
        echo -e "| 7)   ./start.sh update_imagem      -> atualiza imagem                                         |"
        echo -e "| 8)   ./start.sh rollback_imagem    -> reverte  atualização para estado anterior 1 vez  somente|"
        echo -e "| 9)   ./start.sh get_all            -> traz dodos os podes                                     |" 
        echo -e "|-----------------------------------------------------------------------------------------------|"
     
}



case $1 in
0 | get_all) 
        get_all
        #exit 1
        ;;
1 | teste_templete) 
        teste_templete
        #exit 1
        ;;
2 | teste_deploy) 
        teste_deploy
        #exit 1
        ;;
3 | delete_namespace) 
        delete_namespace
        #exit 1
        ;;
4 | create_namepace) 
        create_namepace
        #exit 1
        ;;
5 | uninstall) 
        uninstall
        #exit 1
        ;;
6 | install_update) 
        install_update
        #exit 1
        ;;
7 | update_imagem) 
        update_imagem
        #exit 1
        ;;
8 | rollback_imagem ) 
        rollback_imagem 
        #exit 1
        ;;
9 | get_all ) 
        get_all 
        #exit 1
        ;;
10 | rollback_helm ) 
         rollback_helm 
        #exit 1
        ;;
        
*) 
    Menu
    #get_all
    #exit 1
    ;;
esac