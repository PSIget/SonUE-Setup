@Echo Off
Color 0B

Title Packed FreeArc
@Echo.****************************************************
@Echo.*                                                  *
@Echo.*                  Packed FreeArc                  *
@Echo.*                                                  *
@Echo.****************************************************
TimeOut 2

CLS

SET STARTTIME=%TIME%
bin\Arc.exe create -r -di -i2 -ep1 -m9x -ld=192m -s256m "Output\Data.arc" "Input\*.*"
SET ENDTIME=%TIME%

FOR /F "tokens=1-4 delims=:.," %%a IN ("%STARTTIME%") DO (SET /A "START=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100")
FOR /F "tokens=1-4 delims=:.," %%a IN ("%ENDTIME%") DO (SET /A "END=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100")
SET /A elapsed=END-START
SET /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
IF %hh% lss 10 SET hh=0%hh%
IF %mm% lss 10 SET mm=0%mm%
IF %ss% lss 10 SET ss=0%ss%
IF %cc% lss 10 SET cc=0%cc%
SET DURATION=%hh%:%mm%:%ss%,%cc%

@ECHO.*****************************************************
@ECHO.*                                                   *
@ECHO.*           Started Pack  : %STARTTIME%             *
@ECHO.*           Finished Pack : %ENDTIME%             *
@ECHO.*                                                   *
@ECHO.*           Total  Time   : %DURATION%             *
@ECHO.*                                                   *
@ECHO.*****************************************************
@ECHO.

Pause
