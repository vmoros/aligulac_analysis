import shutil
import os
import psycopg2

def main():
    regions = ['Korea', 'China', 'Taiwan', 'Europe', 'Oceania', 'North America',
                                        'South America', 'Other']
    periods = get_periods()
    conn_string = "host = 'localhost' dbname = 'postgres'\
user = 'postgres' password='postgres'"
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()

    # make fresh regions folder
    if os.path.exists("regions"):
        shutil.rmtree("regions")
        print("Deleting regions folder to start fresh")
    os.makedirs("regions")
    print("Making regions folder")
    
    for region in regions:
        # make file with region in file name
        with open("regions/" + region.replace(" ", "_") + ".txt", "w+") as f:
            # add header and center justification lines in reddit table format
            f.write("|Period ID|Period start|Period end|Race|Count of race in period|\n")
            f.write("|:-:|:-:|:-:|:-:|:-:|\n")
            # retrieve, transform, and write data for each period
            for period in periods:
                print("Working on period " + str(period) + " for region " + region)
                # get race info for region, period combination
                cursor.execute(region_query(region, period))
                # process each line into reddit table format and write to file
                # cursor.fetchall() gives a list of tuples
                query_output = tuple_list_to_reddit(cursor.fetchall())
                for s in query_output:
                    f.write("|" + s + "|\n")
        print("Made file with data for " + region)
                    
    cursor.close()
    conn.close()
    return

def region_query(region, period):
    return('''SELECT p.id, p.start, p.end, p.race, COUNT(*)
FROM (
SELECT pe.id, pe.start, pe.end, pl.race
FROM public.player AS pl
JOIN public.rating AS r ON pl.id = r.player_id
JOIN public.period AS pe ON r.period_id = pe.id
WHERE (CASE WHEN pl.country = 'KR' THEN 'Korea'
     WHEN pl.country = 'CN' THEN 'China'
     WHEN pl.country = 'TW' THEN 'Taiwan'
     WHEN pl.country IN ('AT', 'BE', 'BG', 'BY', 'CY', 'CZ', 'DE',
'DK', 'EE', 'ES', 'FI', 'FR', 'GB', 'GR', 'HR', 'HU', 'IE',
'IT', 'LT', 'LU', 'LV', 'MT', 'NL', 'NO', 'PL', 'PT', 'RO',
                  'RU', 'SE', 'SI', 'SK', 'UA', 'UK') THEN 'Europe'
     WHEN pl.country IN ('AS', 'AU', 'CK', 'FJ', 'PF', 'GU',
'KI', 'MH', 'FM', 'NR', 'NC', 'NZ', 'NU', 'NF', 'MP', 'PW',
'PG', 'PN', 'WS', 'SB', 'TK', 'TO', 'TV', 'VU', 'WF') THEN 'Oceania'
     WHEN pl.country IN ('AG', 'AI', 'AN', 'AW', 'BB', 'BL',
'BM', 'BS', 'BZ', 'CA', 'CR', 'CU', 'DM', 'DO', 'GD', 'GL',
'GP', 'GT', 'HN', 'HT', 'JM', 'KN', 'KY', 'LC', 'MF', 'MQ',
'MS', 'MX', 'NI', 'PA', 'PM', 'PR', 'SV', 'TC', 'TT', 'US',
                            'VC', 'VG', 'VI') THEN 'North America'
     WHEN pl.country IN ('AR', 'BO', 'BR', 'CL', 'CO', 'EC',
'FK', 'GF', 'GY', 'PE', 'PY', 'SR', 'UY', 'VE') THEN 'South America'
     ELSE 'Other' END) = '%s'
AND r.period_id = %s
ORDER BY r.rating DESC
LIMIT 100) AS p
GROUP BY p.id, p.start, p.end, p.race
ORDER BY p.race DESC''' % (region, period))

def get_periods():
    conn_string = "host = 'localhost' dbname = 'postgres'\
user = 'postgres' password='postgres'"
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    cursor.execute('''SELECT DISTINCT pe.id
                   FROM public.period AS pe''')
    return(sorted([p[0] for p in cursor.fetchall()]))

def tuple_list_to_reddit(tuple_list):
    # turn each tuple into a list of strings
    output = [[str(a) for a in tup] for tup in tuple_list]
    # join each list of strings with pipes
    output = ["|".join(a) for a in output]
    return(output)

