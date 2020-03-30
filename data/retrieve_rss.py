import feedparser
import pandas as pd


NewsFeed = feedparser.parse("https://connect.biorxiv.org/relate/feed/181")
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
for e in entries:
    abstract.append(e["description"])
    title.append(e["title"])
    ID.append(e["id"])
    link.append(e["link"])
    if "www.medrxiv.org" in e["link"]:
        is_medRxiv.append("True")
    else:
        is_medRxiv.append("False")

    publication_date.append(e['prism_publicationdate'])
    update_date.append(e['updated'])
    subject.append("")#no info?
    authors.append(("; ".join(a["name"] for a in e["authors"])))
    #print(e["updated"])
print(entries[1].keys())
deduplicate ={k:"" for k in ID}

print(len(deduplicate.keys()))#check if there are ducplicate IDS
print('Number of RSS posts : {}'.format(len(NewsFeed.entries)))
print('Number of titles : {}'.format(len(title)))

df= pd.DataFrame(list(zip(title, abstract, authors,link,ID,publication_date,update_date, subject, is_medRxiv)), columns=["title", "abstract", "authors","link","ID","publication_date","update_date", "subject", "is_medRxiv"])
df.to_csv("data/bioRxiv_rss.csv")
print(df.head())
