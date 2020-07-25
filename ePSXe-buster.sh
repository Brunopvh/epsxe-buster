#!/usr/bin/env bash
#
# Autor: Bruno Chaves
__version__='2020-07-25'
# Ultima modificação: 2019-010-03
#
# Este programa istala o emulador ePSxe versão 64 bits no debian 10.
#
# https://www.epsxe.com/
#
# https://raw.githubusercontent.com/Brunopvh/epsxe-buster/master/ePSXe-buster.sh
# git clone https://github.com/Brunopvh/epsxe-buster.git
# cd epsxe-buster/ && chmod +x ePSXe-buster.sh && ./ePSXe-buster.sh
#
# Exucuçã via wget:
# wget -qc https://raw.githubusercontent.com/Brunopvh/epsxe-buster/master/ePSXe-buster.sh -O - | bash 
#
# 

CRed="\e[0;31m"
CSRed='\e[1;31m'
CGreen="\e[0;32m"
CYellow="\e[0;33m"
CSYellow="\e[1;33m"
CReset="\e[m"

_msg()
{
	echo '-----------------------------------------------'
	echo -e " $@"
	echo '-----------------------------------------------'
}

_yellow()
{
	echo -e "[${CYellow}+${CReset}] $@"
}

_red()
{
	echo -e "[${CRed}!${CReset}] $@"
}

_syellow()
{
	echo -e "${CSYellow}$@${CReset}"
}

_sred()
{
	echo -e "${CSRed}$@${CReset}"
}

if [[ $(id -u) == '0' ]]; then
	_red 'Não execute como root, saindo...'
	exit 1
fi

if [[ -z "$DISPLAY" ]]; then 
	_red 'Nescessário logar em sessão gráfica para prosseguir, saindo...'
	exit 1 
fi


# Path do programa no disco.
export readonly dir_root=$(dirname $(readlink -f "$0"))

# Nome do sistema
export os_name=$(grep '^ID=' /etc/os-release | sed 's|.*=||g')

case "$os_name" in
	debian) ;;
	ubuntu|linuxmint) ;;
	*) _red 'Seu sistema não é suportado por este programa.'; exit 1;;
esac

# Codinome
export os_codename=$(grep '^VERSION_CODENAME' /etc/os-release | sed 's|.*=||g') 
export os_version_id=$(grep 'VERSION_ID=' /etc/os-release | sed 's/.*=//g;s/"//g' | cut -c -2)

case "$os_version_id" in
	10|18|19) ;; # Debian 10/Ubuntu 18.04/LinuxMint/19.X
	*) _red 'Seu sistema não é suportado - suporte apenas para (Debian 10 | Ubuntu 18.04 | LinuxMint 19.X)'; exit 1;;
esac

_msg "Sistema: $os_name $os_version_id"


#DIR_TEMP=$(mktemp -d)
DIR_TEMP="/tmp/epsxe_$USER";                                     mkdir -p "$DIR_TEMP"
DIR_DOWNLOADS="$HOME/.cache/epsxe-buster/downloads";             mkdir -p "$DIR_DOWNLOADS"
DIR_BIN="${HOME}/.local/bin";                                    mkdir -p "$DIR_BIN" 
DirUnpack="$DIR_TEMP/unpack";                                    mkdir -p "$DirUnpack"
destinationConfigDir="${HOME}/.epsxe";                           mkdir -p "$destinationConfigDir" 
destinationBackupDir="$HOME"/ePSXe_backups/$(date "+%F-%T-%Z");  mkdir -p "$destinationBackupDir"

mkdir -p "${HOME}/.icons" 

# Urls de downloads do icone e do arquivo de instalação .zip
UrlEpsxeZip="http://www.epsxe.com/files/ePSXe205linux_x64.zip"
URLepsxeIcon="https://raw.githubusercontent.com/brandleesee/ePSXe64Ubuntu/master/.ePSXe.svg"

# Urls dos pacotes .deb queridos pelo epsxe. 
URLlibsslDeb9='http://ftp.us.debian.org/debian/pool/main/o/openssl1.0/libssl1.0.2_1.0.2u-1~deb9u1_amd64.deb'
URLlibsslDeb8="http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u12_amd64.deb"
URLlibcurl3Deb9='http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl3_7.52.1-5+deb9u10_amd64.deb'
URLlibcurl4Debian="http://ftp.us.debian.org/debian/pool/main/c/curl/libcurl4_7.65.3-1_amd64.deb"
URLlibcurl3Ubuntu='http://archive.ubuntu.com/ubuntu/pool/main/c/curl3/libcurl3_7.58.0-2ubuntu2_amd64.deb'
URLecmDeb='http://ftp.us.debian.org/debian/pool/main/c/cmdpack/ecm_1.03-1+b1_amd64.deb'

