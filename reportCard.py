import openpyxl
import pyodbc
import pandas as pd
import plotly.graph_objects as go
from IPython.display import display, HTML
from xhtml2pdf import pisa
import pdfkit
import plotly
import plotly.express as px
import numpy as np

con = pyodbc.connect("DRIVER={SQL Server};SERVER=;DATABASE=;UID=;PWD=")
cur = con.cursor()

# MD Chart Review - Needs Review
cr_needsReview = "exec Chart_Review_Needs_Review @Start_date = '20200101', @End_Date = '20200331'"
cr_needsReview1 = pd.read_sql(cr_needsReview, con)
cr_needsReview1.to_excel("C:/Users/nfischoff/PycharmProjects/qcc_q1_2020/qcc_excel/cr_needsReview.xlsx")

cr_needsReview2_1 = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc_q1_2020\\qcc_excel\\cr_needsReview.xlsx')
cr_needsReview2 = cr_needsReview2_1.drop(columns=['Unnamed: 0', 'supervising_physician', 'encounter_number'])

# Privileged Procedures

priv1 = "exec selected_procedures_by_clinicians_qcc @Start_Date='20190401', @End_date='20200331'"
priv2 = pd.read_sql(priv1, con)

priv2.to_excel("C:/Users/nfischoff/PycharmProjects/qcc_q1_2020/qcc_excel/priv.xlsx")

priv = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc_q1_2020\\qcc_excel\\priv.xlsx')
priv_df = priv.drop(columns=['Unnamed: 0'])

priv_req_maint = pd.read_excel(
    'C:/Users/nfischoff/PycharmProjects/qcc_q1_2020/qcc_excel/Priv Proc Req and Maintenance.xlsx')

# Combined Audits
ca_qs = "exec qcc_comb_audits @Start_Date='20191001', @End_Date='20200331'"
ca = pd.read_sql(ca_qs, con)

ca.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_q1_2020/ca.xlsx")

ca1 = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc_q1_2020\\qcc_excel\\ca.xlsx')
ca1_1a = ca1.drop(columns=['Unnamed: 0', 'order_rank'])

ca1_1a['pg_prov'] = ca1_1a['provider_name'].replace(to_replace=[r'\sMD', r'\sNP', r'\sPA'], value='', regex=True)



# MD CHART REVIEWS
 prov_sp = "exec Chart_Review_Counts_SP_Providers @Start_Date='20191001', @End_Date='20191231'"
 prov_sp1 = pd.read_sql(prov_sp,con)

 prov_sp1.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/prov_sp1.xlsx")


rev = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc_q1_2020\\qcc_excel\\prov_sp1.xlsx')
rev_df = rev.drop(columns=['Unnamed: 0', 'countPastDue', 'countPending'])
rev_df.columns = ['supervising_physician', 'provider', 'approved', 'needs review']
rev_df1 = rev_df[['supervising_physician', 'provider', 'approved', 'needs review']]

rev_df1.style.format({
    'needs review': '{:,.0f}'.format
})

rev_df1

