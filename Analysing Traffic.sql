/* Traffic Source Analysis
    Where your custoers are coming from?
    Which channels are driving highest quality traffic?*/
    
use mavenfuzzyfactory;

/* Q-Which ads (i.e. utm_content are driving the most sessions?*/

select website_sessions.utm_content,count(distinct website_sessions.website_session_id) as sessions, 
count(distinct orders.order_id) as ordr,
(count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)) as session_to_ordr_cnv_rt
 from website_sessions
left join orders
on orders.website_session_id=website_sessions.website_session_id
where website_sessions.created_at<"2012-04-12"
group by website_sessions.utm_content
order by count(distinct website_sessions.website_session_id) desc;

/* Q-Where the bulk of website sessions are comming from? (before april-12-2012) */

select utm_source,utm_campaign,http_referer,count(distinct website_session_id) from website_sessions
where created_at<"2012-04-12"
group by 1,2,3
order by 4 desc;

/* Q-What is the conversion rate?
  If it is >=4% then it was good*/
  
select count(distinct website_sessions.website_session_id) as sessions,count(distinct orders.order_id) as ordr,
(count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)) as traffic_cnvrsn_rt
from website_sessions
left join orders
on  website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<"2012-04-14"
and utm_source like "gsearch"
and utm_campaign like "nonbrand";

/* Analysis-As the traffic conversion rate is below 4% we need to reduce the cost price in this campaign*/
/*A month letter after cutting the cost,MD wants to know whether there was volume drop...
 Q-Find up till 12th may 2012 what is the total sessions in each week*/
 
select min(date(created_at)) as week_strt_date,count(website_session_id) as sessions from website_sessions
where created_at<"2012-05-12"
and utm_source like "gsearch"
and utm_campaign like "nonbrand"
group by week(created_at);

/*Analysis- As we bid down gsearch nonbrand our traffic also got reduced*/

/* Q-We need to increase the volume of trafics and hence need to analyse is desktop performance better than mobile*/

select device_type,count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.order_id) as orders,
(count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)) as traffic_cnvrsn_rt
from website_sessions
left join orders
on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at<"2012-05-12"
and utm_source like "gsearch"
and utm_campaign like "nonbrand"
group by 1;

/* Result-Desktop Performance is way better than Mobile so we should be bidding more on desktop device type*/
/*After a month that is 6th june 2012 we need to analyse the total session. 
Q-Calculate the total session for desktop and
mobile separately till 6th june*/

select min(date(created_at)),
count(case 
        when device_type like 'mobile' then website_session_id else Null end) as mob_sesn,
count(case
        when device_type like 'desktop' then website_session_id else Null end) as desk_sesn
        from website_sessions
where website_sessions.created_at<"2012-06-09"
and utm_source like "gsearch"
and utm_campaign like "nonbrand"
group by week(created_at);  

/* Bingooo..We can see the substantial increase in the traffic for desktop device type*/    
/*.....................*/
/*ANALYZING TOP WEBSITE CONTENT*/
/*Q-Most viewed website pages ranked by session*/

select count(distinct website_session_id) as session,pageview_url from website_pageviews
where created_at<"2012-06-09"
group by pageview_url
order by 1 desc;

/*Find out top landing pages*/

select min(website_pageview_id) as minpage,pageview_url,count(website_session_id) as session from website_pageviews
where created_at<"2012-06-12"
group by pageview_url;

-- OR BY USING TEMPORARY TABLE--

Create table tempageview
select website_pageview_id,min(website_pageview_id) as mp from website_pageviews
where created_at<"2012-06-12"
group by website_pageview_id; 

select website_pageviews.pageview_url,count( distinct mp)  
from tempageview
left join website_pageviews
on tempageview.mp=website_pageviews.website_pageview_id
group by website_pageviews.pageview_url
order by 2 desc;  
 
 /* Analysis-Count of landing page for the home page is highest so we will work on optimising and analysing home page */

/*Q-Building Conversion funnels and testing conversion paths*/
-- Select all pageviews of relevant session
-- Identify each relavant pageview as specific funnel step
-- create the session level conversion funnel view
-- Aggregate the data to assess funnel performance
/* First creating flag for each url
then selecting max of each url grouping session*/

