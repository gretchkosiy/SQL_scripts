
selectS.name ASJobName, 
       SS.name ASScheduleName,                     
       CASE(SS.freq_type) 
            WHEN1THEN'Once'WHEN4THEN'Daily'WHEN8THEN(casewhen(SS.freq_recurrence_factor >1) then'Every '+convert(varchar(3),SS.freq_recurrence_factor) +' Weeks'else'Weekly'end) 
            WHEN16THEN(casewhen(SS.freq_recurrence_factor >1) then'Every '+convert(varchar(3),SS.freq_recurrence_factor) +' Months'else'Monthly'end) 
            WHEN32THEN'Every '+convert(varchar(3),SS.freq_recurrence_factor) +' Months'-- RELATIVEWHEN64THEN'SQL Startup'WHEN128THEN'SQL Idle'ELSE'??'ENDASFrequency,   
       CASEWHEN(freq_type =1)                       then'One time only'WHEN(freq_type =4andfreq_interval =1) then'Every Day'WHEN(freq_type =4andfreq_interval >1) then'Every '+convert(varchar(10),freq_interval) +' Days'WHEN(freq_type =8) then(select'Weekly Schedule'=MIN(D1+D2+D3+D4+D5+D6+D7 ) 
                                        from(selectSS.schedule_id, 
                                                        freq_interval,  
                                                        'D1'=CASEWHEN(freq_interval &1<>0) then'Sun 'ELSE''END, 
                                                        'D2'=CASEWHEN(freq_interval &2<>0) then'Mon 'ELSE''END, 
                                                        'D3'=CASEWHEN(freq_interval &4<>0) then'Tue 'ELSE''END, 
                                                        'D4'=CASEWHEN(freq_interval &8<>0) then'Wed 'ELSE''END, 
                                                    'D5'=CASEWHEN(freq_interval &16<>0) then'Thu 'ELSE''END, 
                                                        'D6'=CASEWHEN(freq_interval &32<>0) then'Fri 'ELSE''END, 
                                                        'D7'=CASEWHEN(freq_interval &64<>0) then'Sat 'ELSE''ENDfrommsdb..sysschedules ss 
                                                wherefreq_type =8) asF 
                                        whereschedule_id =SJ.schedule_id 
                                    ) 
            WHEN(freq_type =16) then'Day '+convert(varchar(2),freq_interval)  
            WHEN(freq_type =32) then(selectfreq_rel +WDAY  
                                        from(selectSS.schedule_id, 
                                                        'freq_rel'=CASE(freq_relative_interval) 
                                                                    WHEN1then'First'WHEN2then'Second'WHEN4then'Third'WHEN8then'Fourth'WHEN16then'Last'ELSE'??'END, 
                                                    'WDAY'=CASE(freq_interval) 
                                                                    WHEN1then' Sun'WHEN2then' Mon'WHEN3then' Tue'WHEN4then' Wed'WHEN5then' Thu'WHEN6then' Fri'WHEN7then' Sat'WHEN8then' Day'WHEN9then' Weekday'WHEN10then' Weekend'ELSE'??'ENDfrommsdb..sysschedules SS 
                                                whereSS.freq_type =32) asWS  
                                        whereWS.schedule_id =SS.schedule_id 
                                        )  
        ENDASInterval, 
        CASE(freq_subday_type) 
            WHEN1thenleft(stuff((stuff((replicate('0', 6-len(active_start_time)))+convert(varchar(6),active_start_time),3,0,':')),6,0,':'),8) 
            WHEN2then'Every '+convert(varchar(10),freq_subday_interval) +' seconds'WHEN4then'Every '+convert(varchar(10),freq_subday_interval) +' minutes'WHEN8then'Every '+convert(varchar(10),freq_subday_interval) +' hours'ELSE'??'ENDAS[Time], 
        CASESJ.next_run_date 
            WHEN0THENcast('n/a'aschar(10)) 
            ELSEconvert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  +' '+left(stuff((stuff((replicate('0', 6-len(next_run_time)))+convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8) 
        ENDASNextRunTime 
frommsdb.dbo.sysjobs S 
leftjoinmsdb.dbo.sysjobschedules SJ onS.job_id =SJ.job_id   
leftjoinmsdb.dbo.sysschedules SS onSS.schedule_id =SJ.schedule_id 
orderbyS.name 

 

From <https://portal.bd.bluecrystal.com.au/cms/display/SAHEALTH/Tips+n+Tricks#TipsnTricks-ASE>  