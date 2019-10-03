#!/usr/bin/env bash
#
# Autor: Bruno Chaves
# Versão: 2.8
# Ultima modificação: 2019-010-03
#
# Este programa istalar o emulador ePSxe amd64 no debian 64 bits.
#
# https://www.epsxe.com/
#
# https://raw.githubusercontent.com/Brunopvh/epsxe-buster/master/ePSXe-buster.sh
# git clone https://github.com/Brunopvh/epsxe-buster.git
# cd epsxe-buster/ && chmod +x ePSXe-buster.sh && ./ePSXe-buster.sh
#
# Opicional:
# wget -qc https://raw.githubusercontent.com/Brunopvh/epsxe-buster/master/ePSXe-buster.sh -O - | bash 
#
# 


amarelo="\e[1;33m"
Amarelo="\e[1;33;5m"
vermelho="\e[1;31m"
Vermelho="\e[1;31;5m"
verde="\e[1;32m"
Verde="\e[1;32;5m"
fecha="\e[m"

clear


if [[ $USER == 'root' ]] || [[ $UID == '0' ]]; then
	echo -e "${vermelho}Usuário não pode ser o [root] saindo... $fecha"
	exit 1
fi

if [[ -z "$DESKTOP_SESSION" ]]; then 
	printf "${vermelho}Nescessário logar em modo gráfico [não root] ${fecha}\n"
	exit 1 
fi


#----------------------[ Diretórios de trabalho ]-------------------------#
# export local_trab=$(dirname $0) 
export readonly local_trab=$(dirname $(readlink -f "$0")) # Path do programa no sistema.

export codinome_sistema=$(grep '^VERSION_CODENAME' /etc/os-release | sed 's|.*=||g') # Codinome
export nome_sistema=$(grep '^ID=' /etc/os-release | sed 's|.*=||g') # Sistema

[[ "$codinome_sistema" == "buster" ]] || {
	printf "${vermelho}Este programa e incompativel com seu sistema ${fecha}\n"
	exit 1
}


# Diretórios
DIR_TEMP="/tmp/epsxe-tmp"
DIR_LIBS="/tmp/libs"
DIR_BIN="${HOME}/.local/bin"
dir_configuracao="${HOME}/.epsxe"

mkdir -p "$DIR_TEMP" "$DIR_LIBS" "$dir_configuracao" "$DIR_BIN" "${DIR_BIN}/epsxe-amd64-old" "${HOME}/.icons" ~/Downloads

# Arquivos
arq_epsxe_zip="${DIR_TEMP}"/epsxe-amd64.zip

arq_libcurl3_deb9_amd64="${DIR_TEMP}/libcurl3_7_deb9_amd64.deb"
arq__libcurl4_amd64="${DIR_TEMP}/link_libcurl4_amd64.deb"
arq_libssl1_deb9_amd64="${DIR_TEMP}/libssl1_deb9_amd64.deb"
arq_libssl1_deb8_amd64="${DIR_TEMP}/libssl1.0_deb8_amd64.deb"

arq_configuracao="${dir_configuracao}"/epsxerc

# Links
ftp_us='http://ftp.us.debian.org/debian'
security_deb='http://security.debian.org/debian-security'

link_down_epsxe="http://www.epsxe.com/files/ePSXe205linux_x64.zip"
epsxe_icon="https://raw.githubusercontent.com/brandleesee/ePSXe64Ubuntu/master/.ePSXe.svg"

link_libssl_deb9_amd64="${ftp_us}/pool/main/o/openssl1.0/libssl1.0.2_1.0.2s-1~deb9u1_amd64.deb"
link_libssl_deb8_amd64="${security_deb}/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u11_amd64.deb"
link_libcurl3_deb9_amd64="${ftp_us}/pool/main/c/curl/libcurl3_7.52.1-5+deb9u9_amd64.deb"
link_libcurl4_amd64="${ftp_us}/pool/main/c/curl/libcurl4_7.65.3-1_amd64.deb"


# sha256sum
hash_libcurl3_7_deb9_amd64='f8c55748a97693588c83a0f272cdb1943d8efb55c4d0485e543a7d43cd4a9637'
hash_link_libcurl4_amd64='b82dd3fb8bb1df71fa0a0482df0356cd0eddf516a65f3fe3dad6be82490f1aca'
hash_libssl1_deb8_amd64='793926fb2d9bd152cdf72551d9a36c83090e0f574dbe0063de1528465bf46479'
hash_libssl1_0_2_deb9_amd64='4808b312acefe9e276ac77a23ca4a3d504685f03a7d669827dcde0b8729d7f3c'
hash_epsxe='60a99db5f400328bebe0a972caea6206d1a24d59a092248c0b5fc12e184eca99'
hash_bin_epsxe_amd64='c3f1d88d0e9075e04073237e5dfda6c851ce83af29e912f62baaf67af8a52579'

