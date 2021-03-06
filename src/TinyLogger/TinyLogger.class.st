"
Description
--------------------

I am the main entry point of the project. This project is build with a composite design pattern and I am the composite. I contains subclasses of TinyLeafLogger.

I am a default instance that is used by default in the image when you send #record to a string for example. This instance should be configured by the user before been used (else it will do nothing). 
It is also possible to create another instance with different loggers and to use it. You can also change the default logger objects will use to record logs with the `TinyCurrentLogger` dynamic variable (See example bellow). 

The user can configure the timestamp formating via the #timestampFormatBlock paramater.

Public API and Key Messages
--------------------

- #record: 						Log the parameter we the sub loggers.
- #execute:recordedAs: 		Execute a block and log the task when it beging and ends. This will increase the identation of the logging.
- #addStdoutLogger 			Add a logger on Stdout
- #addTrascriptLogger 		Add a logger on the Transcript
- #addFileLogger 				Add a logger that will log in a file named `TinyLogger.log`
- #addFileLoggerNamed: 		Add a logger on a file whose name is passed as parameter
- #timestampFormatBlock: 	Give as parameter a block taking a stream as parameter and writing the timestamp you want

Examples
--------------------

	""Add two file loggers, a stdio logger and a transcript logger to the default logger.""
	TinyLogger default
		addTranscriptLogger;
		addStdoutLogger;
		addFileLoggerNamed: 'Test.log';
		addFileLoggerNamed: 'MyOtherLog.log'.
		
	""Record a string via the default logger""
	'My string' record.
	TinyLogger default record: 'My string'.
	
	""Record with nesting via the default logger""
	self execute: [ 1 to: 10 do: [ :value | value asString record ] ] recordedAs: 'Task with only one nesting.'
	
	self execute: [ 
		1 to: 10 do: [ :value1 | 
			self execute: [
				1 to: value1 do: [ :value2 | value2 asString record ]
				] recordedAs: 'My second nest'
			 ]
		 ] recordedAs: 'My first nest'.
	
	""Record with a non default logger""
	TinyLogger new
		addTranscriptLogger;
		record: 'Test'.
	
	""Change the default logger Objects should use during the execution of a subpart of the system""	
	TinyCurrentLogger value: (TinyLogger new addTranscriptLogger; yourself) during: [ 
		'test' record.
		TinyCurrentLogger value record: 'Test2'
	]
		
	""Change the default timestamp format""
	TinyLogger default
		timestampFormatBlock:
			[ :aStream :timestamp | timestamp asDate printOn: aStream. aStream << ' '. ""Cannot use #space because of Stdio streams"" timestamp asTime print24: true on: aStream ].
 
Internal Representation and Key Implementation Points.
--------------------

    Instance Variables
	depth:							<anInteger>		I record the depth level of the nesting.
	loggersMap:					<aDictonary>		I am used to store the loggers. I keep for each kind of loggers a collection of their instances.
	timestampFormatBlock:		<aBlock>			I am a block defining the way the timestamp should be written.

"
Class {
	#name : #TinyLogger,
	#superclass : #TinyAbstractLogger,
	#instVars : [
		'timestampFormatBlock',
		'depth',
		'loggersMap'
	],
	#classVars : [
		'Default'
	],
	#category : #'TinyLogger-Core'
}

