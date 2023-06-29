// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";

contract PAULIAN is ERC1155 { 

    uint256 public constant Rock = 1;
    uint256 public constant Paper = 2;
    uint256 public constant Scissors = 3;

    constructor() ERC1155("https://ipfs.io/ipfs/bafybeif3n2osuwvc7kcep4das6dl3qiggmapcuyn3b7urerls6j5q2g4r4/{id}.json") {
        _mint(msg.sender, Rock, 1, "");
        _mint(msg.sender, Paper, 1, "");
        _mint(msg.sender, Scissors, 1, "");
    }
 
    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/bafybeif3n2osuwvc7kcep4das6dl3qiggmapcuyn3b7urerls6j5q2g4r4/",
                Strings.toString(_tokenid),".json"
            )
        );
    }
}