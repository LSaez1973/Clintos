drop function dbo.fnc_genPeriodosVacaciones;
go
-- Vacaciones Por Periodos cada 15 días causados indicando disfrutes/pagos
Create function dbo.fnc_genPeriodosVacaciones(@NumDoc varchar(20), @FechaCorte datetime)
returns @tabla 
	table (		
		Item smallint identity not null,
		Periodo smallint,
		FechaIni datetime,
		FechaFin datetime,
		DiasCal smallint,
		DiasLeg smallint, 
		DiasCau decimal(14,2),
		FraccionPPPA decimal(14,2),
		DiasCauAcum decimal(14,2),
		DiasLeg1 smallint, 
		DiasCau1 decimal(14,2), 
		DiasLeg2 smallint, 	
		DiasCau2 decimal(14,2),
		DiasCauExe decimal(14,2),
		AcumDiasPagIni decimal(14,2), -- Acumulado de días pagados Inicial
		DiasPagados decimal(14,2),
		AcumDiasPagFin as AcumDiasPagIni-DiasPagados, -- Acumulado de días pagados Final
		DiasPendientes decimal(14,2), --as cast(DiasCau-DiasPagados as decimal(14,2)),
		FraccionPPP decimal(14,2), -- Saldo del días no pagado en el periodo por ser fracciones (<1)
		ValorPagado decimal(14,2),
		primary key (Item)
	)
