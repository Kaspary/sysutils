#!/bin/bash

declare heroku_key="b04225cb-e8f1-4bbe-be04-0ac68d996849"
declare projects_path="/home/$USER/Documentos/Projects/SaveMoney/"
declare -a projects=([1]="api" [2]="frontend" [3]="telegram")
declare -a alias_repositories=([1]="api" [2]="web" [3]="bot")

echo "Escolha o projeto para deploy"

for p in "${!projects[@]}"; do 
    echo "$p - ${projects[$p]}"; 
done

echo "0 - SAIR"

read project

if [ -z ${projects[$project]} ]
then
    exit
fi

echo "Você esta prestes a realizar o deploy do projeto \"${projects[$project]}\""
echo "Por favor, confirme esta ação (Y/n):"

read confirm

if [ $confirm != 'y' ] && [ $confirm != 'Y' ]
then
    echo "Deploy cancelado!"
    exit
fi

echo "Iniciando o deploy da aplicação ${projects[$project]}..."

cd $projects_path${projects[$project]}

git push https://heroku:$heroku_key@git.heroku.com/${alias_repositories[$project]}-save-money.git HEAD