# Destino de cada arquivo .deb baixado
FileLIBcurl3Debian9="${DIR_DOWNLOADS}/$(basename $URLlibcurl3Deb9)"
FileLIBcurl4Debian="${DIR_DOWNLOADS}/$(basename $URLlibcurl4Debian)"
FileLIBssl1Debian9="${DIR_DOWNLOADS}/$(basename $URLlibsslDeb9)"
FileLIBssl1Debian8="${DIR_DOWNLOADS}/$(basename $URLlibsslDeb8)"
FileLIBcurl3Ubuntu="${DIR_DOWNLOADS}/$(basename $URLlibcurl3Ubuntu)"
FileEcmDebian="${DIR_DOWNLOADS}/$(basename $URLecmDeb)"

# Arquivos relacionados ao epsxe
epsxeZipFile="$DIR_DOWNLOADS"/epsxe-amd64.zip
epsxeConfigFile="${destinationConfigDir}"/epsxerc
destinationLinkEpsxe="$DIR_BIN/epsxe"

# hash dos arquivos
hashFileLIBcurl3Debian9='e8327c7c91b610141116fd4a5c67f8d13fba8024f18638f0196216d66098e6a7'
hashFileLIBcurl4Debian='b82dd3fb8bb1df71fa0a0482df0356cd0eddf516a65f3fe3dad6be82490f1aca'
hashFileLIBssl1Debian8='c91f6f016d0b02392cbd2ca4b04ff7404fbe54a7f4ca514dc1c499e3f5da23a2'
hashFileLIBssl1Debian9='a208d375182830bdcad42c0b92154d55233d7cfe4a7543015d6a99c5086416c0'
hashFileEcmDebian='ebc021c4579f55cdbe5b2335fca90507146a6982b2609781e27cd3436e298d53'
hashepsxeZipFile='60a99db5f400328bebe0a972caea6206d1a24d59a092248c0b5fc12e184eca99'
hash_bin_epsxe_amd64='c3f1d88d0e9075e04073237e5dfda6c851ce83af29e912f62baaf67af8a52579'

is_executable() 
{
	if [[ -x $(command -v "$1" 2> /dev/null) ]]; then
		return 0
	else
		return 1
	fi
}

_check_cli_requeriments()
{
	if ! is_executable sudo; then
		_red "Instale o pacote (sudo) para prosseguir"
		return 1
	fi

	RequerimentsCli=(
			zenity
			gdebi
			aptitude
			wget
			unzip
		)

	for X in "${RequerimentsCli[@]}"; do
		if ! is_executable "$X"; then
			_yellow "Instalando: $X"
			sudo apt install -y "$X" 
		fi
	done
}

#-----------------[ Ajuda ]----------------#
usage()
{
cat << EOF

   Use: $(readlink -f "$0") --install|--configure|--remove|--help

     -c|--configure    Configura o ePSxe (Bios, MemCards e outros)  
     -i|--install      Somente instala o ePSxe - Não recomendado.
     -r|--remove       Desinstala epsxe e suas dependências.
     -h|--help         Exibe este menu."

EOF
}


#-------------------------[ Função para exibir mensagens com zenity ]----------#
_msg_zenity()
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

#======================================================================#
# PATH
#======================================================================#
# Inserir ~/.local/bin em PATH se ainda não estiver disponível.
if ! echo "$PATH" | grep "$HOME/.local/bin" 1> /dev/null; then
	PATH="$HOME/.local/bin:$PATH"
fi

[[ -f "$HOME/.bashrc" ]] || touch "$HOME/.bashrc"

# Configuar o arquivo ~/.bashrc para inserir o diretório ~/.local/bin
# na variável de ambiente PATH.
if ! grep "^export PATH=.*$HOME/.local/bin" "$HOME"/.bashrc 1> /dev/null; then
	_yellow "Configurando PATH no arquivo ~/.bashrc"
	echo "export PATH=$HOME/.local/bin:$PATH" >> "${HOME}"/.bashrc  
