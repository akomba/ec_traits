# The Sale Mechanism

## Initialise the sale

### Token Arrays

The cardfixed array is effectively in tokenId order because they are never rearranged.

``` solidity
uint24 []cardfixed;
```

#### cardFixed Format (bits:meaning)

- 0 - 13  : number  (10,000 / 16k)
- 14 & 15 : frame   (4 / 4)
- 16 - 20 : picture (32 / 32)
- 21 - 22 : card type (3 / 4)

The traits array, while populated later was created before the contract was launched.

``` solidity
uint32[] traits;
```

As defined in ec.py

#### arrays of tokenIds

- ogs
- alphas
- ordinaries

These arrays are initially all free. As an item is sold, it is removed by the usual array removal methods.

``` text
                          (these have been removed)
       0  1  2  3  4  5    6  7  8  9
 ogs : Og Og Og Og Og Og | Og Og Og Og
 ```

 items 0-5 are for sale, 6 - 9 were sold so they are no longer here

#### buying a card

Anybody buying a card can get that card or one of a better class. You cannot buy a card if there are none left of that class.

1. There must be some cards of this type available.
2. We record that one of this type is requested (noting the address), thereby reducing the availability in this category

``` solidity
uint256 ogDemand;
uint256 alphaDemand;
uint256 ordinaryDemand;
```

#### Selling a card (part II)

- We work through the OG's first. Then the Alpha's, then the Ordinaries.
- We resolve the card to sell, adjusting balances if we get a random upgrade

``` solidity
function getNumberOfCardsAvailable(CardType ct) internal view returns (uint256) {
    if (ct == CardType.OG) return (ogs.length - ogDemand);
    if (ct == CardType.Alpha) return (alphas.length - alphaDemand) + (ogs.length - ogDemand);
    return ordinary.length - ordinaryDemand +  (alphas.length - alphaDemand) + (ogs.length - ogDemand);
}
```

We now take a random position into that number

``` solidity
uint randomPos = random % numberOfCardsAvailable;
```

Then we take the card from whichever group it is in.

If we take from a higher group, we need to increase the demand for that group and release a place from our own group.

``` solidity

function sellCard(address owner, CardType buyer, uint256 random) {
    uint pos = random;
    if (buyer == CardType.OG) {
        markOgCardAsSold(owner,pos);
        return;
    }
    if (buyer == CardType.Alpha) {
        if (pos < ogs.length - ogDemand) {
            markOgCardAsSold(owner,pos);
            alphaDemand--;
            ogDemand++;
            return;
        }
        pos -= ogs.length - ogDemand;
        markAlphaCardAsSold(owner,pos);
        return;
    }
    if (pos < ogs.length - ogDemand) {
        markOgCardAsSold(owner,pos);
        ordinaryDemand--;
        ogDemand++;
        return;
    }
    pos -= ogs.length - ogDemand;
    if (pos < alphas.length - alphaDemand) {
        markAlphaCardAsSold(owner,pos);
        ordinaryDemand--;
        alphaDemand++;
        return;
    }
    pos -= alphas.length - alphaDemand;
    markOrdinaryCardAsSold(owner,pos);
}
```

once the card to sell has been determined, the element must be removed in the appropriate array
The item at the tail is moved to replace it and the array shortened.

A token must be minted with the token ID that we have just moved

``` solidity
function markOgCardAsSold(address owner, uint pos) {
    uint last = ogs.length - 1;
    uint tokenId = uint256(ogs[pos]);
    ogs[pos] = ogs[last];
    _mint(owner, tokenId);
}

function markAlphaCardAsSold(address owner, uint pos) {
    uint last = alphas.length - 1;
    uint tokenId = uint256(alphas[pos]);
    alphas[pos] = alphas[last];
    _mint(owner, tokenId);
}

function markOrdinaryCardAsSold(address owner, uint pos) {
    uint last = ordinaries.length - 1;
    uint tokenId = uint256(ordinaries[pos]);
    ordinaries[pos] = ordinaries[last];
    _mint(owner, tokenId);
}
```

## Remaining Questions

### Is it possible to take an order for a card that cannot be created?

- no. We will not take orders for ordinaries that cannot be created, and since we process the higher value cards first, we cannot get into that situation.
