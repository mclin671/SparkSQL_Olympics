-- Databricks notebook source
-- MAGIC %md
-- MAGIC 
-- MAGIC #Analysis of Olympic Athlete Data

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## What client/dataset did you select and why?
-- MAGIC I selected to work with the client SportsStats to analyze their Olympics dataset. SportsStats is a sports analysis firm partnering with local news and elite personal trainers to provide “interesting” insights to help their partners. Insights could be patterns/trends highlighting certain groups/events/countries, etc. for the purpose of developing a news story or discovering key health insights.
-- MAGIC 
-- MAGIC Insight into sports is interesting since it can help the athlete focus and develop specific attributes that are being recorded. 
-- MAGIC 
-- MAGIC ## Exploratory Data Analysis
-- MAGIC The dataset was downloaded from Dropbox and imported as a table into Databricks.

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS athlete_events
USING csv
OPTIONS (
   header "true",
   path "/FileStore/tables/athlete_events.csv",
   inferSchema "true"
);

-- COMMAND ----------

CREATE TABLE IF NOT EXISTS noc_region
USING csv
OPTIONS (
   header "true",
   path "/FileStore/tables/noc_regions.csv",
   inferSchema "true"
);

-- COMMAND ----------

SELECT 
  *
FROM
  noc_region

-- COMMAND ----------

SELECT 
  Sex, 
  Name, 
  Event, 
  Team,
  Year
FROM
  athlete_events
WHERE 
  Sex <> "F" 
AND
  Sex <> "M"

-- COMMAND ----------

SELECT 
  *
FROM 
  athlete_events

-- COMMAND ----------

SELECT 
COUNT(*) AS Count,
Year,
Team
FROM athlete_events
GROUP BY Team, Year
ORDER BY Year DESC


-- COMMAND ----------

SELECT 
  COUNT(*),
  Age
FROM
  athlete_events
GROUP BY 
  Age

-- COMMAND ----------

SELECT
  Sex,
  COUNT(*)
FROM 
  athlete_events
GROUP BY 
  Sex

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ER Diagram 
-- MAGIC 
-- MAGIC ![er](files/tables/Capture-1.JPG)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ##Description
-- MAGIC 
-- MAGIC The data for SportsStats will be reviewed and analyzed to identify trends between gender, age, and weight for Olympic sports and countries. The analysis can be aimed towards individuals in sports analytics and fans of the Olympics. 
-- MAGIC 
-- MAGIC ##Questions 
-- MAGIC 
-- MAGIC 1. Do top winning teams have an ideal range of height/weight for the same event across different countries?
-- MAGIC 
-- MAGIC 2. How has the inclusion of women in the Olympics changed over time? 
-- MAGIC 
-- MAGIC 3. Look at what teams bring the most medals home compared to number of athletes representing each country. Is there a linear relationship between having more athletes and winning more medals? 
-- MAGIC 
-- MAGIC ##Hypothesis
-- MAGIC 
-- MAGIC 1. Team members of the same team/country will have a lower standard deviation in their weights and heights. However, weights/heights will vary from country to country. 
-- MAGIC 
-- MAGIC 2. Women have participated in more Olympic events as a function of time. 
-- MAGIC 
-- MAGIC 3. As the number of athletes representing a country increases, the number of medals will not increase linearly. 
-- MAGIC 
-- MAGIC ##Approach
-- MAGIC 
-- MAGIC 1. Group team members that medal in an event together and calculate statistics on their attributes. 
-- MAGIC 
-- MAGIC 2. Plot the number of women participating over time using a line graph. 
-- MAGIC 
-- MAGIC 3. Count number of athletes vs. number of medals by country.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ##Weight and Height Data Analysis 
-- MAGIC ###Focused on Men's Basketball
-- MAGIC 
-- MAGIC By graphing the average weight and height of the Olympic gold, silver, and bronze medal teams for men's basketball, it becomes apparant that the overall average height and weight of men has increased from 1896 to 2016. However, being the team with the highest average weight and height does not necessarily correlate with winning the Olympic gold medal. 

-- COMMAND ----------

 --Create new table and filter data for top winning teams and conduct descriptive statistics on athletes on winning teams
 
DROP TABLE IF EXISTS athlete_stats;

