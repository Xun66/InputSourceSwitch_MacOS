//
//  main.m
//  InputSourceSwitchCLI v1.0
//
//  Created by Zhuang Tao on 2020/2/28.
//  Copyright © 2020 Zhuang Tao. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <unistd.h>
@import Carbon;

NSArray* loadAvailableInputSourcesList(BOOL all){
    // all - Show only enabled methods
    NSArray* sources = CFBridgingRelease(TISCreateInputSourceList(NULL, all));
    return sources;
}

NSObject* getPropN(TISInputSourceRef source, CFStringRef prop){
    return (__bridge NSObject*) TISGetInputSourceProperty(source, prop);
}

BOOL isTypeValid(TISInputSourceRef source){
    NSString* sourceType = (NSString*) getPropN(source, kTISPropertyInputSourceType);
    BOOL isInpMode = [sourceType compare:@"TISTypeKeyboardInputMode"] == NSOrderedSame;
    BOOL isLayout = [sourceType compare:@"TISTypeKeyboardLayout"] == NSOrderedSame;
    return isInpMode || isLayout;
}

BOOL isSelectCapable(TISInputSourceRef source){
    NSNumber* isSelectCapable = (NSNumber*) getPropN(source, kTISPropertyInputSourceIsSelectCapable);
    return isSelectCapable.boolValue;
}

BOOL isSelected(TISInputSourceRef source){
    // but some sources are always marked as selected
    NSNumber* isSelectCapable = (NSNumber*) getPropN(source, kTISPropertyInputSourceIsSelectCapable);
    NSNumber* isSelected = (NSNumber*) getPropN(source, kTISPropertyInputSourceIsSelected);
    return isSelectCapable.boolValue && isSelected.boolValue;
}

BOOL isEnabled(TISInputSourceRef source){
    NSNumber* isEnableCapable =  (NSNumber*) getPropN(source, kTISPropertyInputSourceIsEnableCapable);
    NSNumber* isEnabled =  (NSNumber*) getPropN(source, kTISPropertyInputSourceIsEnabled);
    return isEnableCapable.boolValue && isEnabled.boolValue;
}

BOOL isCandidate(TISInputSourceRef source){
    return isTypeValid(source) && isSelectCapable(source) && isEnabled(source);
}

TISInputSourceRef getCurrentSource(NSArray* sources){
    TISInputSourceRef source;
    for(int i=0; i<sizeof(sources); ++i){
        source = (__bridge TISInputSourceRef)(sources[i]);
        if(isSelected(source)&&isTypeValid(source))
            return source;
    }
    perror("error");
    return NULL;
}

void printSourceID(TISInputSourceRef source){
    // Unused
    printf("%s\n", [(NSString*) getPropN(source, kTISPropertyInputSourceID) UTF8String]);
}

void printSourceSummary(TISInputSourceRef source){
    char* sourceID = (char*)[(NSString*) getPropN(source, kTISPropertyInputSourceID) UTF8String];
    char* sourceName = (char*)[(NSString*) getPropN(source, kTISPropertyLocalizedName) UTF8String];
    char* sourceType = (char*)[(NSString*) getPropN(source, kTISPropertyInputSourceCategory) UTF8String];
    NSString* sourceStatus = @"     _";
    
    if(!isSelectCapable(source)){
        sourceStatus = @"Selc X"; // Can't Select
    }else if (!isEnabled(source)){
        sourceStatus = @"Enab X"; // Disabled
    }else if(!isTypeValid(source)){
        sourceStatus = @"Type X"; // N/A
    }else if(isCandidate(source) && isSelected(source)){
        sourceStatus = @"Cur  *"; // Current
    }
    printf("[%6s] %-40s\t%s\t%s\n", [sourceStatus UTF8String], sourceID, sourceType, sourceName);
}

void printSourceDetail(TISInputSourceRef source){
    // Pass
}

void printSources (BOOL allInstalled, BOOL allTypes, BOOL limitCurrent, BOOL onlyID){
    NSArray * sources = loadAvailableInputSourcesList(allInstalled);
    TISInputSourceRef source;
    for(int i=0; i<sources.count; ++i){
        source = (__bridge TISInputSourceRef)(sources[i]);
        if(allTypes || isCandidate(source)){
            if(!limitCurrent || (isCandidate(source) && isSelected(source))){
                if(onlyID){
                    printSourceID(source);
                }else{
                    printSourceSummary(source);
                }
            }
        }
    }
}

int MLSelectInputSource(NSString* layout){
    NSArray* sources = CFBridgingRelease(TISCreateInputSourceList((__bridge CFDictionaryRef)@{
                (__bridge NSString*) kTISPropertyInputSourceID : layout}, FALSE));
    if(sources.count){
        TISInputSourceRef source = (__bridge TISInputSourceRef) sources[0];
        OSStatus status = TISSelectInputSource(source);
        if (status != noErr){
            perror("Failed to set Input source");
            return -2;
        }
    }else{
        printf("Not found: %s", layout.UTF8String);
        return -3;
    }
    return 0;
}

void version (){
    printf("InputSourceSwitchCLI v1.0 \nComplie date %s\n", __DATE__);
}

void usage(char* argv[]) {
    NSArray *aArray = [@(argv[0]) componentsSeparatedByString:@"/"];
    NSString* exec = aArray[aArray.count - 1];
    
    printf("Usage:\n");
    printf("\t%s [-l] [-aiud]\n", [exec UTF8String]);
    printf("\t%s [-c layoutID]\n", [exec UTF8String]);
    printf("Options:\n");
    printf("\t-l List input sources\n");
    printf("\t-a :include unselectable sources\n");
    printf("\t-i :include disabled sources\n");
    printf("\t-u :display only current input source\n");
    printf("\t-d :display only source ID\n");
    printf("\t-c switch to a specific layout (e.g com.apple.keylayout.ABC)\n");
    printf("\t-v display program version\n");
    printf("\t-h display this help\n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        int o;
        const char *optstring = "laiudc:vh";
        BOOL allInstalled = FALSE, allTypes = FALSE, limitCurrent = FALSE, onlyID = FALSE,
            actList = FALSE, actSelect = FALSE;
        NSString* layout = NULL;
        
        if(argc == 1){
            usage(argv);
            return -4;
        }
        
        while ((o = getopt(argc, argv, optstring)) != -1) {
            switch (o) {
                case 'l':
                    actList = TRUE;
                    break;
                case 'a':
                    allTypes = TRUE;
                    break;
                case 'i':
                    allInstalled = TRUE;
                    break;
                case 'u':
                    limitCurrent = TRUE;
                    break;
                case 'd':
                    onlyID = TRUE;
                    break;
                case 'c':
                    actSelect = TRUE;
                    layout = @(optarg);
                    break;
                case 'v':
                    version();
                    return 0;
                case 'h':
                    usage(argv);
                    return 0;
                case '?':
                    usage(argv);
                    return -5;
                    // printf("error optopt: %c\n", optopt);
                    // printf("error opterr: %d\n", opterr);
                    break;
            }
        }

        if(actList){
            printSources(allInstalled, allTypes, limitCurrent, onlyID);
        }else if(actSelect){
            return MLSelectInputSource(layout);
        }else{
            printf("Must specify an action: -l list or -c select.");
            usage(argv);
            return -4;
        }
        return 0;
    }
}