#--------------------[ Função para exibir mensagens ]----------------------#
function _msgs()
{
	# $1=Cor
	# $2=Texto/Mensagem
	# $3=Texto/Mensagem
	if [[ -z "$2" ]]; then
		echo -e "${1}$2 ${fecha}"
	else
		echo -e "${1}$2 \n$3 ${fecha}"
	fi
}

# Função para verificar ou instalar os programas necessários.
function _apps_exist() 
{
	# $1 = programa a verificar ou instalar.
	local msg="Necessário instalar : "
	local msg_falha="Falha ao tentar instalar : "
	echo -e "Checando: $1"
	
	[[ -x $(which $1) ]] || { 
		echo -e "${amarelo}$msg $1 ${fecha}"
		sudo apt install -y $1
			[[ $? == 0 ]] || { echo -e "${vermelho}$msg_falha $1 ${fecha}"; exit 1; } 
	}
}

_apps_exist 'sudo' # sudo.
_apps_exist 'zenity' # zenity.
_apps_exist  'gdebi' # gdebi.
_apps_exist 'aptitude' # aptitude.

#-----------------[ Ajuda ]----------------#
function usage()
{
texto_ajuda="$0 -> Executa todas as funções (instalação e configuração) - Recomendado.

$0 -c|--configure -> Configura o ePSxe (Bios, MemCards e outros) - Não recomendado.

$0 -i|--install -> Somente instala o ePSxe - Não recomendado.

$0 -r|--remove -> Desinstala epsxe e suas dependências.

$0 -h|--help -> Exibe este menu."

_msgs_zenity "--info" "Ajuda" "$texto_ajuda" "900" "350"
}


#-------------------------[ Função para exibir mensagens com zenity ]----------#
function _msgs_zenity()
{

# (Sim Não) --question --title="Abrir" --text="Abrir ePSxe agora ?" 
#
# (Senha) --password --title="[sudo: $USER]"
#
# (Arquivo) --file-selection --title="Selecione o arquivo .bin" --file-filter="*.bin" 
#
#(Erro) --error --title="Falha na autênticação" --text="Senha incorrenta"
#
# (Lista) --list --text "Selecione uma configuração" --radiolist --column "Marcar" --column "Configurar" FALSE Bios TRUE Sair
#
# (Info) --info --title="Reiniciar" --text="Reinicie seu computador para aplicar alterações"
#
# Resolução [--width="550" height="200", --width="300" height="150" ]



case "$1" in
--question) zenity "$1" --title="$2" --text="$3" --width="$4" --height="$5";;
--info) zenity "$1" --title="$2" --text="$3" --width="$4" --height="$5";;
--error) zenity "$1" --title="$2" --text="$3" --width="$4" --height="$5";;
--file-selection) zenity "$1" --title="$2" --file-filter="$3" --file-filter="$4";;
--list) zenity "$1" --title="$2" --text="$3" --width="$4" --height="$5" --radiolist --column "Marcar" --column "$6" $7;; 

esac

}

#==================================== PATH ===================================#
if [[ ! $(echo $PATH | grep "$HOME/.local/bin") ]]; then
	[[ $(grep "^export PATH=$HOME/.local/bin:$PATH" "${HOME}"/.bashrc) ]] || { 
	echo "export PATH=$HOME/.local/bin:$PATH" >> "${HOME}"/.bashrc 
	} 
fi

