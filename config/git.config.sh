# Config global git acount and password cache of git to 1 hour

read -p 'Name: ' name;
read -p 'E-mail: ' email;
read -p 'Password cache [30min]: ' cache;
cache=${cache:-1800}

git config --global user.name $name;
git config --global user.email $email;
git config --global credential.helper "cache --timeout=${cache}";
