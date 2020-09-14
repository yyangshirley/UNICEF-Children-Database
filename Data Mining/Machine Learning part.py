# -*- coding: utf-8 -*-
"""
Created on Sun Apr 19 15:39:16 2020

@author: 12262
"""

from sklearn.model_selection import train_test_split,GridSearchCV
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.preprocessing import Imputer
from sklearn.ensemble import ExtraTreesClassifier
import matplotlib.pyplot as plt
from sklearn.feature_extraction import DictVectorizer

def decisiontree():
    # read data
    Violent = pd.read_excel("C:\\Users\\12262\\Desktop\\ECE 9017\\Violent.xlsx")
    ChildLabour = pd.read_excel("C:\\Users\\12262\\Desktop\\ECE 9017\\ChildLabour.xlsx")
    Education = pd.read_excel("C:\\Users\\12262\\Desktop\\ECE 9017\\Education.xlsx")
    CountryWealth = pd.read_excel("C:\\Users\\12262\\Desktop\\ECE 9017\\CountryWealth.xlsx")
    # merge data
    _mg = pd.merge(Violent,ChildLabour,on='CountryID')
    _mg = pd.merge(_mg,Education,on='CountryID')
    mt = pd.merge(_mg,CountryWealth,on='CountryID')
    
    #data processing
    #fill missing value with mean
    mt = mt.drop(columns=['CountryName','LabourID','CountryID'])
    imp = Imputer(missing_values='NaN', strategy='mean', axis=0)
    imp.fit(mt)
    data= imp.transform(mt)
    
    #put back the column name
    data_final = pd.DataFrame(data, columns = mt.columns)
    #create target: complet school if > rate of mean
    # print(data)
    mean_pmale = data_final['SchoolCompletionRatePrimaryMale'].mean()
    mean_pfemale = data_final['SchoolCompletionRatePrimaryFemale'].mean()
    mean = (mean_pmale+mean_pfemale)/2
    #print(mean)
    
    data_final.loc[(data_final['SchoolCompletionRatePrimaryMale']+data_final['SchoolCompletionRatePrimaryFemale'])/2 > mean, 'MeetLineOrNot'] = '1'
    data_final.loc[(data_final['SchoolCompletionRatePrimaryMale']+data_final['SchoolCompletionRatePrimaryFemale'])/2 <= mean, 'MeetLineOrNot'] = '0'
    # drop gnearted data from data_final
    data_final = data_final.drop(columns=['SchoolCompletionRatePrimaryMale','SchoolCompletionRatePrimaryFemale','SchoolCompletionRateLowerSecMale','SchoolCompletionRateLowerSecFemale','SchoolCompletionRateUpperSecMale','SchoolCompletionRateUpperSecFemale','SchoolCompletionRatePrimary'])
    
    #target
    y = data_final['MeetLineOrNot']
    #input
    x = data_final.iloc[:,0:-2]
    
    #feature improtance (selection)
    model = ExtraTreesClassifier()
    model.fit(x,y)
    print(model.feature_importances_) #use inbuilt class feature_importances of tree based classifiers
    #plot graph of feature importances for better visualization
    feat_importances = pd.Series(model.feature_importances_, index=x.columns)
    feat_importances.nlargest(10).plot(kind='barh')
    plt.show()
    
    # train test split
    x_train, x_test, y_train, y_test = train_test_split(x,y,test_size = 0.25)
    
    #feature engineering -> one hot encoding
    dic_t = DictVectorizer(sparse = False)
    x_train = dic_t.fit_transform(x_train.to_dict(orient = "records"))
    x_test = dic_t.transform(x_test.to_dict(orient = "records"))
    
    #decesion tree predict
    dec = DecisionTreeClassifier()
    param = {"max_depth": [5,8,10,11,15]}
    #graid search + cross validation
    gc = GridSearchCV(dec,param_grid=param, cv=3)
    gc.fit(x_train,y_train)
    #accuracy score
    print("Prediction accuarcy:",gc.score(x_test,y_test))
    print("Best Parameters：",gc.best_params_)
    return None
if __name__ == "__main__":
    decisiontree()