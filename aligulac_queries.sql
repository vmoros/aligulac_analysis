-- All players have ups and downs. Who has had the highest trough? In other words, who has had the best worst moment?
SELECT p.tag, MIN(r.rating)
FROM public.rating AS r
JOIN public.player AS p ON r.player_id = p.id
GROUP BY p.tag
ORDER BY MIN(r.rating) DESC

-- What was the most unfair match ever i.e. which match had the highest difference of player ratings?

SELECT p_a.tag, p_b.tag, CASE WHEN r_a.rating > r_b.rating THEN p_a.tag WHEN r_b.rating > r_a.rating THEN p_b.tag END AS "Favored player",
e.fullname, ABS(r_a.rating - r_b.rating) AS "Rating difference"
FROM public.match AS m
JOIN public.rating AS r_a ON m.rta_id = r_a.id
JOIN public.rating AS r_b ON m.rtb_id = r_b.id
JOIN public.player AS p_a ON m.pla_id = p_a.id
JOIN public.player AS p_b ON m.plb_id = p_b.id
JOIN public.event AS e ON m.eventobj_id = e.id
ORDER BY "Rating difference" DESC
LIMIT 100

-- Most unfair offline match?
SELECT p_a.tag, p_b.tag, CASE WHEN r_a.rating > r_b.rating THEN p_a.tag WHEN r_b.rating > r_a.rating THEN p_b.tag END AS "Favored player",
e.fullname, ABS(r_a.rating - r_b.rating) AS "Rating difference"
FROM public.match AS m
JOIN public.rating AS r_a ON m.rta_id = r_a.id
JOIN public.rating AS r_b ON m.rtb_id = r_b.id
JOIN public.player AS p_a ON m.pla_id = p_a.id
JOIN public.player AS p_b ON m.plb_id = p_b.id
JOIN public.event AS e ON m.eventobj_id = e.id
WHERE m.offline = true
ORDER BY "Rating difference" DESC
LIMIT 100

-- Most unfair GSL Code S match?
SELECT p_a.tag, p_b.tag, CASE WHEN r_a.rating > r_b.rating THEN p_a.tag WHEN r_b.rating > r_a.rating THEN p_b.tag END AS "Favored player",
e.fullname, m.sca, m.scb, ABS(r_a.rating - r_b.rating) AS "Rating difference"
FROM public.match AS m
JOIN public.rating AS r_a ON m.rta_id = r_a.id
JOIN public.rating AS r_b ON m.rtb_id = r_b.id
JOIN public.player AS p_a ON m.pla_id = p_a.id
JOIN public.player AS p_b ON m.plb_id = p_b.id
JOIN public.event AS e ON m.eventobj_id = e.id
WHERE e.fullname LIKE '%Code S%'
ORDER BY "Rating difference" DESC
LIMIT 100

-- What was the biggest upset in GSL Code S history? In other words, what was the most unevenly skilled match in Code S in which the favored player lost?
SELECT p_a.tag, p_b.tag,
CASE WHEN r_a.rating > r_b.rating THEN p_a.tag ELSE p_b.tag END AS "Favored player",
CASE WHEN m.sca > m.scb THEN p_a.tag ELSE p_b.tag END AS "Victorious player",
e.fullname, ABS(r_a.rating - r_b.rating) AS "Rating difference"
FROM public.match AS m
JOIN public.rating AS r_a ON m.rta_id = r_a.id
JOIN public.rating AS r_b ON m.rtb_id = r_b.id
JOIN public.player AS p_a ON m.pla_id = p_a.id
JOIN public.player AS p_b ON m.plb_id = p_b.id
JOIN public.event AS e ON m.eventobj_id = e.id
WHERE e.fullname LIKE '%Code S%'
AND (CASE WHEN r_a.rating > r_b.rating THEN p_a.tag ELSE p_b.tag END) != (CASE WHEN m.sca > m.scb THEN p_a.tag ELSE p_b.tag END)
ORDER BY "Rating difference" DESC
LIMIT 100

-- Who has played the most matches?
SELECT p.tag, COUNT(*) AS "Number of matches"
FROM public.player AS p
JOIN public.match AS m ON p.id IN (m.pla_id, m.plb_id)
GROUP BY p.tag
ORDER BY "Number of matches" DESC

-- Who has played the most offline matches?
SELECT p.tag, COUNT(*) AS "Number of matches"
FROM public.player AS p
JOIN public.match AS m ON p.id IN (m.pla_id, m.plb_id)
WHERE m.offline = true
GROUP BY p.tag
ORDER BY "Number of matches" DESC

-- Every player is stronger in some matchups and weaker in others. Which player has had the biggest skill gap between matchups? In other words, who has had the biggest difference between their best matchup and their worst matchup?
SELECT p.tag,
--GREATEST(r.rating_vp, r.rating_vt, r.rating_vz) - LEAST(r.rating_vp, r.rating_vt, r.rating_vz) AS "Gap",
CASE WHEN GREATEST(r.rating_vp, r.rating_vt, r.rating_vz) = r.rating_vp THEN p.race || 'vP'
     WHEN GREATEST(r.rating_vp, r.rating_vt, r.rating_vz) = r.rating_vt THEN p.race || 'vT'
     ELSE p.race || 'vZ' END AS "Strongest matchup",
CASE WHEN LEAST(r.rating_vp, r.rating_vt, r.rating_vz) = r.rating_vp THEN p.race || 'vP'
     WHEN LEAST(r.rating_vp, r.rating_vt, r.rating_vz) = r.rating_vt THEN p.race || 'vT'
     ELSE p.race || 'vZ' END AS "Weakest matchup"
FROM public.player AS p
JOIN public.rating AS r ON p.id = r.player_id
ORDER BY GREATEST(r.rating_vp, r.rating_vt, r.rating_vz) - LEAST(r.rating_vp, r.rating_vt, r.rating_vz) DESC

-- Who has the highest number of ratings in the top 1,000 ratings of all time?
SELECT foo.tag, COUNT(*)
FROM (
SELECT p.tag
FROM public.rating AS r
JOIN public.player AS p ON r.player_id = p.id
ORDER BY r.rating DESC LIMIT 1000
) AS foo
GROUP BY foo.tag
ORDER BY COUNT(*) DESC

-- Which moment in time had the highest total skill?
SELECT pe.start, pe.end, SUM(r.rating) AS "Total skill"
FROM public.period AS pe
JOIN public.rating AS r ON pe.id = r.period_id
GROUP BY pe.start, pe.end
ORDER BY "Total skill" DESC

-- racial breakdowns of the top 100 players in each period
SELECT pe.id, pe.start, pe.end, pl.race, COUNT(*)
FROM public.period AS pe
JOIN public.rating AS r ON pe.id = r.period_id
JOIN public.player AS pl ON r.player_id = pl.id
WHERE r.position <= 100
GROUP BY pe.id, pe.start, pe.end, pl.race
ORDER BY pe.id ASC, pl.race ASC

--  which periods were most lopsided
SELECT pe.id, pe.start, pe.end, pl.race, COUNT(*)
FROM public.period AS pe
JOIN public.rating AS r ON pe.id = r.period_id
JOIN public.player AS pl ON r.player_id = pl.id
WHERE r.position <= 100
GROUP BY pe.id, pe.start, pe.end, pl.race
ORDER BY COUNT(*) DESC