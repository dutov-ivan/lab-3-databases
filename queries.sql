-- 1) Створити запити для вибірки даних з використанням (разом 8 запитів):
-- Необхідно зробити щонайменше 8 запитів

-- 1
-- a. Найпростіші умови та оператори порівняння
SELECT first_name, last_name, enlistment_date
FROM servicemen
WHERE enlistment_date <= '2022-02-24';

-- b. Умов з використанням логічних операторів AND, OR та NOT та їх комбінацій.

-- 2
-- Усі локації більше за певну довготу та більше за певну широту
SELECT name, longitude, latitude
FROM locations
WHERE latitude > 50
  AND longitude > 22;

-- 3
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

-- 4
-- Атрибути рангів, де можна вибирати з можливих значень, проте вони є необов'язковими
SELECT id, attribute_name, attribute_type, enum_values
FROM rank_attributes
WHERE is_enum
  AND NOT is_mandatory;

-- c. З використанням виразів над стовпцями, як в якості новостворених стовпців, так і умовах

-- 5
-- Отримуємо дані про військові спеціальності в новому (вигаданому) форматуванні:
SELECT id,
       INITCAP(name)      as pretty_name,
       LPAD(code, 4, '0') as pretty_code
FROM military_specialties;

-- 6
-- Створюємо колонку з віком військовослужбовця для контрактників віку 18-21 року.
SELECT id, last_name, first_name, middle_name, AGE(date_of_birth) as age, service_type, discharge_date
FROM servicemen
WHERE (EXTRACT(YEAR FROM AGE(date_of_birth)) BETWEEN 18 AND 21)
  AND service_type = 'contract';

-- d. Використання операторів:
-- i. Приналежності множині

-- 7
-- Усі військовослужбовці, що мають активний тип служби (не резерв тощо)
SELECT last_name, first_name, middle_name, sex, service_type, enlistment_date
FROM servicemen
WHERE service_type IN ('conscription', 'contract', 'mobilized');

-- ii. Приналежності діапазону

-- 8
-- Приналежність місць певному діапазону довготи та широти
SELECT name, longitude, latitude
FROM locations
WHERE latitude BETWEEN 10 AND 52.33
  AND longitude BETWEEN 22 AND 80;

-- iii. Відповідності шаблону

-- 9
-- Шукаємо назви спеціальностей, що пов'язані з ракетами
SELECT id, name, code
FROM military_specialties
WHERE LOWER(name) LIKE 'ракет%';

-- 2) Створити запити з використанням підзапитів та з’єднань (разом 11
-- запитів) (в запитах повинні використовуватись 2 та більше таблиць):

-- a. Використання підзапитів в рядку вибірки полів (у секції select) та
-- вибірки з таблиць (у секції from)

-- 1
-- Виводимо військовослужбовців разом з кількістю військових спеціальностей
SELECT id,
       last_name,
       first_name,
       middle_name,
       date_of_birth,
       (SELECT COUNT(*) FROM servicemen_specialties ss WHERE ss.serviceman_id = s.id) as specialty_count
FROM servicemen s;

-- 2
-- Виводимо військовослужбовців разом із найбільш нещодавно отриманою військовою спеціальністю
SELECT
    s.id,
    s.last_name,
    s.first_name,
    s.middle_name,
    s.date_of_birth,
    sp.name AS last_specialty_name,
    ss.attained_at AS attained_at
FROM servicemen AS s
JOIN (
    SELECT
        serviceman_id,
        MAX(attained_at) AS last_attained_at
    FROM servicemen_specialties
    GROUP BY serviceman_id
) AS LastSpecialty
    ON s.id = LastSpecialty.serviceman_id
JOIN servicemen_specialties AS ss
    ON ss.serviceman_id = LastSpecialty.serviceman_id
   AND ss.attained_at = LastSpecialty.last_attained_at
JOIN military_specialties AS sp
    ON sp.id = ss.specialty_id;

-- b. Використання підзапитів в умовах з конструкціями EXISTS, IN
-- 3
-- Розглядаємо військовослужбовців, що опанували хоча б одну військову спеціальність на високому рівні
SELECT s.id,
    s.last_name,
    s.first_name,
    s.middle_name,
    s.date_of_birth,
    s.enlistment_date
FROM servicemen s
WHERE EXISTS(
    SELECT 1
    FROM servicemen_specialties ss
    WHERE ss.serviceman_id = s.id
    AND proficiency_level = 5
);


-- c. Декартовий добуток
-- 4
-- Виводимо розклад для кожного військовослужбовця в усіх підрозділах на місяць вперед
SELECT
    u.id AS unit_id,
    u.name AS unit_name,
    s.id AS serviceman_id,
    s.last_name,
    s.first_name,
    d::date AS duty_date
