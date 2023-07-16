---Inspecting the data
select * from PortfolioDB..sales_data_sample

select YEAR_ID, count (ORDERNUMBER)
FROM PortfolioDB..sales_data_sample
where YEAR_ID = 2004
group by YEAR_ID

---Checking for unique values
select distinct status from PortfolioDB..sales_data_sample
select distinct year_id from PortfolioDB..sales_data_sample
select distinct PRODUCTLINE from PortfolioDB..sales_data_sample
select distinct COUNTRY from PortfolioDB..sales_data_sample 
select distinct DEALSIZE from PortfolioDB..sales_data_sample 
select distinct TERRITORY from PortfolioDB..sales_data_sample

--DATA ANALYSIS
----Grouping sales by productline

select PRODUCTLINE, sum(sales) Revenue
from PortfolioDB..sales_data_sample
group by PRODUCTLINE
order by 2 desc

---Grouping sales by year
select YEAR_ID, sum(sales) Revenue
from PortfolioDB..sales_data_sample
group by YEAR_ID
order by 2 desc

---Observing number of months on 2005
---Demonstates that only 5 months were operational during that year
select distinct MONTH_ID 
from PortfolioDB..sales_data_sample
where YEAR_ID = 2005


----Grouping sales by the deal size
----Shows medium deals were more popular
select DEALSIZE, sum(sales) Revenue
from PortfolioDB..sales_data_sample
group by DEALSIZE
order by 2 desc

-----Best month for sales in a specific year
select MONTH_ID, sum(sales) Revenue, count (ORDERNUMBER) Frequency
from PortfolioDB..sales_data_sample
where YEAR_ID = 2003  ----- change for each year
group by MONTH_ID
order by 2 desc

-----Both show that November was an exceptional year
select MONTH_ID, sum(sales) Revenue, count (ORDERNUMBER) Frequency
from PortfolioDB..sales_data_sample
where YEAR_ID = 2004  ----- change for each year
group by MONTH_ID
order by 2 desc

-----Since November is the best month, check which product the sell most in November
----Shows that they sell mostly Classic cars in the Month of November
select PRODUCTLINE, sum(sales) Revenue, count (ORDERNUMBER) Frequency
from PortfolioDB..sales_data_sample
where MONTH_ID = 11 and YEAR_ID = 2003  ----- change for each year
group by PRODUCTLINE
order by 2 desc

--for 2004
select PRODUCTLINE,MONTH_ID, sum(sales) Revenue, count (ORDERNUMBER) Frequency
from PortfolioDB..sales_data_sample
where MONTH_ID = 11 and YEAR_ID = 2004  ----- change for each year
group by PRODUCTLINE, MONTH_ID
order by 3 desc

/*
To check who the best customer is (using RFM analysis). A way to segment customers using 
recency (how long ago their last purchase was), frequency (how often they purchased), and
monetary (how much they spent)
Recency - Last Order date
Frequency - Count of orders 
Monetary - Sum of amount spent
*/

DROP table if exists #rfm
;with rfm as
(
	select CUSTOMERNAME,
	sum (SALES) TotalSales, 
	avg (SALES) AvgSales, 
	count (ORDERNUMBER) Frequency, 
	max (ORDERDATE) Latest_Purchase,
	(select max(ORDERDATE) from PortfolioDB..sales_data_sample) Max_Order_date,
	datediff (DD, max (ORDERDATE),(select max(ORDERDATE) from PortfolioDB..sales_data_sample) ) Recency

	from PortfolioDB..sales_data_sample
	group by CUSTOMERNAME
),

rfm_calc as
(
	select 
	r.*,
	ntile (3) over (order by Recency) rfm_recency,
	ntile (3) over (order by Frequency) rfm_frequency,
	ntile (3) over (order by AvgSales) rfm_monetary
	from rfm r
)

select c.*, 
(rfm_recency+rfm_frequency+rfm_monetary) rfm_total,
(cast (rfm_recency as varchar) + cast (rfm_frequency as varchar) +cast (rfm_monetary as varchar)) rfm_total_str
into #rfm    -----select everything into temporary table called #rfm
from rfm_calc c
order by AvgSales desc


----using the temporary table created
select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_total_str in (111, 112 , 121, 122, 123, 131, 132, 211, 212, 114, 141) then 'lost_case'  
		when rfm_total_str in (133, 134, 143, 244, 334, 343, 344, 144) then 'marketing target' 
		when rfm_total_str in (311, 411, 331) then 'new customers'
		when rfm_total_str in (221, 222, 223, 231, 233, 322) then 'potential churners'
		when rfm_total_str in (323, 333,321, 422, 332, 432) then 'active but to encourage' 
		when rfm_total_str in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm 



 -----To check the products that are often bought together

 select distinct ORDERNUMBER, stuff(

		(select ',' + PRODUCTCODE
		from PortfolioDB..sales_data_sample c
		where ORDERNUMBER in (
			select ORDERNUMBER from
				(select ORDERNUMBER, count (*) rn
				from PortfolioDB..sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
				) a
				where rn = 2
				and c.ORDERNUMBER = d.ORDERNUMBER
		)
		for xml path ('')), 1, 1, '') Double_Orders

from PortfolioDB..sales_data_sample d
order by Double_Orders desc
