{ #category : #accessing }
TinyLogger class >> default [
	^ Default ifNil: [ Default := self new ]
]

{ #category : #accessing }
TinyLogger class >> default: anObject [
	Default := anObject
]

{ #category : #initialization }
TinyLogger class >> reset [
	^ self default: nil
]

{ #category : #'public API' }
TinyLogger >> addFileLogger [
	"Since no file name is passed as parameter, I will log in a file named `TinyLogger.log` next to the image."

	self addLogger: TinyFileLogger new
]

{ #category : #'public API' }
TinyLogger >> addFileLoggerNamed: aString [
	self addLogger: (TinyFileLogger named: aString)
]

{ #category : #'public API' }
TinyLogger >> addLogger: aLogger [
	(self loggersMap at: aLogger kind ifAbsentPut: [ OrderedCollection new ]) add: (aLogger parentLogger: self)
]

{ #category : #'public API' }
TinyLogger >> addStdoutLogger [
	self addLogger: TinyStdoutLogger new
]

{ #category : #'public API' }
TinyLogger >> addTranscriptLogger [
	self addLogger: TinyTranscriptLogger new
]

{ #category : #nesting }
TinyLogger >> decreaseDepthLevel [
	self depth: self depth - 1
]

{ #category : #accessing }
TinyLogger >> defaultTimestampFormatBlock [
	^ [ :aStream :timestamp | aStream << timestamp asString ]
]

{ #category : #accessing }
TinyLogger >> depth [
	^ depth
]

{ #category : #accessing }
TinyLogger >> depth: anObject [
	depth := anObject
]

{ #category : #'public API' }
TinyLogger >> execute: aBlock recordedAs: aString [
	self increaseDepthLevel.
	self record: 'Begin: ' , aString.
	self increaseDepthLevel.
	aBlock cull: aString.
	self decreaseDepthLevel.
	self record: 'End: ' , aString.
	self decreaseDepthLevel
]

{ #category : #'accessing - loggers' }
TinyLogger >> fileLoggers [
	^ self loggersMap at: TinyFileLogger kind ifAbsentPut: [ OrderedCollection new ]
]

{ #category : #nesting }
TinyLogger >> increaseDepthLevel [
	self depth: self depth + 1
]

{ #category : #initialization }
TinyLogger >> initialize [
	super initialize.
	self depth: 0.
	self timestampFormatBlock: self defaultTimestampFormatBlock.
	self loggersMap: Dictionary new
]

{ #category : #accessing }
TinyLogger >> loggers [
	"Since the loggers variable contains a dictionary of loggers, here we faltten the dictonary."

	^ self loggersMap values flatCollect: #yourself
]

{ #category : #accessing }
TinyLogger >> loggersMap [
	^ loggersMap
]

{ #category : #accessing }
TinyLogger >> loggersMap: anObject [
	loggersMap := anObject
]

{ #category : #'public API' }
TinyLogger >> record: aString [
	self loggers do: [ :each | each record: aString ]
]

{ #category : #'public API' }
TinyLogger >> removeAllLoggers [
	self loggers do: [ :each | self removeLogger: each ]
]

{ #category : #'public API' }
TinyLogger >> removeFileLoggers [
	self fileLoggers removeAll
]

{ #category : #'public API' }
TinyLogger >> removeLogger: aLogger [
	(self loggersMap at: aLogger kind ifAbsentPut: [ OrderedCollection new ]) remove: aLogger
]

{ #category : #'public API' }
TinyLogger >> removeStdoutLoggers [
	self stdoutLoggers removeAll
]

{ #category : #'public API' }
TinyLogger >> removeTranscriptLoggers [
	self transcriptLoggers removeAll
]

{ #category : #'accessing - loggers' }
TinyLogger >> stdoutLoggers [
	^ self loggersMap at: TinyStdoutLogger kind ifAbsentPut: [ OrderedCollection new ]
]

{ #category : #accessing }
TinyLogger >> timestampFormatBlock [
	^ timestampFormatBlock
]

{ #category : #accessing }
TinyLogger >> timestampFormatBlock: anObject [
	timestampFormatBlock := anObject
]

{ #category : #'accessing - loggers' }
TinyLogger >> transcriptLoggers [
	^ self loggersMap at: TinyTranscriptLogger kind ifAbsentPut: [ OrderedCollection new ]
]

{ #category : #'public API' }
TinyLogger >> withDefaultLoggers [
	self
		removeAllLoggers;
		addTranscriptLogger;
		addStdoutLogger;
		addFileLogger
]
