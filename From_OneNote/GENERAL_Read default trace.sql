

SELECT  TE.name AS [EventName] , 

        --v.subclass_name , 

        T.DatabaseName , 

        T.NTDomainName , 

t.ClientProcessID, 

t.HostName, 

        T.ApplicationName , 

        T.LoginName , 

        T.SPID , 

        T.StartTime , 

        T.RoleName , 

        T.TargetUserName , 

        T.TargetLoginName , 

        T.SessionLoginName, 

T.TextData 

FROM    sys.fn_trace_gettable(CONVERT(VARCHAR(150), ( SELECT TOP 1 

                                                              f.[value] 

                                                      FROM    sys.fn_trace_getinfo(NULL) f 

                                                      WHERE   f.property = 2 

                                                    )), DEFAULT) T 

        JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id 

        --JOIN sys.trace_subclass_values v ON v.trace_event_id = TE.trace_event_id 

        --                                    AND v.subclass_value = T.EventSubClass 

WHERE   TE.name like '%fail%' 

--WHERE t.TextData like 'DBCC%' 