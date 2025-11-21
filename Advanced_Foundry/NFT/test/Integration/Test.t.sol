// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {DeployContract} from "../../script/DeployContract.s.sol";
import {Nft} from "../../src/Contract.sol";

contract TestNFT is Test {
    DeployContract deployer;
    Nft nft;
    address public USER = makeAddr("User");
    string public constant nftImg =
        "ipfs://QmX8fbVeizthCGWemPkfS9aJ1o7s4UCizD2SJ3rRQ5Xqr7";

    function setUp() public {
        deployer = new DeployContract();
        nft = deployer.run();
    }

    function testTokenNameEqual() public view {
        string memory Actual_Name = nft.name();
        string memory expected_Name = "MyToken";
        // assert(Actual_Name == expected_Name); //gives error because strings are not comparable due to strings are dynamic arrays so we have to use keccak256
        assert(
            keccak256(abi.encodePacked(Actual_Name)) ==
                keccak256(abi.encodePacked(expected_Name))
        );
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        nft.mintNft(nftImg);
        assert(nft.balanceOf(USER) == 1); // this one for to check balance count
        assert(
            keccak256(abi.encodePacked(nft.tokenURI(0))) ==
                keccak256(abi.encodePacked(nftImg))
        ); // this one for to check tokenURI has same value
    }
}
