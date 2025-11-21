// SPDX-License-Idenitfier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Nft is ERC721 {
    uint256 public tokenCount;
    mapping(uint256 => string) public tokenURIs;

    constructor() ERC721("MyToken", "MT") {
        tokenCount = 0;
    }

    function mintNft(string memory _tokenURI) public {
        tokenURIs[tokenCount] = _tokenURI;
        _safeMint(msg.sender, tokenCount);
        tokenCount++;
    }

    function tokenURI(
        uint256 _tokenID
    ) public view override returns (string memory) {
        return tokenURIs[_tokenID];
    }
}
