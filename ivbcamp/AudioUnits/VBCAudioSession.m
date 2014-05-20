//
//  VBCAudioSession.m
//  ivbcamp
//
//  Created by Octavian Stirbei on 5/20/14.
//  Copyright (c) 2014 Octavian Stirbei. All rights reserved.
//

#import "VBCAudioSession.h"

#import "AudioDataProcessor.h"

#define kOutputBus 0
#define kInputBus 1

#pragma mark - C methods

void checkStatus(int status){
	if (status) {
		printf("Status not 0! %d\n", status);
        //		exit(1);
	}
}

#pragma mark - Audio IO callbacks

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
	// Because of the way our audio format (setup below) is chosen:
	// we only need 1 buffer, since it is mono
	// Samples are 16 bits = 2 bytes.
	// 1 frame includes only 1 sample
    
    VBCAudioSession *audioSession = (__bridge VBCAudioSession*)inRefCon;
    AudioDataProcessor *audioProcessor = [AudioDataProcessor sharedInstance];
    
	AudioBuffer buffer;
	
	buffer.mNumberChannels = 1;
	buffer.mDataByteSize = inNumberFrames * 2;
	buffer.mData = malloc( inNumberFrames * 2 );
	
	// Put buffer in a AudioBufferList
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
	
    // Then:
    // Obtain recorded samples
	
    OSStatus status;
	
    status = AudioUnitRender([audioSession audioSessionInstance],
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
	checkStatus(status);
	
    // Now, we have the samples we just read sitting in buffers in bufferList
	// Process the new data
	[audioProcessor processRawInputData:&bufferList];
	
	// release the malloc'ed data in the buffer we created earlier
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
static OSStatus playbackCallback(void *inRefCon,
								 AudioUnitRenderActionFlags *ioActionFlags,
								 const AudioTimeStamp *inTimeStamp,
								 UInt32 inBusNumber,
								 UInt32 inNumberFrames,
								 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
    [[AudioDataProcessor sharedInstance] processOutput:ioData];
	
    return noErr;
}


@implementation VBCAudioSession

#pragma mark - Initialization
- (id)init {
    if((self = [super init])) {
        [self configAudioSession];
    }
    return self;
}

+ (VBCAudioSession*)sharedInstance {
    static VBCAudioSession *sharedVBCAudioSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //        [NSThread sleepForTimeInterval:2];
        sharedVBCAudioSession = [[VBCAudioSession alloc] init];
        NSLog(@"Singleton has memory address at: %@", sharedVBCAudioSession);
        //        [NSThread sleepForTimeInterval:2];
    });
    return sharedVBCAudioSession;
}

#pragma mark - deallocation

//No need on ARC enable

#pragma mark - setup

- (void)configAudioSession {
    [self setAudioSessionInstance];
    [self enableRecordingIO];
    [self enablePlaybackIO];
    [self setStreamBasicDescription];
	[self setIOCallbacks];
    [self disableRecorderBufferAllocation];
    [self setAudioDataLength];
    [self initializeAudioInstance];
}

- (void)setAudioSessionInstance {
    OSStatus status;
	
	// Describe audio component
	AudioComponentDescription desc;
    memset(&desc, 0, sizeof(desc));
    
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &_audioSessionInstance);
    checkStatus(status);
}

- (void)enableRecordingIO {
    OSStatus status;
	UInt32 flag = 1;
	// Enable IO for recording
	status = AudioUnitSetProperty(_audioSessionInstance,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Input,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	checkStatus(status);
}

- (void)enablePlaybackIO {
    OSStatus status;
	UInt32 flag = 1;
	// Enable IO for playback
	status = AudioUnitSetProperty(_audioSessionInstance,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Output,
								  kOutputBus,
								  &flag,
								  sizeof(flag));
	checkStatus(status);
}

- (void)applyAudioFormat:(AudioStreamBasicDescription)audioFormat inScope:(AudioUnitScope)inScope inBus:(AudioUnitElement)kBus {
    OSStatus status;
	status = AudioUnitSetProperty(_audioSessionInstance,
								  kAudioUnitProperty_StreamFormat,
								  inScope,
								  kBus,
								  &audioFormat,
								  sizeof(audioFormat));
	checkStatus(status);
    
}

- (void)setStreamBasicDescription {
	// Describe format
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mBitsPerChannel		= 8 * sizeof(AudioSampleType);
	audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBytesPerFrame    = audioFormat.mChannelsPerFrame * sizeof(AudioSampleType);
    audioFormat.mBytesPerPacket   = audioFormat.mBytesPerFrame;
	// Apply format recording
	[self applyAudioFormat:audioFormat inScope:kAudioUnitScope_Output inBus:kInputBus];
	// Apply format playback
	[self applyAudioFormat:audioFormat inScope:kAudioUnitScope_Input inBus:kOutputBus];
}

- (void)setIOCallback:(AURenderCallback)callback propertyId:(AudioUnitPropertyID)propertyId inScope:(AudioUnitScope)inScope inBus:(AudioUnitElement)kBus {
    OSStatus status;
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = callback;
	callbackStruct.inputProcRefCon = (__bridge void*) self;
	status = AudioUnitSetProperty(_audioSessionInstance,
								  propertyId,
								  inScope,
								  kBus,
								  &callbackStruct,
								  sizeof(callbackStruct));
	checkStatus(status);
}

- (void)setIOCallbacks {
	// Set input callback
    [self setIOCallback:recordingCallback propertyId:kAudioOutputUnitProperty_SetInputCallback inScope:kAudioUnitScope_Global inBus:kInputBus];
	// Set output callback
    [self setIOCallback:playbackCallback propertyId:kAudioUnitProperty_SetRenderCallback inScope:kAudioUnitScope_Global inBus:kOutputBus];
}

- (void)disableRecorderBufferAllocation {
    OSStatus status;
	UInt32 flag = 0;
	// Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
	status = AudioUnitSetProperty(_audioSessionInstance,
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	checkStatus(status);
}

- (void)setAudioDataLength {
    /* Set the preferred buffer time */
    Float32 preferredBufferTime = 512.0 / 44100.0;
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,
                            sizeof(preferredBufferTime), &preferredBufferTime);
}

- (void)initializeAudioInstance {
    OSStatus status = AudioUnitInitialize(_audioSessionInstance);
	checkStatus(status);
}

#pragma mark - Control

- (void)startCapture {
	OSStatus status = AudioOutputUnitStart(_audioSessionInstance);
	checkStatus(status);
}

- (void)stopCapture {
	OSStatus status = AudioOutputUnitStop(_audioSessionInstance);
	checkStatus(status);
}

@end
