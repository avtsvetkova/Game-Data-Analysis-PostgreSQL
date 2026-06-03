/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Цветкова Анастасия Валерьевна
 * Дата: 21.12.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков	

-- 1.1. Доля платящих пользователей по всем данным:

-- Запрос: 
SELECT 
	COUNT(id) AS total_users -- общее количество игроков, зарегистрированных в игре
	, SUM(payer) AS payer_count -- количество платящих игроков
	, ROUND(AVG(payer) * 100, 2) AS payer_percent -- доля платящих игроков от общего количества пользователей, зарегистрированных в игре
FROM fantasy.users u 
;

-- Результат:
' 
total_users|payer_count|payer_percent|
-----------+-----------+-------------+
      22214|       3929|        17.69|
'


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:

-- Запрос: 
SELECT 
	r.race -- раса персонажа
	, SUM(u.payer) AS payer_count -- количество платящих игроков этой расы
	, COUNT(u.id) AS total_users -- общее количество зарегистрированных игроков этой расы
	, ROUND(((SUM(u.payer) / COUNT(u.id)::numeric) * 100), 4) AS payer_for_race_percent -- доля платящих игроков среди всех зарегистрированных игроков этой расы
FROM fantasy.users u 
LEFT JOIN fantasy.race r USING(race_id)
GROUP BY r.race 
ORDER BY payer_for_race_percent DESC 
;

-- Результат:
'
race    |payer_count|total_users|payer_for_race_percent|
--------+-----------+-----------+----------------------+
Demon   |        238|       1229|               19.3653|
Hobbit  |        659|       3648|               18.0647|
Human   |       1114|       6328|               17.6043|
Northman|        626|       3562|               17.5744|
Orc     |        636|       3619|               17.5739|
Angel   |        229|       1327|               17.2570|
Elf     |        427|       2501|               17.0732|
'



-- Задача 2. Исследование внутриигровых покупок

-- 2.1. Статистические показатели по полю amount:

-- Запрос:
SELECT 
	COUNT(transaction_id) AS transaction_count -- общее количество покупок
	, SUM(amount) AS total_amount -- суммарная стоимость всех покупок
	, MIN(amount) AS min_amount -- минимальная стоимость покупки
	, MAX(amount) AS max_amount -- максимальная стоимость покупки
	, ROUND(AVG(amount)::numeric, 2) AS avg_amount -- среднее значение
	, PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount -- медиана
	, ROUND(STDDEV(amount)::numeric, 2) AS stdev_amount -- стандартное отклонение стоимости покупки
FROM fantasy.events e
;

-- Результат:
'
transaction_count|total_amount|min_amount|max_amount|avg_amount|median_amount|stdev_amount|
-----------------+------------+----------+----------+----------+-------------+------------+
          1307678|   686615040|       0.0|  486615.1|    525.69|        74.86|     2517.35|
'


-- 2.2: Аномальные нулевые покупки:

-- Запрос:	
WITH zero_amount AS (
	SELECT 
		COUNT(*) AS total_amount_count -- количество всех покупок
		, (
			SELECT 
				COUNT(*) AS zero_amount_count -- количество покупок с нулевой стоимостью
			FROM fantasy.events e
			WHERE amount = 0 OR amount IS NULL
		)
	FROM fantasy.events e
)
SELECT *
	, ROUND((zero_amount_count / total_amount_count::numeric) * 100, 2) AS zero_to_total_amount_perc -- доля нулевых покупок от общего числа
FROM zero_amount
;

-- Результат:
'
total_amount_count|zero_amount_count|zero_to_total_amount_perc|
------------------+-----------------+-------------------------+
           1307678|              907|                     0.07|
'


-- 2.3: Популярные эпические предметы:

-- Запрос:	
WITH total_buyers AS (
	SELECT 
		COUNT(DISTINCT e.id) AS total_buyers -- общее число внутриигровых покупателей
		, COUNT(DISTINCT e.transaction_id) AS total_trans -- общее число покупок
	FROM fantasy.events e 
	WHERE e.amount > 0 -- фильтрация покупок с нулевой стоимостью
)
SELECT 
	i.item_code 
	, i.game_items 
	, COUNT(e.transaction_id) AS trans_by_items_count -- общее количество внутриигровых покупок по предметам
	, ROUND(COUNT(e.transaction_id)::numeric / tb.total_trans * 100, 2) AS trans_by_items_perc -- доля внутриигровых покупок по предметам от всех покупок
--	, COUNT(DISTINCT e.id) AS buyers_by_items_count
	, ROUND(COUNT(DISTINCT e.id)::numeric / tb.total_buyers * 100, 2) AS buyers_by_items_perc -- доля игроков, которые хотя бы раз покупали предмет	
FROM fantasy.events e 
LEFT JOIN fantasy.items i USING(item_code)
CROSS JOIN total_buyers tb
WHERE e.amount > 0 -- фильтрация покупок с нулевой стоимостью
GROUP BY i.item_code, i.game_items, tb.total_trans, tb.total_buyers
ORDER BY trans_by_items_count DESC 
;