as
begin
	--declare @NumDoc varchar(20)='1067935987',@FechaCorte datetime=getdate();
	declare
		@Item int, @ItemVac int, @FechaIni datetime, @FechaFin datetime, @DiasCal smallint, @DiasLeg smallint, @DiasCau decimal(14,2), 
		@DiasLeg1 smallint, @DiasCau1 decimal(14,2), @DiasLeg2 smallint, @DiasCau2 decimal(14,2), @DiasCauExc decimal(14,2), 
		@DiasCauExc1 decimal(14,2), @DiasCauExc2  decimal(14,2), @ValorDia float,
		@TotalDiasPagados decimal(14,2), @SaldoDias decimal(14,2)=0,  @DiasPagosPer decimal(14,2)=0,  
		@TotalValorPagado decimal(14,2), @SaldoValor decimal(14,2)=0, @ValorPagosPer decimal(14,2)=0;
	-- Temporal para agilizar consultas desde otras app's
	declare @fnc_NOMI_DiasAcumVac_xDia as dbo.DiasAcumVac_xPeriodo_Type;
	declare @PagosPeriodosVacaciones table (
		Item	smallint,
		Procedencia	varchar(20),     	     
		FechaIni	datetime,	     	     
		FechaFin	datetime,	     	     
		Disfrutados	decimal(14,8),   
		Compensados	decimal(14,8),    
		TotalPagados	decimal(15,8),    
		ValorPagado	decimal(14,2)    	
	)

	insert into @fnc_NOMI_DiasAcumVac_xDia(Periodo,FechaIni,FechaFin,DiasLeg,MesesLegales,DiasCau)
	select Periodo,FechaIni=min(Fecha),FechaFin=max(Fecha),DiasLeg=Max(DiaPer),MesesLegales=Max(DiaPer)/cast(30 as float),DiasCau=max(DiasAcum)
	from dbo.fnc_NOMI_DiasAcumVac_xDia(@NumDoc,@FechaCorte)
	group by Periodo
	
	insert into @PagosPeriodosVacaciones(Item,Procedencia,FechaIni,FechaFin,Disfrutados,Compensados,TotalPagados,ValorPagado)
	select Item,Procedencia,FechaIni,FechaFin,Disfrutados,Compensados,TotalPagados,ValorPagado
	from dbo.fnc_genPagosPeriodosVacaciones(@numdoc,@FechaCorte);

	select @TotalDiasPagados=sum(TotalPagados), @TotalValorPagado=sum(ValorPagado) from @PagosPeriodosVacaciones;

	--select @TotalDiasPagados=TotalDiasPagados, @TotalValorPagado=ValorPagado from dbo.fnc_ResumenVacaciones(@NumDoc,@FechaCorte);

	select @TotalDiasPagados=coalesce(@TotalDiasPagados,0), @TotalValorPagado=coalesce(@TotalValorPagado,0);
	-- set @ValorDia = case when @TotalDiasPagados>0 then cast(@TotalValorPagado as float)/@TotalDiasPagados else 0 end;

	with 
	b as (
		select a.Periodo, a.FechaIni, a.FechaFin, a.DiasLeg, a.MesesLegales, 
			a.DiasCau, FraccionPPPA=cast(0 as decimal(14,2)), DiasCauAcum = a.DiasCau,
			AcumDiasPagIni=cast(@TotalDiasPagados as decimal(14,2)),  
			DiasPagados=cast(p.DiasPagados as decimal(14,2)), 
			SaldoDiasPagados=cast(r.SaldoDiasPagados as decimal(14,2)), 
			DiasPendientes=cast(q.DiasPendientes as decimal(14,2)), 
			FraccionPPP =cast(s.FraccionPPP as decimal(14,2))
			--, t.tpp
		from @fnc_NOMI_DiasAcumVac_xDia a 
			cross apply (select tpp = case when @TotalDiasPagados>a.DiasCau then 1 else 0 end) t -- Indica pago total de lo causado x periodo
			cross apply (select DiasPagados=case when t.tpp=1 then floor(a.DiasCau) else @TotalDiasPagados end) p
			cross apply (select SaldoDiasPagados=case when t.tpp=1 then @TotalDiasPagados-floor(a.DiasCau) else 0 end) r
			cross apply (select DiasPendientes = case when t.tpp=1 then floor(a.DiasCau)-p.DiasPagados else a.DiasCau-p.DiasPagados end) q
			cross apply (select FraccionPPP = case when t.tpp=1 then a.DiasCau-p.DiasPagados else 0 end) s
		where Periodo=1
		union all
		select a.Periodo,a.FechaIni, a.FechaFin, a.DiasLeg, a.MesesLegales, 
			a.DiasCau, FraccionPPPA=b.FraccionPPP, DiasCauAcum = cast(a.DiasCau + b.FraccionPPP as decimal(14,2)),
			AcumDiasPagIni=cast(dp.AcumDiasPagIni as decimal(14,2)),
			DiasPagados=cast(p.DiasPagados as decimal(14,2)),
			SaldoDiasPagados=cast(dp.SaldoDiasPagados as decimal(14,2)),
			DiasPendientes=cast(q.DiasPendientes as decimal(14,2)), 
			FraccionPPP =cast(dp.FraccionPPP as decimal(14,2))
			--,t.tpp
		from @fnc_NOMI_DiasAcumVac_xDia a 
			join b on a.Periodo=b.Periodo+1
			cross apply (select DiasCau = a.DiasCau+b.FraccionPPP) c
			cross apply (select tpp=case when b.SaldoDiasPagados>c.DiasCau then 1 else 0 end) t
			cross apply (select DiasPagados=case when t.tpp=1 then floor(c.DiasCau) else b.SaldoDiasPagados end) p
			cross apply (
				select DiasPendientes = 
					case when p.DiasPagados>0 then 
						case when cast(p.DiasPagados as int) = p.DiasPagados 
							then floor(c.DiasCau)-p.DiasPagados 
							else c.DiasCau-p.DiasPagados 
						end 
					else c.DiasCau-p.DiasPagados 
					end
			) q
			cross apply (select
							AcumDiasPagIni = b.SaldoDiasPagados,
							SaldoDiasPagados = case when t.tpp=1 then b.SaldoDiasPagados-floor(c.DiasCau) else 0 end,
							FraccionPPP = case when p.DiasPagados>0 then c.DiasCau - p.DiasPagados - q.DiasPendientes else 0 end
						) dp
	)
	insert into @tabla (Periodo, FechaIni, FechaFin, DiasCal, DiasLeg, DiasCau, FraccionPPPA, DiasCauAcum,
		DiasLeg1, DiasCau1, DiasLeg2, DiasCau2, DiasCauExe, AcumDiasPagIni, DiasPagados, DiasPendientes, FraccionPPP, ValorPagado)
	select ItemVac=Periodo, FechaIni, FechaFin, DiasCal=0, DiasLeg, DiasCau, FraccionPPPA, DiasCauAcum, DiasLeg1=0, DiasCau1=DiasCau, DiasLeg2=0, 
		DiasCau2=0, DiasCauExe=0, AcumDiasPagIni, DiasPagados, DiasPendientes, FraccionPPP, 
		ValorPagado = coalesce(p.ValorPagado,0)  --cast(DiasPagados*@ValorDia as Decimal(14,2))
		--,SaldoDiasPagados,tpp
	from b
		outer apply (
			select ValorPagado from @PagosPeriodosVacaciones p where p.FechaIni=b.FechaIni and p.FechaFin=b.FechaFin) p
	order by ItemVac desc

	-- DiasPendientes del ultimo periodo debe quedar con fracciones si las hay.
	update @tabla set DiasPendientes = DiasPendientes+FraccionPPP, FraccionPPP=0 where Item=1

	return;
end
go