create temporary table flag_page_funnel
select website_session_id,
max(flag_products) as fp,
max(flag_mrfuzzy) as fm,
max(flag_cart) as fc,
max(flag_shipping) as fs,
max(flag_billing) as fb,
max(flag_thankyou) as ft from
(select website_sessions.website_session_id,pageview_url,
case when pageview_url like '/products' then 1 else 0 end as flag_products,
case when pageview_url like '/the-original-mr-fuzzy' then 1 else 0 end as flag_mrfuzzy,
case when pageview_url like '/cart' then 1 else 0 end as flag_cart,
case when pageview_url like '/shipping' then 1 else 0 end as flag_shipping,
case when pageview_url like '/billing' then 1 else 0 end as flag_billing,
case when pageview_url like '/thank-you-for-your-order' then 1 else 0 end as flag_thankyou
from website_sessions
left join website_pageviews
on website_sessions.website_session_id=website_pageviews.website_session_id
where utm_source like 'gsearch'
and utm_campaign like 'nonbrand'
and website_sessions.created_at between '2012-08-05' and '2012-09-05'
order by website_sessions.website_session_id,website_pageviews.created_at) as flag_table
group by website_session_id;

-- calculating total session and total pageviews for each page

select count(distinct website_session_id) as ws_total,
count(case when fp=1 then website_session_id else null end) as to_products,
count(case when fm=1 then website_session_id else null end) as to_mrfuzzy,
count(case when fc=1 then website_session_id else null end) as to_cart,
count(case when fs=1 then website_session_id else null end) as to_shipping,
count(case when fb=1 then website_session_id else null end) as to_bill,
count(case when ft=1 then website_session_id else null end) as to_thankyou
from flag_page_funnel;

-- Calaculating click rate from one page to another
select 
count(case when fp=1 then website_session_id else null end)/count(distinct website_session_id) as clkrt_p,
count(case when fm=1 then website_session_id else null end)/count(case when fp=1 then website_session_id else null end) as clkrt_to_mrfuzzy,
count(case when fc=1 then website_session_id else null end)/count(case when fm=1 then website_session_id else null end) as clkrt_to_cart,
count(case when fs=1 then website_session_id else null end)/count(case when fc=1 then website_session_id else null end) as clkrt_to_shipping,
count(case when fb=1 then website_session_id else null end)/count(case when fs=1 then website_session_id else null end) as clkrt_to_bill,
count(case when ft=1 then website_session_id else null end)/count(case when fb=1 then website_session_id else null end) as clkrt_to_thankyou
from flag_page_funnel;

