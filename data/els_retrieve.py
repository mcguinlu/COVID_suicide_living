# -*- coding: utf-8 -*-
"""
Created on Tue Mar 31 15:21:25 2020

@author: Babatunde Kazeem Olorisade and Lena Schmidt
"""

"""An example program that uses the elsapy module"""

from elsapy.elsclient import ElsClient
from elsapy.elsdoc import FullDoc, AbsDoc
from elsapy.elssearch import ElsSearch
import json
import pandas as pd
import re
#import os

#os.chdir("C:\\Users\\lm16564\\OneDrive - University of Bristol\\Documents\\rrr\\COVID_suicide_living")

"""
Note: Create a config.json file in the format

{
apikey: "APIKEY"
}

placed in same folder as the python module

Requirements:
    pip install elsapy pandas
"""
#databases=['scopus','sciencedirect']

#####Search know how: SCOPUS####
#What we know so far:
# search is not case sensitive
# PUBYEAR > 2000 retrieves all records after 2000, but no record from 2000 itself
# AND can be used to combine any query
# TITLE({neuropsychological evidence from}) retrieves exact matches of those words in titles but one can not use wildcards with curly braces! Curly braces retrieve exact phrase matches
# \"self-injur*\" here we can use wildcards to retrieve self-injuries etc
# \"self?harm*\", \"self*harm*\" does not replace a space or hyphen, and the character replaced by ? is not optional,, so something like behavio?r does not match anything that mentions the word "behavior" itself! It would match behaviour, or behavioXr
# \"randomized\",\"randomi?ed\",\"randomised\" retrieve exactly the same results! somehow scopus takes care of this automatically, not sure what the scope of this is, so use ? to be sure.

#EXAMPLE search query: "TITLE-ABS-KEY({neuropsychological evidence from}) AND TITLE({transient binding}) AND PUBYEAR > 2000"
#Example code: retrieve_elsevier("TITLE(\"randomized controlled trial of\") AND PUBYEAR > 2019", "scopus")

#retrieve_elsevier("TITLE-ABS-KEY(\"selfharm*\" OR \"self harm*\" OR \"self-harm*\" OR \"self injur*\" OR \"selfinjur*\" OR \"self-injur*\" OR \"selfmutilat*\" OR \"self mutilat*\" OR \"self-mutilat*\" OR \"suicid*\" OR \"parasuicid*\" OR \"suicide\" OR \"suicidal ideation\" OR \"attempt* suicide\" OR \"suicide attempt*\" OR \"drug overdose\" OR \"selfpoisoning\" OR \"self poisoning\" OR \"self-poisoning\" OR \"self-injurious behavi*\" OR \"selfmutilation\" OR \"self mutilation\" OR \"self-mutilation\" OR \"automutilation\" OR \"suicidal behavi*\" OR \"selfdestructive behavi*\" OR \"self destructive behavi*\" OR \"self-destructive behavi*\" OR \"selfimmolat*\" OR \"self-immolat*\" OR \"self immolat*\" OR \"cutt*\" OR \"headbang\" OR \"head-bang\" OR \"head bang\" OR \"overdose\" OR \"selfinflict*\" OR \"self-inflict*\" OR \"self inflict*\" OR \"hopelessness\" OR \"powerlessness\" OR \"helplessness\" OR \"negative attitude*\" OR \"emotional negativism\" OR \"pessimism\" OR \"depress*\" OR \"hopelessness depression\" OR \"passivity\" OR \"sad-affect\" OR \"sadness\" OR \"decreased affect\" OR \"cognitive rigidity\" OR \"suicidality\" OR \"suicide ideation\") AND TITLE-ABS-KEY(\"nCoV\" OR \"HCoV\" OR \"covid 19\" OR \"covid-19\" OR \"covid19\" OR \"coronavirus\" OR \"19 ncov\" OR \"19-ncov\" OR \"2019 ncov\" OR \"2019-ncov\" OR \"2019ncov\" OR \"n-cov\" OR \"ncov\" OR \"coronavirus disease*\" OR \"sars-cov-2\" OR \"sars cov 2\" OR \"sars-cov 2\" OR \"mers-cov\" OR \"mers cov\") AND PUBYEAR > 2019", "scopus")


## Load configuration
con_file = open("data/config.json")

config = json.load(con_file)
con_file.close()

## Initialize client
client = ElsClient(config['apikey'])
#client.inst_token = config['insttoken']

def scidir_search(search_terms, database):
    """
    Initialize doc search object using ScienceDirect and/or Scopus, and execute search, 
    retrieving all results
    
    parameter
    ---------
    search_terms (str): The string to search
    database ([]): oprional databasename to search
    
    result
    ------
    doc_srch: dataframe
    """
    print("Running scidir_search...")

    print("Searching: {}".format(database))

    doc_srch = ElsSearch(search_terms,database)
    doc_srch.execute(client, get_all = True)
    print("Retrieved {} from {}. Writing to file for further processing".format(len(doc_srch.results),database))
    doc_srch.results_df.to_csv('data/' + str(database) + '.csv', index=None)
        