# RVU Productivity
 prod_sp = "exec rvu_productivity @Start_Date='20191001', @end_date='20191231', @location='0565487A-C88D-484C-9759-3DF762EA0695,782C0260-7552-426E-87D6-38F073F40DAD,ACB96567-0B1F-4AF7-81FC-598B26C3E3DC,A0D201B2-7AD9-40DD-8A0B-F270478B1736,7A28E85F-A7F9-4A54-903C-26E90CBD8EAE,9EA2DE96-E929-499E-819B-4128A72CBC7B,6FAF7F6A-0424-41B0-8B13-D2678C76898A,DA5FCD52-AFBE-47F9-A2A2-D96601252CDF,6CB12D65-A88C-405C-89C0-7FE677C9D638,68C7DDB4-834A-4ABC-B3EB-87BF71D60F41,5C8A71F3-7496-4C4F-86E8-AEE02ADECCF4,05483D36-4D7C-49B7-8FF1-7AE9FA0E2825,D89E78A1-F4E4-4DC5-8A7A-BCC316E3A747,239055AA-220B-4F4B-BC82-0A40825A2F2C,4BD8BD13-6076-4C78-AC9E-FEEC37F226D5,2E863B41-F3B9-4768-AC31-AA300DAA9003,C1CAF54E-57B5-4A9F-84E7-554A8EF4EADB,E53D4FEC-7778-4093-9C45-DC526C9CC8D3,9B706667-0AC8-4BAB-AC72-63B0075D05BF'"
 prod_sp1 = pd.read_sql(prod_sp, con)
 prod_sp1.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/prod_sp1.xlsx")

 prod_sp2 = prod_sp1.drop(columns=['homeLocation', 'hours','total RVU','rendering_provider_id'])
 prod_sp2_1 = prod_sp2[~prod_sp2.description.str.contains("MD,")]
 prod_sp3 = prod_sp2_1.groupby('description').agg({'service_Date':'count', 'MRN count':'mean'})

 prod_sp4 = prod_sp3.reset_index()

 prod_sp4.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/prod_sp4.xlsx")

prod_sp5_1 = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc\\qcc_excel\\prod_sp4.xlsx')

prod_sp5 = prod_sp5_1.drop(columns=['Unnamed: 0', 'service_Date'])
prod_sp5.columns = ['provider', 'Avg Visits']
# prod_agency_avg_visits = round(prod_sp5["Avg Visits"].mean(),1)
prod_agency_avg_visits = 16.6

prod_agency_goal = 19.5

df2 = pd.DataFrame([['Agency Avg', prod_agency_avg_visits], ['Agency Goal', prod_agency_goal]],
                   columns=['provider', 'Avg Visits'])

prod_sp6 = prod_sp5.append(df2).fillna(0)

# rvu_sp2 = prod_sp1.drop(columns=['homeLocation'])
# rvu_sp2_1 = rvu_sp2[~rvu_sp2.description.str.contains("MD,")]

# rvu_sp3 = rvu_sp2_1.groupby('description').agg({'service_Date':'count', 'MRN count':'sum','total RVU':'sum'})
# rvu_sp3['avg RVU per visit'] = rvu_sp3['total RVU'] / rvu_sp3['MRN count']

# rvu_sp4 = rvu_sp3.reset_index()


# rvu_sp3.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/rvu_sp4.xlsx")


rvu_sp5_1 = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc\\qcc_excel\\rvu_sp4.xlsx')

rvu_sp5 = rvu_sp5_1.drop(columns=['service_Date', 'MRN count', 'total RVU'])

rvu_sp5.columns = ['provider', 'Avg RVUs']

# rvu_agency_avg_visits = round(rvu_sp5["Avg RVUs"].mean(), 1)
rvu_agency_avg_visits = 3.1

df3 = pd.DataFrame([['Agency Avg', rvu_agency_avg_visits]], columns=['provider', 'Avg RVUs'])

rvu_sp6_1 = rvu_sp5.append(df3).fillna(0)
rvu_sp6 = rvu_sp6_1.drop_duplicates()

home_loc1 = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\qcc\\qcc_excel\\prod_sp1.xlsx')
home_loc2 = home_loc1.filter(['homeLocation', 'description'], axis=1)
home_loc3 = home_loc2.drop_duplicates()

### COMBINE ELEMENTS

result = pd.merge(ca1_1a,
                  rev_df1,
                  left_on="provider_name",
                  right_on="provider",
                  how="left")

result1_1 = pd.merge(result,
                     prod_sp6,
                     left_on="provider_name",
                     right_on="provider",
                     how="left")

result1 = pd.merge(result1_1,
                   rvu_sp6,
                   left_on="provider_name",
                   right_on="provider",
                   how="left")

result1["Supervising Physician"] = result1["supervising_physician"].fillna('NA')
result1["approved"] = result1["approved"].fillna('NA')

result3 = result1.drop(columns=['provider_x', 'provider_y', 'provider', 'supervising_physician'])

