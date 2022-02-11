
import feedparser
import pandas as pd
from datetime import date


def get_records(query, db_name):  # create lists of data for a data frame from a given query, and return the frame
    title = []
    abstract = []
    authors = []
    link = []
    publication_date = []
    update_date = []
    subject = []
    ID = []
    is_medRxiv = []

    import ssl

    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        # Legacy Python that doesn't verify HTTPS certificates by default
        pass
    else:
        # Handle target environment that doesn't support HTTPS verification
        ssl._create_default_https_context = _create_unverified_https_context


    NewsFeed = feedparser.parse(query)
    #print(NewsFeed)

    entries = [e for e in NewsFeed.entries]
    for e in entries:  # loop through results. Note: will only ever do up to 250 resilts per query. adjust dates and make multiple queries if needed!!!!!!!!!!!!

        title.append(e.get("title", "Not available"))  # get method to avoid key errors
        abstract.append(e.get("summary", "Not available"))
        authors.append(e.get("author", "Not available"))
        link.append(e.get("link", "Not available"))
        update_date.append(e.get("updated", "Not available"))
        ID.append(e.get("id", "Not available"))
        is_medRxiv.append("False")

        t = e.get("published", "Not available").split("T")[
            0]  # returns date with time etc attached, so split it here casue we dont need result to the minute...
        publication_date.append(t)

        terms = "; ".join([en["term"] for en in e.get("tags", [
            {"term": "Not available"}])])  # parse as list and join as string all keywords.
        subject.append(terms)

    print('Number of RSS posts in {} : {}'.format(db_name, len(entries)))
    df = pd.DataFrame(list(zip(title, abstract, authors, link, ID, publication_date, update_date, subject, is_medRxiv)),
                      columns=["title", "abstract", "authors", "link", "ID", "publication_date", "update_date",
                               "subject", "is_medRxiv"])
    return df


############
print("Getting records from Psy- and SocArXives...")
start = "2021-12-12"  # dates to complete the query. Make a new query for each datasource, onlu need to adjust the database of interest in the format statment of the strings below
end = date.today()
print("Date today should be in the format yyyy-mm-dd. Check that it is: {}".format(end))

psy_query = "https://share.osf.io/api/v2/feeds/atom/?elasticQuery=%7B%22bool%22%3A+%7B%22must%22%3A+%7B%22query_string%22%3A+%7B%22query%22%3A+%22%28mental+health+OR+selfharm%2A+OR+self-harm%2A+OR+selfinjur%2A+OR+self-injur%2A+OR+selfmutilat%2A+OR+self-mutilat%2A+OR+suicid%2A+OR+parasuicid%2A+OR+suicide+OR+suicidal+ideation+OR+attempted+suicide+OR+drug+overdose+OR+self%3Fpoisoning+OR+self-injurious+behavio%3Fr+OR+self%3Fmutilation+OR+automutilation+OR+suicidal+behavio%3Fr+OR+self%3Fdestructive+behavio%3Fr+OR+self%3Fimmolation+OR+cutt%2A+OR+head%3Fbang+OR+overdose+OR+self%3Fimmolat%2A+OR+self%3Finflict%2A+OR+hopelessness+OR+powerlessness+OR+helplessness+OR+negative+attitude+OR+emotional+negativism+OR+pessimism+OR+depress%2A+OR+hopelessness+depression+OR+passivity+OR+sad-affect+OR+sadness+OR+decreased+affect+OR+cognitive+rigidity+OR+suicidality+OR+suicide+ideation%29+AND+%28coronavirus+disease%3F19+OR+sars%3Fcov%3F2+OR+mers%3Fcov+OR+19%3Fncov+OR+2019%3Fncov+OR+n%3Fcov+OR+COVID-19+OR+COVID+2019+OR+coronavirus+OR+nCoV+OR+HCoV%29%22%7D%7D%2C+%22filter%22%3A+%5B%7B%22term%22%3A+%7B%22sources%22%3A+%22PsyArXiv%22%7D%7D%2C+%7B%22range%22%3A+%7B%22date%22%3A+%7B%22gte%22%3A+%22{}%7C%7C%2Fd%22%2C+%22lte%22%3A+%22{}%7C%7C%2Fd%22%7D%7D%7D%5D%7D%7D".format(start,end)

#print(psy_query)
soc_query = "https://share.osf.io/api/v2/feeds/atom/?elasticQuery=%7B%22bool%22%3A+%7B%22must%22%3A+%7B%22query_string%22%3A+%7B%22query%22%3A+%22%28mental+health+OR+selfharm%2A+OR+self-harm%2A+OR+selfinjur%2A+OR+self-injur%2A+OR+selfmutilat%2A+OR+self-mutilat%2A+OR+suicid%2A+OR+parasuicid%2A+OR+suicide+OR+suicidal+ideation+OR+attempted+suicide+OR+drug+overdose+OR+self%3Fpoisoning+OR+self-injurious+behavio%3Fr+OR+self%3Fmutilation+OR+automutilation+OR+suicidal+behavio%3Fr+OR+self%3Fdestructive+behavio%3Fr+OR+self%3Fimmolation+OR+cutt%2A+OR+head%3Fbang+OR+overdose+OR+self%3Fimmolat%2A+OR+self%3Finflict%2A+OR+hopelessness+OR+powerlessness+OR+helplessness+OR+negative+attitude+OR+emotional+negativism+OR+pessimism+OR+depress%2A+OR+hopelessness+depression+OR+passivity+OR+sad-affect+OR+sadness+OR+decreased+affect+OR+cognitive+rigidity+OR+suicidality+OR+suicide+ideation%29+AND+%28coronavirus+disease%3F19+OR+sars%3Fcov%3F2+OR+mers%3Fcov+OR+19%3Fncov+OR+2019%3Fncov+OR+n%3Fcov+OR+COVID-19+OR+COVID+2019+OR+coronavirus+OR+nCoV+OR+HCoV%29%22%7D%7D%2C+%22filter%22%3A+%5B%7B%22term%22%3A+%7B%22sources%22%3A+%22SocArXiv%22%7D%7D%2C+%7B%22range%22%3A+%7B%22date%22%3A+%7B%22gte%22%3A+%22{}%7C%7C%2Fd%22%2C+%22lte%22%3A+%22{}%7C%7C%2Fd%22%7D%7D%7D%5D%7D%7D".format(
     start, end)
#print(soc_query)
#print(soc_query)
psa = get_records(psy_query, "PsyArXiv")  # call each database querystring
sca = get_records(soc_query, "SocArXiv")

psa.to_csv("data/psyArXiv.csv")  # save in working dir
sca.to_csv("data/socArXiv.csv")
print("Saved resulting csv files in working directory")
