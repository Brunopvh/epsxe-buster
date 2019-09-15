#!/usr/bin/env bash
#
# Autor: Bruno Chaves
# Versão: 1.9
#
# Este programa istalar o emulador ePSxe amd64 no debian 64 bits.
#
# https://www.epsxe.com/
#
# git clone https://github.com/Brunopvh/epsxe-buster.git
# cd epsxe-buster/ && chmod +x ePSXe-buster.sh && ./ePSXe-buster.sh
#


amarelo="\e[1;33m"
Amarelo="\e[1;33;5m"
vermelho="\e[1;31m"
Vermelho="\e[1;31;5m"
verde="\e[1;32m"
Verde="\e[1;32;5m"
fecha="\e[m"

clear

if [[ -z "$DESKTOP_SESSION" ]]; then 
	printf "${vermelho}Nescessário logar em modo gráfico [não root] ${fecha}\n"
	exit 1 
fi

#----------------------[ Diretórios de trabalho ]-------------------------#
# export local_trab=$(dirname $0) 
export readonly local_trab=$(dirname $(readlink -f "$0")) # Path do programa no sistema.

export codinome_sistema=$(grep '^VERSION_CODENAME' /etc/os-release | sed 's|.*=||g') # Codinome
export nome_sistema=$(grep '^ID=' /etc/os-release | sed 's|.*=||g') # Sistema

if [[ "$codinome_sistema" != "buster" ]]; then
	printf "${vermelho}Este programa e incompativel com seu sistema ${fecha}\n"
	exit 1
fi


# Diretórios
DIR_APPS_LINUX="${HOME}"/"${codinome_sistema}"
DIR_GAMES="${DIR_APPS_LINUX}/Games"
DIR_BIN="${HOME}/.local/bin"
dir_inst="${DIR_BIN}/epsxe-amd64"
dir_libs="${HOME}/.local/tmp/libs"
dir_configuracao="${HOME}/.epsxe"

mkdir -p "$dir_inst" "$DIR_GAMES" "$dir_libs" "$dir_configuracao" "${DIR_BIN}/epsxe-amd64-old" "${HOME}/.icons"

# Arquivos
arq_epsxe_zip="${DIR_GAMES}/epsxe-amd64.zip"
arq_link_libcurl3_deb9_amd64="${DIR_GAMES}/libcurl3_7_deb9_amd64.deb"
arq_link_libcurl4_amd64="${DIR_GAMES}/link_libcurl4_amd64.deb"
arq_libssl1_deb9_amd64="${DIR_GAMES}/libssl1_deb9_amd64.deb"
arq_libssl1_deb8_amd64="${DIR_GAMES}/libssl1.0_deb8_amd64.deb"
arq_bin_epsxe_amd64="${dir_inst}"/epsxe_x64
arq_configuracao="${dir_configuracao}"/epsxerc

# Links
link_down_epsxe="http://www.epsxe.com/files/ePSXe205linux_x64.zip"
link_libssl_deb9_amd64="http://ftp.us.debian.org/debian/pool/main/o/openssl1.0/libssl1.0.2_1.0.2s-1~deb9u1_amd64.deb"
link_libssl_deb8_amd64="http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u11_amd64.deb"
link_libcurl3_deb9_amd64="http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3_7.52.1-5+deb9u9_amd64.deb"
link_libcurl4_amd64="http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl4_7.65.3-1_amd64.deb"
epsxe_icon="https://raw.githubusercontent.com/brandleesee/ePSXe64Ubuntu/master/.ePSXe.svg"

# sha256sum
hash_libcurl3_7_deb9_amd64='f8c55748a97693588c83a0f272cdb1943d8efb55c4d0485e543a7d43cd4a9637'
hash_link_libcurl4_amd64='b82dd3fb8bb1df71fa0a0482df0356cd0eddf516a65f3fe3dad6be82490f1aca'
hash_libssl1_deb8_amd64='793926fb2d9bd152cdf72551d9a36c83090e0f574dbe0063de1528465bf46479'
hash_libssl1_0_2_deb9_amd64='4808b312acefe9e276ac77a23ca4a3d504685f03a7d669827dcde0b8729d7f3c'
hash_epsxe='60a99db5f400328bebe0a972caea6206d1a24d59a092248c0b5fc12e184eca99'
hash_bin_epsxe_amd64='c3f1d88d0e9075e04073237e5dfda6c851ce83af29e912f62baaf67af8a52579'

#----------------- Programas nescessários para proseguir -------------#

if [[ $USER == 'root' ]] || [[ $UID == '0' ]]; then
	echo -e "${vermelho}Usuário não pode ser o [root] saindo... $fecha"
	exit 1
fi

[[ ! -x $(which sudo) ]] && {
	echo -e "${vermelho}[sudo] não instalado saindo... $fecha"
	exit 1
}

# wget
[[ ! -x $(which wget) ]] && { 
	echo -e "${verde}Nescessário instalar wget ${fecha}"
	sudo apt  install -y wget 
	if [[ "$?" != "0" ]]; then exit 1; fi
}