/* Analysis-Based on the click through rates the manager needs to work on product,cart and thank you page.*/
---------------------------
/* A new billing page has been updated billing-2
   Q-Analyse what % of session on this page end up placing an order*/
   
   -- First we need to figure out when billing-2 went live
   select min(website_pageview_id) as first_pgview from website_pageviews
   where pageview_url like '/billing-2';
   -- 53550
   -- Fetching all the session id for billing url
   select website_pageviews.website_session_id,pageview_url from website_pageviews
   where website_pageviews.website_pageview_id>53550
   and created_at<"2012-11-10"
   and pageview_url in("/billing","/billing-2");
   
   -- joining orders
	select website_pageviews.website_session_id,pageview_url,order_id from website_pageviews
    left join orders
    on orders.website_session_id=website_pageviews.website_session_id
   where website_pageviews.website_pageview_id>53550
   and website_pageviews.created_at<"2012-11-10"
   and pageview_url in("/billing","/billing-2");
   
   -- aggregating
   
   select pageview_url,count(distinct website_session_id) as tot_ses,count(distinct order_id) as tot_ordr,
   (count(distinct order_id)/count(distinct website_session_id)) as cnvrsn_rt from(
   select website_pageviews.website_session_id,pageview_url,order_id from website_pageviews
    left join orders
    on orders.website_session_id=website_pageviews.website_session_id
   where website_pageviews.website_pageview_id>53550
   and website_pageviews.created_at<"2012-11-10"
   and pageview_url in("/billing","/billing-2")) as temp
   group by pageview_url;
   
   /*Analysis-Conversion rate for billing-2 page is more*/
   ------------
   /*Q-Calculate monthly trends for gsearch sessions and orders*/
   
   select month(website_sessions.created_at), count(website_sessions.website_session_id) as tot_session,count(order_id) as tot_order from website_sessions
   left join orders
   on website_sessions.website_session_id=orders.website_session_id
   where utm_source like 'gsearch'
   and  website_sessions.created_at<"2012-11-27"
   group by month(website_sessions.created_at);
   
   /*Q-Calculate monthly trends for gsearch sessions and orders by splitting out brand and non-brand campaigns*/
   
   select month(website_sessions.created_at),
   count(case when utm_campaign like 'nonbrand' then website_sessions.website_session_id else null end) as tot_nonbrand_session,
   count(case when utm_campaign like 'nonbrand' then orders.order_id else null end)as tot_nonbrand_order,
   count(case when utm_campaign like  'brand' then website_sessions.website_session_id else null end) as tot_brand_session,
   count(case when utm_campaign like 'brand' then orders.order_id else null end)as tot_brand_order
   from website_sessions
   left join orders
   on website_sessions.website_session_id=orders.website_session_id
   where utm_source like 'gsearch'
   and  website_sessions.created_at<"2012-11-27"
   group by month(website_sessions.created_at);
   
   /*Analysis there is a substantial difference betwwen brand and non-brand campaigns*/
   
   /*Q-Calculate monthly trends for gsearch sessions, non-brand campaigns and orders split by device type*/
   
   select month(website_sessions.created_at),
   count(case when device_type like 'desktop' then website_sessions.website_session_id else null end) as tot_desk_session,
   count(case when device_type like 'desktop' then orders.order_id else null end)as tot_desk_order,
   count(case when device_type like  'mobile' then website_sessions.website_session_id else null end) as tot_moble_session,
   count(case when device_type like 'mobile' then orders.order_id else null end)as tot_moble_order
   from website_sessions
   left join orders
   on website_sessions.website_session_id=orders.website_session_id
   where utm_source like 'gsearch'
   and utm_campaign like 'nonbrand'
   and  website_sessions.created_at<"2012-11-27"
   group by month(website_sessions.created_at);
   
   /*Analysis-Orded through Desktop is higher than mobile*/
   
   /*Q-Calculate Monthly trends of other channels*/
   
   select month(website_sessions.created_at),
   count(distinct case when utm_source like 'gsearch' then website_sessions.website_session_id else null end) as gsearch_paid_sessions,
   count(distinct case when utm_source like 'bsearch' then website_sessions.website_session_id else null end) as bsearch_paid_session,
   count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search,
   count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_typein_session
   from website_sessions
   left join orders
   on website_sessions.website_session_id=orders.website_session_id
   where website_sessions.created_at<"2012-11-27"
   group by month(website_sessions.created_at);
   
   /*Q-Calculate session to orders conversion rate by month*/
   
   select month(website_sessions.created_at),count(website_sessions.website_session_id) as tot_session,count(order_id)as tot_order ,
   (count(order_id)/count(website_sessions.website_session_id)) as cnv_rt from website_sessions
   left join orders   
   on website_sessions.website_session_id=orders.website_session_id
   where website_sessions.created_at<"2012-11-27"
   group by month(website_sessions.created_at);
   
   /*Q -For the gsearch lander test, estimate the revenue that test earned us..
   Look at the conversion rate value from june 19 to july 28,use nonbrand session*/
   
   select min(website_pageview_id) as first_pgview from website_pageviews
   where pageview_url like '/lander-1';
   -- 23504
   
   -- finding first pageviews for all sessions
   
 create temporary table first_test_pageviews
 select website_pageviews.website_session_id,
 min(website_pageviews.website_pageview_id) as min_pgview_id
 from website_pageviews
 inner join website_sessions
 on website_sessions.website_session_id=website_pageviews.website_session_id
 where website_sessions.created_at<"2012-07-28"
 and website_pageviews.website_pageview_id>=23504
 and utm_source like 'gsearch'
 and utm_campaign like 'nonbrand'
 group by website_pageviews.website_session_id;
 
 -- quering landing page for each session
 
 create temporary table nonbrand_session_for_landingpg
 select first_test_pageviews.website_session_id,
 website_pageviews.pageview_url as landing_page
 from first_test_pageviews
 left join website_pageviews
 on first_test_pageviews.min_pgview_id=website_pageviews.website_pageview_id
 where website_pageviews.pageview_url in('/home','/lander-1');
 
 -- Joining with order table
 
 create temporary table nonbrand_session_w_order
 select 
 nonbrand_session_for_landingpg.website_session_id,
 nonbrand_session_for_landingpg.landing_page,
 orders.order_id as ordr
 from nonbrand_session_for_landingpg
 left join orders
 on orders.website_session_id=nonbrand_session_for_landingpg.website_session_id;
 
 select 
      landing_page,
      count(distinct website_session_id) as session,
      count(distinct ordr) as orders,
      (count(distinct ordr)/count(distinct website_session_id)) as cnv 
      from nonbrand_session_w_order
      group by 1;
      
      -- Analysis 0.88% additional orders increase
      -- Finding the last session where '/home' was used
      
