import pandas as pd
import matplotlib.pyplot as plt
import pdb

df = pd.read_csv("DBA.csv")

df["SMA50"] = df["Close"].rolling(50).mean()

for i in range(1, len(df)):
    df.loc[i, 'tr'] = max(
        df.loc[i, 'High'] - df.loc[i, 'Low'],
        abs(df.loc[i, 'High'] - df.loc[i-1, 'Close']),
        abs(df.loc[i, 'Low'] - df.loc[i-1, 'Close'])
    )

pdb.set_trace()

plt.scatter(df['Close'], df['tr'])
plt.xlabel('closes', fontsize=14)
plt.ylabel('tr', fontsize=14)
plt.grid(True)
plt.show()