CREATE TABLE IF NOT EXISTS athlete_stats
  AS (
       SELECT 
        Event,
        Team,
        Year,
        Medal,
        AVG(Weight) AS avg_weight, 
        AVG(Height) AS avg_height, 
        STDDEV(Weight) AS stdev_weight,
        STDDEV(Height) AS stdev_height
      FROM 
        athlete_events
      WHERE 
          (`Medal` = "Gold" OR
          `Medal` = "Silver" OR
          `Medal` = "Bronze") 
      AND
        Weight IS NOT NULL 
      AND
        Height IS NOT NULL
      GROUP BY 
        Event,
        Year,
        Medal,
        Team
  )
 

-- COMMAND ----------

 --Create new table for Men's Basketball
 
DROP TABLE IF EXISTS menbball;

CREATE TABLE IF NOT EXISTS menbball
  AS (
       SELECT 
        *
      FROM 
        athlete_stats
      WHERE 
        Event = "Basketball Men's Basketball"
  )
 

-- COMMAND ----------

SELECT *
FROM menbball

-- COMMAND ----------

-- MAGIC %r
-- MAGIC ##Import data in R environment for visualizations 
-- MAGIC 
-- MAGIC library(SparkR)
-- MAGIC 
-- MAGIC sparkR.session()
-- MAGIC 
-- MAGIC athlete_event <- read.df("/FileStore/tables/athlete_events.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
-- MAGIC 
-- MAGIC noc_region <- read.df("/FileStore/tables/noc_regions.csv", "csv", header = "true", inferSchema = "true", na.strings = "NA")
-- MAGIC 
-- MAGIC athlete_stats <- sql("SELECT 
-- MAGIC         Event,
-- MAGIC         Team,
-- MAGIC         Year,
-- MAGIC         Medal,
-- MAGIC         AVG(Weight) AS avg_weight, 
-- MAGIC         AVG(Height) AS avg_height, 
-- MAGIC         STDDEV(Weight) AS stdev_weight,
-- MAGIC         STDDEV(Height) AS stdev_height
-- MAGIC       FROM 
-- MAGIC         athlete_events
-- MAGIC       WHERE 
-- MAGIC           (`Medal` = 'Gold' OR
-- MAGIC           `Medal` = 'Silver' OR
-- MAGIC           `Medal` = 'Bronze') 
-- MAGIC       AND
-- MAGIC         Weight IS NOT NULL 
-- MAGIC       AND
-- MAGIC         Height IS NOT NULL
-- MAGIC       GROUP BY 
-- MAGIC         Event,
-- MAGIC         Year,
-- MAGIC         Medal,
-- MAGIC         Team")
-- MAGIC 
-- MAGIC menbball <- sql("
-- MAGIC                 SELECT 
-- MAGIC                   *
-- MAGIC                 FROM 
-- MAGIC                   athlete_stats
-- MAGIC                 WHERE 
-- MAGIC                   Event LIKE 'Basketball Men%'
-- MAGIC                 ")

-- COMMAND ----------

-- MAGIC %r
-- MAGIC install.packages("ggrepel")

-- COMMAND ----------

-- MAGIC %r
-- MAGIC ##Convert Spark dataframe to R dataframe and plot analysis 
-- MAGIC 
-- MAGIC library(tidyverse)
-- MAGIC library(SparkR)
-- MAGIC library(ggrepel)
-- MAGIC 
-- MAGIC menbball_r <- collect(menbball)
-- MAGIC menbball_r$Medal <- factor(menbball_r$Medal, levels = c('Gold', 'Silver', 'Bronze'))
-- MAGIC 
-- MAGIC ##Plot Weight Data
-- MAGIC ggplot(data = menbball_r, aes(x = Year, y = avg_weight, group = Medal, colour = Medal)) + geom_line() +
-- MAGIC geom_text_repel(aes(label = round(avg_weight, digits = 1))) + 
-- MAGIC scale_colour_manual(values = c("#CD950C", "#8B8878", "#8B4513")) + 
-- MAGIC labs(x = "Year", y = "Average Weight (kg)", title = "Average Weight of Olympic Medaling Teams in Men's Basketball") +
-- MAGIC theme_bw()

-- COMMAND ----------

-- MAGIC %r
-- MAGIC 
-- MAGIC ##Plot Height Data
-- MAGIC ggplot(data = menbball_r, aes(x = Year, y = avg_height, group = Medal, colour = Medal)) + geom_line() +
-- MAGIC geom_text_repel(aes(label = round(avg_height, digits = 1))) + 
-- MAGIC scale_colour_manual(values = c("#CD950C", "#8B8878", "#8B4513")) + 
-- MAGIC labs(x = "Year", y = "Average Height (m)", title = "Average Height of Olympic Medaling Teams in Men's Basketball") +
-- MAGIC theme_bw()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Gender Analysis - How has overall participation of women changed over time?
-- MAGIC 
-- MAGIC Plotting the number of male and female athletes participating in the winter and summer Olympics from 1896 - 2016 shows that although the participation of women has increased, the number of male athletes in the Olympics has increased as well. Female participation in the Olympics increased immensely between 1980 - 2000 partially due to overall awareness of women's rights (i.e. the Women's Suffrage Movement) and due to the fact that in 1991, the IOC made it mandatory for all new sports applying for Olympic recognition to have female competitors.  <p>
-- MAGIC An initial hypothesis for the difference between the number of male and female athletes was that because there is larger amount of Olympic sports for men, more men will participate in the Olympics. A quick SQL query showed that there are 464 distinct Olympic events that men participate in while there are only 211 distinct Olympic events that women participate in, which confirmed my initial hypothesis. 

-- COMMAND ----------

SELECT 
  COUNT (DISTINCT Event)
FROM 
  athlete_events
WHERE 
  Event LIKE "%Men%"

-- COMMAND ----------

SELECT 
  COUNT (DISTINCT Event)
FROM 
  athlete_events
WHERE 
  Event LIKE "%Women%"

-- COMMAND ----------

SELECT
  COUNT(*) AS Count,
  Sex, 
  Year, 
  Season
FROM 
  athlete_events
WHERE
  Sex = "F"
OR 
  Sex = "M"
GROUP BY 
  Sex,
  Year,
  Season

-- COMMAND ----------

-- MAGIC %r
-- MAGIC ## Import data for gender analysis 
-- MAGIC 
-- MAGIC library(SparkR)
-- MAGIC 
-- MAGIC sparkR.session()
-- MAGIC 
-- MAGIC gender_cnt <- sql("
-- MAGIC SELECT
-- MAGIC   COUNT(*) AS Count,
-- MAGIC   Sex, 
-- MAGIC   Year,
-- MAGIC   Season
-- MAGIC FROM 
-- MAGIC   athlete_events
-- MAGIC WHERE
-- MAGIC   Sex = 'F'
-- MAGIC OR 
-- MAGIC   Sex = 'M'
-- MAGIC GROUP BY 
-- MAGIC   Sex,
-- MAGIC   Year, 
-- MAGIC   Season")

-- COMMAND ----------

-- MAGIC %r
-- MAGIC 
-- MAGIC library(tidyverse)
-- MAGIC 
-- MAGIC gender_cntr <- collect(gender_cnt)
-- MAGIC gender_cntr$Year <- as.numeric(gender_cntr$Year)
-- MAGIC 
-- MAGIC ggplot(data = gender_cntr, aes(x = Year, y = Count, group = Sex, colour = Sex)) + 
-- MAGIC geom_line() + 
-- MAGIC scale_x_continuous(limits = c(1890, 2020), breaks = seq(1900, 2020, 20)) +
-- MAGIC facet_wrap(~Season)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC ##Analysis of Relationship between Number of Athletes and Medals Earned By Country
-- MAGIC Although the R^2 value is 0.8508 for a linear fit between the number of athletes and the number of medals earned by country, further analysis of the fit shows that there is NO linear relationship between the two variables. The data is heavily right skewed and the residuals do not have constant variance around mean of 0. 

-- COMMAND ----------

-- MAGIC %python
-- MAGIC dbutils.fs.rm('dbfs:/user/hive/warehouse/athlete_event_bronze', recurse = True)
-- MAGIC dbutils.fs.rm('dbfs:/user/hive/warehouse/athlete_event_silver', recurse = True)

-- COMMAND ----------

DROP TABLE IF EXISTS athlete_event_bronze;
CREATE TABLE IF NOT EXISTS athlete_event_bronze
USING DELTA
AS
  SELECT * FROM athlete_events

-- COMMAND ----------

SELECT
  COUNT(*),
  NOC
FROM 
  athlete_event_bronze
WHERE 
  LENGTH(NOC) > 3
GROUP BY 
  NOC

-- COMMAND ----------

UPDATE athlete_event_bronze
  SET NOC = 
    (CASE 
    WHEN NOC LIKE '%Great Britain%' THEN 'GBR'
    WHEN NOC LIKE '%Canada%' THEN 'CAN'
    WHEN NOC LIKE '%Netherlands%' THEN 'NED'
    WHEN NOC LIKE '%Australia%' THEN 'ANZ'
    WHEN NOC LIKE '%Canada%' THEN 'CAN'
    WHEN NOC LIKE '%Germany' THEN 'GDR'
    WHEN NOC LIKE '%Russia%' OR NOC LIKE '%URS%' THEN 'RUS'
    WHEN NOC LIKE '%Spirit%' OR NOC LIKE '%United States%' OR NOC LIKE '%New York%' THEN 'USA'
    WHEN NOC LIKE '%Sweden%' THEN 'SWE'
    WHEN NOC LIKE '%Austria%' THEN 'AUT'
    WHEN NOC LIKE '%Fiji%' THEN 'FIJ'
    WHEN NOC LIKE '%France%' THEN 'FRA'
    ELSE NOC
    END)

-- COMMAND ----------

SELECT *
FROM athlete_event_bronze

-- COMMAND ----------

SELECT
  COUNT(ID) AS athlete_num,
  SUM(CASE WHEN Medal = 'Gold' OR Medal = 'Silver' OR Medal = 'Bronze' THEN 1 ELSE 0 END) medal_num,
  NOC
FROM athlete_event_bronze
GROUP BY 
  NOC

-- COMMAND ----------

DROP TABLE IF EXISTS athlete_event_silver;

CREATE TABLE athlete_event_silver
USING DELTA
AS 
  SELECT
    COUNT(ID) AS athlete_num,
    SUM(CASE WHEN Medal = 'Gold' OR Medal = 'Silver' OR Medal = 'Bronze' THEN 1 ELSE 0 END) medal_num,
    NOC
  FROM athlete_event_bronze
  GROUP BY 
    NOC

-- COMMAND ----------

SELECT *
FROM athlete_event_silver

-- COMMAND ----------

DESCRIBE DETAIL athlete_event_silver

-- COMMAND ----------

-- MAGIC %r
-- MAGIC library(SparkR)
-- MAGIC 
-- MAGIC athlete_event_silver <- read.df('dbfs:/user/hive/warehouse/athlete_event_silver')
-- MAGIC athletedf <- SparkR::collect(athlete_event_silver)

-- COMMAND ----------

-- MAGIC %r
-- MAGIC library(tidyverse)
-- MAGIC 
-- MAGIC ggplot(athletedf, aes(x = athlete_num, y = medal_num)) + 
-- MAGIC geom_point() + 
-- MAGIC geom_smooth(method = lm)

-- COMMAND ----------

-- MAGIC %r
-- MAGIC 
-- MAGIC install.packages('statsr')
-- MAGIC library(statsr)

-- COMMAND ----------

-- MAGIC %r
-- MAGIC medal_athlete <- lm(athlete_num ~ medal_num, data = athletedf)
-- MAGIC summary(medal_athlete)

-- COMMAND ----------

-- MAGIC %r
-- MAGIC ## Check for linearity and constant variability
-- MAGIC ggplot(data = medal_athlete, aes(x = .fitted, y = .resid)) + 
-- MAGIC geom_jitter() + 
-- MAGIC geom_hline(yintercept = 0, linetype = "dashed") + 
-- MAGIC xlab("Fitted Values") + 
-- MAGIC ylab("Residuals")

-- COMMAND ----------

-- MAGIC %r
-- MAGIC 
-- MAGIC ##Check for nearly normal residuals
-- MAGIC 
-- MAGIC ggplot(data = medal_athlete, aes(x = .resid)) + 
-- MAGIC geom_histogram() + 
-- MAGIC xlab("Residuals")

-- COMMAND ----------

-- MAGIC %r
-- MAGIC 
-- MAGIC ##Check for nearly normal residuals
-- MAGIC 
-- MAGIC ggplot(data = medal_athlete, aes(sample = .resid)) + 
-- MAGIC stat_qq()

-- COMMAND ----------

-- MAGIC %md
-- MAGIC 
-- MAGIC #Push to Github

-- COMMAND ----------

-- MAGIC %sh
-- MAGIC git init
-- MAGIC git config --global user.email "lin.michelle2@gmail.com"
-- MAGIC git config --global user.name "mclin671"
-- MAGIC git remote set-url origin https://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@github.com/mclin671/SparkSQL_Olympics.git

-- COMMAND ----------

-- MAGIC %sh 
-- MAGIC 
-- MAGIC git pull origin main --allow-unrelated-histories

-- COMMAND ----------

-- MAGIC %sh 
-- MAGIC git add . 
-- MAGIC git commit -m "Initial Commit"
-- MAGIC git push -u origin main

-- COMMAND ----------