result3['Avg Visits'] = result3['Avg Visits'].apply('{:,.1f}'.format)

result3['Avg RVUs'] = result3['Avg RVUs'].apply('{:,.1f}'.format)
result3['needs review'] = result3['needs review'].apply('{:,.0f}'.format)

result3.to_excel("C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/result3.xlsx")

ca2 = {n: result3[result3['provider_name'] == rows]
       for n, rows in enumerate(result3.groupby('provider_name').groups)}

## PRESS GANEY DATA
pg_1 = pd.read_csv('C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/Press Ganey/PressGaney_612019_12312019.csv')

pg_1['provider'] = pg_1["Provider ID"].replace(to_replace=[r"\'"], value='', regex=True)

pg = pg_1[pg_1.Question != "Std Care Provider"]

pg_comments = pd.read_csv(
    'C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/Press Ganey/PressGaney_Comments_1012019_12312019.csv')

pg_agency = pd.read_csv(
    'C:/Users/nfischoff/PycharmProjects/qcc/qcc_excel/Press Ganey/PressGaney_Agency_612019_12312019.csv')

pgag = pg_agency[pg_agency.Question != "Std Care Provider"]

pgag1 = pgag.drop(columns=['n'])

pd.set_option('display.max_colwidth', -1)

prov_home_location = pd.read_excel('C:\\Users\\nfischoff\\PycharmProjects\\untitled\\provider_locations.xlsx')

