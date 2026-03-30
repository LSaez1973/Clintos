drop Trigger if exists dbo.trc_CIU_UI 
go
Create Trigger dbo.trc_CIU_UI 
on CIU for insert, update
as
begin
	if update(DPTO) or update(IDPAIS)
	begin
		update CIU set IDPAIS = coalesce(p.IDPAIS,'COL')
		from inserted i
			join CIU c with(nolock) on c.CIUDAD=i.CIUDAD
			left join DEP d with(nolock) on d.DPTO=c.DPTO
			left join PAI p with(nolock) on p.IDPAIS=d.IDPAIS
	end
end
go
