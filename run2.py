import pdb
import sys
import random
import csv
import array

# USAGE:
# python3 run2.py DBA.csv

dates = []
opens = array.array('f')
highs = array.array('f')
lows = array.array('f')
closes = array.array('f')
volumes = array.array('f')
def parse_row(row):
    dates.append(row[0])
    opens.append(float(row[1]))
    highs.append(float(row[2]))
    lows.append(float(row[3]))
    closes.append(float(row[4]))
    volumes.append(float(row[6]))
with open(sys.argv[1]) as f:
    reader = csv.reader(f)
    first_line_parse = False
    for row in reader:
        if first_line_parse == False:
            first_line_parse = True
            continue
        else:
            parse_row(row)
count = len(volumes)
print("DONE import of data.  We have", count, 'rows')

print("Basic dollar-cost-averaging")
leftover = tot_bought = tot_spent = 0
for i in range(0, count-1, 10):
    close = closes[i]
    spendable = 50 + leftover
    bought = int(spendable / close)
    tot_bought += bought
    spent = bought * close
    tot_spent += spent
    leftover = spendable - spent

def median(data):
    data = sorted(data)
    index = len(data) // 2
    if len(data) % 2 != 0:
        return data[index]
    return (data[index -1] + data[index]) / 2

median_close = median(closes)
print(leftover, tot_bought, tot_spent, " average price bought=", tot_spent / tot_bought, " median price of security=", median_close)
print("DONE dollar-cost-averaging")

hh100 = array.array('f')
ll100 = array.array('f')
for i in range(100, count-1):
    hh100.append(max(highs[i-100:i]))
    ll100.append(min(lows[i-100:i]))

def breakout_100d_hh_or_ll():
    # This is a pretty good strategy actually, for trenders like DBA or XQQ.
    # For IBM, which is stable, we lose 10%
    print("T2 - Breakout from highest high or lowest low of last 100 days")

    profit = 0
    for i in range(101, count-6):
        # Minus another 100 for hh and ll because they are 100 elements shorter than the
        # main arrays.
        if highs[i-1] > hh100[i-2-100]:
            profit += closes[i+5] - opens[i]
        elif lows[i-1] < ll100[i-2-100]:
            profit += opens[i] - closes[i+5]

    return profit

print('t2 profit=', breakout_100d_hh_or_ll(), 'median=', median_close)

exit(0)

df["SMA50"] = df["Close"].rolling(50).mean()
df["sma14"] = df["Close"].rolling(14).mean()

high_low = df['High'] - df['Low']
high_close = np.abs(df['High'] - df['Close'].shift(1))
low_close = np.abs(df['Low'] - df['Close'].shift(1))
ranges = pd.concat([high_low, high_close, low_close], axis=1)
df['tr'] = np.max(ranges, axis=1)

df['atr10'] = df['tr'].rolling(10).mean()


# plt.plot(df.index, df['Close'], linestyle='solid')
# plt.plot(df.index, df['hh100'], color='blue')
# plt.plot(df.index, df['ll100'], color='red')
# plt.plot(df.index, df['sma14'], color='pink')
# plt.show()

breakout_100d_hh_or_ll()


# plt.scatter(df['tr'], df['atr10'])
# plt.xlabel('tr', fontsize=14)
# plt.ylabel('atr10', fontsize=14)
# plt.grid(True)
# plt.show()
