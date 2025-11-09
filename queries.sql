-- 1) Створити запити для вибірки даних з використанням (разом 8 запитів):
-- a. Найпростіші умови та оператори порівняння
SELECT first_name, last_name, enlistment_date
FROM servicemen
WHERE enlistment_date <= '2022-02-24';

-- b. Умов з використанням логічних операторів AND, OR та NOT та їх комбінацій.
-- Усі локації більше за певну довготу та більше за певну широту
SELECT name, longitude, latitude
FROM locations
WHERE latitude > 50
  AND longitude > 22;

-- Шукаємо командирів, в тому числі колишніх, для навчання молодих офіцерів.
SELECT serviceman_id,
       assigned_at,
       discharged_at,
       role,
       (discharged_at IS NULL) as is_active
FROM unit_members
WHERE role = 'COMMANDER'
  AND (assigned_at <= '2024-01-01'
    OR discharged_at <= '2023-02-24');

-- Атрибути рангів, де можна вибирати з можливих значень, проте вони є необов'язковими
SELECT id, attribute_name, attribute_type, enum_values
FROM rank_attributes
WHERE is_enum
  AND NOT is_mandatory;

-- c. З використанням виразів над стовпцями, як в якості новостворених стовпців, так і умовах
-- Отримуємо дані про військові спеціальності в новому (вигаданому) форматуванні:
SELECT id,
       INITCAP(name)      as pretty_name,
       LPAD(code, 4, '0') as pretty_code
FROM military_specialties;

-- Створюємо колонку з віком військовослужбовця для контрактників віку 18-21 року.
SELECT id, last_name, first_name, middle_name, AGE(date_of_birth) as age, service_type, discharge_date
FROM servicemen
WHERE (EXTRACT(YEAR FROM AGE(date_of_birth)) BETWEEN 18 AND 21)
  AND service_type = 'contract';

-- d. Використання операторів:
-- i. Приналежності множині
-- Усі військовослужбовці, що мають активний тип служби (не резерв тощо)
SELECT last_name, first_name, middle_name, sex, service_type, enlistment_date
FROM servicemen
WHERE service_type IN ('conscription', 'contract', 'mobilized');

-- ii. Приналежності діапазону
-- Приналежність місць певному діапазону довготи та широти
SELECT name, longitude, latitude
FROM locations
WHERE latitude BETWEEN 10 AND 52.33
  AND longitude BETWEEN 22 AND 80;

-- iii. Відповідності шаблону
-- Шукаємо назви спеціальностей, що пов'язані з ракетами
SELECT id, name, code
FROM military_specialties
WHERE LOWER(name) LIKE 'ракет%';

-- 2) Створити запити з використанням підзапитів та з’єднань (разом 11
-- запитів) (в запитах повинні використовуватись 2 та більше таблиць):

-- h. Об’єднання та перетин запитів
-- Знаходимо перспективних військовослужбовців (командирів та тих, хто гарно вчиться)

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
SELECT u.id,
       u.name,
       NULL             AS first_name,
       NULL             AS last_name,
       NULL             AS rank_name,
       SUM(ms.quantity) AS munition_quantity
FROM units u
         JOIN munition_supplies ms ON u.id = ms.unit_id
GROUP BY u.id, u.name
HAVING SUM(ms.quantity) > 100;
