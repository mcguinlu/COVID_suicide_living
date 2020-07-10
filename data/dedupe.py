import pandas as pd
import re
from fuzzywuzzy import fuzz
from tqdm import tqdm
from datetime import date
#import os

#os.chdir("C:\\Users\\lm16564\\OneDrive - University of Bristol\\Documents\\rrr\\COVID_suicide_living")

def fuzzymatch(a, b, min_match):
    if fuzz.ratio(a, b) > min_match:  # matching ore than specified ratio
        # print("-------match to {} ratio---------".format(min_match))
        # print(a)
        # print(b)
        # print(fuzz.ratio(a, b))
        return True

    return False  # match is less, therefore text is too different


def rowmatch(row, indexes, mydict, min_match_title, min_match_abstrct):
    try:
        t1 = row["title"].strip().lower()  # remove trailing spaces and lower the letters
    except:
        return False, None
    try:
        a1 = row["abstract"].strip().lower()[:495]
    except:
        a1 = ""

    match = False
    index = None  # save location of the duplicate in master df

    if t1 != "":  # only attempt matching if there is a title to start with.
        for i in indexes:  # attempt to match this title with every title in the master frame
            try:
                t2 = mydict["title"][i].strip().lower()  # remove trailing spaces and lower the letters
            except:
                t2 = ""
            match = fuzzymatch(t1, t2, min_match_title)

            if match:  # continue only if titles are matching
                if a1 != "":
                    try:
                        a2 = mydict["abstract"][i].strip().lower()[:495]
                    except:
                        a2 = ""
                        # print("matched title but found no second abstract")
                        # print(t1)
                        # print(t2)

                        index = i
                        break

                    match = fuzzymatch(a1, a2, min_match_abstrct)
                    if match:
                        # print("Matched on full record")
                        # print(t1)
                        # print(t2)
                        # print(a1)
                        # print(a2)
                        index = i
                        break
                    else:
                        index = None



                else:
                    # print("Matched title, but found no first abstract, returning True")#for e.g. dblp records there are no abstracts, but we still want to deduplicate and get rid of them!
                    # print(t1)
                    # print(t2)
                    # print("-------")

                    index = i
                    break

    return match, index  # is true if match was found and loop broken. Is false if all rows were checked and fuzzy matching was below the threshold


def dedupe_loop_within(wos, name, min_match_title, min_match_abstract):
    wos_orig = wos.copy()
    wos_orig["Deduplication_Notes"] = ["" for d in wos_orig["title"].values]  # has no abstracts
    orig_length = wos.shape[0]
    print("Deduplicating {} data".format(name))
    new_rows = []
    counter = 0
    masterdf = pd.DataFrame(columns=wos.columns.values)
    #

    pd.set_option("display.max_colwidth", 5000)

    with tqdm(total=wos.shape[0]) as pbar:

        for i, row in wos.iterrows():
            mydict = masterdf.to_dict()
            indexes = list(masterdf.index.values)  # iterate over dict rather than df for 6 times speedup!
            match, index = rowmatch(row, indexes, mydict, min_match_title, min_match_abstract)
            if match:
                # print(index)
                # print(masterdf.at[index, "Deduplication_Notes"])
                wos_orig.at[i, "Deduplication_Notes"] = "{} CHECK DUPLICATE STATUS [SOURCE:{} {}]".format(
                    str(wos_orig.at[index, "Deduplication_Notes"]), str(masterdf.loc[index]["source"]),
                    re.sub(r"\s+", " ",
                           masterdf.loc[index].to_string().replace("\n", "; "))).strip()  # modift masterdf in place

                # print(masterdf.at[index, "Deduplication_Notes"])
                counter += 1
            else:
                masterdf = masterdf.append(row, ignore_index=True)
                # print(masterdf.head())
            pbar.update(1)

    print(
        "Adding {} rows out of {} to master data and identified {} as duplicates".format(masterdf.shape[0], orig_length,
                                                                                         counter))

    # masterdf.to_csv("all_results.csv")
    # wos_orig.to_csv( "all_results_with_duplicates-{}.csv".format(date.today()))  # save version that has dupes in it
    masterdf.to_csv(os.path.join("results", "all_results.csv"))
    wos_orig.to_csv(os.path.join("results", "all_results_with_duplicates-{}.csv".format(
        date.today())))  # save version that has dupes in it

    return masterdf


