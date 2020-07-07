import pandas as pd
import re
from fuzzywuzzy import fuzz
from tqdm import tqdm
from datetime import date
import os

os.chdir("C:\\Users\\lm16564\\OneDrive - University of Bristol\\Documents\\rrr\\COVID_suicide_living")

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
        a1 = row["abstract"].strip().lower()[:495].strip()#crop to pubmed-length for matching purposes
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
                        a2 = mydict["abstract"][i].strip().lower()[:495].strip()#crop to pubmed-length for matching purposes
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

    previous=[]
    duplicate= []

    pd.set_option("display.max_colwidth", 5000)
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
                previous.append(re.sub(r"\s+", " ",row.to_string().replace("\n", "; ")))
                duplicate.append(re.sub(r"\s+", " ",masterdf.loc[index].to_string().replace("\n", "; ")))

                #print("For new entry:{}\nCHECK DUPLICATE STATUS [SOURCE:{} {}]".format(re.sub(r"\s+", " ",row.to_string().replace("\n", "; ")), str(masterdf.loc[index]["source"]),re.sub(r"\s+", " ",masterdf.loc[index].to_string().replace("\n", "; "))).strip())


                # print(masterdf.at[index, "Deduplication_Notes"])
                counter += 1
            else:
                masterdf = masterdf.append(row, ignore_index=True)
                new_deduped = new_deduped.append(row, ignore_index=True)
                # print(masterdf.head())
            pbar.update(1)

    print("Adding {} rows out of {} to master data and identified {} as duplicates".format(new_deduped.shape[0], new.shape[0],counter))

    print("Replacing NA with empty spaces...")
    new_deduped= new_deduped.fillna("")
    new_deduped['link'] = new_deduped['link'].apply(lambda x: re.sub("https://www.doi.org", "https://doi.org", x))
    new_deduped.to_csv(name)
    print("Saved the new, deduplicated rows as {}".format(name))

    deduped = pd.DataFrame(columns=["Previous", "Duplicate"])
    deduped["Previous"]= previous
    deduped["Duplicate"] = duplicate
    deduped.to_csv("duplication_report.csv")



def dedupe_me(path, match_title, match_abstract, path_2=""):
    df = pd.read_csv(path)
    print("Reading the file all_results_tmp.csv that contains the previous results. It has {} records, and its {} column names are {}".format(df.shape[0], len(list(df.columns)), list(df.columns)))
    if path_2 != "":
        df_toadd = pd.read_csv(path_2)
        print("Reading the file new_results.csv that contains the new results. It has {} records, and its {} column names are {}".format(df_toadd.shape[0], len(list(df.columns)), list(df_toadd.columns)))

        ###debugging column names
        #for col in list(df.columns):
            #if col not in list(df_toadd.columns):
               # print(col)
        #print("df 2")
        #for col in list(df_toadd.columns):
            #if col not in list(df.columns):
                #print(col)

        dedupe_loop_additional(df, df_toadd, "data\\results\\new_and_deduped.csv", match_title, match_abstract)
    else:
        dedupe_loop_within(df, "data\\results\\new_and_deduped.csv", match_title, match_abstract)


path = "data\\results\\all_results_tmp.csv"
path_new = "data\\results\\new_results.csv"

#alternative if you have problems with relative and absolute paths, try this! its the OS modeule that has an option to grab the current working directorys absolute path:

######################FOR PATH PROBLEMS###########################
#path = os.path.join(os.getcwd(), "all_results_tmp.csv")
#path = os.path.join(os.getcwd(), "new_results.csv")

dedupe_me(path, 95, 90, path_new)  # use this when adding data. creates the file "results/all_results_updated.csv"

# dedupe_me(path, 95, 90)#USE THIS WHEN DEDUPING WITHIN< TO GET RID OF THE dupes in the previous screening!
