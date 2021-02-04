from random import randint

TRAITS=[
        {"name": "FREE raffle creation", "chance":10, "type": "%"},
        {"name": "FREE Bingo Creation", "chance":10, "type": "%"},
        {"name": "FREE All services", "chance":2, "type": "%"},
        {"name": "DISCOUNT 5%", "chance":25, "type": "%"},
        {"name": "DISCOUNT 15%", "chance":15, "type": "%"},
        {"name": "DISCOUNT 25%", "chance":5, "type": "%"},
        {"name": "Revshare 0.01%", "chance":100, "type": "#"},
        {"name": "Revshare 0.1%", "chance":10, "type": "#"},
        {"name": "Revshare 1%", "chance":1, "type": "#"},
        {"name": "Sale share 0.01%", "chance":100, "type": "#"},
        {"name": "Sale share 0.1%", "chance":10, "type": "#"},
        {"name": "Sale share 1%", "chance":1, "type": "#"},
        {"name": "Serial Early Adopter (100-999)", "chance":1000, "type": "#"},
        {"name": "Serial OG (10-99)", "chance":90, "type": "#"},
        {"name": "Serial Founder (0-9)", "chance":10, "type": "#"},
        {"name": "MISC Disco Dropper", "chance":10, "type": "%"},
        {"name": "MISC +1 ticket", "chance":5, "type": "%"},
        {"name": "MISC +2 tickets", "chance":3, "type": "%"},
        {"name": "MISC +3 tickets", "chance":1, "type": "%"},
        {"name": "MISC Faketoshi", "chance":3, "type": "%"},
        {"name": "MISC Lucky", "chance":2, "type": "%"},
        {"name": "MISC Very Lucky", "chance":1, "type": "%"},
        {"name": "The Orwellians", "chance":1984, "type": "#"},
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

for c in range(CARD_COUNTER):
    card = {"#":c,"traits":[],"immutable":[]}
    for trait in TRAITS:
        # calculate chance
        chance = trait["chance"]
        type = trait["type"]
        if type == "%":
            r =randint(0,100)
            if r <= chance:
                card["traits"].append(trait["name"])
    # trait by serial
    if c<10:
        card["immutable"].append("Founder")
    elif c<100:
        card["immutable"].append("OG")
    elif c<1000:
        card["immutable"].append("Albha")
    else:
        card["immutable"].append("Beta")



    print(card)
    cards.append(card)

# stats
trait_counts=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
for c in range(CARD_COUNTER):
    trait_counts[len(cards[c]["traits"])]+=1

print("Number of traits:", len(TRAITS))
print("Trait counts:")
print(trait_counts)
