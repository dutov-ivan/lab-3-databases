-- a) Найпростіші умови та оператори порівняння
SELECT first_name, last_name, enlistment_date
    FROM servicemen
    WHERE enlistment_date <= '2022-02-24';

-- б) Умов з використанням логічних операторів AND, OR та NOT та їх комбінацій.
-- Знаходимо перспективних військовослужбовців (командирів та тих, хто гарно вчиться)


-- 2)
-- h. Об’єднання та перетин запитів
SELECT s.first_name, s.last_name, u.name AS "Unit name", um.role, ms.code, ss.proficiency_level, ss.attained_at
FROM servicemen s
JOIN unit_members um ON s.id = um.serviceman_id
JOIN units u ON um.unit_id = u.id
JOIN servicemen_specialties ss ON s.id = ss.serviceman_id
JOIN military_specialties ms ON ss.specialty_id = ms.id
WHERE ss.proficiency_level >= 3
  AND ss.attained_at >= NOW() - INTERVAL '2 years'

UNION

SELECT s.first_name, s.last_name, u.name AS "Unit name", um.role, ms.code, ss.proficiency_level, ss.attained_at
FROM servicemen s
JOIN unit_members um ON s.id = um.serviceman_id
JOIN units u ON um.unit_id = u.id
JOIN servicemen_specialties ss ON s.id = ss.serviceman_id
JOIN military_specialties ms ON ss.specialty_id = ms.id
WHERE um.role = 'COMMANDER';

-- Перетин
-- Всі підрозділи, у яких командир має ранг офіцера або в яких більше 20 видів амуніції.
-- Units where commander has officer rank

-- Units that have more than 20 munition types
SELECT
    u.id,
    u.name,
    NULL AS first_name,
    NULL AS last_name,
    NULL AS rank_name,
    SUM(ms.quantity) AS munition_quantity
FROM units u
JOIN munition_supplies ms ON u.id = ms.unit_id
GROUP BY u.id, u.name
HAVING SUM(ms.quantity) > 100;
