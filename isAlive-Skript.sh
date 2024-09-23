#!/bin/bash

# Gucken ob der Benutzer root ist
if [ "$(id -u)" != "0" ]; then
  echo $(tput setaf 1)Bitte wechseln Sie zu einem Root Benutzer$(tput sgr0)
  exit 1;
fi

#Name vom Script
SCRIPTNAME="isAlive"
LOCK=".lock-isAlive"

#Status
status="Ausgeschaltet"

# Fehler Codes
FEHLER1='Fehler! Crontab wurde noch nicht benutzt oder ist nicht installiert. (Fehlercode 01)'
FEHLER2='Fehler! Der Sender oder dem Empfeanger ist unbekannt. (FehlerCode2)'

# Script Verzeichniss
	reldir=`dirname $0`
	cd $reldir
	SCRIPTPATH=`pwd`

content=$(wget https://raw.githubusercontent.com/lofentblack/isAlive-Skript/refs/heads/main/version.txt -q -O -)
Version=$content

checkUpdate() {
content=$(wget https://raw.githubusercontent.com/lofentblack/isAlive-Skript/refs/heads/main/version.txt -q -O -)
version=$content

# Eingabedatei
AnzahlZeilen=$(wc -l ${LOCK} | awk ' // { print $1; } ')
for LaufZeile in $(seq 1 ${AnzahlZeilen})
 do
  Zeile=$(sed -n "${LaufZeile}p" ${LOCK})
  Test=${Zeile}
	if [[ "$Test" == *"version"* ]]; then
		if [[ "$Test" == *"version"* ]]; then
		  var1=$(sed 's/version=//' <<< "$Test")
		  var2=$(sed 's/^.//;s/.$//' <<< "$var1")
		  SkriptVersion=$var2
		fi
	fi
done

if ! [[ $version == $SkriptVersion ]]; then
	sudo apt-get install wget -y
	clear
	clear

	echo $(tput setaf 3)"Update verfügbar! Update von "$SkriptVersion" zu "$version"." 
	echo "$(tput sgr0)"
	wget https://raw.githubusercontent.com/lofentblack/isAlive-Skript/refs/heads/main/isAlive-Skript.sh -O isAlive-Skript.new.sh
	rm $LOCK
	chmod 775 isAlive-Skript.new.sh
	rm isAlive-Skript.sh
	mv isAlive-Skript.new.sh isAlive-Skript.sh

fi
}

checkUpdate

Port_Test() {

cd /$SCRIPTPATH

	sed '/'#'/d' isAlive.config > isAlive_ports.txt
	sed -i '/^$/d' isAlive_ports.txt

	# Eingabedatei
	INPUTDATEI=isAlive_ports.txt
	AnzahlZeilen=$(wc -l ${INPUTDATEI} | awk ' // { print $1; } ')
	
	Sender=""
	Empfanger=""
	
	for LaufZeile in $(seq 1 ${AnzahlZeilen})
	 do

	  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
	  Test=${Zeile}

		if [[ "$Test" == *"E-Mail"* ]]; then
			if [[ "$Test" == *"E-Mail-sender"* ]]; then
			  var1=$(sed 's/E-Mail-sender=//' <<< "$Test")
			  var2=$(sed 's/^.//;s/.$//' <<< "$var1")
			  Sender=$var2
			elif [[ "$Test" == *"E-Mail-empfanger"* ]]; then
			  varer1=$(sed 's/E-Mail-empfanger=//' <<< "$Test")
			  varer2=$(sed 's/^.//;s/.$//' <<< "$varer1")
			  Empfanger=$varer2
			else
				if ! [[ "$Test" == *"E-Mail-sender"* ]]; then
					echo $(tput setaf 1)'Das Feld "E-Mailsenden" ist leer oder nicht korrekt ausgefüllt worden'
				elif ! [[ "$Test" == *"E-Mail-empfanger"* ]]; then
					echo $(tput setaf 1)'Das Feld "E-Mailempfanger" ist leer oder nicht korrekt ausgefüllt worden'
				else
					echo $FEHLER2
				fi
				echo "$(tput sgr0)"
				exit 0;
			fi
		fi

	done

	##send_mail

	send_mail () {
		txt="Achtung der Port: $1 ist ausgefallen. Eventuell funktioniert nun der $2 Dienst nicht mehr."
		echo -e "To: $Empfanger\nSubject: Server Port Warnung\nFrom: $Sender\n$txt" | sendmail $Empfanger
	}

	netstat -tulpen >> LBsite.txt

	is_port_alive() {

		#Abfrage port Anfang
		sed '/':$1'/!d' LBsite.txt > LBsite$1.txt
		port=$(head -n 1 LBsite$1.txt)
		
		DATE=`date +%H:%M`" "`date +%d.%m.%Y`
		if ! [ -s port_error_$1.txt ]; then
			if [ -z "$port" ]; then
		    	> port_error_$1.txt
				echo -e "Port: "$1"\t exestiert nicht!\t Dienst: "$2" Versuch um: $DATE" >> port_error_$1.txt
				send_mail $1 $2
			fi		
		else
			echo -e "port: "$1"\t exestiert nicht!\t Dienst: "$2" Versuch um: $DATE" >> port_error_$1.txt
		fi

		rm LBsite$1.txt
		#Abfrage port Ende

	}

	Port=""
	Dienst=""

	for LaufZeile in $(seq 1 ${AnzahlZeilen})
	 do

	  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
	  Line=${Zeile}

		if [[ "$Line" == *"port"* ]]; then
		  if [[ "$Line" == *"-port="* ]]; then
				for (( i = 1; i < 1000; i++ )); do
				VAR="port"$i"-port="
					if [[ "$Line" == *"$VAR"* ]]; then
						TMP0=$(sed "s/$VAR//" <<< "$Line")
			  		TMP3=$(sed 's/^.//;s/.$//' <<< "$TMP0")
			  		Port=$TMP3
						for LaufZeile in $(seq 1 ${AnzahlZeilen})
						 do
						  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
						  Line=${Zeile}
							VARS="port"$i"-dienst="
							if [[ "$Line" == *"$VARS"* ]]; then
								TMP1=$(sed "s/$VARS//" <<< "$Line")
			  				TMP2=$(sed 's/^.//;s/.$//' <<< "$TMP1")
			  				Dienst=$TMP2

			  				is_port_alive $Port "$Dienst"

							fi
						done
					fi
				done
			fi	
		fi

	done

	if [ -f LBsite.txt ]; then
		rm LBsite.txt
	fi
	if [ -f isAlive_ports.txt ]; then
		rm isAlive_ports.txt
	fi
}

Port_richtigkeits_Test() {

	cd /$SCRIPTPATH

	sed '/'#'/d' isAlive.config > isAlive_ports.txt
	sed -i '/^$/d' isAlive_ports.txt

	# Eingabedatei
	INPUTDATEI=isAlive_ports.txt
	AnzahlZeilen=$(wc -l ${INPUTDATEI} | awk ' // { print $1; } ')
	
	Sender=""
	Empfanger=""
	
	for LaufZeile in $(seq 1 ${AnzahlZeilen})
	 do

	  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
	  Test=${Zeile}

		if [[ "$Test" == *"E-Mail"* ]]; then
			if [[ "$Test" == *"E-Mail-sender"* ]]; then
			  var1=$(sed 's/E-Mail-sender=//' <<< "$Test")
			  var2=$(sed 's/^.//;s/.$//' <<< "$var1")
			  Sender=$var2
			elif [[ "$Test" == *"E-Mail-empfanger"* ]]; then
			  varer1=$(sed 's/E-Mail-empfanger=//' <<< "$Test")
			  varer2=$(sed 's/^.//;s/.$//' <<< "$varer1")
			  Empfanger=$varer2
			else
				if ! [[ "$Test" == *"E-Mail-sender"* ]]; then
					echo $(tput setaf 1)'Das Feld "E-Mail-senden" ist leer oder nicht korrekt ausgefüllt worden'
				elif ! [[ "$Test" == *"E-Mail-empfanger"* ]]; then
					echo $(tput setaf 1)'Das Feld "E-Mail-empfanger" ist leer oder nicht korrekt ausgefüllt worden'
				else
					echo $FEHLER2
				fi
				echo "$(tput sgr0)"
				exit 0;
			fi
		fi

	done

	clear
	clear

	echo "$(tput setaf 2)"
	figlet -f slant -c $SCRIPTNAME
	echo $rot
	echo "Mit dem download akzeptieren Sie die Lizenz von lofentblack.de/licence"
	echo "$(tput sgr0)"
	echo "Die folgenden Ports können überwacht werden:"
	echo " "
	for LaufZeile in $(seq 1 ${AnzahlZeilen})
	 do

	  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
	  Line=${Zeile}

		if [[ "$Line" == *"port"* ]]; then
		  if [[ "$Line" == *"-port="* ]]; then
				for (( i = 1; i < 1000; i++ )); do
				VAR="port"$i"-port"
					if [[ "$Line" == *"$VAR"* ]]; then
						for LaufZeile in $(seq 1 ${AnzahlZeilen})
						 do
						  Zeile=$(sed -n "${LaufZeile}p" ${INPUTDATEI})
						  Line=${Zeile}
							VARS="port"$i"-dienst"
							if [[ "$Line" == *"$VARS"* ]]; then
								echo "$(tput setaf 2)$VAR und $VARS"
							fi
						done
					fi
				done
			fi	
		fi
	done
		echo "$(tput sgr0)"
		echo "Neustart in 10 Sekunden..."
		sleep 10
		lofentblackDEScript	
	if [ -f isAlive_ports.txt ]; then
		rm isAlive_ports.txt
	fi
}

if ! [ -z ${1+x} ]; then
	if [ $1 == "porttest" ]; then
		Port_Test
		exit 0;
	fi
fi

lofentblackDEScript() {

rot="$(tput setaf 1)"
gruen="$(tput setaf 2)"
gelb="$(tput setaf 3)"
dunkelblau="$(tput setaf 4)"
lila="$(tput setaf 5)"
turkies="$(tput setaf 6)"

# Notwendige Packete
installations_packete() {

apt-get install sudo -y
sudo apt-get update -y
sudo apt-get install screen -y

screen=instalations_packete_lb.de_script
screen -Sdm $screen apt-get install figlet -y && screen -Sdm $screen sudo apt-get upgrade -y && screen -Sdm $screen sudo apt-get install cron -y

echo "Notwendige Pakete sind nun installiert"

sleep 10

clear
clear
echo $gruen"Bitte starten Sie das Skript neu!"
echo "$(tput sgr0)"

}

status_test() {

	if [ -d /var/spool/cron/crontabs/ ]; then

		cd /var/spool/cron/crontabs/

		if [ -f root ]; then
			ladedatei=root
			fgrep $SCRIPTNAME.sh "$ladedatei" >> ausgabe.txt
		fi
				
		if [ -f admin ]; then
			ladedatei=admin
			fgrep $SCRIPTNAME.sh "$ladedatei" >> ausgabe.txt
		fi

		if [ -s ausgabe.txt ]; then
			status="Eingeschaltet"
		else
			status="Ausgeschaltet"
		fi

	else
		status="Ausgeschaltet"
	fi

	if [ -f ausgabe.txt ]; then
		rm ausgabe.txt
	fi

}

vorlage_generieren() {

if [ -f isAlive.config ]; then
	rm isAlive.config
fi

	echo -e '#################################################################################
##                                                                             ##
## Sie müssen unten immer ein Port und ein Port Dienst eingeben.               ##
## Als Beispiel port17-port="123" und port17-dienst="Test_Port"                ##
##                        /\               /\                                  ##
##                        ||               ||                                  ##
##                        ||               ||                                  ##
##                        ||               ||                                  ##
## 1) Es MUSS immer ein Port               ||                                  ##
## angegeben werden zu Überprüfung         ||                                  ##
##                                         ||                                  ##
## 2) Ebenfalls ist es wichtig, dass ein Port dienst, damit dies               ##
## in der E-Mail Angeben werden kann.                                          ##
##                                                                             ##
## Wird eines dieser Bedingungen nicht erfüllt wird der Port nicht Überwacht.  ##
## Zum Aktivieren muss die raute(#) vor dem Port entfernt werden.              ##
##                                                                             ##
##    !!! Ebenfalls darf sich keine raute(#) in den Port-dienst befinden !!!   ##
##                                                                             ##
##  Es können bis zu 1000 Ports insgesamt bestehen. Dabei sollten die nummern  ##
##             möglichts immer Zählweise fortlaufend entsprechen.              ##
##                                                                             ##
#################################################################################



######################
## Sender/Empfänger ##
######################

E-Mail-sender="Sender@LofentBlack.de"
E-Mail-empfanger="Empfanger@LofentBlack.de"


##############
## Webseite ##
##############

#port1-port="80"
#port1-dienst="http"

#port2-port="443"
#port2-dienst="https (SSL)"

#port3-port="25"
#port3-dienst="interne E-Mail"


################
## MailServer ##
################

#port4-port="4433"
#port4-dienst="Mail-Server Webserver-Port (SSL)"

#port5-port="993"
#port5-dienst="SSL/TLS FQDN des Mailservers (Posteingangsserver)"

#port6-port="587"
#port6-dienst="STARTTLS FQDN des Mailservers (Postausgangsserver)"


###############
## Minecraft ##
###############

#port7-port="25565"
#port7-dienst="Minecraft default server port"


###############
## Teamspeak ##
###############

#port8-port="9987"
#port8-dienst="Teamspeak UDP Standart-Port eingehend"

#port9-port="30033"
#port9-dienst="Teamspeak TCP Dateitransfers eingehend"

#port10-port="10011"
#port10-dienst="Teamspeak TCP ServerQuery eingehend"
' >> isAlive.config
}

LOGO() {
 	clear
	clear

	echo "$(tput setaf 2)"
	figlet -f slant -c $SCRIPTNAME
	echo $rot
	echo "Mit dem download akzeptieren Sie die Lizenz von lofentblack.de/licence"
	echo "$(tput sgr0)"
	status_test
	echo $gelb"Die Überwachung ist momentan: "$status
	echo "$(tput sgr0)"
	echo "1) Einstellungen der Ports testen"
	echo "2) Überwachung aktivieren"
	echo "3) Überwachung deaktivieren"
	echo "4) Vorlage erneut generieren"
	echo "5) Beenden"
	read -p "Was willst möchten Sie machen? " machen
}

  if [ -s $SCRIPTPATH/$LOCK ]; then

	LOGO

	if [ $machen == "1" ]; then
		Port_richtigkeits_Test
	elif [ $machen == "2" ]; then

		#Aktivieren
		#Eingeschaltet

		if [ $status == "Eingeschaltet" ]; then
			clear
			clear
			echo $gelb"Die Überwachung ist bereits eingeschaltet"
			sleep 2
			LOGO
		fi

		if [ -d /var/spool/cron/crontabs/ ]; then

			cd /var/spool/cron/crontabs/

			if [ -f root ]; then
				echo -e '*/5 * * * * sudo '$SCRIPTPATH/$SCRIPTNAME.sh' "porttest" > /dev/null 2>&1' >> root
				echo -e '2 2 * * * cd '$SCRIPTPATH' && rm port_error_* > /dev/null 2>&1' >> root
				chown root root
				chmod 600 root
			fi
			
			if [ -f admin ]; then
				echo -e '*/5 * * * * sudo '$SCRIPTPATH/$SCRIPTNAME.sh' "porttest" > /dev/null 2>&1' >> admin
				echo -e '2 2 * * * cd '$SCRIPTPATH' && rm port_error_* > /dev/null 2>&1' >> admin
				chowm admin root
				chmod 600 admin
			fi
			LOGO
		else
			echo $rot$FEHLER1
			echo "$(tput sgr0)"
			exit 0;
		fi

	elif [ $machen == "3" ]; then

		#Deaktivieren
		#Ausgeschaltet

		if [ $status == "Ausgeschaltet" ]; then
			clear
			clear
			echo $gelb"Die Überwachung ist bereits ausgeschaltet"
			sleep 2
			LOGO
		fi

		if [ -d /var/spool/cron/crontabs/ ]; then

			cd /var/spool/cron/crontabs/

			if [ -f root ]; then
				sed '/'$SCRIPTNAME.sh'/d' root > LBsite.txt
				rm root
				sed '/'port_error'/d' LBsite.txt > root
				rm LBsite.txt
				chown root root
				chmod 600 root
			fi
			
			if [ -f admin ]; then
				sed '/'$SCRIPTNAME.sh'/d' admin > LBsite.txt	
				rm admin
				sed '/'port_error'/d' LBsite.txt > admin
				rm LBsite.txt
				chowm admin root
				chmod 600 admin
			fi
			LOGO
		else
			echo $rot$FEHLER1
			echo "$(tput sgr0)"
			exit 0;
		fi

	elif [ $machen == "4" ]; then
		cd $SCRIPTPATH
		echo $rot"Wenn eine neue Vorlage generiert wird, wird die alte automatisch überschrieben."
		read -p "Sind Sie sich sicher? (Y/N) " sicherheit
		if [ $sicherheit = "y" ] || [ $sicherheit = "Y" ] || [ $sicherheit = "J" ] || [ $sicherheit = "j" ] || [ $sicherheit = "ja" ] || [ $sicherheit = "Ja" ] || [ $sicherheit = "Yes" ] || [ $sicherheit = "yes" ] || [ $sicherheit = "ok" ] || [ $sicherheit = "Ok" ] || [ $sicherheit = "OK" ] || [ $sicherheit = "oK" ] || [ $sicherheit = "JA" ] || [ $sicherheit = "jA" ] || [ $sicherheit = "YES" ] || [ $sicherheit = "YEs" ] || [ $sicherheit = "yES" ] || [ $sicherheit = "yeS" ] || [ $sicherheit = "YeS" ] || [ $sicherheit = "yES" ] || [ $sicherheit = "yEs" ]; then
			echo ""
			echo "$(tput sgr0)"
			vorlage_generieren
			echo $gruen"Die Vorlage wurde erneut generiert."
			sleep 2
			LOGO
		else
			echo ""
			echo $gruen"Vorgang abgebrochen."
			echo "$(tput sgr0)"
		fi
	else
		echo ""
		echo $gruen"Einen schönen Tag!"
		echo "$(tput sgr0)"
	fi

	elif ! [ -s $SCRIPTPATH/$LOCK ]; then
    > $LOCK
    echo -e 'int=true\nversion="'$Version'"\n\n#Mit dieser Datei erkennt das Skript das alle notwendigen Pakete installiert worden sind und das die Vorlage erstellt wurde. Sollte diese Datei gelöscht werden oder der Namen geändert werden\ndann wird die Vorlage die alte Config Datei überschreiben und das Skript neu Installieren.' > $SCRIPTPATH/$LOCK
    vorlage_generieren
    installations_packete
fi
if [ -f isAlive_ports.txt ]; then
	rm isAlive_ports.txt
fi
}
lofentblackDEScript