def dedupe_loop_additional(original, new, name, min_match_title, min_match_abstract):
    print("Deduping additional dataframe")
    #print(new_df.shape[0])
    #wos_orig = wos.copy()
    #wos_orig["Deduplication_Notes"] = ["" for d in wos_orig["title"].values]  # has no abstracts
    #orig_length = wos.shape[0]
    #print("Deduplicating {} data".format(name))
    new_rows = []
    counter = 0
    masterdf = original.copy()
    new_deduped=pd.DataFrame(columns=list(new.columns))
    #
    dupe_list=[]


    pd.set_option("display.max_colwidth", 5000)#otherwise cell contents are cut away
    print("Iterating {} rows of new data to find duplicates".format(new.shape[0]))
    with tqdm(total=new.shape[0]) as pbar:

        for i, row in new.iterrows():
            mydict = masterdf.to_dict()
            indexes = list(masterdf.index.values)  # iterate over dict rather than df for 6 times speedup!
            # print(row.to_string())
            match, index = rowmatch(row, indexes, mydict, min_match_title, min_match_abstract)
            if match:
                # print(index)
                # print(masterdf.at[index, "Deduplication_Notes"])
                def dupe_report(new, orig):
                    id=orig["ID"]
                    source_orig = orig["source"]
                    source_new = new["source"]
                    title_orig=orig["title"]
                    title_new = new["title"]
                    abstract_new = new["abstract"]
                    abstract_orig = orig["abstract"]
                    author_new = new["authors"]
                    author_orig = orig["authors"]
                    link_new = new["link"]
                    link_orig = orig["link"]
                    date_added=date.today()
                    #decision_orig=orig["initial_decision"]

                    return pd.Series([id,source_orig,source_new,title_orig,title_new,abstract_orig,abstract_new,author_orig,author_new,link_orig,link_new, date_added], index=["ID","source original", "source new", "title original","title new","abstract original","abstract new","author original","author new","link original","link new", "date added"])


                dupe_list.append(dupe_report(row, masterdf.loc[index]))#add a duplication report to the list
                #print("For new entry:{}\nCHECK DUPLICATE STATUS [SOURCE:{} {}]".format(re.sub(r"\s+", " ",row.to_string().replace("\n", "; ")), str(masterdf.loc[index]["source"]),re.sub(r"\s+", " ",masterdf.loc[index].to_string().replace("\n", "; "))).strip())


                counter += 1
            else:
                masterdf = masterdf.append(row, ignore_index=True)#add new entry to master data becasue it is not a duplicate
                new_deduped = new_deduped.append(row, ignore_index=True)#add new entry to a data fram that just consists of new entries
                # print(masterdf.head())
            pbar.update(1)

    print("Adding {} rows out of {} to master data and identified {} as duplicates".format(new_deduped.shape[0], new.shape[0],counter))

    print("Replacing NA with empty spaces...")
    new_deduped= new_deduped.fillna("")
    new_deduped['link'] = new_deduped['link'].apply(lambda x: re.sub("https://www.doi.org", "https://doi.org", x))
    new_deduped.to_csv(name)
    print("Saved the new, deduplicated rows as {}".format(name))

    #################Deduplication report: append new duplicates to it
    dup_df=pd.read_csv("data\\results\\dedupe_report.csv")
    counter=0
    for e in dupe_list:

        if not ((dup_df["ID"] == e[0]) & (dup_df['source original'] == e[1])& (dup_df['source new'] == e[2]) & (dup_df['abstract new'] == e[6]) & (dup_df['title new'] == e[4])).any():
            dup_df = dup_df.append(e, ignore_index=True)#append new just if it is not in there already
            counter +=1
        # else:#duplicate of duplicate, can discard
        #     print("Following duplicate of duplicate: \n{}\n".format(e[1]))

    dup_df.to_csv("data\\results\\dedupe_report.csv",index=False)
    print("Added {} records to the dedupe_report.csv".format(counter))

def dedupe_me(path, match_title, match_abstract, path_2=""):
    df = pd.read_csv(path)
    print("Reading the file all_results_tmp.csv that contains the previous results. It has {} records, and its {} column names are {}".format(df.shape[0], len(list(df.columns)), list(df.columns)))
    if path_2 != "":
        df_toadd = pd.read_csv(path_2)
        print("Reading the file new_results.csv that contains the new results. It has {} records, and its {} column names are {}".format(df_toadd.shape[0], len(list(df.columns)), list(df_toadd.columns)))


        dedupe_loop_additional(df, df_toadd, "data\\results\\new_and_deduped.csv", match_title, match_abstract)
    else:
        #use this to deduplicate results within one single spreadsheet - not needed for LSR app since deduplication hapens based on a deduplicated database+ newly added records
        dedupe_loop_within(df, "data\\results\\new_and_deduped.csv", match_title, match_abstract)


path = "data\\results\\all_results_tmp.csv"#is previous results but with some replacements
path_new = "data\\results\\new_results.csv"

if not os.path.exists("data\\results\\dedupe_report.csv"):
    dupes=pd.DataFrame(columns=["ID","source original", "source new","title original","title new","abstract original","abstract new","author original","author new","link original","link new", "date added"])
    dupes.to_csv("data\\results\\dedupe_report.csv",index=False)
#alternative if you have problems with relative and absolute paths, try this! its the OS modeule that has an option to grab the current working directorys absolute path:

dedupe_me(path, 95, 90, path_new)  # use this when adding data. creates the file "results/all_results_updated.csv"
