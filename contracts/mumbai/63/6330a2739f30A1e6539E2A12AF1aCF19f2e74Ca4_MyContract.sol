// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "hardhat/console.sol";

contract MyContract {
    string public name = 'base boiler name';

    function setName(string memory _name) public {
        name = _name;
    }
    function getName() public view returns(string memory) {
        return name;
    }
    function resetName() public {
        name = 'reset boiler name';
    }


    function pay() public payable returns (address, address, uint256){
        // global vars
        return(
            msg.sender,
            tx.origin,
            msg.value
        );
    }

    function getBlockInfo() public view returns (uint256,uint256,uint256) {
        return (
            block.number,
            block.timestamp,
            block.chainid
        );
    }
}