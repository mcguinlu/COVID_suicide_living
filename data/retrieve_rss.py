import feedparser
import pandas as pd
import time

calls=[x * 30 for x in range(0, 17)]#specify how man calls should me made. one call retrieves 30 papers, hence [x * 30 for x in range(0, 10)] means to retrieve last 300 papers, or 200 for 6000.
master_df=pd.DataFrame(columns=["title", "abstract", "authors","link","ID","publication_date","update_date", "subject", "is_medRxiv"])#results from all calls will be merged here.
wait=[x*300 for x in range(1,20)]

for call in calls:
    if call in wait:
        print('pausing for 10 secs...')
        time.sleep(10)
    feed_address="https://api.biorxiv.org/covid19/{}/xml".format(call)
    NewsFeed = feedparser.parse(feed_address)
    entries = [e for e in NewsFeed.entries]


    title =[]
    abstract=[]
    authors=[]
    link=[]
    publication_date=[]
    update_date=[]
    subject=[]
    ID=[]
    is_medRxiv=[]

    deduplicate={}
    print("Found {} entries in the rss feed".format(len(entries)))
    for e in entries:
        #print(e)
        abstract.append(e.get("description", "Not available"))
        #print(e.get("description", "Not available"))
        title.append(e.get("title", "Not available"))
        ID.append(e.get("id", "Not available"))
        if e.get("link", None) is not None: 
            link.append(e.get("link")).strip('"')
        else:
            link.append(e.get("link", "Not available"))    


        if "medrxiv" in e.get("link", "Not available"):
            is_medRxiv.append("True")
        else:
            is_medRxiv.append("False")

        print(e.get("prism_publicationdate", "Not available"))
        publication_date.append(e.get("prism_publicationdate", "Not available"))



        update_date.append(e.get("updated", "Not available"))
        subject.append("")#no info?
        if (e.get("prism_publicationdate", "Not available") != e.get("updated", "Not available")):
            print("The following bioRxiv entry has been updated!")
            print(e)
        try:
            authors.append(("; ".join(a.get("name","Not available") for a in e.get("authors", [{"name": "Not available"}]))))
        except:
            print("Fixing empty author instance")
            authors.append(("; ".join(a["name"] for a in e["authors"] if "name" in a.keys())))
            print(authors[-1])

        #print(e["updated"])
    #print(entries[1].keys())
    #deduplicate ={k:"" for k in ID}

    #print(len(deduplicate.keys()))#check if there are ducplicate IDS
    print('Number of RSS posts : {}'.format(len(NewsFeed.entries)))
    print('Number of titles : {}'.format(len(title)))

    df= pd.DataFrame(list(zip(title, abstract, authors,link,ID,publication_date,update_date, subject, is_medRxiv)), columns=["title", "abstract", "authors","link","ID","publication_date","update_date", "subject", "is_medRxiv"])

    frames=[master_df, df]#simple list for concat of results
    master_df= pd.concat(frames, ignore_index=True)


master_df.to_csv("data/bioRxiv_rss.csv")
print(df.head())
