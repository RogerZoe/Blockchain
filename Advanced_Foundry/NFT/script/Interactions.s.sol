// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Nft} from "../src/Contract.sol";

//integration is used for interacting with the NFT contract and 

contract Interactions is Script {
    string public constant nftImg =
        "ipfs://QmX8fbVeizthCGWemPkfS9aJ1o7s4UCizD2SJ3rRQ5Xqr7";

    // Your deployed NFT contract on Sepolia
    address constant nftContract = 0xe192F294E69dc3984364A7A332AD270D9708e945;

    function run() public {
        vm.startBroadcast();
        Nft(nftContract).mintNft(nftImg);
        vm.stopBroadcast();
    }
}
