import pandas as pd
import re
from fuzzywuzzy import fuzz
from tqdm import tqdm
from datetime import date

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
        a1 = row["abstract"].strip().lower()
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
                        a2 = mydict["abstract"][i].strip().lower()
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
    wos_orig= wos.copy()
    wos_orig["Deduplication_Notes"] = ["" for d in wos_orig["title"].values]  # has no abstracts
    orig_length=wos.shape[0]
    print("Deduplicating {} data".format(name))
    new_rows = []
    counter = 0
    masterdf=pd.DataFrame(columns=wos.columns.values)
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
                    str(wos_orig.at[index, "Deduplication_Notes"]),str(masterdf.loc[index]["source"]),
                    re.sub(r"\s+", " ", masterdf.loc[index].to_string().replace("\n", "; "))).strip()  # modift masterdf in place

                # print(masterdf.at[index, "Deduplication_Notes"])
                counter += 1
            else:
                masterdf = masterdf.append(row, ignore_index=True)
                #print(masterdf.head())
            pbar.update(1)

    print("Adding {} rows out of {} to master data and identified {} as duplicates".format(masterdf.shape[0],orig_length, counter))

    masterdf.to_csv("all_results.csv")
    wos_orig.to_csv( "all_results_with_duplicates-{}.csv".format(date.today()))  # save version that has dupes in it


    return masterdf

def dedupe_me(path, match_title, match_abstract):

    df=pd.read_csv(path)

    dedupe_loop_within(df, "all_results.csv", match_title, match_abstract)


#usage
path=os.path.join("results", "all_results.csv")
dedupe_me(path, 95, 90)