select max(website_sessions.website_session_id) as max_home
 from website_sessions
 left join website_pageviews
 on website_sessions.website_session_id=website_pageviews.website_session_id
 where website_sessions.created_at<"2012-11-27"
 and website_pageviews.pageview_url like '/home'
 and utm_source like 'gsearch'
 and utm_campaign like 'nonbrand';
 
 -- 17145
 -- counting number of session after 17145
 
 select count(website_session_id) from website_sessions
 where created_at<"2012-11-27"
 and website_session_id>17145
 and utm_source like 'gsearch'
 and utm_campaign like 'nonbrand';
 
 /*Analysis-22972 traffic was in lander page since the test
 so 22972*0.88%=202 orders inncreased*/
 -------------
 /*Q For the landing page test done in previous question calculate the conversion funnel*/
 
 create temporary table url_flag_session
 select
     website_session_id,
     max(homepage) as hp,
     max(landingpage) as lp,
     max(productpage) as pp,
     max(fuzzypage) as fp,
     max(cartpage) as cp,
     max(shippage) as sp,
     max(billpage) as bp,
     max(thankyoupage) as tp from(
 
 Select website_sessions.website_session_id,
 website_pageviews.pageview_url,
 case when pageview_url like '/home' then 1 else 0 end as homepage,
 case when pageview_url like '/lander-1' then 1 else 0 end as landingpage,
 case when pageview_url like '/products' then 1 else 0 end as productpage,
 case when pageview_url like '/the-original-mr-fuzzy' then 1 else 0 end as fuzzypage,
 case when pageview_url like '/cart' then 1 else 0 end as cartpage,
 case when pageview_url like '/shipping' then 1 else 0 end as shippage,
 case when pageview_url like '/billing' then 1 else 0 end as billpage,
 case when pageview_url like '/thank-you-for-your-order' then 1 else 0 end as thankyoupage
 from website_sessions
 left join website_pageviews
 on website_sessions.website_session_id=website_pageviews.website_session_id
 where website_sessions.created_at between "2012-6-19" and "2012-07-28"
 and utm_source like 'gsearch'
 and utm_campaign like 'nonbrand') as abc
 group by 1;
 
 -- grouping home and landing page w.r.t session
 
 select
 case when hp=1 then "home_page"
      when lp=1 then "landing_page"
      else "Check logic"
      end as segment,
 count(distinct website_session_id) as session,
 count(case when pp=1 then website_session_id  else null end) as to_p,
 count(case when fp=1 then website_session_id  else null end) as to_f,
 count(case when cp=1 then website_session_id  else null end) as to_c,
 count(case when sp=1 then website_session_id  else null end) as to_s,
 count(case when bp=1 then website_session_id  else null end) as to_b,
 count(case when tp=1 then website_session_id  else null end) as to_t
 from url_flag_session
 group by 1;



