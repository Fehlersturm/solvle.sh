#!/bin/bash
##Generate the 5 letter dictionary:
#grep -e ^......$ words_alpha.txt > 5ltr
##Count Usage frequency
#for letr in a b c d e f g h i j k l m n o p q r s t u v w x y z
#do
#  count=$(grep -c $letr 5ltr)
#  echo $count $letr >> stat
#done
#sort -g stat > stattm; mv stattm stat
#functions
#addltr()
#remltr()
#suggest()
#googleit()
#columns()
#askResultsResolve()
#0=known, 1-5=letters excluded from position, 6-10 letters known for position, 11-15=nextguessforpos  16=removed, 17=nextguesses
strings=("" "." "." "." "." "." "" "" "" "" "" "" "" "" "" "" "" "")

result=""
begindeco="VVVVV-"
enddeco="AAAAA-"
NumberLtrsIncluded=5
moreSuggestions=0
cp stat remain
guessno=0

function einende() {
for filename in remain suggestions singleletrsug multiletrsug sorting tmp
do
  [[ -e $filename ]] && rm $filename
done
}
trap einende EXIT

function askResultsResolve(){
  read -r -p "the word you used as guess. all lower case. enter: " guess
  read -r -p "the result in the format X=Wrong, Y=Yellow, G=Green, e.g.: XXGXY: " results
  if [[ $(( ${#results}+${#guess} ))  != 10 ]]
  then
    echo "!!Should be 5 letters long"
    return 1
  fi
  for i in $(seq 1 5)
  do
    ltr=$(echo $guess | cut -c $i)
    result=$(echo $results | cut -c $i)
    if [[ $result == "GGGGG" ]]
    then
      echo "gg"
      exit 0
    fi
    case $result in
        [Xx]* ) addltr 16 $ltr;;
        [Gg]* ) addltr 0 $ltr 
                strings[$(( 5+$i ))]=$ltr;;
        [Yy]* ) addltr 0 $ltr
                strings[$i]=${strings[$i]}$ltr;;
        * ) echo "$result is not a valid Input"; exit 1;;
    esac
  done
  grep -v -e [$(echo ${strings[16]} | sed 's# ##g')] remain > tmp
  mv tmp remain
  guessno=$(( $guessno+1 ))
  NumberLtrsIncluded=$(( $NumberLtrsIncluded+$guessno*3 ))
}

function addltr() {
  index=$1
  shift
  for ltr in $@
  do
    [[ $(echo ${strings[$index]} | grep -c $ltr) == 0 ]] && strings[$index]="${strings[index]} $ltr"
  done
  
}

function remltr() {
  index=$1
  shift
  for ltrtrem in $@
  do
    string[$index]=$(echo ${strings[$index]} | sed "s# $ltrtrem##g" )
  done
}

function columnize() {
  columns=$(( $(tput cols)/7-1 ))
  words=$(wc -l $1 | cut -d " " -f 1)
  if [[ $words -lt $columns ]] 
  then
    lines=0
  else
    lines=$(( $words/$columns-1 ))
  fi

  i=0
  j=0
  declare -A columnized
  for word in $(cat $1)
  do
    columnized[$i:$j]="${word//[$'\t\r\n']}"
    if [[ $i -eq $lines ]]
    then
      i=0
      j=$(( $j+1 ))
    else
      i=$(( $i+1 ))
    fi
  done
  i=0
  j=0

  for i in $(seq 0 $columns)
  do
  echo -n $begindeco
  done
  echo ""

  for i in $(seq 0 $lines)
  do
  line=""
    for j in $(seq 0 $columns)
    do
    line="$line  ${columnized[$i:$j]}  "
    done
    echo $line
  done

  for i in $(seq 0 $columns)
  do
  echo -n $enddeco
  done
  echo ""
  unset columnized
}


function suggest() {
for file in singleletrsug multiletrsug suggestions
do
  [[ -e $file ]] && rm $file
done
wordsfound=0
strings[17]=""  
#0=known, 1-5=letters excluded from position, 6-10 letters known for position, 11-15=nextguessforpos  16=removed, 17=nextguesses
remainingltrs=$(wc -l remain | cut -d " " -f 1)

if [[ $NumberLtrsIncluded -gt $remainingltrs ]]
then
  echo "!!No more letters to add"
  NumberLtrsIncluded=$remainingltrs
fi

  for ltr in $(tail -n $(( $NumberLtrsIncluded )) remain | cut -d " " -f 2)
  do
    addltr 17 $ltr
  done

  knownp=""
  exclpos=""
  for i in $(seq 0 4)
  do
    if [[ ${#strings[$(( 6+$i ))]} == 0 ]]
    then
      strings[$(( 11+$i ))]="${strings[0]} ${strings[17]}"
      knownp="$knownp-"
    else 
      strings[$(( 11+$i ))]=${strings[$(( 6+$i ))]}
      knownp="$knownp${strings[$(( 6+$i ))]//[$'\t\r\n\ ']}"
    fi
    if [[ "${strings[$(( 1+$i ))]}" == "." ]]
    then
      exclpos="$exclpos-"
    else
      exclpos=$exclpos[${strings[$(( 1+$i ))]//[$'\t\r\n\ ']}]
    fi
  done 
expincl=("." "." "." "." ".")
i=0

for ltr in ${strings[0]}
do
expincl[$i]=$ltr
i=$(( $i+1 ))
done

exp="^[${strings[11]//[$'\t\r\n\ ']}][${strings[12]//[$'\t\r\n\ ']}][${strings[13]//[$'\t\r\n\ ']}][${strings[14]//[$'\t\r\n\ ']}][${strings[15]//[$'\t\r\n\ ']}]"
expexcl="-e ^[${strings[1]//[$'\t\r\n\ ']}].... -e ^.[${strings[2]//[$'\t\r\n\ ']}]... -e ^..[${strings[3]//[$'\t\r\n\ ']}].. -e ^...[${strings[4]//[$'\t\r\n\ ']}]. -e ^....[${strings[5]//[$'\t\r\n\ ']}]"
grep -e $exp 5ltr | grep -v $expexcl | grep ${expincl[0]} | grep ${expincl[1]} | grep ${expincl[2]} | grep ${expincl[3]} | grep ${expincl[4]} > suggestions
echo $exp
echo "Excluded: ${strings[16]//[$'\t\r\n ']} Excluded from Position: ${exclpos//[\.]} 
Known: ${strings[0]//[$'\t\r\n ']} Known for Position: $knownp 
Current Letter Selection: ${strings[0]//[$'\t\r\n ']}${strings[17]//[$'\t\r\n ']} " 

  wordsfound=$(wc -l suggestions | cut -d " " -f 1)

  if (( 0==$wordsfound ))
  then
        if [[ $NumberLtrsIncluded -lt $remainingltrs ]]
        then
          NumberLtrsIncluded=$(( $NumberLtrsIncluded+1 ))
          echo "No words found. adding another letter"
          suggest
          return
        fi
  elif (( 0<$wordsfound && $wordsfound<=5 ))
  then
    if [[ $NumberLtrsIncluded -lt $(( $remainingltrs-2 )) ]]
    then
      echo "only $wordsfound found. they where:"
      columnize suggestions
      echo "adding another letter just in case"
      NumberLtrsIncluded=$(( $NumberLtrsIncluded+1 ))
      suggest
      return
    fi
  elif (( 6<=$wordsfound && $wordsfound<=300 ))
  then
    columnize suggestions
  elif (( 301<=$wordsfound ))
  then
    cp suggestions multiletrsug
    echo "found $wordsfound words which is alot. the sorting algorithms might be slow! to view unsorted press m"
  fi
}

function remrepeat() {
  for file in singleletrsug multiletrsug
  do
    [[ -e $file ]] && rm $file
  done
  for word in $(cat suggestions)
  do
    wword=${word//[$'\t\r\n']}
    i=0
    oslw=1
    sword=("" "" "" "" "")
    for ltr in $(grep -o . <<<$wword)
    do
      if [[ " ${sword[*]} " =~ " $ltr " ]]
      then
        oslw=0
        break
      fi        
        sword[$i]=$ltr
        i=$(( $i+1 ))
    done

    if [[ $oslw == 1 ]]
    then
      echo $word >> singleletrsug
    else 
      echo $word >> multiletrsug
    fi
  done
  echo "there is $(wc -l multiletrsug | cut -d " " -f  1)  words which use the same letter mutliple times. To show them press m"
  mv singleletrsug suggestions
  columnize suggestions
}

function sortbyusage() {
  [[ -e sorting ]] && rm sorting
  for word in $(cat suggestions)
  do
    wword=${word//[$'\t\r\n']}
    grep $wword 5ltrfrequency >> sorting
  done  
  sort -r -n sorting | cut -d " " -f2 > suggestions
  columnize suggestions
}

function mainLoop() {
suggest
while true; do
echo "remove words with repeating letters. press l"
echo "add letters to the suggestion pool. press a"
echo "remove letters from pool. press r"
echo "Rank Suggestions by frequency. press f"
echo "Enter next word. press n"
echo "I am done Quit! press q"
echo "press ENTER" 
    read -r -p "what next?" answer
    case $answer in
        [Mm]* ) columnize multiletrsug;;
        [Aa]* ) NumberLtrsIncluded=$(( $NumberLtrsIncluded+1 )); break;;
        [Rr]* ) NumberLtrsIncluded=$(( $NumberLtrsIncluded-1 )); break;;
        [Ll]* ) remrepeat;;
        [Ff]* ) sortbyusage;;
        [Nn]* ) askResultsResolve; break;;
        [Qq]* ) exit 0;;
        * ) echo "$answer is Invalid! Pick from [margnq]";;
    esac
done
}

while true
do
  mainLoop
done