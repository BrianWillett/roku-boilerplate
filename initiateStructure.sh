#!/bin/bash
#get the script's directory credit to Dave Dopson for the directory script that works with symlinking
#https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  TARGET="$(readlink "$SOURCE")"
  if [[ $TARGET == /* ]]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET"
  fi
done
RDIR="$( dirname "$SOURCE" )"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

if [ -z "$1" ]; then
  echo
  echo "Please enter a project name"
  echo
  exit 1
fi

#check if folder already exists
if [ -d "$1" ]; then
  echo ""
  echo "$1 already exists, please choose a different name."
  echo ""
else

#Create File Dirs
echo "Creating directory " $1
mkdir $1
#move placeholder images to the new directory
cp -R $DIR/images $1/
cd $1

echo "Initializing git repo"
git init

echo "Creating gitignore"
touch .gitignore

echo "Writing gitignore"
printf "node_modules
dist
out
.roku-deploy-staging
.DS_Store
.env" >> .gitignore

echo "Creating .vscode directory"
mkdir .vscode

cd .vscode

echo "Creating launch.json"
touch launch.json

echo "Writing launch.json"
printf "{
// Use IntelliSense to learn about possible attributes.
// Hover to view descriptions of existing attributes.
// For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
\"version\": \"0.1.0\",
\"configurations\": [
  {
    \"type\": \"brightscript\",
    \"request\": \"launch\",
    \"name\": \"BrightScript Debug: Launch\",
    \"stopOnEntry\": false,
    \"host\": \"\${promptForHost}\",
    \"password\": \"\${promptForPassword}\",
    \"rootDir\": \"\${workspaceFolder}/dist/\",
    //run the BrighterScript build before each launch
    \"preLaunchTask\": \"build\",
    \"enableDebuggerAutoRecovery\": true,
    \"stopDebuggerOnAppExit\": false,
    \"injectRaleTrackerTask\": true
  },
  {
    \"type\": \"brightscript\",
    \"request\": \"launch\",
    \"name\": \"BrightScript Debug: Launch From ENV\",
    \"stopOnEntry\": false,
    \"envFile\": \"\${workspaceFolder}/.env\",
    \"host\": \"\${env:ROKU_HOST}\",
    \"password\": \"\${env:ROKU_PASSWORD}\",
    \"rootDir\": \"\${workspaceFolder}/dist/\",
    //run the BrighterScript build before each launch
    \"preLaunchTask\": \"build\",
    \"enableDebuggerAutoRecovery\": true,
    \"stopDebuggerOnAppExit\": false,
    \"injectRaleTrackerTask\": true
  }
]
}" >> launch.json

echo "Creating tasks.json"
touch tasks.json

echo "Writing tasks.json"
printf "{
  \"version\": \"2.0.0\",
  \"tasks\": [
      {
          \"label\": \"build\",
          \"command\": \"npm\",
          \"type\": \"shell\",
          \"group\": {
              \"kind\": \"build\",
              \"isDefault\": true
          },
          \"args\": [
              \"run\",
              \"build\"
          ]
      }
  ]
}" >> tasks.json

cd .. #Back to root level

# echo "Creating out directory"
# mkdir out

echo "Creating src directory"
mkdir src
cd src

echo "Creating assets directory"
mkdir assets
cd assets

echo "Creating assets sub directories"
mkdir fonts

cd .. #Back to src level

echo "Creating components directory"
mkdir components

cd components

echo "Creating component directories and files"
mkdir Managers
mkdir Modules
mkdir Scenes

cd Scenes

mkdir Main

cd Main

touch Main.brs

printf "sub init()
  onOpen()
end sub

sub onOpen()
  ' Do Stuff
end sub" >> Main.brs

touch Main.xml

printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<component name=\"Main\" extends=\"Scene\">
  <script type=\"text/brightscript\" uri=\"Main.brs\" />
  <interface>
  </interface>
  <children>
      <Label id=\"helloWorld\" translation=\"[200,200]\" text=\"Hello, World!\" />
  </children>
</component>" >> Main.xml

cd .. #Back to Scenes level
cd .. #Back to Components level

mkdir Screens
mkdir Tasks

cd .. #Back to src level

echo "Creating source directory"
mkdir source
cd source

echo "Creating main.brs"
touch main.brs

echo "Writing main.brs"
printf "sub main(params)

  screen = createObject(\"roSGscreen\")
  port = createObject(\"roMessagePort\")
  screen.setMessagePort(port)

  scene = screen.createScene(\"Main\")
  screen.show() ' vscode_rale_tracker_entry

  while true
      msg = wait(0,port)
      msgType = type(msg)
      if \"roSGScreenEvent\" = msgType
          if msgType.isScreenClose() then return
      end if
  end while
end sub" >> main.brs

echo "Creating utils.brs"
touch utils.brs

cd .. #Back to src level

echo "Creating manifest"
touch manifest

echo "Writing manifest"
printf "#   Channel Details
title=$1
major_version=0
minor_version=1
build_version=00001

##   Channel Assets
###  Main Menu Icons / Channel Poster Artwork
#### Image sizes are FHD: 540x405px | HD: 336x210px | SD: 246x140px
mm_icon_focus_fhd=pkg:/assets/images/channel-poster_fhd.png
mm_icon_focus_hd=pkg:/assets/images/channel-poster_hd.png
mm_icon_focus_sd=pkg:/assets/images/channel-poster_sd.png

###  Splash Screen + Loading Screen Artwork
#### Image sizes are FHD: 1920x1080px | HD: 1280x720px | SD: 720x480px
splash_screen_fhd=pkg:/assets/images/splash-screen_fhd.png
splash_screen_hd=pkg:/assets/images/splash-screen_hd.png
splash_screen_sd=pkg:/assets/images/splash-screen_sd.png

splash_color=#000000
splash_min_time=3000

# Resolution
ui_resolutions=FHD

# Constants
bs_const=DEBUG=true

supports_input_launch=1" >> manifest

cd .. #Back to root level
#move placeholder images to the assets folder
mv images src/assets/

echo "Creating .env"
touch .env

echo "Writing .env"
printf "ROKU_HOST=<Enter Roku IP Here>
ROKU_PASSWORD=<Enter Roku Password Here>" >> .env

echo "Create and populate roku config"
touch .roku_config.json
printf "{
  \"projects\": {
    \"sample\": {
      \"app_name\": \"$1\",
      \"stage_method\": \"script\",
      \"source_files\": [
        \"assets\",
        \"components\",
        \"source\",
        \"manifest\"
      ],
      \"stages\": {
        \"main\": {
          \"key\": \"main\",
          \"script\": {
            \"stage\": \"cp -r ./src/* .\",
            \"unstage\": \"rm -rf manifest source components assets\"
          }
        }
      }
    }
  },
  \"keys\": {
    \"main\": {
      \"keyed_pkg\": \"./keys/key_8537270f33ab76b0e4ce3312f786abe18e9db1f4.pkg\",
      \"password\": \"tO73Km+HNdZCVTD7qJ/1Mg==\"
    }
  }
}" >> .roku_config.json

echo "Create and populate bsconfig.json"
touch bsconfig.json
printf "{
  \"rootDir\": \"src\",
  \"files\": [\"**/*\"],
  \"sourceMap\": true,
  \"stagingFolderPath\": \"dist\",
  \"retainStagingFolder\": true,
  \"diagnosticFilters\": [
    {
      \"src\": \"**/components/Tasks/TrackerTask.xml\",
      \"codes\": [1067]
    }
  ]
}" >> bsconfig.json

echo "Create and populate dist directory"
mkdir dist
cp -R src/ dist

echo "Create and populate package.json"
touch package.json
printf "{
  \"name\": \"$1\",
  \"version\": \"1.0.0\",
  \"description\": \"\",
  \"scripts\": {
    \"build\": \"bsc\",
    \"package\": \"roku --package --stage main -O out -V\"
  },
  \"author\": \"\",
  \"license\": \"ISC\"
}" >> package.json

echo "Installing npm and dependencies"
npm install
npm i brighterscript
#bundle install

#open in code
echo "Opening project in VS Code"
code .
fi