for i in ca2:

    prov = ca2[i]['provider_name'].iloc[0]
    prov_bar = str(prov.split(' ')[0])

    pgProv = ca2[i]['pg_prov'].iloc[0]

    audits_p = pd.DataFrame(
        ca2[i].drop(columns=["Supervising Physician", "Avg Visits", "approved", "pg_prov", "Avg RVUs", "needs review"]))
    c1 = audits_p.drop_duplicates()
    c2 = c1.reset_index()
    c3 = c2.drop(columns=["index", "provider_name"])

    c3['Family_Planning'] = c3['Family_Planning'].astype(float).map("{:.1%}".format)
    c3['MAB'] = c3['MAB'].astype(float).map("{:.1%}".format)
    c3['IUC'] = c3['IUC'].astype(float).map("{:.1%}".format)
    c3['Implant'] = c3['Implant'].astype(float).map("{:.1%}".format)
    c3['Breast'] = c3['Breast'].astype(float).map("{:.1%}".format)
    c3['Colpo'] = c3['Colpo'].astype(float).map("{:.1%}".format)

    # c3.iloc[-1] =  c3.iloc[-1].astype(int)

    c4 = c3.replace('nan%', 'NA')

    sign_lines = ''

    if prov in []:
        sign_lines = '''
                              <span class="date">Date</span>
                              <span class="lead_signature">Medical Director</span>
                              <span class="clin_signature">Lead Clinician</span>
                            '''
    else:
        sign_lines = '''
                              <span class="date">Date</span>
                              <span class="lead_signature">Lead Clinician Signature</span>
                              <span class="clin_signature">Clinician Signature</span>
                            '''

    dac = ''

    if c4["Family_Planning"].iloc[4] == 'NA':
        fp_n_val = '0'
    else:
        fp_n_val1 = str(float(c4["Family_Planning"].iloc[4].replace("%", "")) / 100)
        fp_n_val = fp_n_val1.replace(".0", "")

    if c4["MAB"].iloc[4] == 'NA':
        mab_n_val = '0'
    else:
        mab_n_val1 = str(float(c4["MAB"].iloc[4].replace("%", "")) / 100)
        mab_n_val = mab_n_val1.replace(".0", "")

    if c4["IUC"].iloc[4] == 'NA':
        iuc_n_val = '0'
    else:
        iuc_n_val1 = str(float(c4["IUC"].iloc[4].replace("%", "")) / 100)
        iuc_n_val = iuc_n_val1.replace(".0", "")

    if c4["Implant"].iloc[4] == 'NA':
        implant_n_val = '0'
    else:
        implant_n_val1 = str(float(c4["Implant"].iloc[4].replace("%", "")) / 100)
        implant_n_val = implant_n_val1.replace(".0", "")

    if c4["Breast"].iloc[4] == 'NA':
        breast_n_val = '0'
    else:
        breast_n_val1 = str(float(c4["Breast"].iloc[4].replace("%", "")) / 100)
        breast_n_val = breast_n_val1.replace(".0", "")

    if c4["Colpo"].iloc[4] == 'NA':
        colpo_n_val = '0'
    else:
        colpo_n_val1 = str(float(c4["Colpo"].iloc[4].replace("%", "")) / 100)
        colpo_n_val = colpo_n_val1.replace(".0", "")

    if c3['Colpo'][0] == 'nan%':

        dac = '''<table class="tab table table-bordered">
                                    <thead>
                                        <th scope="col"></th>
                                        <th scope="col">Family Planning, n = ''' + fp_n_val + '''</th>
                                        <th scope="col">MAB, n= ''' + mab_n_val + ''' </th>
                                        <th scope="col">IUC, n= ''' + iuc_n_val + '''</th>
                                        <th scope="col">Implant, n= ''' + implant_n_val + '''</th>
                                        <th scope="col">Breast Mass, n = ''' + breast_n_val + '''</th>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td scope="col">''' + c4["category"].iloc[0] + '''</td>
                                            <td scope="col">''' + c4["Family_Planning"].iloc[0] + '''</td>
                                            <td scope="col">''' + c4["MAB"].iloc[0] + '''</td>
                                            <td scope="col">''' + c4["IUC"].iloc[0] + '''</td>
                                            <td scope="col">''' + c4["Implant"].iloc[0] + '''</td>
                                            <td scope="col">''' + c4["Breast"].iloc[0] + '''</td>
                                        </tr>

                                        <tr>
                                            <td scope="col">''' + c4["category"].iloc[1] + '''</td>
                                            <td datastatus=''' + c4["Family_Planning"].iloc[
            1] + ''' class="status" scope="col">''' + c4["Family_Planning"].iloc[1] + '''</td>
                                            <td datastatus=''' + c4["MAB"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["MAB"].iloc[1] + '''</td>
                                            <td datastatus=''' + c4["IUC"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["IUC"].iloc[1] + '''</td>
                                            <td datastatus=''' + c4["Implant"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["Implant"].iloc[1] + '''</td>
                                            <td datastatus=''' + c4["Breast"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["Breast"].iloc[1] + '''</td>
                                        </tr>
                                        <tr>
                                            <td scope="col">''' + c4["category"].iloc[2] + '''</td>
                                            <td scope="col">''' + c4["Family_Planning"].iloc[2] + '''</td>
                                            <td scope="col">''' + c4["MAB"].iloc[2] + '''</td>
                                            <td scope="col">''' + c4["IUC"].iloc[2] + '''</td>
                                            <td scope="col">''' + c4["Implant"].iloc[2] + '''</td>
                                            <td scope="col">''' + c4["Breast"].iloc[2] + '''</td>
                                        </tr>

                                        <tr>
                                            <td scope="col">''' + c4["category"].iloc[3] + '''</td>
                                            <td datastatus=''' + c4["Family_Planning"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Family_Planning"].iloc[3] + '''</td>
                                            <td datastatus=''' + c4["MAB"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["MAB"].iloc[3] + '''</td>
                                            <td datastatus=''' + c4["IUC"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["IUC"].iloc[3] + '''</td>
                                            <td datastatus=''' + c4["Implant"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Implant"].iloc[3] + '''</td>
                                            <td datastatus=''' + c4["Breast"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Breast"].iloc[3] + '''</td>
                                        </tr>
                                    </tbody>
                                </table>   '''

    else:
        dac = '''<table class="tab table table-bordered">
                                               <thead>
                                                   <th scope="col"></th>
                                                    <th scope="col">Family Planning, n = ''' + fp_n_val + '''</th>
                                                    <th scope="col">MAB, n= ''' + mab_n_val + ''' </th>
                                                    <th scope="col">IUC, n= ''' + iuc_n_val + '''</th>
                                                    <th scope="col">Implant, n= ''' + implant_n_val + '''</th>
                                                    <th scope="col">Breast Mass, n = ''' + breast_n_val + '''</th>
                                                   <th scope="col">Colpo, n = ''' + colpo_n_val + '''</th>
                                               </thead>
                                               <tbody>
                                                   <tr>
                                                       <td scope="col">''' + c4["category"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["Family_Planning"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["MAB"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["IUC"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["Implant"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["Breast"].iloc[0] + '''</td>
                                                       <td scope="col">''' + c4["Colpo"].iloc[0] + '''</td>
                                                   </tr>

                                                   <tr>
                                                       <td scope="col">''' + c4["category"].iloc[1] + '''</td>
                                                       <td datastatus=''' + c4["Family_Planning"].iloc[
            1] + ''' class="status" scope="col">''' + c4["Family_Planning"].iloc[1] + '''</td>
                                                       <td datastatus=''' + c4["MAB"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["MAB"].iloc[1] + '''</td>
                                                       <td datastatus=''' + c4["IUC"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["IUC"].iloc[1] + '''</td>
                                                       <td datastatus=''' + c4["Implant"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["Implant"].iloc[1] + '''</td>
                                                       <td datastatus=''' + c4["Breast"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["Breast"].iloc[1] + '''</td>
                <td datastatus=''' + c4["Colpo"].iloc[
                  1] + ''' class="status" scope="col">''' + c4["Colpo"].iloc[1] + '''</td>
                                                   </tr>
                                                   <tr>
                                                       <td scope="col">''' + c4["category"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["Family_Planning"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["MAB"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["IUC"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["Implant"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["Breast"].iloc[2] + '''</td>
                                                       <td scope="col">''' + c4["Colpo"].iloc[2] + '''</td>
                                                   </tr>

                                                   <tr>
                                                       <td scope="col">''' + c4["category"].iloc[3] + '''</td>
                                                       <td datastatus=''' + c4["Family_Planning"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Family_Planning"].iloc[3] + '''</td>
                                                       <td datastatus=''' + c4["MAB"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["MAB"].iloc[3] + '''</td>
                                                       <td datastatus=''' + c4["IUC"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["IUC"].iloc[3] + '''</td>
                                                       <td datastatus=''' + c4["Implant"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Implant"].iloc[3] + '''</td>
                                                       <td datastatus=''' + c4["Breast"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Breast"].iloc[3] + '''</td>
                <td datastatus=''' + c4["Colpo"].iloc[
                  3] + ''' class="status" scope="col">''' + c4["Colpo"].iloc[3] + '''</td>
                                                   </tr>
                                               </tbody>
                                           </table>   '''

    reviews_p = pd.DataFrame(ca2[i].drop(
        columns=["provider_name", "category", "Family_Planning", "MAB", "IUC", "Implant", "Breast", "Colpo",
                 "Avg Visits", "pg_prov"]))

    reviews_col = ["Supervising Physician", "approved", "needs review"]
    reviews = reviews_p[reviews_col].drop_duplicates()

    chart_reviews = reviews['approved']
    cr = chart_reviews.to_string(index=False)

    reviews_tab = ''
    if cr == ' NA':
        reviews_tab = '''<div></div>'''
    elif cr != ' NA':
        reviews_tab = '''<hr/><p> MD Chart Reviews </p>''' + reviews.to_html(index=False).replace(
            '<table border="1" class="dataframe">', '<table class="tab table table-bordered">')

    visits = pd.DataFrame(ca2[i].drop(
        columns=["Family_Planning", "MAB", "IUC", "Implant", "Breast", "Colpo", "Supervising Physician", "approved",
                 "pg_prov"]))

    v1 = pd.DataFrame([['Agency Avg', prod_agency_avg_visits], ['Agency Goal', prod_agency_goal]],
                      columns=['provider_name', 'Avg Visits'])
    visits1 = visits.append(v1)
    prov_visits_p = visits['Avg Visits']
    prov_visits = prov_visits_p.drop_duplicates()

    prov_visits1 = float(prov_visits)

    home_location = prov_home_location.loc[prov_home_location['Provider'] == prov]

    if not home_location.empty:
        home_location1 = home_location['Location Description'].iloc[0]
    else:
        if "MD," in prov:
            home_location1 = "MDs"
        elif pd.isna(prov_visits1):
            home_location1 = "no visits"
        else:
            home_location1 = 'other'

    pa0 = float(prov_visits) * 12.0
    pa1 = prod_agency_avg_visits * 12
    pa2 = prod_agency_goal * 12

    prov_bar_color = ''

    if pa0 < pa1:
        prov_bar_color = '#F79646'
    elif pa1 <= pa0 <= pa2:
        prov_bar_color = '#EFE10F'
    else:
        prov_bar_color = '#70AD47'

    rvu_prod = pd.DataFrame(ca2[i].drop(columns=["Family_Planning", "MAB", "IUC",
                                                 "Implant", "Breast", "Colpo", "Supervising Physician", "approved",
                                                 "Avg Visits",
                                                 "pg_prov", "needs review", "category"]))

    rvu1 = pd.DataFrame([['Agency Avg', rvu_agency_avg_visits]],
                        columns=['provider_name', 'Avg RVUs'])

    rvu_prod1_1 = rvu_prod.append(rvu1).drop_duplicates()
    rvu_prod1 = rvu_prod1_1.rename(columns={"provider_name": "Provider"})

    cr = cr_needsReview2[cr_needsReview2['provider_name'] == prov]
    cr1 = cr.drop(columns=["provider_name"])

    comment_review_tab = ''
    if not cr1.empty:
        comment_review_tab = '''<hr/> ''' + cr1.to_html(index=False).replace('<table border="1" class="dataframe">',
                                                                             '<table class="tab table table-bordered">')
    else:
        comment_review_tab = ''

    p = priv_df[priv_df['provider_name'] == prov]
    p1_1 = p.drop(columns=["provider_name"])
    # p1["Required for sign-off"] = 'TBD'
    # p1["Required for maintenance"] = 'TBD'
    # p1.columns = ["Skill", "Completed", "Required for sign-off", "Required for maintenance"]
    p1_1.columns = ["Skill", "Completed"]

    # priv_req_maint

    p1_2 = pd.merge(p1_1,
                    priv_req_maint,
                    left_on="Skill",
                    right_on="Privileged Procedure",
                    how="left")

    p1 = p1_2.drop(columns=["Privileged Procedure"]).fillna('TBD')

    priv_tab = ''
    if not p1.empty:
        priv_tab = '''<div> <p>Privileged Procedures Completed in the Last 12 Months*</p>''' + \
                   p1.to_html(index=False).replace('<table border="1" class="dataframe">',
                                                   '<table class="tab table table-bordered">') + \
                   '''<p id="ast">*Only procedures within the last 12 months will be recorded as completed.
                    If training another Clinician, the procedure may be documented under their name, this procedure will be recorded for both the trainer and the trainee.</p>
                   </div> <hr/>'''
    else:
        priv_tab = '''<div></div> '''

    pg1 = pg[pg['provider'] == pgProv]

    nval = round(pg1["n"].mean(), 0)

    pg2 = pg1.drop(columns=['Provider ID', 'provider', 'n'])

    pgb = pd.merge(pg2,
                   pgag1,
                   left_on="Question",
                   right_on="Question",
                   how="left")

    pgb1 = pgb.rename(columns={"mean_x": "Provider Avg"})
    pgb2_1 = pgb1.rename(columns={"mean_y": "Agency Avg"})
    pgb2_1["Prov vs Agency"] = pgb2_1["Provider Avg"] - pgb2_1["Agency Avg"]

    pgb2_1.style.format({
        'Prov vs Agency': '{:,.1f}'.format
    })

    pgb2 = pgb2_1.round({'Prov vs Agency': 1})

    pg3 = ''
    if nval >= 10.0 and not pg1.empty:
        pg3 = '''<div class="contentBlock"><p>Press Ganey Reviews, 6/1/2019 - 12/31/2019, n=''' + str(
            nval) + '''</p>''' + '''
                            <table class="tab table table-bordered">
                                    <thead>
                                        <th scope="col">Question</th>
                                        <th scope="col">Provider Avg</th>
                                        <th scope="col">Agency Average</th>
                                        <th scope="col">Provider vs Agency</th>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[0]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[0]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[0]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[0]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[0]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[1]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[1]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[1]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[1]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[1]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[2]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[2]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[2]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[2]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[2]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[3]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[3]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[3]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[3]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[3]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[4]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[4]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[4]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[4]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[4]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[5]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[5]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[5]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[5]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[5]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[6]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[6]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[6]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[6]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[6]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[7]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[7]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[7]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[7]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[7]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[8]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[8]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[8]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[8]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[8]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[9]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[9]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[9]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[9]) + ''' class="status" scope="col">''' + str(pgb2["Prov vs Agency"].iloc[9]) + '''</td>
                                         </tr>
                                         <tr>
                                            <td scope="col">''' + str(pgb2["Question"].iloc[10]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Provider Avg"].iloc[10]) + '''</td>
                                            <td scope="col">''' + str(pgb2["Agency Avg"].iloc[10]) + '''</td>
                                            <td datastatus=''' + str(
            pgb2["Prov vs Agency"].iloc[10]) + ''' class="status" scope="col">''' + str(
            pgb2["Prov vs Agency"].iloc[10]) + '''</td>
                                         </tr>
                                    </tbody>
                        </table>   '''
    else:
        pg3 = '''<div></div>'''

    pc1 = pg_comments[pg_comments['Provider ID'] == pgProv]

    pc2 = pc1.drop(columns=['Provider ID'])

    pc3 = ''

    if not pc1.empty:
        pc3 = '''<div> <p>Press Ganey Comments, 10/1/2019 - 12/31/2019</p>''' + pc2.to_html(index=False).replace(
            '<table border="1" class="dataframe">', '<table class="tab table table-bordered">') + '''</div>'''
    else:
        pc3 = '''<div></div>'''

    if pa0 > 0:
        rvus_and_productivity_charts = '''
                    <div class ="row">
                        <div class ="column">
                            <p> Average Unique Visits </p>
                            <div class ="chart">
                                <div id = "redbar" style = "width: ''' + str(
            pa0) + '''px;"> ''' + prov_bar + ''' - ''' + str(prov_visits1) + ''' </div >
                                <div id = "yellowbar" style = "background-image: linear-gradient(red,yellow); width:''' + str(
            pa1) + '''px;"> Agency Average - ''' + str(prod_agency_avg_visits) + ''' </div>
                                <div id = "greenbar" style = "width:''' + str(pa2) + '''px;" > Agency Goal - ''' + str(
            prod_agency_goal) + ''' </div></div></div><div class ="column">
                            <p> Average RVUs per Visit </p>''' + rvu_prod1.to_html(index=False).replace(
            '<table border="1" class="dataframe">', '<table class="tab table table-bordered">') + '''
                        </div>
                    </div>
                    '''
    else:
        rvus_and_productivity_charts = '''<div></div>'''

    html_string = '''
        <html>
                <head>
                        <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
                        <script src="https://d3js.org/d3.v5.min.js"></script>
                        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
                          <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>body{ margin: 0 100} </style>
                </head>
                <style>
                .tab {
                    font-size: 9px;
                }
                .chart div {
                      font: 10px sans-serif;
                      background-color: steelblue;
                      text-align: right;
                      padding: 3px;
                      margin: 1px;
                      color: white;
                }

                #redbar {
                    color: black;
                    background-color: ''' + prov_bar_color + '''
                }

                #yellowbar {
                    color: black;
                    background-color: #d3d3d3;
                    border-top: 1px solid  #909090;
                }

                #greenbar {
                    color: black;
                    background-color: #d3d3d3;
                    border-top: 1px solid  #909090;
                }

                #qcc_title {
                    font-size: 20px;
                }

                #audit_title {
                    font-size: 14px;
                }

                .cr_list {
                    list-style-type: none;
                    text-align: left;
                    margin: 0px;
                    padding: 0px 100px 0px 0px;
                }

                .saplan {
                    width:100%;
                    height: 180px;
                }

                .comments {
                    width: 100%;
                    height: 50px;
                }

                .cheader {
                    font-size: 8px;
                }

                .ack_line {
                    margin-top: 10px;
                }

                .signature_lines {
                    margin-top: 30px;
                }

                .ack {
                    font-size: 10px;
                }

                .date, .lead_signature, .clin_signature {
                    float: left;
                    margin: 20px 10px;
                    border-top: 1px solid #000;
                    width: 200px;
                    text-align: center;
                    font-size: 10px;
                }

                .column {
                    float: left;
                    width: 47%;
                    margin-left: 15px
                }

                .row:after {
                    content: "";
                    display: table;
                    clear: both;
                }

                td[datastatus^="-"]{
                    color: red;
                }

                td[datastatus="NA"]{
                    color: black;
                }

                td[datastatus="0.0%"]{
                    color: black;
                }

                .status {
                    color: green;
                }

                .contentBlock {
                    display:block ! important;
                    page-break-inside:avoid ! important;
                }

                #ast {
                    margin-top: 5px;
                    font-size: 8px;
                }


                </style>
                <body>
                        <h3 id="qcc_title" >Quarterly Clinical Conversation (QCC) Q4 2019: ''' + prov + ''' </h3>
                        <hr/>
                        <div>
                            <p>Documentation Audit Summary</p> ''' + dac + '''
                        <div>
                            <table class="tab table table-bordered">
                                <thead>
                                    <tr>
                                        <th scope="col"></th>
                                        <th scope="col">Ultrasound</th>
                                        <th scope="col">EPEM</th>
                                        <th scope="col">CBE</th>
                                        <th scope="col">Rh/Microscopy</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <th scope="row">Satisfactory</th>
                                        <th scope="row">X</th>
                                        <th scope="row">X</th>
                                        <th scope="row"> X </th>
                                        <th scope="row"> X  </th>
                                    </tr>
                                    <tr>
                                        <th scope="row">Unsatisfactory</th>
                                        <th scope="row">    </th>
                                        <th scope="row">    </th>
                                        <th scope="row">    </th>
                                        <th scope="row">    </th>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div> ''' + reviews_tab + '''</div>
                        <div>  ''' + comment_review_tab + '''
                        </div>

                        <div>''' + rvus_and_productivity_charts + '''</div>
                        <hr/>

                        <div>
                            ''' + priv_tab + '''
                        </div>


                            <div >
                            ''' + pg3 + '''
                            </div>
                            <div>
                            ''' + pc3 + '''
                            </div>
                        <div class="contentBlock">
                            <div>
                                <form>
                                    Summary and Action Plan <input class="saplan" type="text">
                                </form>
                            </div>
                            <div class="contentBlock">
                            <div class="ack_line">
                                <p class="ack">
                                    *We have reviewed this data and created an action plan based on the goals of the quarterly clinical conversation. This action plan will be reviewed on a quarterly basis to assess results and
                                    areas of focus.
                                </p>
                            </div>
                            <div class="signature_lines"> ''' + sign_lines + '''

                            </div>
                            </div>
                        </div>
                </body>
        </html>'''

    home_location1

    pdfkit.from_string(html_string,
                       'C:/Users/nfischoff/PycharmProjects/qcc/qcc_pdfs/' + home_location1 + '/' + prov + '.pdf')

