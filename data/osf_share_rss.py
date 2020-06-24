import feedparser
import pandas as pd
from datetime import date


def get_records(query, db_name):#create lists of data for a data frame from a given query, and return the frame
    title = []
    abstract = []
    authors = []
    link = []
    publication_date = []
    update_date = []
    subject = []
    ID = []
    is_medRxiv = []

    NewsFeed = feedparser.parse(query)

    entries = [e for e in NewsFeed.entries]
    for e in entries:#loop through results. Note: will only ever do up to 250 resilts per query. adjust dates and make multiple queries if needed!!!!!!!!!!!!


        title.append(e.get("title", "Not available"))#get method to avoid key errors
        abstract.append(e.get("summary", "Not available"))
        authors.append(e.get("author", "Not available"))
        link.append(e.get("link", "Not available"))
        update_date.append(e.get("updated", "Not available"))
        ID.append(e.get("id", "Not available"))
        is_medRxiv.append("False")

        t=e.get("published", "Not available").split("T")[0]#returns date with time etc attached, so split it here casue we dont need result to the minute...
        publication_date.append(t)


        terms = "; ".join([en["term"] for en in e.get("tags", [{"term": "Not available"}])])#parse as list and join as string all keywords.
        subject.append(terms)


    print('Number of RSS posts in {} : {}'.format(db_name, len(entries)))
    df = pd.DataFrame(list(zip(title, abstract, authors, link, ID, publication_date, update_date, subject, is_medRxiv)),
                      columns=["title", "abstract", "authors", "link", "ID", "publication_date", "update_date","subject", "is_medRxiv"])
    return df

############
print("Getting records from Psy- and SocArXives...")
start="2020-06-08"#dates to complete the query. Make a new query for each datasource, onlu need to adjust the database of interest in the format statment of the strings below
end=date.today()
psy_query="https://share.osf.io/api/v2/atom/?elasticQuery=%7B%22bool%22%3A%20%7B%22must%22%3A%20%7B%22query_string%22%3A%20%7B%22query%22%3A%20%22(mental%20health%20OR%20selfharm*%20OR%20self-harm*%20OR%20selfinjur*%20OR%20self-injur*%20OR%20selfmutilat*%20OR%20self-mutilat*%20OR%20suicid*%20OR%20parasuicid*%20OR%20suicide%20OR%20suicidal%20ideation%20OR%20attempted%20suicide%20OR%20drug%20overdose%20OR%20self%3Fpoisoning%20OR%20self-injurious%20behavio%3Fr%20OR%20self%3Fmutilation%20OR%20automutilation%20OR%20suicidal%20behavio%3Fr%20OR%20self%3Fdestructive%20behavio%3Fr%20OR%20self%3Fimmolation%20OR%20cutt*%20OR%20head%3Fbang%20OR%20overdose%20OR%20self%3Fimmolat*%20OR%20self%3Finflict*%20OR%20hopelessness%20OR%20powerlessness%20OR%20helplessness%20OR%20negative%20attitude%20OR%20emotional%20negativism%20OR%20pessimism%20OR%20depress*%20OR%20hopelessness%20depression%20OR%20passivity%20OR%20sad-affect%20OR%20sadness%20OR%20decreased%20affect%20OR%20cognitive%20rigidity%20OR%20suicidality%20OR%20suicide%20ideation)%20AND%20(coronavirus%20disease%3F19%20OR%20sars%3Fcov%3F2%20OR%20mers%3Fcov%20OR%2019%3Fncov%20OR%202019%3Fncov%20OR%20n%3Fcov%20OR%20COVID-19%20OR%20COVID%202019%20OR%20coronavirus%20OR%20nCoV%20OR%20HCoV)%22%7D%7D%2C%20%22filter%22%3A%20%5B%7B%22term%22%3A%20%7B%22sources%22%3A%20%22{}%22%7D%7D%2C%20%7B%22range%22%3A%20%7B%22date%22%3A%20%7B%22gte%22%3A%20%22{}%7C%7C%2Fd%22%2C%20%22lte%22%3A%20%22{}%7C%7C%2Fd%22%7D%7D%7D%5D%7D%7D".format("PsyArXiv",start,end)
soc_query="https://share.osf.io/api/v2/atom/?elasticQuery=%7B%22bool%22%3A%20%7B%22must%22%3A%20%7B%22query_string%22%3A%20%7B%22query%22%3A%20%22(mental%20health%20OR%20selfharm*%20OR%20self-harm*%20OR%20selfinjur*%20OR%20self-injur*%20OR%20selfmutilat*%20OR%20self-mutilat*%20OR%20suicid*%20OR%20parasuicid*%20OR%20suicide%20OR%20suicidal%20ideation%20OR%20attempted%20suicide%20OR%20drug%20overdose%20OR%20self%3Fpoisoning%20OR%20self-injurious%20behavio%3Fr%20OR%20self%3Fmutilation%20OR%20automutilation%20OR%20suicidal%20behavio%3Fr%20OR%20self%3Fdestructive%20behavio%3Fr%20OR%20self%3Fimmolation%20OR%20cutt*%20OR%20head%3Fbang%20OR%20overdose%20OR%20self%3Fimmolat*%20OR%20self%3Finflict*%20OR%20hopelessness%20OR%20powerlessness%20OR%20helplessness%20OR%20negative%20attitude%20OR%20emotional%20negativism%20OR%20pessimism%20OR%20depress*%20OR%20hopelessness%20depression%20OR%20passivity%20OR%20sad-affect%20OR%20sadness%20OR%20decreased%20affect%20OR%20cognitive%20rigidity%20OR%20suicidality%20OR%20suicide%20ideation)%20AND%20(coronavirus%20disease%3F19%20OR%20sars%3Fcov%3F2%20OR%20mers%3Fcov%20OR%2019%3Fncov%20OR%202019%3Fncov%20OR%20n%3Fcov%20OR%20COVID-19%20OR%20COVID%202019%20OR%20coronavirus%20OR%20nCoV%20OR%20HCoV)%22%7D%7D%2C%20%22filter%22%3A%20%5B%7B%22term%22%3A%20%7B%22sources%22%3A%20%22{}%22%7D%7D%2C%20%7B%22range%22%3A%20%7B%22date%22%3A%20%7B%22gte%22%3A%20%22{}%7C%7C%2Fd%22%2C%20%22lte%22%3A%20%22{}%7C%7C%2Fd%22%7D%7D%7D%5D%7D%7D".format("SocArXiv",start,end)


psa= get_records(psy_query, "PsyArXiv")#call each database querystring
sca= get_records(soc_query, "SocArXiv")

psa.to_csv("psyArXiv.csv")#save in working dir
sca.to_csv("socArXiv.csv")
print("Saved resulting csv files in working directory")