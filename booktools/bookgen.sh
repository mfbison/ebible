#!/usr/bin/env bash

[[ -z $1 ]] && printf "pass the ebible/corpus/ bible file as an argument;" && exit

#make script executable with command "chmod +x bookgen" (3.8 bash manual)
#run the script with "./address/to/bookgen address/to/ebible/corpus/biblefile" (4.1 bash manual, Bourne Shell Builtins "a period")
#This script creates 2 html files, which are to be turned into PDFs with (preferably Chrome's) print preview
# afterward, all of pdf0 is printed, flipped hand over fist/x-axis 180 over z-axis, placed back into the printer
# and then all of pdf1 is printed
dateserial="$(date +%s)"
sourceserial="${dateserial::5}" #first 5 digits of unix time, or about 30 hours between versions
PROJECTDIRECTORY=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOURCEFILE=$1
XMLREFFILE=xmlChapterName6.csv #external book name reference. only has about 180 viable bookname translations
sourceslice=${SOURCEFILE##*/} #effectively all variable ${} syntax is covered in 3.5 bash manual,parameter expansion
InputBookName="${sourceslice:4:-4}"
InputISO=${InputBookName::3}
SUBDIR=$PROJECTDIRECTORY/$sourceserial/$InputBookName
INDEXFILE=index.txt #the index is serialized like 001001001 is Gen 1 1, so it can be offset by 3 for any
LOGFILE=$SUBDIR/LOGFILE.txt
TRANSLATIONSINDEXFILE="../metadata/translations.csv"
mapfile -t source < $SOURCEFILE
mapfile -t indexlinearray < $INDEXFILE
set -f #stop file expansion from * character in strings, set globally, so script cannot use file "globbing" for any method after this point
w=0
while [[ -z "${source[$w]}" ]]; do
((w++))
[[ $w -gt $BOOKCAP ]] && echo "read file empty?" && exit
done

INIT()
{
# TODO help/select bible, values, font
mapfile -t BookMeta < <(awk -k -v name=$InputBookName 'NR==1 {for(i=1;i<=NF;i++){r[i]=$i}} $2==name {for(i=1;i<=NF;i++){printf "%s\n", r[i]"#"$i}}' $TRANSLATIONSINDEXFILE)
mapfile -t EndoBook < <(awk -k -v iso="$InputISO" '($4==iso||$2==iso) && ($6==1||$6==2) {for(i=7;i<=NF;i++){printf "%s\n",$i};exit}' $XMLREFFILE)
[[ -z $EndoBook ]] && mapfile -t EndoBook < <(awk -k '$2=="eng" && $6==1 {for(i=7;i<=NF;i++){printf "%s\n",$i};exit}' $XMLREFFILE)
EndoBook=("" "${EndoBook[@]}") #start index from 1 to match book nums
IFS="@" read -r FontLink FontAvgW < <(awk -v FS=$'\t' -v fw="${BookMeta[28]##*#}" '$1==fw {print $2"@"$3}' link_font.tsv)
#OTNO=$(awk -k -v str="$InputBookName" '$1 ~ $str {print $13}' $TRANSLATIONSINDEXFILE) # unused
#NTNO=$(awk -k -v str="$InputBookName" '$1 ~ $str {print $16}' $TRANSLATIONSINDEXFILE) # unused
[[ ${BookMeta[26]##*#} == "ltr" ]] && LeftToRight=true||LeftToRight=false #every file is either ltr or rtl
$LeftToRight && TextAlignSwitch=(0 1) || TextAlignSwitch=(1 0) #order the left and right elements in css
BOOKCAP=(31170) #TODO
declare -A FontMime=([ttf]="truetype" [otf]="opentype" [woff]="woff" [woff2]="woff")
printf "%s\n" "${BookMeta[@]/\#/: }"|cat -n
#menu
# read -r -t 4 -p "Papers per Sheaf (default 16 if empty):" SheafPapersARG

printf '\n%s\n\n' "in font like Amiri, there is behaviour that causes \
text like: \
،ِهِسْأَرِب ًاباَصُم ًاسِجَن َصَرْبَأ ٍذِئَنآ ُنوُكَي [44] \
ِباَصُمْلا ىَلَعَو [45] .ِهِتَساَجَنِب ُنِهاَكْلا ُمُكْحَيَو \
ُهَسْأَر َفِشْكَيَو ُهَباَيِث َّقُشَي ْنَأ ِصَرَبْلا ِءاَدِب \
.‘!ٌسِجَن !ٌسِجَن’ :َيِداَنُيَو ،ِهْيَبِراَش َيِّطَغُيَو \
ُهَدْحَو ُميِقُي ًاسِجَن ِهِضَرَم ِةَرْتَف َلوُط ُّلَظَيَو [46] \
to render "words" attached to the verse number word. \
the person writing this only speaks english and cannot \
audit the script's behaviour in other languages, and as such \
cannot recommend it's use. this must be entirely described as \
a logical definition of book format"
}

DocumentRules()
{
	read -r -t 30 -p "FontBoxHeight(points, default 7):" FontBoxARG
	read -r -t 30 -p "LineSpacing(default 1.2):" LineSpaceARG

BindingTabNO=0
# Points==========
PageH=842
PageW=595
BookletPageH=$PageW
BookletPageW=$((PageH/2))
FontBoxH=${FontBoxARG:=7}
FontBoxW=$(awk \
	-v fbh=$FontBoxH \
	-v faw=${FontAvgW:=.5} \
	'BEGIN {printf "%.2f", fbh*faw;exit}') #.5 is the hardcoded assumption of font width to font height. this script isnt reactive enough to satisfy curious font standards

# Characters========
LineSpace=${LineSpaceARG:=1.2}
CharAllocH=$(awk \
	-v b=$BookletPageH \
	-v f=$FontBoxH \
	-v l=$LineSpace \
	'BEGIN {print int(b/(f*l));exit}')
CharAllocW=$(awk \
	-v bpw=$BookletPageW \
	-v fbw=$FontBoxW \
	'BEGIN {printf "%.1f", bpw/fbw;exit}')
headval=$(awk \
	-v chaw=$CharAllocH \
	'BEGIN {printf "%.0f", chaw*.08;exit}') #arbitrarily identified multipliers for head/foot alloc
footval=$(awk \
	-v chaw=$CharAllocH \
	'BEGIN {printf "%.0f", chaw*.04;exit}')
HeaderAlloc=${headval:=8}
FooterAlloc=${footval:=5}
ColAllocH=$(( CharAllocH - HeaderAlloc - FooterAlloc ))
ColAllocW=$(awk \
	-v chaw=$CharAllocW \
	-v fbh=$FontBoxH \
	-v bt=$BindingTabNO \
	'BEGIN {print int( (chaw - ( (3*2) + (fbh*(bt/2)) ))/2 );exit}') #intending on the behavior of 1em=fontheight, even though in practice it doesnt vary from a standard 16 pts /2 because 2 col, 3*2...? 3 borders per page i think
[[ -n $SOURCEFILE ]] && SOURCEwc=($(head -$BOOKCAP $SOURCEFILE|tr '\n' ' '|wc -wm))

printf '%s\n' \{ \
"PageH: $PageH" \
"PageW: $PageW" \
"LineSpace: $LineSpace" \
"BookletPageH: $BookletPageH" \
"BookletPageW: $BookletPageW" \
"FontBoxH: $FontBoxH" \
"FontAvgW: $FontAvgW" \
"FontBoxW: $FontBoxW" \
"CharAllocH: $CharAllocH" \
"CharAllocW: $CharAllocW" \
"HeaderAlloc: $HeaderAlloc" \
"FooterAlloc: $FooterAlloc" \
"ColAllocH: $ColAllocH" \
"ColAllocW: $ColAllocW" \
"Character division/sim pagecount: $((${SOURCEwc[1]}/((ColAllocW*2)*ColAllocH)))"| tee -a $LOGFILE
[[ -z "$FontLink$FontAvgW" ]] && echo "font not currently supported. assuming an avg width of 0.5. the browser may still load its own"
}

PageSeries()
{
BookPages=${#conconREF[@]}
BookPagesCeiling=$(( 4-(${#conconREF[@]}%4) )) #generated pages rounded to 4, so every paper has all 4 pages identified
SheafPapers=${SheafPapersARG:=16}
SheafRange=$((SheafPapers * 4))
SheafHarmonics=$(( (BookPages+BookPagesCeiling)/SheafRange )) #sheaf 1 range is all that is needed to generate the rest of the series, harmonically
SheafModulus=$(( (BookPages+BookPagesCeiling) % SheafRange)) #sheafmodulus is also the size of the Final Sheaf. which is component to final product
LowerBound=1
UpperBound=$SheafRange
TSStage=($LowerBound $UpperBound)
OpSwitch=(++ --)
#=== base harmonic
for ((trash=0;trash<SheafPapers;trash++)); do #arbitrarily identified series relationship between booklet page and double sided (by whole stack) paper printing
	TransformSet1+=($((TSStage[TextAlignSwitch[1]]${OpSwitch[TextAlignSwitch[1]]}))
                  $((TSStage[TextAlignSwitch[0]]${OpSwitch[TextAlignSwitch[0]]}))) #absolutely hateful method of managing differences in text orientation
	TransformSet2+=($((TSStage[TextAlignSwitch[0]]${OpSwitch[TextAlignSwitch[0]]}))
                  $((TSStage[TextAlignSwitch[1]]${OpSwitch[TextAlignSwitch[1]]})))
done
#=== rest of the harmonics
for ((sheafi=1;sheafi<SheafHarmonics;sheafi++)); do
	for ((TShalf=0;TShalf<(SheafRange/2);TShalf++)) do # base harmonic already made, the rest are functions of it. half is in each array
		TransformSet1+=($((${TransformSet1[$TShalf]} + SheafRange*sheafi)))
		TransformSet2+=($((${TransformSet2[$TShalf]} + SheafRange*sheafi))) #this TransformSet2 must happen after the entirety of half the printing job is finished and the paper has been fed at the correct orientation.(bottom up and over, 180 turn...somersault and cartwheel)
	done
done
#=== modulus, not harmonic
if ((SheafModulus != 0)); then # FinalSheaf; the sheaf that is not a complete harmonic at the end of the book, equal to pages % sheafrange, earlier contrived to be div by 4
	ModTSStage=($(( (BookPages+BookPagesCeiling+1)-SheafModulus ))
	            $(( BookPages+BookPagesCeiling )) ) #Final lower and upper bounds, as defined by final modulus size instead of sheaf size
	for ((finalsheaf=0;finalsheaf<(SheafModulus/4);finalsheaf++)); do
	  TransformSet1+=($((ModTSStage[TextAlignSwitch[1]]${OpSwitch[TextAlignSwitch[1]]}))
		                $((ModTSStage[TextAlignSwitch[0]]${OpSwitch[TextAlignSwitch[0]]})))
		TransformSet2+=($((ModTSStage[TextAlignSwitch[0]]${OpSwitch[TextAlignSwitch[0]]}))
		                $((ModTSStage[TextAlignSwitch[1]]${OpSwitch[TextAlignSwitch[1]]})))
	done
fi
}

PageGen()
{
READKEY=$w #number to check first line location
BookName=${EndoBook[$((10#${indexlinearray[$READKEY]::3}))]} #first values
TempBookName=$BookName 
printf '%s' "$BookName/"
Page=1
constr=(-1) #a header element to correctly track the whitespace added between words eg word#word#word is 3 words and 2 ws. word is 1 word, 0 whitespace
TheWordChapter="Chapter"
message_length=$((${#TheWordChapter}+5)) #2 whitespace and size of 3 dedicated spaces to int "%3d"
paddingQU=$(( (ColAllocW - message_length) / 6 ))
CHtildes="~~~" #"$(for((i=0;i<paddingQU;i++));do printf '%s' \~; done)"

while true; do
while ((${#conconstr[@]} < 2*ColAllocH)); do
	if [[ -z ${sourcelinearray[$MAPKEY]} ]] && (( ${#conconstr[@]} % ColAllocH != ColAllocH - 1)); then # math to find the (not) last line of either column
		if [[ $READKEY -lt $BOOKCAP ]]; then
			Read
		else
			break 2 #the break that finalizes whole function
		fi
	elif [[ -z ${sourcelinearray[$MAPKEY]} ]]; then #is last line of column, terminate column on finished sentence
		conconstr+=("${constr[*]:1}")
		constr=(-1)
	elif (( constr+1+${#sourcelinearray[$MAPKEY]} > ColAllocW )); then #line is full, print and reloop
(( constr>ColAllocW )) && printf '%s\n' "constr should never be bigger than page alloc, fail at ${LINENO} check" "${constr[1]}" && exit #debug
		if ((MAPKEY!=1)); then #key is 1 here when the word after VerseNO element broke the line, this regresses it
		conconstr+=("${constr[*]:1}")
		constr=(-1)
		else
		conconstr+=("${constr[*]:1:$((${#constr[@]}-2))}") #minus the first and last element
		constr=(-1 "${constr[@]: -1}")
		fi
	else # ! last line ! empty source line. build line
		constr+=("${sourcelinearray[$MAPKEY]}")
		((constr+=${#sourcelinearray[$MAPKEY]}+1)) #word size + space
		((MAPKEY++))
		((wordcount++))
	fi
done #while < 2*ColAllocH
#==== Page filled, print
	if ((${#conconstr[@]}==2*ColAllocH)); then
		eval "concon$Page=(\"$BookName@$TempBookName\" \"\${conconstr[@]}\")"
		conconREF+=("concon$Page[@]")
		TempBookName=""
		unset conconstr
		((Page++))
	fi
done #while true

#=== final page print
printf '\n%s\n' "FINAL LINE -${sourcelinearray[*]}- PAGE COUNT ${#conconREF[@]}" #debug
	eval "concon$Page=(\"$BookName@$TempBookName\" \"\${conconstr[@]}\")"
	conconREF+=("concon$Page[@]")
	TempBookName=""
	unset conconstr
}

Read() #new read operations. book change, chapter change, break whole page
{
MAPKEY=0
ReadBook=${EndoBook[$((10#${indexlinearray[$READKEY]::3}))]}
ReadCH=$((10#${indexlinearray[$READKEY]:3:3})) #slicing serial number and turning it base 10
if $LeftToRight; then
VerseNO="[$((10#${indexlinearray[$READKEY]:6:3}))]"
else
[[ $((10#${indexlinearray[$READKEY]:6:3})) =~ (.)(.?)(.?) ]] && VerseNO=]${BASH_REMATCH[3]}${BASH_REMATCH[2]}${BASH_REMATCH[1]}[
fi
sourcelinearray=($VerseNO ${source[$READKEY]})
((wordcount--))# debug. added versenumber word
((pageconcharcount-=1+${#VerseNO})) #debug , 1 space and not 2, because the SOURCEwc \n->' ' is adding the implicit space to source

while ((READKEY<BOOKCAP)); do #next non-empty line in source
	((READKEY++))
	if [[ -n ${source[$READKEY]} ]]; then
		break
	fi
done

if [[ $BookName != $ReadBook ]]; then
	[[ -n "${constr[@]}" ]] && conconstr+=("${constr[*]:1}")
	printf '%s' "$ReadBook/" #debug

	eval "concon$Page=(\"$BookName@$TempBookName\" \"\${conconstr[@]}\")"
	conconREF+=("concon$Page[@]")
	unset conconstr
	((Page++))

	constr=(-1)
	TempBookName=$ReadBook
	BookName=$ReadBook
	ChapterNO=1
	CHBANNERGEN="$($LeftToRight && printf '%s %3d %s' "<div class=\"ChapterHeader\">$CHtildes" $ChapterNO "$CHtildes</div>" || printf '%s %3d %s' "<div class=\"ChapterHeader\">$CHtildes" $ChapterNO "$CHtildes</div>"|rev)"
	conconstr+=("$CHBANNERGEN") #print chapter 1 banner
	((pageconcharcount-=${#CHBANNERGEN}))

	elif (( ChapterNO != ReadCH )); then
	ChapterNO=$ReadCH
	CHBANNERGEN="$($LeftToRight && printf '%s %3d %s' "<div class=\"ChapterHeader\">$CHtildes" $ChapterNO "$CHtildes</div>" || printf '%s %3d %s' "<div class=\"ChapterHeader\">$CHtildes" $ChapterNO "$CHtildes</div>"|rev)"

	if [[ -n $constr ]]; then #print line before adding chapter header
		conconstr+=("${constr[*]:1}")
		constr=(-1)
	fi

	if (( ${#conconstr[@]} % ColAllocH == ColAllocH - 1 )); then #checking for final line in both columns, or 1 before remainder 0
		conconstr+=("")
		constr=($ColAllocW "$CHBANNERGEN") #bignum to trigger line break after being passed back to PageGen
		((pageconcharcount-=${#CHBANNERGEN}))
	else #is not either final column line
		conconstr+=("$CHBANNERGEN")
		((pageconcharcount-=${#CHBANNERGEN}))
	fi
fi #if book!book/Chapter!chapter
}

Cobbler()  #cobble 2 bookletspages/page, 2 pages/paper
{
PAGEKEYS=0
TRANSFORMREFERENCEARRAY=(TransformSet1[@] TransformSet2[@])
PageSeries

IFS=$'\n' IndexPage=("Index@"
$(for ipx in {0..1}; do
	((ipx==0)) && for ((i=0;i<${#BookMeta[@]};i++)); do
		printf '%s\n' "${BookMeta[$i]%%#*}"
	done
	((ipx==1)) && for ((i=0;i<${#BookMeta[@]};i++)); do
		printf '%s\n' "${BookMeta[$i]##*#}"
	done
done)
)

conconREF+=("IndexPage[@]")
for SIDE in {0..1}; do
>$SUBDIR/FINAL$SIDE.html

eval "CurrentTransformCopy=(\${${TRANSFORMREFERENCEARRAY[$SIDE]}})"
PAGEKEYS=0

cat <<-EOF >> "$SUBDIR/FINAL$SIDE.html"
<!DOCTYPE html>
<head>
<meta charset="UTF-8">
<style>
@font-face {
 font-family: '${BookMeta[28]##*#}';
 src: url('../../$FontLink') format('${FontMime[${FontLink##*.}]}');
 font-weight: normal;
 font-style: normal;
}
@page {
 size: A4 landscape;
}
@media print {
 .a4-page {
 break-after: page;
 }
}
body {
 background: #eee;
}
.a4-page {
 background: white;
 width: 297mm;
 height: 210mm;
}
.wrapper0 {
 padding: 0% 2% 0% 2%;
 position: relative;
 float: left;
 height: 100%;
 width: 45%;
 }
.wrapper1 {
 padding: 0% 2% 0% 2%;
 position: relative;
 float: right;
 height: 100%;
 width: 45%;
 }
.pageheader {
 text-align: center;
 font-size: $((FontBoxH < 9 ? FontBoxH+1 : 9))pt;
 border-bottom: 1px solid;
 margin-left: 20%;
 margin-right: 20%;
}
.ChapterHeader {
 text-align: $($LeftToRight && printf justify||printf right);
 font-size: $((FontBoxH < 9 ? FontBoxH+1 : 9))pt;
 display: block;
 margin: 1pt;
 font-weight: bold;
}
.BookHeader {
 text-decoration: underline;
 margin: 2%;
 text-align: center;
 display: block;
 font-family: ${BookMeta[28]##*#},"DejaVu Sans", Courier, mono;
 font-size: $((FontBoxH < 10 ? FontBoxH+3 : 12))pt;
}
.footer {
 font-size: $((FontBoxH < 10 ? FontBoxH : 10))pt;
 position: absolute;
 bottom: 0;
 text-align: center;
 width: 100%;
 margin-bottom: $((FontBoxH < 10 ? FontBoxH : 10))pt;
}
table[is="table${TextAlignSwitch[0]}"] {
 min-width: 50%;
 float: left;
 font-size: ${FontBoxH}pt;
 line-height: $LineSpace;
 border-collapse: collapse;
 border-spacing: 0px;
 }
table[is="table${TextAlignSwitch[1]}"] {
 min-width: 50%;
 float: right;
 font-size: ${FontBoxH}pt;
 line-height: $LineSpace;
 border-collapse: collapse;
 border-spacing: 0px;
 }
#table {
# border-collapse: collapse;
# width: 100%;
# border-spacing: 0px;
# }
tr {
 border-collapse: collapse;
}
td[is="td${TextAlignSwitch[0]}"] {
 padding: 0px 2% 0px 0px;
 text-align: $($LeftToRight && printf justify || printf right);
 font-family: ${BookMeta[28]##*#}, "DejaVu Sans", Courier, mono;
 border-collapse: collapse;
}
td[is="td${TextAlignSwitch[1]}"] {
 padding:0px 0px 0px 2%;
 text-align: $($LeftToRight && printf justify || printf right);
 font-family: ${BookMeta[28]##*#},"DejaVu Sans", Courier, mono;
 border-collapse: collapse;
 border-left: 1px solid;
}
</style>
</head>
EOF

while [[ $PAGEKEYS -lt ${#CurrentTransformCopy[@]} ]]; do

  PAGENO1="${CurrentTransformCopy[((PAGEKEYS++))]:-7777}"
	eval "Page1=(\"\${${conconREF[((PAGENO1-1))]:-7777}}\")"
	BN1=${Page1[0]%%@*} #array header element data
	BH1=${Page1[0]##*@}
	Page1=("${Page1[@]:1}") #slicing out header
	local -i a1=${#Page1[@]}
	local -i b1=$(( (a1-(a1/2))*2 )) # smallest even containing $a
	local -i c1=$((b1/2)) #offset for column 2

	PAGENO2="${CurrentTransformCopy[((PAGEKEYS++))]:-7777}"
	eval "Page2=(\"\${${conconREF[((PAGENO2-1))]:-7777}}\")"
	BN2=${Page2[0]%%@*}
	BH2=${Page2[0]##*@}
	Page2=("${Page2[@]:1}")
	local -i a2=${#Page2[@]}
	local -i b2=$(( (a2-(a2/2))*2 ))
	local -i c2=$((b2/2))

if ! $LeftToRight; then #source RTL text is given LTR, this is the text reversal
[[ $BN1 != "Index" ]] && IFS=$'\n' Page1=($(printf '%s\n' ${Page1[@]}|rev))
[[ $BN2 != "Index" ]] && IFS=$'\n' Page2=($(printf '%s\n' ${Page2[@]}|rev))
fi

	pagecon+=("<div class=\"a4-page\">")
	#===page1
	pagecon+=("<div class=\"wrapper0\"><div class=\"pageheader\">$BN1</div><div class=\"BookHeader\">$BH1</div><table is=\"table0\">")
	for ((i=0;i<c1;i++)); do
	pagecon+=("<tr><td is=\"td0\">${Page1[$i]}</td></tr>")
	((pageconcharcount+=${#Page1[$i]}))
	done
	pagecon+=("</table><table is=\"table1\">")
	for ((i=0;i<c1;i++)); do
	pagecon+=("<tr><td is=\"td1\">${Page1[$((i+c1))]}</td></tr>")
	((pageconcharcount+=${#Page1[$((i+c1))]}))
	done
	pagecon+=("</table><div class=\"footer\">$PAGENO1</div></div>")
	#===page2
	pagecon+=("<div class=\"wrapper1\"><div class=\"pageheader\">$BN2</div><div class=\"BookHeader\">$BH2</div><table is=\"table0\">")
	for ((i=0;i<c2;i++)); do
	pagecon+=("<tr><td is=\"td0\">${Page2[$i]}</td></tr>")
	((pageconcharcount+=${#Page2[$i]}))
	done
	pagecon+=("</table><table is=\"table1\">")
	for ((i=0;i<c2;i++)); do
	pagecon+=("<tr><td is=\"td1\">${Page2[$((i+c2))]}</td></tr>")
	((pageconcharcount+=${#Page2[$((i+c2))]}))
	done
	pagecon+=("</table><div class=\"footer\">$PAGENO2</div></div>")
	#===
	pagecon+=("</div>") #a4-page div

	printf '%s\n' "${pagecon[@]}" >> $SUBDIR/FINAL$SIDE.html
	unset pagecon

	printf '%s ' "($PAGENO1:${#Page1[@]} $PAGENO2:${#Page2[@]})" >> $LOGFILE #debug
done #while key<
done #for 0 1
}

#=========== main
INIT
DocumentRules
mkdir -p "$SUBDIR"
PageGen "$1"
Cobbler
#============ debug
#if ((wordcount != ${SOURCEwc[0]})); then
#	echo "SOURCE WORD COUNT DOES NOT MATCH, forcefully cleaning files to prevent perverted output"
#	echo "check source material for \* or \~ characters"
#	rm -r $SUBDIR/FINAL*
#fi
printf '%s\n' \
"Pages generated: ${#conconREF[@]}" \
"Bookpages: ${BookPages}+$BookPagesCeiling" \
"elapsed seconds: $(($(date +%s)-dateserial))" \
"sourcewordcount: ${SOURCEwc[0]}" \
"wordcount: $wordcount" \
"sourcecharcount: ${SOURCEwc[1]}" \
"pageconcharcount: $pageconcharcount" \
"sourceworddiff: $((${SOURCEwc[1]}-pageconcharcount))" \
"set1: ${TransformSet1[*]}" \
"set2: ${TransformSet2[*]}" \
"READKEY/$READKEY lastbook/$BookName" \
\} >> $LOGFILE
printf '%s\n' "files located in:" "$SUBDIR"