#---------------------[ Função para instalar o programa ]---------------------#
function _inst_eps() 
{

# Instalar dependências.
_msgs "$verde" "==> ${fecha}Instalando: libncurses5 libsdl-ttf2.0-0 unzip"
sudo sh -c 'apt update; apt -y install libncurses5 libsdl-ttf2.0-0 unzip'

[[ $? == "0" ]] || exit 1

#----------------------------[ Baixar arquivos ]---------------#

# ePSxe.zip
[[ $(sha256sum "$arq_epsxe_zip" | cut -d ' ' -f 1) == "$hash_epsxe" ]] || {
	echo -e "${Verde}Baixando:${fecha} $arq_epsxe_zip"
	wget "$link_down_epsxe" -O "$arq_epsxe_zip"
}

# libssl 1.0.2 amd64 deb 9
[[ $(sha256sum "$arq_libssl1_deb9_amd64" | cut -d ' ' -f 1) == "$hash_libssl1_0_2_deb9_amd64" ]] || {
	echo -e "${Verde}Baixando:${fecha} $arq_libssl1_deb9_amd64"
	wget "$link_libssl_deb9_amd64" -O "$arq_libssl1_deb9_amd64"	
}

# libssl 1.0 amd64 deb 8
[[ $(sha256sum "$arq_libssl1_deb8_amd64" | cut -d ' ' -f 1) == "$hash_libssl1_deb8_amd64" ]] || {
	echo -e "${Verde}Baixando:${fecha} $arq_libssl1_deb8_amd64"
	wget "$link_libssl_deb8_amd64" -O "$arq_libssl1_deb8_amd64"
}

# libcurl3 amd64
[[ $(sha256sum "$arq_libcurl3_deb9_amd64" | cut -d ' ' -f 1) == "$hash_libcurl3_7_deb9_amd64" ]] || {
	echo -e "${Verde}Baixando:${fecha} $arq_libcurl3_deb9_amd64"
	wget "$link_libcurl3_deb9_amd64" -O "$arq_libcurl3_deb9_amd64"
}

#================================== Copia dos downloads =================================#
_msgs "$verde" "==> ${fecha}Fazendo backup de $DIR_TEMP em ~/Downloads"
cp -vu "$DIR_TEMP"/* ~/Downloads 1> /dev/null 2>&1
sleep 3

#============================== Descompactar e instalar =================================#
[[ $(sha256sum "$HOME"/.local/bin/epsxe-amd64/epsxe_x64 | cut -d ' ' -f 1) == "$hash_bin_epsxe_amd64" ]] || {

	# Backup da versão anterior.
	cp -ru "$HOME"/.local/bin/epsxe-amd64/* "${HOME}"/.local/bin/epsxe-amd64-old/ 1> /dev/null 2>&1
	rm -rf "$HOME"/.local/bin/epsxe-amd64/* 1> /dev/null 2>&1

	_msgs "$verde" "==> ${fecha}Instalando: $HOME/.local/bin/epsxe-amd64/epsxe_x64"
	unzip "$arq_epsxe_zip" -d "$HOME"/.local/bin/epsxe-amd64
	chmod -R +x "$HOME"/.local/bin/epsxe-amd64
	ln -sf "$HOME"/.local/bin/epsxe-amd64/epsxe_x64 ~/.local/bin/epsxe
}

# libssl1.0.2 deb9 amd64
[[ $(aptitude show libssl1.0.2 | grep '^Estado' | cut -d ' ' -f 2) == 'instalado' ]] || { 
	_msgs "$verde" "==> ${fecha}$arq_libssl1_deb9_amd64"; sudo gdebi-gtk "$arq_libssl1_deb9_amd64" 
}

# libssl1.0.0 deb8 amd64
[[ $(aptitude show libssl1.0.0 | grep '^Estado' | cut -d ' ' -f 2) == 'instalado' ]] || {
	_msgs "$verde" "==> ${fecha}$arq_libssl1_deb8_amd64"; sudo gdebi-gtk "$arq_libssl1_deb8_amd64"
}

# Extrair libcurl3
sudo rm -rf "$DIR_LIBS"/* 1> /dev/null 2>&1 # Limpar o diretório de extração.
sudo dpkg-deb -x "$arq_libcurl3_deb9_amd64" "$DIR_LIBS"

sudo cp -vu "${DIR_LIBS}"/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0 '/usr/lib/x86_64-linux-gnu/'
sudo cp -vu "${DIR_LIBS}"/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0 '/lib/x86_64-linux-gnu/libcurl.so.4.4.0'

sudo ln -sf '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0' '/usr/lib/x86_64-linux-gnu/libcurl.so.4'
sudo ln -sf '/lib/x86_64-linux-gnu/libcurl.so.4.4.0' '/lib/x86_64-linux-gnu/libcurl.so.4'

wget "$epsxe_icon" -O "${HOME}/.icons/ePSXe.svg" # Icone.

echo "[Desktop Entry]" > "${HOME}/.local/share/applications/ePSXe.desktop"
	{
	  echo "Type=Application"
	  echo "Terminal=false"
	  echo "Exec=$HOME/.local/bin/epsxe-amd64/epsxe_x64"
	  echo "Name=ePSXe"
	  echo "Comment=Emulador PS1"
	  echo "Icon=${HOME}/.icons/ePSXe.svg"
	  echo "Categories=Game;Emulator;"
	} >> "${HOME}/.local/share/applications/ePSXe.desktop"


if [[ "$?" == "0" ]]; then 
	
	cp -u "${HOME}/.local/share/applications/ePSXe.desktop" ~/Desktop 1>/dev/null 2>&1
	cp -u "${HOME}/.local/share/applications/ePSXe.desktop" ~/'Área de trabalho' 1>/dev/null 2>&1
	"$HOME"/.local/bin/epsxe-amd64/epsxe_x64 # Abrir o epsxe.

fi
} # Fim de _inst_eps


#---------------------------[ Função para desinstalar o programa ]--------------#
function _remove_epsxe()
{

remover=$(_msgs_zenity "--question" "Desinstalar" "Deseja remover ePSxe ?" "400" "150")

	if [[ $? == 0 ]]; then
		
		sudo rm '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0' 1> /dev/null 2>&1
		sudo rm '/lib/x86_64-linux-gnu/libcurl.so.4.4.0' 1> /dev/null 2>&1
		
		[[ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0 ]] && {
			sudo ln -sf /usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0 '/usr/lib/x86_64-linux-gnu/libcurl.so.4' 
		}
		
		[[ -f /lib/x86_64-linux-gnu/libcurl.so.4.5.0 ]] && {
			sudo ln -sf /lib/x86_64-linux-gnu/libcurl.so.4.5.0 '/lib/x86_64-linux-gnu/libcurl.so.4'
		}
		
		sudo aptitude remove libssl1.0.0
		sudo aptitude remove libssl1.0.2
		sudo ldconfig # Reconfigurar as libs.
		
		rm -rf ~/.local/bin/epsxe-amd64 1> /dev/null 2>&1	
		rm -rf ~/.local/bin/epsxe 1> /dev/null 2>&1	
		rm -rf ~/.local/share/applications/ePSXe.desktop 1> /dev/null 2>&1
		rm -rf ~/.icons/ePSXe.svg 1> /dev/null 2>&1
		
	_msgs_zenity "--info" "Operação finalizada" "ePSXe desinstalado" "450" "150"
	fi

}


#-------------------------------[ Configuração da  Bios ]-------------------------------#
function _config_bios() {

	arq_bios=$(_msgs_zenity "--file-selection" "Selecione o arquivo .bin" "*.bin" "*.BIN")
		
		# Arquivo inválido, sair do programa.
		[[ -z "$arq_bios" ]] && exit 1 
		
	sed -i "s|^BiosPath = .*|BiosPath = $arq_bios|g" "$arq_configuracao"
	grep --max-count=1 '^BiosPath' "$arq_configuracao"	
	_msgs_zenity "--info" "Configuração da bios" "Bios configurada: $arq_bios" "550" "150"
	
}

#----------------------------[ Configuração MemCards ]----------------#
function _config_memcards() {

	arq_memcard1=$(_msgs_zenity "--file-selection" "Selecione o memorycard 1 .mcr" "*.mcr")

		[[ -z "$arq_memcard1" ]] && exit 1

	sed -i "s|^MemcardPath1 = .*|MemcardPath1 = $arq_memcard1|g" "$arq_configuracao"
	grep --max-count=1 '^MemcardPath1' "$arq_configuracao"
	_msgs_zenity "--info" "Configuração memory card 1" "Memory Card 1 configurado: $arq_memcard1" "600" "150"
	
	arq_memcard2=$(_msgs_zenity "--file-selection" "Selecione o memorycard 2 .mcr" "*.mcr")

		[[ -z "$arq_memcard2" ]] && exit 1

	sed -i "s|^MemcardPath2 = .*|MemcardPath2 = $arq_memcard2|g" "$arq_configuracao"
	grep --max-count=1 '^MemcardPath2' "$arq_configuracao"
	_msgs_zenity "--info" "Configuração memory card 2" "Memory Card 2 configurado: $arq_memcard2" "600" "150"

}

#-----------------------------[ Função menu configuração ]-----------#
function _configurar_epsxe()
{

while :; do

# 1=acao, 2=titulo, 3=texto, 4=largura, 5=altura, 6=nome da coluna, 7=lista de opções
lista_opcoes="TRUE Bios FALSE MemoryCards FALSE Sair"
menu_config=$(_msgs_zenity "--list" "Configurar ePSxe" "Selecione uma configuração" "430" "450" "Configurações" "$lista_opcoes")

	case "$menu_config" in
		Sair) break && exit 0;;	
		Bios) (_config_bios);;
		MemoryCards) (_config_memcards);;
	esac
	[[ "$?" != "0" ]] && break && exit 1
	
done

}

#--------------------------------------[ Argumentos ]----------------------#
if [[ ! -z "$1" ]]; then
	if [[ "$#" > 3 ]]; then
		_msgs_zenity "--error" "Erro" "Use no máximo 3 argumentos" "350" "100"
		(usage)
	fi

	while [[ "$1" ]]; do
		case "$1" in
			-c|--configure) (_configurar_epsxe);;
			-i|--install) (_inst_eps);;
			-h|--help) (usage);;
			-r|--remove) (_remove_epsxe);;
			-v|--version) grep '^# Versão:' $0 | sed 's|^# ||g';;
			*) (usage); break; exit 1;;
		
		esac
		shift
	done
elif [[ -z "$1" ]]; then
	(_inst_eps)
	(_configurar_epsxe)
fi

_msgs "$verde" "==> ${fecha}Limpando cache"
sudo rm -rf "$DIR_LIBS" 1> /dev/null 2>&1
sudo rm -rf "$DIR_TEMP"

#sudo -K # Resetar senha sudo.
