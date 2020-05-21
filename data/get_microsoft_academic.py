import pandas as pd
#
#Script to turn the CORD-19 database, which includes Elsevier, CZI, PMC data and Microsoft Adademic indexed articles into a database that is searchable for our living review
#
#
#

max_date="2020"#get no older publications than this year

title =[]
abstract=[]
authors=[]
link=[]#dois
publication_date_orig=[]
publication_date=[]
update_date=[]
subject=[]
ID=[]
url=[]
source=[]

doi_string="https://www.doi.org/"#to piece toether hyperlinks

df = pd.read_csv("metadata.csv")
print(df.head())
print("No of entries at start: {}".format(len(df["cord_uid"])))
#print(df["Microsoft Academic Paper ID"][43134])
#df = df[df["Microsoft Academic Paper ID"].notna()]
#print("No of entries with MA ID: {}".format(len(df["cord_uid"])))
df = df[df["pubmed_id"].isna()]
print("No of entries with no PubMed: {}".format(len(df["cord_uid"])))

df.columns = ['Microsoft Academic Paper ID' if x=='mag_id' else x for x in df.columns]


#print(type(df["publish_time"][1]))

for index, row in df.iterrows():

    mydate=str(row["publish_time"])#date format is really bad in these data, need to be cleaned below
    #print(mydate)
    if mydate[0:4] == max_date and row["source_x"]!= "biorxiv" and row["source_x"]!= "medrxiv" and row["source_x"]!= "WHO"and row["source_x"]!= "arxiv":#use this to filter results. We don't need records pre-2020 and records that come from the arxives or the WHO
        if len(mydate)==4:
            publication_date.append(mydate)
        else:
            #print(mydate)
            #print("x")
            parts = mydate.split("-")
            try:
                if len(parts[1])==1:
                    parts[1]="0"+ parts[1]
                if len(parts[2])==1:
                    parts[2]="0"+ parts[2]

                publication_date.append(str(parts[2])+"/"+str(parts[1])+"/"+str(parts[0]))
            except:
                print(parts)
                publication_date.append(mydate)

        publication_date_orig.append(row["publish_time"])
        title.append(row["title"])
        abstract.append(row["abstract"])
        authors.append(row["authors"])
        link.append(doi_string+str(row["doi"]))
        url.append(row["url"])
        source.append(row["source_x"])

        update_date.append("NA")
        subject.append("NA")
        if str(row["Microsoft Academic Paper ID"]) != "nan":
            ID.append("MA ID "+str(int(row["Microsoft Academic Paper ID"])))
        elif str(row["doi"]) != "nan":
            ID.append(str(row["doi"]))
        else:
            ID.append("CORD-19 ID " + str(row["cord_uid"]))




df= pd.DataFrame(list(zip(title, abstract, authors,link,url,source,ID,publication_date,update_date, subject,publication_date_orig)), columns=["title", "abstract", "authors","link","URL","Source","ID","publication_date","update_date", "subject","Uncleaned publication data"])
df.to_csv("MA_elsevier_database.csv")
print(df.head())






print("".format())
print("".format())
print("".format())
print("".format())
