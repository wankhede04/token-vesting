# Token Vesting

Vesting contract for equity distribution according to various classes(designation)

## Problem statement

An early stage startup is planning to offer its employees some equity as crypto tokens based on their designation in the company. They have defined 3 classes of equity based on seniority level, they are as follows:
1. CXO - 1000 tokens, released 25% each year after a cliff period of 1 year.
2. Senior manager - 800 tokens, released 25% each year after a cliff period of 1 year.
3. Others - 400 tokens, released 50% each year after a cliff period of 1 year.


For being transparent about the equity grants and vesting, the company has decided to manage them on Ethereum blockchain.

### Key points
Develop a set of smart contracts to:
1. Maintain equity classes configuration
2. Grant equity to an employee based on their designation
3. Unlock equity amount as per the vesting period
4. Ability to check balance of unlocked tokens for an address
5. Transfer of tokens after they are unlocked

---
## Steps
Install dependencies
```sh
yarn
```

Hardhat help
```sh
npx hardhat help
```

Compile contract(s)
```sh
yarn complie
```

Run tests
```sh
yarn test
```

Deploy contracts
```sh
NETWORK=<network> yarn deploy
```

Remove artifacts
```sh
yarn clean
```

## Footnote
Developed by [wankhedeO4](https://github.com/wankhede04)