fi

__download__()
{
	# Baixar os arquivos com wget
	# $1 = URL
	# $1 = Arquivo
	local URL="$1"
	local FILE="$2"

	if [[ -f "$FILE" ]]; then
		_yellow "Arquivo encontrado: $FILE"
		return 0
	fi

	_yellow "Baixando: $URL"
	printf "%s" "[>] Destino: $FILE "
	cd "$DIR_DOWNLOADS"
	wget -q "$URL" -O "$FILE"

	if [[ "$?" == '0' ]]; then
		_syellow "OK"
		return 0
	else
		_sred "(__download__) falha"
		return 1
	fi
}

__shasum__()
{
	# Esta função compara a hash de um arquivo local no disco com
	# uma hash informada no parametro "$2" (hash original). 
	#   Ou seja "$1" é o arquivo local e "$2" é uma hash

	if [[ ! -f "$1" ]]; then
		_red "(__shasum__) arquivo inválido: $1"
		return 1
	fi

	if [[ -z "$2" ]]; then
		_red "(__shasum__) use: __shasum__ <arquivo> <hash>"
		return 1
	fi

	_yellow "Gerando hash do arquivo: $1"
	local hash_file=$(sha256sum "$1" | cut -d ' ' -f 1)
	
	echo -ne "[>] Comparando valores "
	if [[ "$hash_file" == "$2" ]]; then
		echo -e "${CYellow}OK${CReset}"
		return 0
	else
		_sred 'FALHA'
		rm -rf "$1"
		_red "(__shasum__) o arquivo inseguro foi removido: $1"
		return 1
	fi
}


__rmdir__()
{
	# Função para remover diretórios e arquivos, inclusive os arquivos é diretórios
	# que o usuário não tem permissão de escrita, para isso será usado o "sudo".
	#
	# Use:
	#     __rmdir__ <diretório> ou
	#     __rmdir__ <arquivo>
	[[ -z $1 ]] && return 1

	# Se o arquivo/diretório não for removido por falta de privilegio 'root'
	# A função __sudo__ irá remover o arquivo/diretório.
	while [[ $1 ]]; do
		printf "[>] Removendo: $1 "
		if rm -rf "$1" 2> /dev/null || sudo rm -rf "$1"; then
			_syellow "OK"
		else
			_sred "FALHA"
		fi
		shift
	done
}

_clean_temp_dirs()
{
	cd "$DIR_TEMP"
	cd "$DirUnpack" && __rmdir__ $(ls) 
}

_unpack()
{
	# Obrigatório informar um arquivo no argumento $1.
	if [[ ! -f "$1" ]]; then
		_red "(_unpack) nenhum arquivo informado como argumento"
		return 1
	fi

	# Destino para descompressão.
	if [[ -d "$2" ]]; then 
		DirUnpack="$2"
	elif [[ -d "$DirUnpack" ]]; then
		DirUnpack="$DirUnpack"
	else
		_red "(_unpack): nenhum diretório para descompressão foi informado"
		return 1
	fi 
	
	cd "$DirUnpack"
	path_file="$1"

	# Detectar a extensão do arquivo.
	if [[ "${path_file: -6}" == 'tar.gz' ]]; then    # tar.gz - 6 ultimos caracteres.
		type_file='tar.gz'
	elif [[ "${path_file: -7}" == 'tar.bz2' ]]; then # tar.bz2 - 7 ultimos carcteres.
		type_file='tar.bz2'
	elif [[ "${path_file: -6}" == 'tar.xz' ]]; then  # tar.xz
		type_file='tar.xz'
	elif [[ "${path_file: -4}" == '.zip' ]]; then    # .zip
		type_file='zip'
	elif [[ "${path_file: -4}" == '.deb' ]]; then    # .deb
		type_file='deb'
	else
		_red "(_unpack) arquivo não suportado: $path_file"
		__rmdir__ "$path_file"
		return 1
	fi

	printf "%s\n" "[>] Descomprimindo: $path_file "
	printf "%s" "[>] Destino: $DirUnpack "
	
	# Descomprimir.	
	case "$type_file" in
		'tar.gz') tar -zxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1;;
		'tar.bz2') tar -jxvf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1;;
		'tar.xz') tar -Jxf "$path_file" -C "$DirUnpack" 1> /dev/null 2>&1;;
		zip) unzip "$path_file" -d "$DirUnpack" 1> /dev/null 2>&1;;
		deb) ar -x "$path_file" 1> /dev/null;;
		*) return 1;;
	esac

	if [[ "$?" == '0' ]]; then
		_syellow "OK"
		return 0
	else
		_sred "FALHA"
		_red "(_unpack) erro: $path_file"
		__rmdir__ "$path_file"
		return 1
	fi
}

