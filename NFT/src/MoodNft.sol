// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    uint256 private s_tokenId;
    string private s_sadImageUri;
    string private s_happyImageUri;

    enum Mood {
        Sad,
        Happy
    }

    mapping(uint256 => Mood) private s_mood;

    constructor(string memory sadImageUri, string memory happyImageUri)
        ERC721("MoodNFT", "MNFT")
    {
        s_sadImageUri = sadImageUri;
        s_happyImageUri = happyImageUri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenId);
        s_mood[s_tokenId] = Mood.Happy; 
        s_tokenId++;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        // FIX: Instead of _exists(tokenId_), we call ownerOf(tokenId_).
        // The ownerOf function will automatically revert if the token does not exist,
        // so we don't even need a separate 'require' statement.
        // This is a common and gas-efficient way to check for existence.
        ownerOf(tokenId_);

        string memory imageURI = s_mood[tokenId_] == Mood.Happy
            ? s_happyImageUri
            : s_sadImageUri;

        string memory moodString = s_mood[tokenId_] == Mood.Happy ? "Happy" : "Sad";

        bytes memory jsonBytes = abi.encodePacked(
            '{"name":"', name(), ' #', tokenId_,
            '", "description":"An NFT that reflects your mood!",',
            '"attributes":[{"trait_type":"Mood","value":"',
                moodString,
            '"}], "image":"', imageURI, '"}'
        );
        
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(jsonBytes)));
    }

    function flipMood(uint256 tokenId_) public {
        // FIX: We manually reconstruct the logic of _isApprovedOrOwner
        // using publicly available functions.
        address owner = ownerOf(tokenId_); // This also checks for existence.
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender) || getApproved(tokenId_) == msg.sender,
            "ERC721: caller is not token owner or approved"
        );

        if (s_mood[tokenId_] == Mood.Happy) {
            s_mood[tokenId_] = Mood.Sad;
        } else {
            s_mood[tokenId_] = Mood.Happy;
        }
    }
}