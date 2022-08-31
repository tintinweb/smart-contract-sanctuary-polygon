// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract RandomGenerator { 

    event RandomNumberGenerated(
        address indexed by,
        uint256 indexed randomNumber,
        uint256 maxNumber,
        uint256 time
    );
    event RandomNumberWithNameGenerated(
        address indexed by,
        uint256 indexed randomNumber,
        string randomName,
        uint256 totalNames,
        uint256 time
    );

    function getRandomNumber(uint256 maxNumber,uint256 _anyNumber) public returns(uint256){
        uint256 _randomNumber = uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,msg.sender,maxNumber,_anyNumber)));
        uint256 _number = _randomNumber % (maxNumber+1);
        emit RandomNumberGenerated(msg.sender,_number,maxNumber,block.timestamp);
        return _number;
    }

    
    function getRandomStringFromArray(string[] memory _names,uint256 _anyNumber)  public returns(string memory) {
        uint256 _totalNames = _names.length;
        uint256 _randomNumber = getRandomNumber(_totalNames - 1,_anyNumber);
        string memory _randomName = _names[_randomNumber];
        // console.log("random name",_randomName);

        emit RandomNumberWithNameGenerated(msg.sender,_randomNumber,_randomName,_totalNames,block.timestamp);
        return _randomName;
    }

}