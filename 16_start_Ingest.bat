@TITLE EMA Ingest %4 %6 in progress... 
<Sonal>
@ECHO OFF
REM ---------------------------------------------------------------------
REM Ingestion Delta/Retry
REM ---------------------------------------------------------------------

if "%~5"=="" (
	echo.
	echo Starts the EMA Ingest in Retry/Delta Mode which produces the FileCopyList for later processing 
	echo.
    echo. %0 runID repository environment mode baseRunID dry-run_mode
	echo.
	echo.	runID			Number of the run used as prefix to distinct individual runs
	echo.	repository		Name of the repository in caps used prefixes and target in several locations
	echo.	environment		Name of the environment in caps starwhich configuration subdirectory should be used
	echo.	mode			Ingestion mode to be used either DELTA or RESTART
	echo.	baseRunID		RunID which was used for the initial ingestion as a base for this delta or restart
	echo.	dry-run_mode		Optional parameter to tell EMA to run in dry-run mode. Produced FileCopyList will not contain
	echo.				valid target storageIDs! 
	echo.
	echo. For example:
	echo.
	echo.	%0 5 xEDI_JP DEV DELTA 5
	echo.	%0 37 xEDI_CH TST RESTART 37 --dry-run
	echo.
    goto :eof
)

REM TODO add RESTART functionality

REM Parse batch Parameters

REM Prefix the runID with leading zeros to receive 0001 - 9999
SET RUN_ID=000%1
SET RUN_ID=%RUN_ID:~-4%

SET REPOSITORY=%2

SET ENVIRONMENT=%3

SET MODE=%4

SET BASE_RUN_ID=000%5
SET BASE_RUN_ID=%BASE_RUN_ID:~-4%

SET DRY_RUN=%6

REM set common environment parameters
CALL config\setenv.bat





REM EMA Ingestion Parameters
REM ------------------



SET LOG_TIMESTAMP=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%
SET LOG_TIMESTAMP=%LOG_TIMESTAMP: =0%

SET EMA_ACTION=INGEST


REM Target Ingestion Parameters

SET EMA_IN_LOG4J_CONFIG_FILE=file:%EMA_CONFIG_ROOT%\log4j.properties

REM SET EMA_IN_STORAGE_MAP_FILE=%EMA_CONFIG_ROOT%\%ENVIRONMENT%\%REPOSITORY%.storagemap.properties
SET EMA_IN_STORAGE_MAP_FILE=%EMA_CONFIG_ROOT%\storagemap.%REPOSITORY%.properties


REM Mongo Parameters

SET STG_DB_NAME=%RUN_ID%_%REPOSITORY%

REM SET STG_DB_DUMP=%STG_DB_NAME%_RESTART
SET STG_DB_DUMP=%BASE_RUN_ID%_%REPOSITORY%_RESTART

SET LOST_FOUND=/m_ema_migration/%REPOSITORY%/Lost+Found


SET FILE_COPY_LIST=%EMA_ROOT%\data\%RUN_ID%_%REPOSITORY%.FileCopyList



REM Print out header

ECHO.
ECHO Performing action:		%EMA_ACTION% %DRY_RUN%
ECHO Running mode:			%MODE%
ECHO Using database: 		%STG_DB_NAME%
ECHO Using baseline: 		%STG_DB_DUMP%
ECHO Start timestamp:		%LOG_TIMESTAMP%
ECHO.
ECHO.

CALL:startIngest %REPOSITORY%

@TITLE EMA Ingest %MODE% %DRY_RUN% completed. 
REM PAUSE & GOTO:EOF
GOTO:EOF

REM Start Ingestion

:startIngest
ECHO Processing: %~1
TIME /T

java -Doptions.default=%OPTIONS_DEFAULT% -cp %CLASSPATH% com.emc.ema.ingestor.IngestManager --action %EMA_ACTION% --mode %MODE% --mongo-db %STG_DB_NAME% --storage-map %EMA_IN_STORAGE_MAP_FILE% --file-copy-list %FILE_COPY_LIST% --preload-dbs %STG_DB_DUMP% --lost-found %LOST_FOUND%  %DRY_RUN% > %LOG_PATH%\%RUN_ID%_%LOG_TIMESTAMP%_%EMA_ACTION%_%MODE%_%REPOSITORY%.log 2> %LOG_PATH%\%RUN_ID%_%LOG_TIMESTAMP%_%EMA_ACTION%_%MODE%_%REPOSITORY%_err.log
REM java -Doptions.default=%OPTIONS_DEFAULT% -cp %CLASSPATH% com.emc.ema.ingestor.IngestManager --action %EMA_ACTION% --mode %MODE% --mongo-db %STG_DB_NAME% --storage-map %EMA_IN_STORAGE_MAP_FILE% --file-copy-list %FILE_COPY_LIST% --preload-dbs %STG_DB_DUMP% --lost-found %LOST_FOUND%  %DRY_RUN% --no-batch > %LOG_PATH%\%RUN_ID%_%LOG_TIMESTAMP%_%EMA_ACTION%_%MODE%_%REPOSITORY%.log 2> %LOG_PATH%\%RUN_ID%_%LOG_TIMESTAMP%_%EMA_ACTION%_%MODE%_%REPOSITORY%_err.log

TIME /T
ECHO.
GOTO:EOF

