#!/bin/bash



function utilisation(){

echo -e "Utilisation : mode [SERVEUR] [PORT] [ARCHIVE]\n"
	echo -e "\t -list    : lister les archives dans le serveur"
	echo -e "\t -browse  : naviguer à l'interieur du serveur"
	echo -e "\t -extract : extraire l'archive entrée en argument\n"
}



function attribution_de_droits(){

chmod u+$(echo $1 | cut -c 2,4) $2
chmod g+$(echo $1 | cut -c 5,7) $2
chmod o+$(echo $1 | cut -c 8,10) $2


}

function creation_de_fichiers(){
end="$3"
beg=$(( end - 1 ))
nom_fichier="$(echo $1 | cut -d ' ' -f 1)"
premier_caractere_deuxieme_champ="$(echo $1 | cut -d ' ' -f 2 | cut -c 1)"
	if [ "$premier_caractere_deuxieme_champ" = "d" ];then

		mkdir $2/$nom_fichier 
	elif [ "$premier_caractere_deuxieme_champ" = "-" ];then
		if [ "$(echo $1 | cut -d ' ' -f 3)" = "0" ];then 
			touch "$2/$nom_fichier"
		else

			a="$(echo $1 | cut -d ' ' -f 4)"
			contenu_fichier="$(( a + beg ))"
			
			b="$(echo $1 | cut -d ' ' -f 5)"
			fin_du_fichier="$(( contenu_fichier + b ))"
			fin_du_fichier="$(( fin_du_fichier - 1 ))"
			sed -n $contenu_fichier','$fin_du_fichier'p' archive.arch > "$2/$nom_fichier"
		fi
	fi
}

function creation_des_dossiers(){
 #mkdir -p $(curl -s $1:$2/$3 | grep '^directory' | cut -d' ' -f2)

#Initialisation de variables begin , end , archives qui permettent d'afficher seulement le header du fichier l'archive
begin="$(curl -s $1:$2/$3 | head -1 | cut -d':' -f1)" 
end="$(curl -s $1:$2/$3 | head -1 | cut -d':' -f2)" 
archive="$(curl -s $1:$2/$3 | sed -n $begin,$((end-1))p)"
#echo $begin $end
#On se rend compte que le nombre de dossiers est egal au nombre de @, donc nous comptons les @
nombre_de_dossiers="$(curl -s $1:$2/$3 | sed -n "$begin,$((end-1))p" | grep -o '@' | wc -l)"

#On crée les dossiers recursivement 
mkdir -p $(curl -s $1:$2/3 | head -$begin | tail -1  | cut -d ' ' -f 2)

 #Ici on fait une boucle dans laquelle on prend tout ce qui se trouve entre le directory $repertoire et le @ puis on le met dans un fichier appelé temporaire 
for ((i=0;i<$nombre_de_dossiers;i++ )); do

echo  -e "$archive" | cut -d '@' -f$((i+1)) -z | sed '/^$/d' > temporaire

#On recupere à chaque fois le dossier racine courant dans la variable racine
racine="$(head -1 temporaire | cut -d' ' -f2)"	
sed '1d' temporaire > temporaire1
echo $racine 
		while read line;do

			echo $line
			creation_de_fichiers "$line" "$racine" "$end"
			attribution_de_droits "$(echo $line | cut -d ' ' -f 2)" "$racine/$(echo $line | cut -d ' ' -f 1)" 

		done < temporaire1
rm temporaire temporaire1

done
}



if [ "$1" = "-list" ];then
	echo "Bienvenu sur votre serveur d'archives; vos archives sont:"
	echo ""
	curl -s $2:$3/listearchives

elif [ "$1" = "-extract" ];then

curl -s $2:$3/$4 > archive.arch
creation_des_dossiers $2 $3 $4

elif [ "$1" = "-browse" ];then

#On recupere l'archive
	curl -s $2:$3/$4 > archive.arch

begin="$(cat archive.arch | head -1 | cut -d':' -f1)" 
end="$(cat archive.arch | head -1 | cut -d':' -f2)" 
archive="$(cat archive.arch  | sed -n $begin,$((end-1))p)"
base=$(cat archive.arch | head -$begin | tail -1  | cut -d ' ' -f 2)
base_orig=$base
mon_invite="vsh:$base>"
while :
do
	echo -n $mon_invite

read line 

	
cmd=$(echo $line | cut -d ' ' -f 1)
arg1=$(echo $line | cut -d ' ' -f 2)



if [ "$cmd" = "cd" ];then
	if [ "$arg1" =  "/" ]; then 
		base="$base_orig"
		mon_invite="vsh:$base>"
	elif [ "$arg1" = ".." ];then
		if [ "$base" != "$base_orig" ]; then
#Nous comptons le nombre de / c'est à dire le nombre de repertoire de notre base
compter_nombre_de_slash="$(echo $base | grep -o '/' | wc -l )"

#cette variable permet de retourner le nombre de /-1 donc le dossier courant-1 donc le dossier parent
position="$(( compter_nombre_de_slash - 1 ))"

#Nous affectons une nouvelle valeur à $base
base="$(echo $base | cut -d '/' -f 1-$position)/"
#Nous affichons $base
mon_invite="vsh:$base>"
fi

	

elif [ "$(cat archive.arch | grep 'directory '$base$arg1)" != "" ];then 
	base="$base$arg1/"
	mon_invite="vsh:$base>"

	fi
fi

if [ "$cmd" = "pwd" ];then

	echo $base