-- Результат:
' Топ-10:
item_code|game_items               |trans_by_items_count|trans_by_items_perc|buyers_by_items_perc|
---------+-------------------------+--------------------+-------------------+--------------------+
     6010|Book of Legends          |             1004516|              76.87|               88.41|
     6011|Bag of Holding           |              271875|              20.81|               86.77|
     6012|Necklace of Wisdom       |               13828|               1.06|               11.80|
     6536|Gems of Insight          |                3833|               0.29|                6.71|
     5964|Treasure Map             |                3084|               0.24|                5.46|
     4112|Amulet of Protection     |                1078|               0.08|                3.23|
     5411|Silver Flask             |                 795|               0.06|                4.59|
     5691|Strength Elixir          |                 580|               0.04|                2.40|
     5541|Glowing Pendant          |                 563|               0.04|                2.57|
     5999|Gauntlets of Might       |                 514|               0.04|                2.04|
'




-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:

-- Запрос:
WITH total_users AS (
    SELECT 
        u.race_id
        , COUNT(DISTINCT u.id) AS total_users -- общее количество зарегистрированных игроков по расам
    FROM fantasy.users u
    GROUP BY u.race_id
),
buyers AS (
    SELECT 
        u.race_id
        , COUNT(DISTINCT e.id) AS total_buyers -- количество игроков каждой расы, которые совершают внутриигровые покупки
        , ROUND(COUNT(DISTINCT e.id)::numeric / tu.total_users * 100, 2) AS buyers_perc -- доля покупателей от общего количества зарегистрированных игроков каждой расы
    FROM fantasy.events e
    LEFT JOIN fantasy.users u ON e.id = u.id
    LEFT JOIN total_users tu ON u.race_id = tu.race_id
    WHERE e.amount > 0 -- фильтрация покупок с нулевой стоимостью
    GROUP BY u.race_id, tu.total_users
),
payers AS (
    SELECT 
        u.race_id
        , ROUND(COUNT(DISTINCT e.id)::numeric / b.total_buyers * 100, 2) AS payers_perc -- доля платящих игроков среди игроков каждой расы, которые совершили внутриигровые покупки
    FROM fantasy.events e
    LEFT JOIN fantasy.users u ON e.id = u.id
    LEFT JOIN buyers b ON u.race_id = b.race_id
    WHERE e.amount > 0 -- фильтрация покупок с нулевой стоимостью
    	AND u.payer = 1 -- фильтр на платящих игроков (покупки за реальные деньги)
    GROUP BY u.race_id, b.total_buyers
),
buyer_stats AS (
    SELECT
        u.race_id
        , u.id AS user_id
        , COUNT(e.transaction_id) AS trans_count -- количество всех покупок по расе и игроку
        , AVG(e.amount) AS avg_trans_amount -- средняя сумма одной покупки игрока
        , SUM(e.amount) AS total_trans_amount -- общая сумма всех покупок игрока
    FROM fantasy.events e
    LEFT JOIN fantasy.users u ON e.id = u.id
    WHERE e.amount > 0
    GROUP BY u.race_id, u.id
),
avg_metrics AS (
    SELECT
        race_id
        , ROUND(AVG(trans_count)::numeric, 2) AS avg_trans_per_buyer -- среднее количество покупок на одного игрока, совершившего внутриигровые покупки
        , ROUND(AVG(avg_trans_amount)::numeric, 2) AS avg_trans_amount_per_buyer -- средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
        , ROUND(AVG(total_trans_amount)::numeric, 2) AS total_trans_amount_per_buyer -- средняя суммарная стоимость всех покупок на одного игрока, совершившего внутриигровые покупки
    FROM buyer_stats
    GROUP BY race_id
)
SELECT
    r.race
    , tu.total_users -- общее количество зарегистрированных игроков
    , b.total_buyers -- количество игроков, которые совершают внутриигровые покупки
    , b.buyers_perc -- их доля от общего количества зарегистрированных игроков
    , p.payers_perc -- доля платящих игроков среди игроков, которые совершили внутриигровые покупки
    , am.avg_trans_per_buyer -- среднее количество покупок на одного игрока, совершившего внутриигровые покупки
    , am.avg_trans_amount_per_buyer -- средняя стоимость одной покупки на одного игрока, совершившего внутриигровые покупки
    , am.total_trans_amount_per_buyer -- средняя суммарная стоимость всех покупок на одного игрока, совершившего внутриигровые покупки
FROM total_users tu
LEFT JOIN buyers b USING (race_id)
LEFT JOIN payers p USING (race_id)
LEFT JOIN avg_metrics am USING (race_id)
LEFT JOIN fantasy.race r USING (race_id)
ORDER BY r.race;


-- Результат:
'
race    |total_users|total_buyers|buyers_perc|payers_perc|avg_trans_per_buyer|avg_trans_amount_per_buyer|total_trans_amount_per_buyer|
--------+-----------+------------+-----------+-----------+-------------------+--------------------------+----------------------------+
Angel   |       1327|         820|      61.79|      16.71|             106.80|                    775.55|                    48668.65|
Demon   |       1229|         737|      59.97|      19.95|              77.87|                    735.48|                    41197.38|
Elf     |       2501|        1543|      61.70|      16.27|              78.79|                    791.84|                    53761.65|
Hobbit  |       3648|        2266|      62.12|      17.70|              86.13|                    699.90|                    47620.92|
Human   |       6328|        3921|      61.96|      18.01|             121.40|                    733.62|                    48941.01|
Northman|       3562|        2229|      62.58|      18.21|              82.10|                    781.05|                    62520.66|
Orc     |       3619|        2276|      62.89|      17.40|              81.74|                    709.44|                    41760.04|
'




