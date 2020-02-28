# InputSourceSwitchCLI
This is a small command line tool for MacOS. It's main purpose is to auto switch to ascii input source when opening a new terminal window, if you also use some other non-ascii input methods.  

### Features
* List avaliable input sources
* List all input sources
* List current input source
* Show only the source ID instead of summary
* Switch to specific input source

### Usage
```
Usage:
	InputSourceSwitchCLI [-l] [-auid]
	InputSourceSwitchCLI [-c layoutID]
Options:
	-l List input sources
	-a :include unselectable sources
	-i :include disabled sources
	-u :display only current input source
	-d :display only source ID
	-c switch to a specific layout (e.g com.apple.keylayout.ABC)
	-v display program version
	-h display this help
```

### Examples  
* Show available sources: `InputSourceSwitchCLI -l`
* Show current source ID: `InputSourceSwitchCLI -lud`
* Switch to source: `InputSourceSwitchCLI -c com.apple.keylayout.ABC`

### Notes
* Release built with XCode 11.3
* ~~写啥Makefile, 要啥自行车啊, 反正是也不懂oc，自己能用就行了~~
* ~~早知道GitHub有类似的项目谁写这个啊:(~~