_config_ubuntu_libs()
{
	_msg "Instalando: libncurses5 libsdl-ttf2.0-0 libssl1.0.0 ecm"
	sudo apt install -y libncurses5 libsdl-ttf2.0-0 libssl1.0.0 ecm libssh2-1 # libssh2-1-dev
	
	__download__ "$URLlibcurl3Deb9" "$FileLIBcurl3Debian9" || return 1     # libcurl3 amd64
	__download__ "$URLlibsslDeb9" "$FileLIBssl1Debian9" || return 1	       # libssl 1.0.2 amd64 deb 9
	__shasum__ "$FileLIBcurl3Debian9" "$hashFileLIBcurl3Debian9" || return 1
	__shasum__ "$FileLIBssl1Debian9" "$hashFileLIBssl1Debian9" || return 1

	# instalar o pacote (libssl1.0.2 deb9 amd64) - com o gdebi.
	if [[ $(aptitude show libssl1.0.2 | egrep -m 1 '(Estado|State)' | cut -d ' ' -f 2) != 'instalado' ]]; then
		_msg "Instalando: $FileLIBssl1Debian9"
		sudo gdebi "$FileLIBssl1Debian9" 
	fi
	
	_clean_temp_dirs
	
	# Extrair libcurl3
	# sudo dpkg-deb -x "$FileLIBcurl3Debian9" "$DirUnpack"
	_unpack "$FileLIBcurl3Debian9" || return 1
	_unpack "$DirUnpack"/data.tar.xz || return 1
	cd "$DirUnpack"/usr/lib/x86_64-linux-gnu

	# Para reverter essa configuração caso o 'curl' apresentar erros, use o seguinte comando
	# sudo ln -sf /lib/x86_64-linux-gnu/libcurl.so.4.5.0 /lib/x86_64-linux-gnu/libcurl.so.4 && sudo ldconfig
	#
	_msg "Configurando: /usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0"
	sudo cp -v -n libcurl.so.4.4.0 '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0'
	sudo ln -sf '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0' '/usr/lib/x86_64-linux-gnu/libcurl.so.4'
}

_config_debian_libs()
{
	local DebianDestinationLibs='/lib/x86_64-linux-gnu/'
	#local DebianDestinationLibs="$HOME/.local/lib"
	mkdir -p "$DebianDestinationLibs"
	
	__download__ "$URLlibsslDeb9" "$FileLIBssl1Debian9" || return 1	     # libssl 1.0.2 amd64 deb 9
	__download__ "$URLlibsslDeb8" "$FileLIBssl1Debian8" || return 1      # libssl 1.0 amd64 deb 8
	__download__ "$URLlibcurl3Deb9" "$FileLIBcurl3Debian9" || return 1   # libcurl3 amd64
	__download__ "$URLecmDeb" "$FileEcmDebian" || return 1               # ecm.deb

	__shasum__ "$FileLIBssl1Debian9" "$hashFileLIBssl1Debian9" || return 1
	__shasum__ "$FileLIBssl1Debian8" "$hashFileLIBssl1Debian8" || return 1
	__shasum__ "$FileLIBcurl3Debian9" "$hashFileLIBcurl3Debian9" || return 1
	__shasum__ "$FileEcmDebian" "$hashFileEcmDebian" || return 1

	# libncurses5
	_msg "Instalando: libncurses5 multiarch-support libsdl-ttf2.0-0"
	sudo apt install -y libncurses5 multiarch-support libsdl-ttf2.0-0

	# libssl1.0.2 deb9 amd64 - instalar o pacote com o gdebi
	if [[ $(aptitude show libssl1.0.2 | egrep -m 1 '(Estado|State)' | cut -d ' ' -f 2) != 'instalado' ]]; then
		_msg "Instalando: $FileLIBssl1Debian9"
		sudo gdebi "$FileLIBssl1Debian9" 
	fi

	# libssl1.0.0 deb8 amd64
	if [[ $(aptitude show libssl1.0.0 | egrep -m 1 '(Estado|State)' | cut -d ' ' -f 2) != 'instalado' ]]; then
		_msg "Instalando: $FileLIBssl1Debian8"
		sudo gdebi "$FileLIBssl1Debian8"
	fi

	# ecm.deb
	if [[ $(aptitude show ecm | egrep -m 1 '(Estado|State)' | cut -d ' ' -f 2) != 'instalado' ]]; then
		_msg "Instalando: $FileEcmDebian"
		sudo gdebi "$FileEcmDebian"
	fi

	# Extrair libcurl3
	_unpack "$FileLIBcurl3Debian9" || return 1
	_unpack "$DirUnpack"/data.tar.xz || return 1
	cd "$DirUnpack"/usr/lib/x86_64-linux-gnu

	# Para reverter essa configuração caso o 'curl' apresentar erros, use o seguinte comando
	# sudo ln -sf /lib/x86_64-linux-gnu/libcurl.so.4.5.0 /lib/x86_64-linux-gnu/libcurl.so.4 && sudo ldconfig
	#
	_msg "Configurando: $DebianDestinationLibs/libcurl.so.4.4.0"
	sudo cp -v -n 'libcurl.so.3' "$DebianDestinationLibs/libcurl.so.3"
	sudo cp -v -n 'libcurl.so.4' "$DebianDestinationLibs/libcurl.so.4"
	sudo cp -v -n 'libcurl.so.4.4.0' "$DebianDestinationLibs/libcurl.so.4.4.0"
	sudo ln -sf "$DebianDestinationLibs/libcurl.so.4.4.0" "$DebianDestinationLibs/libcurl.so.4"
}