fi
if [ "$cmd" = "ls" ];then

#echo $begin $end
nombre_de_dossiers="$(cat archive.arch  | sed -n "$begin,$((end-1))p" | grep -o '@' | wc -l)"
begin="$(cat archive.arch | head -1 | cut -d':' -f1)" 
end="$(cat archive.arch | head -1 | cut -d':' -f2)"  
archive="$(cat archive.arch  | sed -n $begin,$((end-1))p)"
for ((i=0;i<$nombre_de_dossiers;i++ )); do

echo  -e "$archive" | cut -d '@' -f$((i+1)) -z | sed '/^$/d' > temporaire
racine="$(head -1 temporaire | cut -d' ' -f2)/"	
racine="$(echo $racine |  sed 's,//,/,')"
if [ "$racine" = "$base" ];then

	sed '1d' temporaire > temporaire1 
		while read line;do
			deuxieme_champ="$(echo $line | cut -d ' ' -f 2)"
			premier_caractere_deuxieme_champ="$(echo $line | cut -d ' ' -f 2 | cut -c 1)"
				
				if [ "$premier_caractere_deuxieme_champ" = "d" ];then
						dossier="$(echo $line | cut -d' ' -f 1)"
						echo $dossier'/'

				elif [ "$(echo $deuxieme_champ | grep 'x')" != "" ];then

					fichier_executable="$(echo $line | cut -d' ' -f 1)"
					echo $fichier_executable'*'
				else
					echo $line | cut -d' ' -f 1
				fi


		done < temporaire1
		break
fi
done
rm temporaire temporaire1
fi

if [ "$cmd" = "cat" ];then

	nombre_de_dossiers="$(cat archive.arch  | sed -n "$begin,$((end-1))p" | grep -o '@' | wc -l)"

for ((i=0;i<$nombre_de_dossiers;i++ )); do

echo  -e "$archive" | cut -d '@' -f$((i+1)) -z | sed '/^$/d' > temporaire
racine="$(head -1 temporaire | cut -d' ' -f2)/"	
racine="$(echo $racine |  sed 's,//,/,')"
if [ "$racine" = "$base" ];then 
	sed '1d' temporaire > temporaire1 
		while read line;do
			if [ "$arg1" = "$(echo $line | cut -d ' ' -f 1)" ]; then 
			deuxieme_champ="$(echo $line | cut -d ' ' -f 2)"
			premier_caractere_deuxieme_champ="$(echo $line | cut -d ' ' -f 2 | cut -c 1)"
			
				if [ "$premier_caractere_deuxieme_champ" = "d" ];then
						echo "Desolé c'est un dossier "
						break


				
					elif [ "$(echo $line | cut -d ' ' -f 3)" = "0" ];then 
			:
		else


			end="$(cat archive.arch | head -1 | cut -d':' -f2)" 
			beg=$(( end - 1 ))		
			a="$(echo $line | cut -d ' ' -f 4)"
			contenu_fichier="$(( a + beg ))"
			
			b="$(echo $line | cut -d ' ' -f 5)"
			fin_du_fichier="$(( contenu_fichier + b ))"
			fin_du_fichier="$(( fin_du_fichier - 1 ))"
			sed -n $contenu_fichier','$fin_du_fichier'p' archive.arch 2>/dev/null
				fi

fi


		done < temporaire1
		break
fi
done
rm temporaire temporaire1 2>/dev/null
fi

if [ "$cmd" = "rm" ];then

	


	nombre_de_dossiers="$(cat archive.arch  | sed -n "$begin,$((end-1))p" | grep -o '@' | wc -l)"

for ((i=0;i<$nombre_de_dossiers;i++ )); do

echo  -e "$archive" | cut -d '@' -f$((i+1)) -z | sed '/^$/d' > temporaire
racine="$(head -1 temporaire | cut -d' ' -f2)/"	
racine="$(echo $racine |  sed 's,//,/,')"
if [ "$racine" = "$base" ];then 
	sed '1d' temporaire > temporaire1 
		while read line;do
			if [ "$arg1" = "$(echo $line | cut -d ' ' -f 1)" ]; then 
			deuxieme_champ="$(echo $line | cut -d ' ' -f 2)"
			premier_caractere_deuxieme_champ="$(echo $line | cut -d ' ' -f 2 | cut -c 1)"
			sed -i "s,$line,," archive.arch 2>/dev/null
				if [ "$premier_caractere_deuxieme_champ" = "d" ];then
						
					#echo  $base$arg1
					sed -i "s,directory $base$arg1,," archive.arch 2>/dev/null
					:


				else

			end="$(cat archive.arch | head -1 | cut -d':' -f2)" 
			beg=$(( end - 1 ))		
			a="$(echo $line | cut -d ' ' -f 4)"
			contenu_fichier="$(( a + beg ))"
			
			b="$(echo $line | cut -d ' ' -f 5)"
			fin_du_fichier="$(( contenu_fichier + b ))" 
			fin_du_fichier="$(( fin_du_fichier - 1 ))"
			sed -n $contenu_fichier','$fin_du_fichier'p' archive.arch > temporaire
			while read line; do
			sed -i "s,$line,,g" archive.arch 2>/dev/null
			done < temporaire
				
		fi
fi


		done < temporaire1
		break
fi
done
rm temporaire temporaire1 2>/dev/null
fi




if [ "$cmd" = "exit" ];then

	exit 0
fi


done

elif [[ $# -lt 4 ]]
then 
:
else 

utilisation
fi

