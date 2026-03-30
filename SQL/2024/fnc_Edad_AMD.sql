drop function if exists dbo.fnc_Edad_AMD
go
Create function dbo.fnc_Edad_AMD(@FechaIni datetime, @FechaFin datetime)
returns @edadAMD table (
	A smallint, M tinyint, D tinyint
) 
as
begin
	declare @now date,@dob date, @now_i int,@dob_i int, @days_in_birth_month int
	declare @years int, @months int, @days int
	set @now = @FechaFin 
	set @dob = @FechaIni -- Date of Birth

	set @now_i = convert(varchar(8),@now,112) -- iso formatted: 20130228
	set @dob_i = convert(varchar(8),@dob,112) -- iso formatted: 20120229
	set @years = ( @now_i - @dob_i)/10000
	-- (20130228 - 20120229)/10000 = 0 years

	set @months =(1200 + (month(@now)- month(@dob))*100 + day(@now) - day(@dob))/100 %12
	-- (1200 + 0228 - 0229)/100 % 12 = 11 months

	set @days_in_birth_month = day(dateadd(d,-1,left(convert(varchar(8),dateadd(m,1,@dob),112),6)+'01'))
	set @days = (sign(day(@now) - day(@dob))+1)/2 * (day(@now) - day(@dob))
			  + (sign(day(@dob) - day(@now))+1)/2 * (@days_in_birth_month - day(@dob) + day(@now))
	-- ( (-1+1)/2*(28 - 29) + (1+1)/2*(29 - 29 + 28))
	-- Explain: if the days of now is bigger than the days of birth, then diff the two days
	--          else add the days of now and the distance from the date of birth to the end of the birth month 
	insert into @edadAMD
	select @years,@months,@days -- 0, 11, 28 
	return;
end
go