# Instalar o programa
_install_epsxe() 
{
	__download__ "$URLepsxeIcon" "${HOME}/.icons/ePSXe.svg" # Icone.
	__download__ "$UrlEpsxeZip" "$epsxeZipFile"             # Arquivo de instalação .zip
	__shasum__ "$epsxeZipFile" "$hashepsxeZipFile" || return 1

	# Backup da versão anterior.
	if [[ -d "$DIR_BIN/epsxe-amd64" ]]; then
		_yellow "Fazendo backup da versão instalada anteriormente"
		cp -R -u "$DIR_BIN"/epsxe-amd64 "$destinationBackupDir" 1> /dev/null
		rm -rf "$DIR_BIN"/epsxe-amd64
	fi

	[[ ! -d "$DIR_BIN/epsxe-amd64" ]] && mkdir "$DIR_BIN/epsxe-amd64"

	_unpack "$epsxeZipFile" || return 1
	cd "$DirUnpack"
	cp -R -u epsxe_x64 "$DIR_BIN"/epsxe-amd64/
	cp -R -u docs "$DIR_BIN"/epsxe-amd64/

	echo '#!/bin/sh' > "$destinationLinkEpsxe"
	{
		echo ' '
		echo "cd $DIR_BIN/epsxe-amd64"
		echo './epsxe_x64 "$@"'
	} >> "$destinationLinkEpsxe"

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

	chmod -R +x "$DIR_BIN"/epsxe-amd64
	chmod +x "$destinationLinkEpsxe"

	if is_executable "$destinationLinkEpsxe"; then 
		cp -u "${HOME}/.local/share/applications/ePSXe.desktop" ~/Desktop/ 1> /dev/null 2>&1
		cp -u "${HOME}/.local/share/applications/ePSXe.desktop" ~/'Área de trabalho'/ 1> /dev/null 2>&1
	fi
}

