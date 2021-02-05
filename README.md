# Tests and calculations for the ehter.cards traits system


# types of features:
* COMMON TRAITS: random chance to get any of these, no upper limit. can be revealed at minting time
* LIMITED TRAITS: only limited number is available. Will be pre-determined. Hidden until all 10k cards sold.
* IMMUTABLE TRAITS: deterministically assinged based on characteristics, for example by number of digits in serial number
* BONUSES: extra treats issued automatically, for example blind bags and tickets. 

# TABLE

| Trait Type | Name | Chance | Type |
|---|---|---|---|
|Common | FREE raffle creation | 10 | % |
|Common | FREE Bingo Creation | 10 | % |
|Common | FREE All services | 2 | % |
|Common | DISCOUNT 5% | 25 | % |
|Common | DISCOUNT 15% | 15 | % |
|Common | DISCOUNT 25% | 5 | % |
|Common | MISC Disco Dropper | 10 | % |
|Common | MISC +1 ticket | 5 | % |
|Common | MISC +2 tickets | 3 | % |
|Common | MISC +3 tickets | 1 | % |
|Common | MISC Faketoshi | 3 | % |
|Common | MISC Lucky | 2 | % |
|Common | MISC Very Lucky | 1 | % |
|Limited | The Orwellians | 1984 | # |
|Limited | Revshare 0.01% | 100 | # |
|Limited | Revshare 0.1% | 10 | # |
|Limited | Revshare 1% | 1 | # |
|Limited | Sale share 0.01% | 100 | # |
|Limited | Sale share 0.1% | 10 | # |
|Limited | Sale share 1% | 1 | # |
|Immutable | Serial Beta (1000-9999) | 9000 | # |
|Immutable | Serial Alpha (100-999) | 900 | # |
|Immutable | Serial OG (10-99) | 90 | # |
|Immutable | Serial Founder (1-9) | 9 | # |
|Immutable | The One (0) | 1 | # |



# How to use

Init the database:
```
python ec.py init
```

Buy a card:
```
python ec.by buy
```

Buy all cards:
```
python ec.py buyall
```

Stats:
```
python ec.py stats
```

Remove db and restarts:
```
rm cards.p
```