def reformat_and_update(filename):

    print('Reformatting '+ filename)
    result = pd.read_csv(filename)
    print(list(result.columns))
    try:
        print(list(result["authors"]))
    except:
        pass
    abstracts=[]

    #if filename == 'scopus.csv':
    #    result = result[['dc:identifier', 'dc:title','prism:coverDate', 'prism:coverDisplayDate', 'prism:doi', 'pubmed-id','pii']] #removing fields not needed
    #elif filename == 'sciencedirect.csv':
    #    result = result[['dc:identifier', 'dc:title','load-date', 'prism:coverDate', 'prism:doi', 'pii']]
           
    for index, record in result.iterrows():
        abstract = None
        try:
            if record['prism:doi'] and abstract is None:
                abstract = doi_fulltext(record['prism:doi'])
        except:
            pass
        try:
            if abstract is None and record['pii']:
                abstract = pii_fulltext(record['pii'])
        except:
            pass
        try:
            abstract = abstract.strip()
            print("Successful retrieval of abstract!")
            abstracts.append(abstract)
        except:
            print("Abstract is: {}".format(abstract))
            abstracts.append("")




    result["abstract"] = abstracts

    result.to_csv(filename, index = None)
    print("Done reformatting,. Exiting now...")
        
    

def doi_fulltext(doi = None):
    """ScienceDirect (full-text) document example using DOI"""
    doi_doc = FullDoc(doi = doi)
    if doi_doc.read(client):
        abstract =  doi_doc.data['coredata']['dc:description']
        return abstract

        
        
def pii_fulltext(pii = None):
    ## ScienceDirect (full-text) document example using PII
    pii_doc = FullDoc(sd_pii = pii)
    if pii_doc.read(client):
        abstract =  pii_doc.data['coredata']['dc:description']
        return abstract


def scopus_abs(scopus_id=None):
    ## Scopus (Abtract) document example
    # Initialize document with ID as integer
    scp_doc = AbsDoc(scp_id = scopus_id)
    if scp_doc.read(client):
        print("scp_doc.title: ", scp_doc.title)
        scp_doc.write()   

   
def lsr_pipeline_format(filename, source_name):
    print("Starting pipeline format..")
    df = pd.read_csv(filename)
    filler= ["Not available"]* df.shape[0]#list of row number length

    #['dc:identifier', 'dc:title', 'load-date', 'prism:coverDate', 'prism:doi', 'pii', 'abstract']

    title=[entry for entry in df.get('dc:title', filler)]
    abstract = [re.sub(r"^Abstract","",str(entry)).strip() for entry in df.get('abstract', filler)]
    abstract = [re.sub(r"\s{2,}", " ", str(entry)).strip() for entry in abstract]

    authors = ["" for x in df.get('dc:title', filler)]#empty list of proper length
    source = [source_name for x in df.get('dc:title', filler)]

    link = []
    url = []
    for l in df.get('prism:doi', filler):
        if l == "Not available":
            value="Not available"
        else:
            value="https://www.doi.org/{}".format(l)#piece together hyperlink
        link.append(value)#double, becasue the MA and rss feed files also have 2 different hyperlink fields
        url.append(value)


    ID = [entry for entry in df.get('prism:doi', filler)]
    publication_date = [entry for entry in df.get('prism:coverDate', filler)]  # there were 2 dates for each retrieved record, this is the earlier date
    update_date=["" for x in df.get('dc:title', filler)]#empty list of proper length
    subject=["" for x in df.get('dc:title', filler)]#empty list of proper length
    publication_date_orig=["" for x in df.get('dc:title', filler)]#empty list of proper length

    df = pd.DataFrame(list(zip(title, abstract, authors, link, url, source, ID, publication_date, update_date, subject,
                               publication_date_orig)),
                      columns=["title", "abstract", "authors", "link", "URL", "Source", "ID", "publication_date",
                               "update_date", "subject", "Uncleaned publication data"])

    df.to_csv(filename)

    print(list(df.columns))

def retrieve_elsevier(search_string, database):
    #
    #This is the main function for access to this script. It takes an elsevier search string as parameter,
    #and saves csv files into the working directory.
    #outputs:
    #
    #'sciencedirect.csv'
    #'scopus.csv'
    #
    #Sample usage:
    #retrieve_elsevier("TITLE(neuropsychological evidence from patients) AND PUBYEAR > 2011")

    print("Running main function, searching for: {}".format(search_string))

    scidir_search(search_string, database)#search

    ##filenames = ['sciencedirect.csv', 'scopus.csv']

    if database=="scopus":
        reformat_and_update('data/scopus.csv')#gets the abstracts and makes a csv file
        lsr_pipeline_format('data/scopus.csv', "Scopus")  # reformat the output again, this time for lsr pipeline
    else:
        reformat_and_update('data/sciencedirect.csv')  # gets the abstracts and makes a csv file
        lsr_pipeline_format('data/sciencedirect.csv', "ScienceDirekt")#reformat the output again, this time for lsr pipeline


####entry point
with open("data/search_scopus.txt","r") as f:
    query = f.readline()

print("Running scopus search with following query read from search_scopus.txt: {}".format(query))

retrieve_elsevier(query, "scopus")