#---------------------------[ Função para desinstalar o programa ]--------------#
_remove_epsxe()
{

remover=$(_msg_zenity "--question" "Desinstalar" "Deseja remover ePSxe ?" "400" "150")

	if [[ $? == 0 ]]; then
		sudo rm '/usr/lib/x86_64-linux-gnu/libcurl.so.4.4.0' 1> /dev/null 2>&1
		sudo rm '/lib/x86_64-linux-gnu/libcurl.so.4.4.0' 1> /dev/null 2>&1
		
		if [[ -f /usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0 ]]; then
			_msg "Configurando (libcurl.so.4.5): /usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0"
			sudo ln -sf /usr/lib/x86_64-linux-gnu/libcurl.so.4.5.0 '/usr/lib/x86_64-linux-gnu/libcurl.so.4' 
		fi
		
		_msg "Removendo: libssl1.0.2"; sudo aptitude remove libssl1.0.2
		#sudo aptitude remove libssl1.0.0
		_msg "Executando: sudo ldconfig"; sudo ldconfig # Reconfigurar as libs.
		
		rm -rf ~/.local/bin/epsxe-amd64 1> /dev/null 2>&1	
		rm -rf ~/.local/bin/epsxe 1> /dev/null 2>&1	
		rm -rf ~/.local/share/applications/ePSXe.desktop 1> /dev/null 2>&1
		rm -rf ~/.icons/ePSXe.svg 1> /dev/null 2>&1
		
		_msg_zenity "--info" "Operação finalizada" "ePSXe desinstalado" "450" "150"
	fi

}


#-------------------------------[ Configuração da  Bios ]-------------------------------#
_config_bios() {

	epsxeBiosPath=$(_msg_zenity "--file-selection" "Selecione o arquivo .bin" "*.bin" "*.BIN")
		
	# Arquivo inválido, sair do programa.
	[[ ! -f "$epsxeBiosPath" ]] && return 1 
		
	sed -i "s|^BiosPath = .*|BiosPath = $epsxeBiosPath|g" "$epsxeConfigFile"
	grep --max-count=1 '^BiosPath' "$epsxeConfigFile"	
	_msg_zenity "--info" "Configuração da bios" "Bios configurada: $epsxeBiosPath" "550" "150"
	
}

#----------------------------[ Configuração MemCards ]----------------#
_config_memcards() {

	epsxeMemcard1Path=$(_msg_zenity "--file-selection" "Selecione o memorycard 1 .mcr" "*.mcr")

	[[ ! -f "$epsxeMemcard1Path" ]] && return 1

	sed -i "s|^MemcardPath1 = .*|MemcardPath1 = $epsxeMemcard1Path|g" "$epsxeConfigFile"
	grep --max-count=1 '^MemcardPath1' "$epsxeConfigFile"
	_msg_zenity "--info" "Configuração memory card 1" "Memory Card 1 configurado: $epsxeMemcard1Path" "600" "150"
	
	epsxeMemcard2Path=$(_msg_zenity "--file-selection" "Selecione o memorycard 2 .mcr" "*.mcr")

	[[ ! -f "$epsxeMemcard2Path" ]] && return 1

	sed -i "s|^MemcardPath2 = .*|MemcardPath2 = $epsxeMemcard2Path|g" "$epsxeConfigFile"
	grep --max-count=1 '^MemcardPath2' "$epsxeConfigFile"
	_msg_zenity "--info" "Configuração memory card 2" "Memory Card 2 configurado: $epsxeMemcard2Path" "600" "150"

}

#-----------------------------[ Função menu configuração ]-----------#
_configure_epsxe()
{

while :; do
	# $1=acao 
	# $2=titulo 
	# $3=texto
	# $4=largura 
	# $5=altura
	# $6=nome da coluna
	# $7=lista de opções
	#
	options_list="TRUE Bios FALSE MemoryCards FALSE Sair"
	menu_config=$(_msg_zenity "--list" "Configurar ePSxe" "Selecione uma configuração" "430" "450" "Configurações" "$options_list")

	case "$menu_config" in
		Sair) break; return 0;;	
		Bios) _config_bios;;
		MemoryCards) _config_memcards;;
		*) _yellow "Saindo..."; break; return;;
	esac
done
}

run()
{
	#sudo apt update
	_check_cli_requeriments
	_install_epsxe
	# Instalar dependências e libs para debian/ubuntu.
	case "$os_name" in
		debian) _config_debian_libs || return 1;;
		ubuntu|linuxmint) _config_ubuntu_libs || return 1;;
	esac
	"$DIR_BIN/epsxe"	
}

main()
{
	_clean_temp_dirs
	
	if [[ -z $1 ]]; then
		usage
		return 1
	fi

	while [[ "$1" ]]; do
		case "$1" in
			-i|--install) run "$@";;
			-c|--configure) _configure_epsxe;;
			-h|--help) usage; return; break;;
			-r|--remove) _remove_epsxe;;
			-v|--version) echo -e " V${__version__}"; return 0; break;;
			*) usage; return 1; break;;
		esac
		shift
	done

	return "$?"
}

main "$@"