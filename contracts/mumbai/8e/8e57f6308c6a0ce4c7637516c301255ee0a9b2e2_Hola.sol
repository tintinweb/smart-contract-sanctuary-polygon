/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "./ICustodia.sol";
contract Hola {

    /*function registerERC721(address _ERC721) external {
        ICustodia Icustodia = ICustodia(_ERC721);

        require(!isRegister[_ERC721],"contract already registered");
        require(
            Icustodia.owner() == msg.sender,
            "you are not the owner of the contract"
        );

        emit register(
            _ERC721,
            Icustodia.owner(),
            Icustodia.name(),
            Icustodia.symbol()
        );

        dateRegister[_ERC721]=block.timestamp;

        isRegister[_ERC721]=true;

    }

    
    mapping (address=>bool) internal isRegister;
    mapping (address=>uint) internal dateRegister;

    event register(
        address indexed _address,
        address indexed owner,
        string indexed name,
        string symbol
    );*/
}