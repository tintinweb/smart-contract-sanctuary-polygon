// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.12;

    import "./Ownable.sol";

    contract DocumentRegistry is Ownable{

        mapping (string => uint256) documents;

        function add(string memory hash) public onlyOwner returns(uint256 dateAdded){
            uint256 timeAdded = block.timestamp;
            documents[hash] = timeAdded;
            return timeAdded;
        }

        function verify(string memory hash) public view returns(uint dateAdded){
            return  documents[hash];
        }
    }