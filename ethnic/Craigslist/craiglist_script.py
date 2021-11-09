### NYC Housing Search ###

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import time
import pandas as pd

# Read in NYC Zip Codes
zipcodes = pd.read_csv("/Users/freddy/Desktop/STAT 454/Transit/Craigslist/nyc-zip-codes.csv")
zipcodes.head()

# Generate Craigslist Links
base_links = []
for i in range(0, len(zipcodes)):
    link = "https://newyork.craigslist.org/d/housing/search/hhh/aap?postal={}".format(zipcodes.iloc[i, 2])
    base_links.append(link)


# Extract Listing Data Function
def getZipListings(link):
    # Open the driver
    driver = webdriver.Chrome(executable_path="/Users/freddy/Downloads/chromedriver")
    driver.get(link)

    # Prepare the vectors
    titles = []
    dates = []
    prices = []
    bedrooms = []
    links = []

    # Extract the data
    items = driver.find_elements_by_class_name('result-info')
    for item in items:
        # Title
        try:
            titles.append(item.find_element_by_class_name('result-title').get_attribute('innerText'))
        except:
            titles.append("")

        # Date
        try:
            dates.append(item.find_element_by_class_name('result-date').get_attribute('datetime'))
        except:
            dates.append("")

        # Price
        try:
            prices.append(item.find_element_by_class_name('result-price').get_attribute('innerText'))
        except:
            prices.append("")

        # Bedrooms
        try:
            bedrooms.append(item.find_element_by_class_name('housing').get_attribute('innerText'))
        except:
            bedrooms.append("")

        # Link
        try:
            links.append(item.find_element_by_class_name('result-title').get_attribute('href'))
        except:
            links.append("")

    driver.close()
    data = [titles, dates, prices, bedrooms, links]
    df = pd.DataFrame(data).transpose()
    df.columns = ['Title', 'Date', 'Price', 'Bedrooms', 'Link']
    df['Zipcode'] = int(link[-5:])

    return df


# Loop over Zipcodes
housing = pd.DataFrame()
for link in base_links:
    time.sleep(2)
    try:
        temp = getZipListings(link)
        temp = temp.merge(zipcodes, on='Zipcode', how='left')
        housing = pd.concat([housing, temp])
    except:
        time.sleep(20)

housing = housing.merge(zipcodes, on='Zipcode', how='left')

# Rearrange columns for order
housing = housing[['Borough', 'Neighborhood', 'Zipcode', 'Date', 'Price', 'Bedrooms', 'Title', 'Link']]
housing.head()

# Clean the Data
for i in range(0, len(housing)):
    try:
        housing.iloc[i, 4] = housing.iloc[i, 4].replace('$', '')
    except:
        housing.iloc[i, 4] = housing.iloc[i, 4]

    try:
        housing.iloc[i, 5] = housing.iloc[i, 5].replace('\n', '')
    except:
        housing.iloc[i, 5] = housing.iloc[i, 5]

    try:
        housing.iloc[i, 5] = housing.iloc[i, 5].replace('-', '')
    except:
        housing.iloc[i, 5] = housing.iloc[i, 5]

    try:
        housing.iloc[i, 5] = housing.iloc[i, 5].strip()
    except:
        housing.iloc[i, 5] = housing.iloc[i, 5]

    try:
        if housing.iloc[i, 5].find('br') == True:
            housing.iloc[i, 5] = housing.iloc[i, 5][0:3]
        else:
            housing.iloc[i, 5] = None
    except:
        None

# Remove Duplictates
housing = housing.drop_duplicates(subset=['Zipcode', 'Price', 'Bedrooms', 'Title'], keep='first')

# Export the Data
housing.to_csv("nyc-housing.csv", index=False)