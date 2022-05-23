# Config global git acount and password cache of git to 1 hour

read -p 'Name: ' name;
read -p 'E-mail: ' email;
read -p 'Password cache in minutes [30]: ' cache;
cache=${cache:-30};

git config --global user.name "${name}";
git config --global user.email "${email}";
git config --global credential.helper "cache --timeout=$((cache*60))";
