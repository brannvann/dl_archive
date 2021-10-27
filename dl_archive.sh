#!/bin/bash

baseurl="https://archive.org/details/"
magazine="computerpress"

if [[ -n "$1" ]]; 
then
	magazine="$1"
else
	echo "usage: $0 collection_name"
	exit
fi

if [ ! -d "$magazine" ]; then
	echo "create directory $magazine" 
	mkdir "$magazine"
fi
if [ ! -d "$magazine" ]; then
	echo "cannot create directory $magazine" 
	exit
fi
cd "$magazine"

filelist="$magazine""_filelist.txt"
> "$filelist"

page_number=1
fetching_flag=true
while $fetching_flag
do
	detail_url="$baseurl$magazine?&sort=-week&page=$page_number"
	
	echo "read $detail_url"
	detail_page=`curl -s $detail_url`
	
	detail_list=`echo "$detail_page" | grep "<a href=" | grep "details" | grep " title=" | awk -F"\"" '{print $2}' | awk -F"/" '{print $3}'`
	echo "$detail_list" | while read -r line; do
		if((${#line} > 1)) 
		then
			issue_url="$baseurl$line"
			issue_page=`curl -s $issue_url`
			issue_ref=`echo "$issue_page" | grep "href=\"/download/" | grep "stealth" | grep "text[.]pdf"`
			if [ -z "${issue_ref}" ]; then
				issue_ref=`echo "$issue_page" | grep "href=\"/download/" | grep "stealth" | grep "[.]pdf"`
			fi
			if [ -z "${issue_ref}" ]; then
				issue_ref=`echo "$issue_page" | grep "href=\"/download/" | grep "stealth" | grep "[.]djvu"`
			fi
			if [ -z "${issue_ref}" ]; then
				echo "cannot get link to $line"
			fi
			if [ -n "${issue_ref}" ]; then
				pdfname="https://archive.org"`echo "$issue_ref" | awk -F"\"" '{print $4}'`
				echo "$pdfname"
				echo "$pdfname" >> "$filelist"
			fi
		fi
	done

	if `echo "$detail_page" | grep -q -s "Fetching more results"`; 
	then
		page_number=$((page_number+1)) 
	else
		fetching_flag=false
	fi

done

if [[ -n "$2" ]]; then
	wget -nc -c -i "$filelist"
fi




