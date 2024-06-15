-- https://stackoverflow.com/questions/4305691/need-to-list-all-triggers-in-sql-server-database-with-table-name-and-tables-sch



Select
  [Parent] = Left((Case When Tr.Parent_Class = 0 Then '(Database)' Else Object_Name(Tr.Parent_ID) End), 32),
  [Schema] = Left(Coalesce(Object_Schema_Name(Tr.Object_ID), '(None)'), 16),
  [Trigger name] = Left(Tr.Name, 32), 
  [Type] = Left(Tr.Type_Desc, 3), -- SQL or CLR
  [MS?] = (Case When Tr.Is_MS_Shipped = 1 Then 'X' Else ' ' End),
  [On?] = (Case When Tr.Is_Disabled = 0 Then 'X' Else ' ' End),
  [Repl?] = (Case When Tr.Is_Not_For_Replication = 0 Then 'X' Else ' ' End),
  [Event] = Left((Case When Tr.Parent_Class = 0 
                       Then (Select Top 1 Left(Te.Event_Group_Type_Desc, 40)
                             From Sys.Trigger_Events As Te
                             Where Te.Object_ID = Tr.Object_ID)
                       Else ((Case When Tr.Is_Instead_Of_Trigger = 1 Then 'Instead Of ' Else 'After ' End)) +
                             SubString(Cast((Select [text()] = ', ' + Left(Te.Type_Desc, 1) + Lower(SubString(Te.Type_Desc, 2, 32)) +
                                                    (Case When Te.Is_First = 1 Then ' (First)' When Te.Is_Last = 1 Then ' (Last)' Else '' End)
                                             From Sys.Trigger_Events As Te
                                             Where Te.Object_ID = Tr.Object_ID
                                             Order By Te.[Type]
                                             For Xml Path ('')) As Character Varying), 3, 60) End), 60)
  -- If you like: 
  -- , [Get text with] = 'Select Object_Definition(' + Cast(Tr.Object_ID As Character Varying) + ')'
From 
  Sys.Triggers As Tr
Order By
  Tr.Parent_Class, -- database triggers first
  Parent -- alphabetically by parent


  --------------------------



SELECT
   ServerName   = @@servername,
   DatabaseName = db_name(),
   SchemaName   = isnull( s.name, '' ),
   TableName    = isnull( o.name, 'DDL Trigger' ),
   TriggerName  = t.name, 
   [Event] = Left((Case When t.Parent_Class = 0 
                       Then (Select Top 1 Left(Te.Event_Group_Type_Desc, 40)
                             From Sys.Trigger_Events As Te
                             Where Te.Object_ID = t.Object_ID)
                       Else ((Case When t.Is_Instead_Of_Trigger = 1 Then 'Instead Of ' Else 'After ' End)) +
                             SubString(Cast((Select [text()] = ', ' + Left(Te.Type_Desc, 1) + Lower(SubString(Te.Type_Desc, 2, 32)) +
                                                    (Case When Te.Is_First = 1 Then ' (First)' When Te.Is_Last = 1 Then ' (Last)' Else '' End)
                                             From Sys.Trigger_Events As Te
                                             Where Te.Object_ID = t.Object_ID
                                             Order By Te.[Type]
                                             For Xml Path ('')) As Character Varying), 3, 60) End), 60),

    OBJECTPROPERTY( t.object_id, 'ExecIsUpdateTrigger') AS [isupdate],
    OBJECTPROPERTY( t.object_id, 'ExecIsDeleteTrigger') AS [isdelete],
    OBJECTPROPERTY( t.object_id, 'ExecIsInsertTrigger') AS [isinsert],
    OBJECTPROPERTY( t.object_id, 'ExecIsAfterTrigger') AS [isafter],
    OBJECTPROPERTY( t.object_id, 'ExecIsInsteadOfTrigger') AS [isinsteadof],
    OBJECTPROPERTY( t.object_id, 'ExecIsTriggerDisabled') AS [disabled]
	--, Defininion   = object_definition( t.object_id )

FROM sys.triggers t
   LEFT JOIN sys.all_objects o
      ON t.parent_id = o.object_id
   LEFT JOIN sys.schemas s
      ON s.schema_id = o.schema_id
ORDER BY 
   SchemaName,
   TableName,
   TriggerName

   --SELECT * FROM sys.triggers