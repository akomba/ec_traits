from random import randint
import pprint

TRAITS=[
        {"type": "common",    "subtype": "free",  "name": "FREE raffle creation",           "chance":10,   "occurence":0 },
        {"type": "common",    "subtype": "free",  "name": "FREE Bingo Creation",            "chance":10,   "occurence":0 },
        {"type": "common",    "subtype": "free",  "name": "FREE All services",              "chance":3,    "occurence":0 },
        {"type": "common",    "subtype": "disco", "name": "DISCOUNT 5%",                    "chance":25,   "occurence":0 },
        {"type": "common",    "subtype": "disco", "name": "DISCOUNT 15%",                   "chance":15,   "occurence":0 },
        {"type": "common",    "subtype": "disco", "name": "DISCOUNT 25%",                   "chance":10,   "occurence":0 },
        {"type": "limited",   "subtype": "rev",   "name": "Revshare 0.01%",                 "chance":100,  "occurence":0 },
        {"type": "limited",   "subtype": "rev",   "name": "Revshare 0.1%",                  "chance":10,   "occurence":0 },
        {"type": "limited",   "subtype": "rev",   "name": "Revshare 1%",                    "chance":1,    "occurence":0 },
        {"type": "limited",   "subtype": "sale",  "name": "Sale share 0.01%",               "chance":100,  "occurence":0 },
        {"type": "limited",   "subtype": "sale",  "name": "Sale share 0.1%",                "chance":10,   "occurence":0 },
        {"type": "limited",   "subtype": "sale",  "name": "Sale share 1%",                  "chance":1,    "occurence":0 },
        {"type": "immutable", "subtype": "sale",  "name": "Beta", "chance":9000, "occurence":0 },
        {"type": "immutable", "subtype": "sale",  "name": "Alpha", "chance":900, "occurence":0 },
        {"type": "immutable", "subtype": "ser",   "name": "OG",              "chance":90,   "occurence":0 },
        {"type": "immutable", "subtype": "ser",   "name": "Founder",           "chance":9,    "occurence":0 },
        {"type": "immutable", "subtype": "ser",   "name": "The One",                    "chance":1,    "occurence":0 },
        {"type": "common",    "subtype": "dd",    "name": "MISC Disco Dropper",             "chance":10,   "occurence":0 },
        {"type": "common",    "subtype": "tix",   "name": "MISC +1 ticket",                 "chance":6,    "occurence":0 },
        {"type": "common",    "subtype": "tix",   "name": "MISC +2 tickets",                "chance":4,    "occurence":0 },
        {"type": "common",    "subtype": "tix",   "name": "MISC +3 tickets",                "chance":2,    "occurence":0 },
        {"type": "common",    "subtype": "f",     "name": "MISC Faketoshi",                 "chance":4,    "occurence":0 },
        {"type": "common",    "subtype": "lucky", "name": "MISC Lucky",                     "chance":3,    "occurence":0 },
        {"type": "common",    "subtype": "lucky", "name": "MISC Very Lucky",                "chance":1,    "occurence":0 },
        {"type": "limited",   "subtype": "orw",   "name": "The Orwellians",                 "chance":1984, "occurence":0 }
]

# "MISC Virgin": {"chance":?, "type": "#"},


# types of features:
# COMMON TRAITS: random chance to get any of these, no upper limit. can be revealed at minting time
# LIMITED TRAITS: only limited number is available. Will be pre-determined. Hidden until all 10k cards sold.
# IMMUTABLE TRAITS: deterministically assinged based on characteristics, for example by number of digits in serial number
# BONUSES: extra treats issued automatically, for example blind bags and tickets. 


# we issue 10,000 cards and calculate the chances of traits on each card

# handling limited issuance traits can be done by pre-determining what serial cards will get it
# that is easy -- the difficult part is to hide that from the people before the issuance is over
# it can be done -- this is exactly what hashmasks did
# the cards' traits were pre-determined, but hidden until all cards were sold
# we need to do the same with the limited traits





CARD_COUNTER = 10000
cards=[]

# pre-populating cards
for c in range(CARD_COUNTER):
    card = {"#":c,"limited":[], "traits":[], "common":[], "immutable":[], "subtypes":[]}
    # trait by serial
    if c == 0:
        card["traits"].append("The One")
        card["immutable"].append("The One")
    elif c<10:
        card["traits"].append("Founder")
        card["immutable"].append("Founder")
    elif c<100:
        card["traits"].append("OG")
        card["immutable"].append("OG")
    elif c<1000:
        card["traits"].append("Alpha")
        card["immutable"].append("Alpha")
    else:
        card["traits"].append("Beta")
        card["immutable"].append("Beta")
    cards.append(card)

# pre-generate limiteds
for trait in TRAITS:
    if trait["type"] == "limited":
        # we need to select 'chance' number of serials from the amount of possible cards (CARD_COUNTER)
        selected = []
        while len(selected) < trait["chance"]:
            r = randint(0,CARD_COUNTER-1)
            if not r in selected:
                if (trait["subtype"] not in cards[r]["subtypes"]):
                    selected.append(r)
                    cards[r]["subtypes"].append(trait["subtype"])
                    cards[r]["traits"].append(trait["name"])
                    cards[r]["limited"].append(trait["name"])

# generate cards
for c in range(CARD_COUNTER):
    for trait in TRAITS:
        # if card alread have tyhis subtype, then ignore it
        if not trait["subtype"] in cards[c]["subtypes"]:
            # calculate chance
            if trait["type"] == "common":
                r =randint(0,100)
                if r <= trait["chance"]:
                    cards[c]["subtypes"].append(trait["subtype"])
                    cards[c]["traits"].append(trait["name"])
                    cards[c]["common"].append(trait["name"])
    print(cards[c])

# stats
trait_counts=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
for c in range(CARD_COUNTER):
    common_traits= len(cards[c]["common"])
    limited_traits= len(cards[c]["limited"])
    trait_counts[(common_traits+limited_traits)]+=1

# occurences
for card in cards:
    for trait in TRAITS:
        if trait["name"] in card["traits"]:
            trait["occurence"]+=1


for trait in TRAITS:
    print(trait["name"], ": ", trait["occurence"])

print("Common Trait counts:")
print(trait_counts)

print("larger combos")
large_combos=[[],[],[],[],[],[],[],[]]
for card in cards:
    if len(card["traits"])> 3:
        large_combos[len(card["traits"])].append(card)

#for c in range(len(large_combos)):
#    if len(large_combos[c]) > 0:
#        print("cards with ",c," traits:")
#        for card in large_combos[c]:
#            print(card)