FROM unit_members um
JOIN servicemen s ON s.id = um.serviceman_id
JOIN units u ON u.id = um.unit_id
CROSS JOIN generate_series(
    date_trunc('month', CURRENT_DATE)::date,
    (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::date,
    INTERVAL '1 day'
) AS d
WHERE
    (um.discharged_at IS NULL OR um.discharged_at >= d)
    AND um.assigned_at <= d
ORDER BY u.id, s.id, duty_date;

-- d. З’єднання декількох таблиць за рівністю та умовою відбору
-- 5
-- Знаходимо підрозділи та їхні збереження разом із типами амуніції, що мають калібр.

SELECT u.id           AS unit_id,
       u.name         AS unit_name,
       mt.name        AS munition_name,
       mt.description,
       ma.attribute_name,
       mv.value_float AS caliber_value,
       ms.quantity
FROM units u,
     munition_supplies ms,
     munition_types mt,
     munition_categories mc,
     munition_category_attributes ma,
     munition_type_attribute_values mv
WHERE ms.unit_id = u.id
  AND ms.munition_type_id = mt.id
  AND mt.category_id = mc.id
  AND mc.id = ma.category_id
  AND ms.munition_type_id = mt.id
  AND mv.attribute_id = ma.id
  AND ma.attribute_name LIKE 'Калібр%'
  AND ma.attribute_type = 'FLOAT';

-- e. Внутрішнього з'єднання
-- 6
-- Військовослужбовці та їхня чинна роль в підрозділах
SELECT s.id, s.last_name, s.first_name, s.service_type, um.role, u.name
    FROM servicemen s
JOIN unit_members um ON um.serviceman_id = s.id
    JOIN units u ON um.unit_id = u.id
WHERE um.discharged_at IS NULL AND s.discharge_date IS NULL
ORDER BY u.name;

-- f. Лівого зовнішнього з'єднання
-- 7
-- Переглядаємо, чи всі атрибути амуніції виставлені, як необхідні, так і опціональні

SELECT
    ma.id AS attribute_id,
    ma.attribute_name,
    ma.attribute_type,
    ma.is_mandatory,
    CASE
        WHEN COUNT(DISTINCT mv.munition_type_id) < COUNT(DISTINCT mt.id)
            THEN 'не виставлено всюди'
        ELSE 'виставлено'
    END AS status
FROM munition_category_attributes AS ma
JOIN munition_categories AS mc ON ma.category_id = mc.id
JOIN munition_types AS mt ON mt.category_id = mc.id
LEFT JOIN munition_type_attribute_values AS mv
    ON mv.attribute_id = ma.id
    AND mv.munition_type_id = mt.id
GROUP BY
    ma.id, ma.attribute_name, ma.attribute_type, ma.is_mandatory;

-- g. Правого зовнішнього з'єднання
-- 8
-- Переглядаємо, чи всі атрибути рангів мають значення
-- для кожного військовослужбовця, як необхідні, так і опціональні

SELECT
    ra.id,
    ra.attribute_name,
    ra.is_mandatory,
    CASE
        WHEN COUNT(DISTINCT rv.serviceman_id) < COUNT(DISTINCT s.id)
            THEN 'не виставлено всюди'
        ELSE 'виставлено'
    END AS status
FROM rank_attributes AS ra
JOIN servicemen AS s
    ON s.current_rank_id = ra.id
LEFT JOIN rank_attribute_values AS rv
    ON rv.attribute_id = ra.id
    AND rv.serviceman_id = s.id
GROUP BY
    ra.id,
    ra.attribute_name,
    ra.is_mandatory
ORDER BY ra.id, ra.attribute_name;


-- h. Об’єднання та перетин запитів
-- 9
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
-- 10
-- Всі підрозділи, у яких командир має ранг офіцера та в яких більше 20 видів амуніції.

SELECT
    u.id, u.name, u.parent_unit_id, u.location_id, u.unit_level_id, u.created_at
FROM units u
JOIN unit_members um ON u.id = um.unit_id
JOIN servicemen s ON s.id = um.serviceman_id
JOIN ranks r ON r.id = s.current_rank_id
JOIN rank_categories rc ON rc.id = r.category_id
WHERE um.role = 'COMMANDER'
  AND rc.name LIKE 'Офіцер%'

INTERSECT

SELECT
    u.id, u.name, u.parent_unit_id, u.location_id, u.unit_level_id, u.created_at
FROM units u
JOIN (
    SELECT ms.unit_id
    FROM munition_supplies ms
    JOIN munition_types mt ON ms.munition_type_id = mt.id
    GROUP BY ms.unit_id
    HAVING COUNT(DISTINCT mt.id) > 5
) AS mun ON u.id = mun.unit_id;


