// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Script, console} from "forge-std/Script.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {MoodNft} from "../src/MoodNft.sol";

contract DeployMoodNft is Script {
    function run() external returns (MoodNft) {
        string memory sadSvg = vm.readFile("./img/Image.svg");
        string memory HappySvg = vm.readFile("./img/Image.svg");
        console.log(sadSvg, "sadSvg");

        vm.startBroadcast();
        MoodNft moodNft = new MoodNft(
            svgToImageURI(sadSvg),
            svgToImageURI(HappySvg)
        );
        vm.stopBroadcast();
        return moodNft;
    }

    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        // Encode the raw SVG to Base64
        string memory svgBase64 = Base64.encode(bytes(svg));

        // Return the data URI image format
        return
            string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
    }
}
