import pandas as pd
import logging

logger = logging.getLogger()
logging.basicConfig(level=logging.INFO)

def get_registrations(user_utm_file_name,users_file_name):
    df_user_utm = pd.read_csv(user_utm_file_name, names=["utmDate","userId","utmSource"])
    df_user_utm = df_user_utm.astype({'utmDate':'datetime64', 'userId':'int64', 'utmSource':'object'})
    df_users = pd.read_csv(users_file_name, names=["userId","registrationDate"])
    df_users = df_users.astype({'userId':'int64', 'registrationDate':'datetime64'})

    logging.info(df_user_utm.dtypes)
    logging.info(df_users.dtypes)

    df_user_utm["ranking"] = df_user_utm.groupby("userId")["utmDate"].rank("dense", ascending=True) # assuming no duplicates on [userId,utmDate]
    df_user_utm["number_of_utm_touches"] = df_user_utm.groupby("userId")["ranking"].transform(max)
    df_first_touch = df_user_utm[df_user_utm.ranking.eq(1)]
    df_user_utm_registration = pd.merge(df_users, df_first_touch, on='userId') # assuming no duplicates on userId from users table

if __name__ == '__main__':
    get_registrations('user_utm.csv','users.csv')