<<<<<<< HEAD


# **NFT Collection – Solidity + Foundry Project**

A simple and clean NFT smart contract project built using **Solidity**, **Foundry**, and best practices learned from the **Cyfrin Updraft** courses.
This project demonstrates how to create ERC-721 NFTs, mint tokens, manage metadata, and test contracts with Foundry.

## 🚀 Features

* Fully compliant **ERC-721** NFT smart contract
* Custom NFT name & symbol
* On-chain or off-chain metadata support
* Public minting function (or owner-only depending on your version)
* Gas-efficient Solidity patterns inspired by Cyfrin auditing lessons
* Complete Foundry test suite

## 🛠️ Tech Stack

* **Solidity**
* **Foundry**
* **OpenZeppelin Contracts**
* **Chainlink** (optional if your version uses randomness)

## 📁 Project Structure

```
/src
  ├── MyNFT.sol
/test
  ├── MyNFT.t.sol
/scripts
  ├── Deploy.s.sol
foundry.toml
README.md
```

## 📌 Smart Contract Overview

The core NFT contract extends **ERC721** and uses a simple mint function:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 private _tokenId;

    constructor() ERC721("My Cyfrin NFT", "CYFN") Ownable(msg.sender) {}

    // Mint function anyone can call (or restrict to owner if needed)
    function mintNFT() external returns (uint256) {
        _tokenId++;
        _mint(msg.sender, _tokenId);
        return _tokenId;
    }
}
```

The contract stays intentionally simple to demonstrate fundamentals clearly.

## 🔬 Testing (Foundry)

Run the full test suite:

```
forge test -vvv
```

Tests include:

* Contract deployment
* Minting behavior
* Ownership checks
* Events & state changes

## 🚢 Deployment

Deploy to any EVM chain using Foundry scripts:

```
forge script script/Deploy.s.sol --rpc-url <YOUR_RPC> --private-key <KEY> --broadcast
```

## 📦 Metadata

If your project uses off-chain metadata, add your JSON files to `ipfs/` or upload them to Pinata / NFT.Storage.
Update your `tokenURI` logic accordingly.

## 📚 Learned From

This project was built while learning from:

**Cyfrin Updraft – Foundry & Solidity Courses**
These courses taught:

* Secure smart contract patterns
* Efficient testing
* Real-world development flows
* NFT standards and best practices

## 🤝 Contributing

Feel free to fork, open issues, or suggest improvements.

## 🧑‍💻 Author

**Arif**
Aspiring Web3 Developer | Building and learning daily

=======
data:image/svg+xml;base64,
PHN2ZyB3aWR0aD0iMTAyNHB4IiBoZWlnaHQ9IjEwMjRweCIgdmlld0JveD0iMCAwIDEwMjQgMTAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBmaWxsPSIjMzMzIiBkPSJNNTEyIDY0QzI2NC42IDY0IDY0IDI2NC42IDY0IDUxMnMyMDAuNiA0NDggNDQ4IDQ0OCA0NDgtMjAwLjYgNDQ4LTQ0OFM3NTkuNCA2NCA1MTIgNjR6bTAgODIwYy0yMDUuNCAwLTM3Mi0xNjYuNi0zNzItMzcyczE2Ni42LTM3MiAzNzItMzcyIDM3MiAxNjYuNiAzNzIgMzcyLTE2Ni42IDM3Mi0z
NzIgMzcyeiIvPgogIDxwYXRoIGZpbGw9IiNFNkU2RTYiIGQ9Ik01MTIgMTQwYy0yMDUuNCAwLTM3
MiAxNjYuNi0zNzIgMzcyczE2Ni42IDM3MiAzNzIgMzcyIDM3Mi0xNjYuNiAzNzItMzcyLTE2Ni42
LTM3Mi0zNzItMzcyek0yODggNDIxYTQ4LjAxIDQ4LjAxIDAgMCAxIDk2IDAgNDguMDEgNDguMDEg
MCAwIDEtOTYgMHptMzc2IDI3MmgtNDguMWMtNC4yIDAtNy44LTMuMi04LjEtNy40QzYwNCA2MzYu
MSA1NjIuNSA1OTcgNTEyIDU5N3MtOTIuMSAzOS4xLTk1LjggODguNmMtLjMgNC4yLTMuOSA3LjQt
OC4xIDcuNEgzNjBhOCA4IDAgMCAxLTgtOC40YzQuNC04NC4zIDc0LjUtMTUxLjYgMTYwLTE1MS42
czE1NS42IDY3LjMgMTYwIDE1MS42YTggOCAwIDAgMS04IDguNHptMjQtMjI0YTQ4LjAxIDQ4LjAx
IDAgMCAxIDAtOTYgNDguMDEgNDguMDEgMCAwIDEgMCA5NnoiLz4KICA8cGF0aCBmaWxsPSIjMzMz
IiBkPSJNMjg4IDQyMWE0OCA0OCAwIDEgMCA5NiAwIDQ4IDQ4IDAgMSAwLTk2IDB6bTIyNCAxMTJj
LTg1LjUgMC0xNTUuNiA2Ny4zLTE2MCAxNTEuNmE4IDggMCAwIDAgOCA4LjRoNDguMWM0LjIgMCA3
LjgtMy4yIDguMS03LjQgMy43LTQ5LjUgNDUuMy04OC42IDk1LjgtODguNnM5MiAzOS4xIDk1Ljgg
ODguNmMuMyA0LjIgMy45IDcuNCA4LjEgNy40SDY2NGE4IDggMCAwIDAgOC04LjRDNjY3LjYgNjAw
LjMgNTk3LjUgNTMzIDUxMiA1MzN6bTEyOC0xMTJhNDggNDggMCAxIDAgOTYgMCA0OCA0OCAwIDEg
MC05NiAweiIvPgo8L3N2Zz4=
>>>>>>> e997d0b (Files)
