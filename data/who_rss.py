
import pandas as pd

import urllib3
import xmltodict

def get_feed(link):



    def getxml(link):
        url = link


        http = urllib3.PoolManager()

        response = http.request('GET', url)
        try:
            data = xmltodict.parse(response.data)
        except:
            print("Failed to parse xml from response")
        return data


    print("Retrieving data...")
    dat = getxml(link)
    docs = dat["response"]["result"]["doc"]
    print("Parsing {} documents...".format(len(docs)))

    title = []
    abstract = []
    authors = []
    link = []
    publication_date = []
    update_date = []
    subject = []
    ID = []
    is_medRxiv = []

    #arr str, float
    for d in docs:
        ti=""
        au = ""
        ab=""
        li=""
        subj=""

        
        is_med="False"

        ###############################GET MAIN PUBLICATION DATA
        for ar in d["arr"]:
            #print(ar)
            #######################First step is to get content type and content itself, trying to catch errors early on by filling NA if retrieval fails for any reason
            try:
                content = ar["str"]
                if isinstance(content, list):
                    content="; ".join(content)


            except:
                content= "NA"
            try:
                content_tag=ar["@name"]
            except:
                content_tag="NA"

            ###############################################################################FILL FIELDS OF INTEEST
            ################################abstract: multiple options:
            # if content_tag == "ab_en":
            #     if ab == "":
            #         ab= content
            #     else:
            #         ab = "{}\nTranslated abstract:\n{}".format(ab, content)
            if content_tag == "ab":

                if ab == "":
                    ab= content
                else:
                    ab = "{}\nOriginal abstract:\n{}".format(ab, content)
                ab= ab.replace("(AU);", "(AU)\n\n")#some additions made by who people

                #print(ab)
            # if content_tag == "ab_en":
            #     if ab == "":
            #         ab= content
            #     else:
            #         ab = "{}\nSpanish abstract:\n{}".format(ab, content)

            #
            #TODO: add specific language abstracts that should be retrieved, if applicable
            #
             ###########titles
            # if content_tag == "ti_en":
            #     if ti == "":
            #         ti= content
            #     else:
            #         ti = "{}\nTranslated title:\n{}".format(ti, content)
            if content_tag == "ti":
                if ti == "":
                    ti= content
                else:
                    ti = "{}\nOther title:\n{}".format(ti, content)
            # if content_tag == "ti_es":
            #     if ti == "":
            #         ti = content
            #     else:
            #         ti = "{}\nSpanish title:\n{}".format(ti, content)

            #
            # TODO: add specific language titles that should be retrieved, if applicable
            #
             ##################other fields
            if content_tag == "au":
                if au == "":
                    au=content 
                else:
                    au=au+"; "+content

            if content_tag == "ur":
                if li == "":
                    li = content
                else:
                    li = "{}; {}".format(li, content)
            if content_tag == "mh":
                if subj == "":
                    subj = content
                else:
                    subj = subj+ "; " + content
                    
            if content_tag == "db":
                if subj == "":
                    subj = "Database: " + content
                else:
                    subj = subj + "; Database: " + content
            if content_tag == "cp":
                if subj == "":
                    subj = "Country: " + content
                else:
                    subj = subj + "; Country: " + content
            if content_tag == "type":
                if subj == "":
                    subj = "Publication type: " + content
                else:
                    subj = subj + "; Publication type: " + content
            if content_tag == "fo":
                if subj == "":
                    subj = "Publication details: " + content
                else:
                    subj = subj + "; Publication details: " + content
            if content_tag == "fo":
                if subj == "":
                    subj = "Publication details: " + content
                else:
                    subj = subj + "; Publication details: " + content
    ####################ADDITIONAL PUBLICATION DATA
        dat = "NA"
        id = "NA"
        for s in d["str"]:

            try:
                content = s["#text"]
                if isinstance(content, list):
                    content = "; ".join(content)


            except:
                content = "NA"
            try:
                content_tag = s["@name"]
            except:
                content_tag = "NA"


            #######################################date and ID retrieval
            if content_tag == "da":
                #print(content)
                if dat == "NA":
                    dat = content
                else:
                    dat = "{}; Published: {}".format(dat, content)
            if content_tag == "entry_date":
                #print(content)
                if dat == "NA":
                    dat = "Date added to database: "+content
                else:
                    dat = "{}; Added to database: {}".format(dat, content)

            if content_tag == "id":

                if id == "NA":
                    id = content
                else:
                    id = "{}\nDates:\n{}".format(id, content)
            ########################################################################add to lists for df
        title.append(ti)
        abstract.append(ab)
        authors.append(au)
        link.append(li)
        publication_date.append(dat)
        update_date.append("NA")
        subject.append(subj)
        ID.append(id)
        is_medRxiv.append("False")
        #print("-------")



    print('Number of RSS posts : {}'.format(len(docs)))
    print('Number of titles : {}'.format(len(title)))
    #
    df= pd.DataFrame(list(zip(title, abstract, authors,link,ID,publication_date,update_date, subject, is_medRxiv)), columns=["title", "abstract", "authors","link","ID","publication_date","update_date", "subject", "is_medRxiv"])
    return df

print("Starting WHO retrieval")
df = get_feed("https://search.bvsalud.org/global-literature-on-novel-coronavirus-2019-ncov/?output=xml&lang=en&from=0&sort=DATENTRY_DESC&format=summary&count=9000&fb=&page=1&skfp=&index=tw&q=")
print("Writing to file in working directory: who_rss.csv")
df.to_csv("data/who_rss.csv")