# zenity
[[ ! -x $(which zenity) ]] && { 
	echo -e "${verde}Nescessário instalar zenity $fecha"
	sudo apt install -y zenity
	if [[ "$?" != "0" ]]; then exit 1; fi
}

# gdebi
[[ ! -x $(which gdebi) ]] && { 
	echo -e "${verde}Nescessário instalar gdebi $fecha"
	sudo apt install -y gdebi
	if [[ "$?" != "0" ]]; then exit 1; fi
}

#-----------------[ Ajuda ]----------------#
function usage()
{
texto_ajuda="$0 -> Executa todas as funções (instalação e configuração) - Recomendado.

$0 -c|--configure -> Configura o ePSxe (Bios, MemCards e outros) - Não recomendado.

$0 -i|--install -> Somente instala o ePSxe - Não recomendado.

$0 -h|--help -> Exibe este menu."

msgs_zenity "--info" "Ajuda" "$texto_ajuda" "900" "350"
}


#-------------------------[ Função para exibir mensagens com zenity ]----------#
function msgs_zenity()
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

#---------------------[ Função para instalar o programa ]---------------------#
function _inst_eps() 
{

# Autênticação [sudo].
while true; do
	clear
	sudo -K
	senha=$(zenity --password --title="[sudo: $USER]")
	echo $senha | sudo -S ls / 1> /dev/null 2>&1 # Verificar se a senha foi validada.
	
	[[ $? != 0 ]] && {
		zenity --error --title="Falha na autênticação" --text="Senha incorrenta" --width="310" height="200"	
		continue 
	}
	break # Senha foi validada, encerrar o loop e prosseguir.
done

# Instalar dependências.
echo $senha | sudo -S sh -c 'apt update; apt -y install libncurses5 libsdl-ttf2.0-0 unzip'

[[ $? != "0" ]] && exit 1

#----------------------------[ Baixar arquivos ]---------------#

# ePSxe.zip
if [[ $(sha256sum "$arq_epsxe_zip" | cut -d ' ' -f 1) != "$hash_epsxe" ]]; then
	echo -e "${Verde}Baixando:${fecha} $arq_epsxe_zip"
	wget "$link_down_epsxe" -O "$arq_epsxe_zip"
fi

# libssl 1.0.2 amd64 deb 9
if [[ $(sha256sum "$arq_libssl1_deb9_amd64" | cut -d ' ' -f 1) != "$hash_libssl1_0_2_deb9_amd64" ]]; then
	echo -e "${Verde}Baixando:${fecha} $arq_libssl1_deb9_amd64"
	wget "$link_libssl_deb9_amd64" -O "$arq_libssl1_deb9_amd64"	
fi

# libssl 1.0 amd64 deb 8
if [[ $(sha256sum "$arq_libssl1_deb8_amd64" | cut -d ' ' -f 1) != "$hash_libssl1_deb8_amd64" ]]; then
	echo -e "${Verde}Baixando:${fecha} $arq_libssl1_deb8_amd64"
	wget "$link_libssl_deb8_amd64" -O "$arq_libssl1_deb8_amd64"
fi

# libcurl3 amd64
if [[ $(sha256sum "$arq_link_libcurl3_deb9_amd64" | cut -d ' ' -f 1) != "$hash_libcurl3_7_deb9_amd64" ]]; then
	echo -e "${Verde}Baixando:${fecha} $arq_link_libcurl3_deb9_amd64"
	wget "$link_libcurl3_deb9_amd64" -O "$arq_link_libcurl3_deb9_amd64"
fi

#----------------------- Backup de versões anteriores se existir -------#

# Descompactar e instalar
if [[ $(sha256sum $arq_bin_epsxe_amd64 | cut -d ' ' -f 1) != "$hash_bin_epsxe_amd64" ]]; then

	cp -rvu "${dir_inst}"/* "${HOME}/.local/bin/epsxe-amd64-old"/ 1> /dev/null 2>&1
	rm -rf "${dir_inst}"/* 1> /dev/null 2>&1

	unzip "$arq_epsxe_zip" -d "$dir_inst"
	chmod +x "$arq_bin_epsxe_amd64"
	ln -sf "$arq_bin_epsxe_amd64" ~/.local/bin/epsxe64
fi

# Incluir $HOME/.local/bin  em PATH se não estiver disponível.
echo "$PATH" | egrep -q "${HOME}/.local/bin"
	[[ $? != "0" ]] && export PATH="$HOME/.local/bin:$PATH"

# libssl1.0.2 deb9 amd64
if [[ $(aptitude show libssl1.0.2 | grep '^Estado' | cut -d ' ' -f 2) != 'instalado' ]]; then
	sudo gdebi-gtk "$arq_libssl1_deb9_amd64"
fi

# libssl1.0.0 deb8 amd64
if [[ $(aptitude show libssl1.0.0 | grep '^Estado' | cut -d ' ' -f 2) != 'instalado' ]]; then
	sudo gdebi-gtk "$arq_libssl1_deb8_amd64"
fi

# Extrair libcurl3
sudo rm -rf "${dir_libs}"/* 1> /dev/null 2>&1 # Limpar o diretório de extração das libs.
sudo dpkg-deb -x "$arq_link_libcurl3_deb9_amd64" "${dir_libs}"

sudo cp -vu "${dir_libs}"/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0 '/usr/lib/x86_64-linux-gnu/'
sudo cp -vu "${dir_libs}"/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0 '/lib/x86_64-linux-gnu/libcurl.so.4.4.0'

sudo ln -sf '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0' '/usr/lib/x86_64-linux-gnu/libcurl.so.4'
sudo ln -sf '/lib/x86_64-linux-gnu/libcurl.so.4.4.0' '/lib/x86_64-linux-gnu/libcurl.so.4'

# sudo ldconfig -> Recunfigura as libs, porem o programa não ira funcionar mais.

sudo -K # Resetar senha sudo.
wget "$epsxe_icon" -O "${HOME}/.icons/ePSXe.svg"

echo "[Desktop Entry]" > "${HOME}/.local/share/applications/ePSXe.desktop"
	{
	  echo "Type=Application"
	  echo "Terminal=false"
	  echo "Exec=$arq_bin_epsxe_amd64"
	  echo "Name=ePSXe"
	  echo "Comment=Emulador PS1"
	  echo "Icon=${HOME}/.icons/ePSXe.svg"
	  echo "Categories=Game;Emulator;"
	} >> "${HOME}/.local/share/applications/ePSXe.desktop"


[[ "$?" == "0" ]] && "$arq_bin_epsxe_amd64"
	
} # Fim de _inst_eps

#-------------------------------[ Bios ]-------------------------------#
function _config_bios() {

	arq_bios=$(msgs_zenity "--file-selection" "Selecione o arquivo .bin" "*.bin" "*.BIN")
		
		# Arquivo inválido, sair do programa.
		[[ -z "$arq_bios" ]] && exit 1 
		
	sed -i "s|^BiosPath = .*|BiosPath = $arq_bios|g" "$arq_configuracao"
	grep --max-count=1 '^BiosPath' "$arq_configuracao"	
	msgs_zenity "--info" "Configuração da bios" "Bios configurada: $arq_bios" "550" "150"
	
}

#----------------------------[ MemCards ]----------------#
function _config_memcards() {

	arq_memcard1=$(msgs_zenity "--file-selection" "Selecione o memorycard 1 .mcr" "*.mcr")
		[[ -z "$arq_memcard1" ]] && exit 1
	sed -i "s|^MemcardPath1 = .*|MemcardPath1 = $arq_memcard1|g" "$arq_configuracao"
	grep --max-count=1 '^MemcardPath1' "$arq_configuracao"
	msgs_zenity "--info" "Configuração memory card 1" "Memory Card 1 configurado: $arq_memcard1" "600" "150"
	
	arq_memcard2=$(msgs_zenity "--file-selection" "Selecione o memorycard 2 .mcr" "*.mcr")
		[[ -z "$arq_memcard2" ]] && exit 1
	sed -i "s|^MemcardPath2 = .*|MemcardPath2 = $arq_memcard2|g" "$arq_configuracao"
	grep --max-count=1 '^MemcardPath2' "$arq_configuracao"
	msgs_zenity "--info" "Configuração memory card 2" "Memory Card 2 configurado: $arq_memcard2" "600" "150"

}

#-----------------------------[ Função menu configuração ]-----------#
function _configurar_epsxe()
{

while :; do

# alias pkexec='pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY'
# pkexec garted

# 1=acao, 2=titulo, 3=texto, 4=largura, 5=altura, 6=nome da coluna, 7=lista de opções
lista_opcoes="TRUE Bios FALSE MemoryCards FALSE Sair"
menu_config=$(msgs_zenity "--list" "Configurar ePSxe" "Selecione uma configuração" "430" "450" "Configurações" "$lista_opcoes")

	case "$menu_config" in
		Sair) break && exit 0;;	
		Bios) (_config_bios);;
		MemoryCards) (_config_memcards);;
	esac
	[[ "$?" != "0" ]] && break && exit 1
	
done

}

#--------------------------[ Argumentos ]-----------#
if [[ ! -z "$1" ]]; then
	if [[ "$#" > 3 ]]; then
		msgs_zenity "--error" "Erro" "Use no máximo 3 argumentos" "350" "100"
		(usage)
	fi

	while [[ "$1" ]]; do
		case "$1" in
			-c|--configure) (_configurar_epsxe);;
			-i|--install) (_inst_eps);;
			-h|--help) (usage);;
			-v|--version) grep '^# Versão:' $0 | sed 's|^# ||g';;
			*) (usage); break; exit 1;;
		
		esac
		shift
	done
elif [[ -z "$1" ]]; then
	(_inst_eps)
	(_configurar_epsxe)
fi



