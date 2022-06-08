#!/bin/sh
###
# Shell script to update Domain Name O3API / O3WEBAPP  with the right IP
# One HAS TO provide O3API_SITE_SECRET and O3WEB_SITE_SECRET as ENV variables!
# Optionally one can also redefine O3API_SITE and O3WEB_SITE
###

###
# default sites for o3api and o3webapp
o3api_site=api.o3as.fedcloud.eu
o3web_site=web.o3as.fedcloud.eu
###

# function to check if SITE responds, if not => update IP via nsupdate service
check_hostname()
{
  site=$1
  secret=$2

  response=$(curl -s -o /dev/null -w "%{http_code}"  https://${site})

  if [ $response -eq 200 ]; then
     message="is responding, do NOT update IP"
  else
     message=$(curl https://${site}:${secret}@nsupdate.fedcloud.eu/nic/update)
  fi
  echo "${site}: CODE ${response} : ${message}"
}

# one can define O3API_SITE and O3WEB_SITE via Environment Variables
# if not defined => use default values provided above
if [ ${#O3API_SITE} -le 1 ]; then
  O3API_SITE=${o3api_site}
fi
if [ ${#O3WEB_SITE} -le 1 ]; then 
  O3WEB_SITE=${o3web_site}
fi

# one has to define correct O3API_SITE_SECRET and O3WEB_SITE_SECRET via ENV Variables
# if not defined => use dummy ones for proper function calling, BUT
# nsupdate will NOT provide proper hostnames (you need right secrets)!
if [ ${#O3API_SECRET} -le 1 ]; then
  O3API_SITE_SECRET="dummysecret"
fi
if [ ${#O3WEB_SECRET} -le 1 ]; then
  O3WEB_SITE_SECRET="dummysecret"
fi

echo $(date +"%F %T %Z")

check_hostname $O3API_SITE $O3API_SITE_SECRET
check_hostname $O3WEB_SITE $O3WEB_SITE_SECRET
