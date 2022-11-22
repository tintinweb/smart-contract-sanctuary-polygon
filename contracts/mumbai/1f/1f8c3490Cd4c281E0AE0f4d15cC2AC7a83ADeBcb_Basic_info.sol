// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract Basic_info {

   bytes32 public answer;
   bytes32 private GGG;


    function hash(
        string memory _text
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text));

    }

    function hashFFF(string memory _text) public {
     answer = keccak256(abi.encodePacked(_text));

    }

    function hashGGG(string memory _text) public {
     GGG = keccak256(abi.encodePacked(_text));

    }

    // Magic word is "Solidity"
    function guess(string memory _word) public view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == answer;
    }

    function guessGGG(string memory _word) public view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == GGG;
    }

    
  
}