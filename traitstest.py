from random import randint
import random
import pickle
import sys

TRAITS=[
    {"type": "common",    "subtype": "free",  "name": "FREE raffle creation", "chance":10,   "occurence":0 },
    {"type": "common",    "subtype": "free",  "name": "FREE Bingo Creation",  "chance":10,   "occurence":0 },
    {"type": "common",    "subtype": "free",  "name": "FREE All services",    "chance":3,    "occurence":0 },
    {"type": "common",    "subtype": "disco", "name": "DISCOUNT 5%",          "chance":25,   "occurence":0 },
    {"type": "common",    "subtype": "disco", "name": "DISCOUNT 15%",         "chance":15,   "occurence":0 },
    {"type": "common",    "subtype": "disco", "name": "DISCOUNT 25%",         "chance":10,   "occurence":0 },
    {"type": "limited",   "subtype": "rev",   "name": "Revshare 0.01%",       "chance":100,  "occurence":0 },
    {"type": "limited",   "subtype": "rev",   "name": "Revshare 0.1%",        "chance":10,   "occurence":0 },
    {"type": "limited",   "subtype": "rev",   "name": "Revshare 1%",          "chance":1,    "occurence":0 },
    {"type": "limited",   "subtype": "sale",  "name": "Sale share 0.01%",     "chance":100,  "occurence":0 },
    {"type": "limited",   "subtype": "sale",  "name": "Sale share 0.1%",      "chance":10,   "occurence":0 },
    {"type": "limited",   "subtype": "sale",  "name": "Sale share 1%",        "chance":1,    "occurence":0 },
    {"type": "immutable", "subtype": "sale",  "name": "Beta",                 "chance":9000, "occurence":0 },
    {"type": "immutable", "subtype": "sale",  "name": "Alpha",                "chance":900,  "occurence":0 },
    {"type": "immutable", "subtype": "ser",   "name": "OG",                   "chance":90,   "occurence":0 },
    {"type": "immutable", "subtype": "ser",   "name": "Founder",              "chance":9,    "occurence":0 },
    {"type": "immutable", "subtype": "ser",   "name": "The One",              "chance":1,    "occurence":0 },
    {"type": "common",    "subtype": "dd",    "name": "MISC Disco Dropper",   "chance":10,   "occurence":0 },
    {"type": "common",    "subtype": "tix",   "name": "MISC +1 ticket",       "chance":6,    "occurence":0 },
    {"type": "common",    "subtype": "tix",   "name": "MISC +2 tickets",      "chance":4,    "occurence":0 },
    {"type": "common",    "subtype": "tix",   "name": "MISC +3 tickets",      "chance":2,    "occurence":0 },
    {"type": "common",    "subtype": "f",     "name": "MISC Faketoshi",       "chance":4,    "occurence":0 },
    {"type": "common",    "subtype": "lucky", "name": "MISC Lucky",           "chance":3,    "occurence":0 },
    {"type": "common",    "subtype": "lucky", "name": "MISC Very Lucky",      "chance":1,    "occurence":0 },
    {"type": "limited",   "subtype": "orw",   "name": "The Orwellians",       "chance":1984, "occurence":0 }
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


# TODO: Artwork
# TODO: Frame
# Physical frame (5)
# Russian Roulette
# The Orwells

CARD_COUNTER = 10000
cards=[]
available_cards=[]
available_og=[]
available_alpha=[]

image_decider = []
frame_decider = []

#===============================================================

# in percentages
frames = [
        [70,"common"],
        [20, "silver"],
        [9, "gold"],
        [1, "epic"]
        ]

# available images
images = [
        [5,"fantasy1"],
        [10,"fantasy2"],
        [50,"fantasy3"],
        [3,"fantasy4"],
        [45,"fantasy5"],
        [2,"fantasy6"],
        [90,"fantasy7"],
        [35,"fantasy8"],
        [40,"fantasy9"],
        [70,"fantasy10"],
        [25,"fantasy11"],
        [80,"fantasy12"],
        [50,"fantasy13"],
        [50, "zoo1"],
        [50,"zoo2"],
        [50,"zoo3"],
        [50,"zoo4"],
        [50,"zoo5"],
        [50,"zoo6"],
        [50,"zoo7"],
        [50,"zoo8"],
        [50,"zoo9"],
        [70,"baron1"],
        [65,"baron2"],
        [65,"baron3"],
        [55,"baron4"],
        [45,"baron5"],
        [35,"baron6"],
        [25,"baron7"],
        [15,"baron8"],
        [15,"baron9"],
        [5,"baron10"]
        ]


#===============================================================

def initiate_image_decider():
    for image in images:
        l = image[0]
        im = image[1]
        for i in range(l):
            image_decider.append(im)

def initiate_frame_decider():
    for frame in frames:
        l = frame[0]
        im = frame[1]
        for i in range(l):
            frame_decider.append(im)

def select_visuals():
    global image_decider
    if len(image_decider) == 0:
        initiate_image_decider()

    global frame_decider
    if len(frame_decider) == 0:
        initiate_frame_decider()


    image = random.choice(image_decider)
    frame = random.choice(frame_decider)

    return({"image":image, "frame":frame})


def pre_populate():
    # pre-populating cards
    for c in range(CARD_COUNTER):
        card = {"#":c,"limited":[], "traits":[], "common":[], "immutable":[], "subtypes":[], "visuals":{}, "sold":False}
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

    # pre-generate the array that is used to pre-generate limiteds
    limited_decider = []
    for card in cards:
        if "OG" in card["traits"]:
            limited_decider.append(card["#"])
            limited_decider.append(card["#"])
        elif "Alpha" in card["traits"]:
            limited_decider.append(card["#"])
        limited_decider.append(card["#"])

    print("limited_decider size:", len(limited_decider))

    # pre-generate limiteds
    for trait in TRAITS:
        if trait["type"] == "limited":
            # we need to select 'chance' number of serials from the amount of possible cards (CARD_COUNTER)
            selected = []
            chance = trait["chance"]

            while len(selected) < trait["chance"]:
                r = randint(0,len(limited_decider)-1)
                c = limited_decider[r]
                if not c in selected:
                    if (trait["subtype"] not in cards[c]["subtypes"]):
                        selected.append(r)
                        cards[c]["subtypes"].append(trait["subtype"])
                        cards[c]["traits"].append(trait["name"])
                        cards[c]["limited"].append(trait["name"])
    # save cards
    save_cards()


def select_card(type):
    r = randint(0,len(CARD_COUNTER)-1)


def load_cards():
    global cards
    cards = pickle.load( open( "cards.p", "rb" ) )

    # populate available arrays
    available_cards
    for card in cards:
        if not card["sold"]:
            available_cards.append(card["#"])
            if "OG" in card["traits"]:
                available_og.append(card["#"])
            if "Alpha" in card["traits"]:
                available_alpha.append(card["#"])

def save_cards(c=False):
    pickle.dump( cards, open( "cards.p", "wb" ) )


def buy_card(ctype="any"):
    global cards

    a = available_cards
    if ctype == "og":
        a = available_og
    elif ctype == "alpha":
        a = available_alpha

    if len(a) == 0:
        print("no more cards to sell")
        exit()

    c = random.choice(a)


    cards[c]["visuals"] = select_visuals()
    
    for trait in TRAITS:
        # if card alread have this subtype, then ignore it
        if not trait["subtype"] in cards[c]["subtypes"]:
            # calculate chance
            if trait["type"] == "common":
                r =randint(0,100)
                chance = trait["chance"]
                if "OG" in cards[c]["traits"]:
                    chance = chance * 3
                elif "Alpha" in cards[c]["traits"]:
                    chance = chance * 2

                if r <= chance:
                    cards[c]["subtypes"].append(trait["subtype"])
                    cards[c]["traits"].append(trait["name"])
                    cards[c]["common"].append(trait["name"])
    #print(cards[c])

    cards[c]["sold"] = True;

    if c in available_cards: available_cards.remove(c)
    if c in available_og: available_og.remove(c)
    if c in available_alpha: available_alpha.remove(c)
   
    return(c)


def stats(c = 0):

    global cards
    # card details
    # OG available
    # Alpha available
    # All available

    print("Card details")
    print(cards[c])

    print("=============")
    print("OG available:",len(available_og))
    print("Alpha available:",len(available_alpha))
    print("All available:",len(available_cards))


def fullstats():
    # stats
    global cards
    load_cards()
    
    # occurences
    for card in cards:
        for trait in TRAITS:
            if trait["name"] in card["traits"]:
                trait["occurence"]+=1



    print("==================")
    print("Available cards:", len(available_cards))
    print(" ")
    
    print("==================")
    print("Traits:")
    for trait in TRAITS:
        print(trait["name"], ": ", trait["occurence"])
    print(" ")

    traitstats("any")
    traitstats("OG")
    traitstats("Alpha")
    traitstats("Beta")


    #print("larger combos")
    #large_combos=[[],[],[],[],[],[],[],[]]
    #for card in cards:
    #    if len(card["traits"])> 3:
    #        large_combos[len(card["traits"])].append(card)

    #for c in range(len(large_combos)):
    #    if len(large_combos[c]) > 0:
    #        print("cards with ",c," traits:")
    #        for card in large_combos[c]:
    #            print(card)



    # TODO 
    # implement pricing
    # implement image
    # implement graphics
    # implement eth logo graphics

    # functions

    # mint_card
    # optional parameter: OG, Alpha
    # prepopulate
    # load data
    # mint all cards
    # stats


def traitstats(name):
    
    trait_counts=[0,0,0,0,0,0,0,0,0]
    counter = 0
    for card in cards:
        if name == "any" or name in card["traits"]:
            counter += 1
            common_traits= len(card["common"])
            limited_traits= len(card["limited"])
            trait_counts[(common_traits+limited_traits)]+=1

    print("==================")
    print(name)
    print("-----")
    print(trait_counts)
    print(" ")
    print("Number of cards:",counter)
    print("-----")
    for tc in range(len(trait_counts)):
        if trait_counts[tc] != 0:
            occurence = trait_counts[tc]
            chance = float(occurence / (counter / 100))
            print("cards with %i traits:  %i. Chance: %2f." % (tc, trait_counts[tc], chance))
            
    occurence = trait_counts[0]
    chance = float(occurence / (counter / 100))
    chance = 100 - chance
    print("Chance of getting any trait:", chance)





def buy_single(ctype="any"):
    load_cards()
    c = buy_card(ctype)
    save_cards()
    stats(c)


def buy_all():
    print("buying all cards")
    load_cards()
    for c in range(len(available_cards)):
        buy_card()
    save_cards()
    stats()



if len(sys.argv) > 1:
    p = sys.argv[1]
    if p == "buy":
        if len(sys.argv) == 3:
            buy_single(sys.argv[2])
        else:
            buy_single()
    if p == "init":
        pre_populate()

    if p == "buyall":
        buy_all()
    if p == "stats":
        fullstats()
