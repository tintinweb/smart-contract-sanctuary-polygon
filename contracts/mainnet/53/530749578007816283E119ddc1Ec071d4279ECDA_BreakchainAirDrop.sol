/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



interface OlympusERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract BreakchainAirDrop {

    mapping(address=>bool) airDropAccess;

    uint public airDropBalance;

    uint public airDropPerUser;

    address public owner;

    address public xchain;

    constructor(address _xchain){
        owner = msg.sender;
        airDropAccess[msg.sender] = true;
        xchain = _xchain;
    }

    function createAirDrop (uint _amount, address[] memory _airDropList) public {
        require(msg.sender == owner, "only owner can edit");

        OlympusERC20Token(xchain).transferFrom(msg.sender, address(this), _amount);

        airDropBalance += _amount;
        uint recipients = _airDropList.length;
        airDropPerUser = airDropBalance / recipients;

        for (uint i =0; i < recipients; i++){
            airDropAccess[_airDropList[i]] = true;
        }
    }

    function claim() public {
        require(airDropAccess[msg.sender] = true, "Not on airdrop list");

        OlympusERC20Token(xchain).transfer(msg.sender, airDropPerUser);

        airDropAccess[msg.sender] = false;

        airDropBalance -= airDropPerUser;

    }

    function removeFromAirDrop(address[] memory _list) public {
        require(msg.sender == owner, "only owner can edit");
        for(uint i=0; i<_list.length; i++) {
            airDropAccess[_list[i]] = false;

        }

    }

    function isAirdrop(address _address) public view  returns (bool){
        return airDropAccess[_address];
    }

    function airdropAmount(address _address) public view  returns (uint){

        if (airDropAccess[_address]) {
            return airDropPerUser;
        } else{
            return 0;
        }
            
    }
    
}