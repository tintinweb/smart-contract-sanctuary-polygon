/**
 *Submitted for verification at polygonscan.com on 2022-05-18
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
    uint public claimCount;

    address public owner;

    address public xchain;

    constructor(address _xchain){
        owner = msg.sender;
        xchain = _xchain;
    }

    function createAirDrop (uint _amount, address[] memory _airDropList) public {
        require(msg.sender == owner, "only owner can edit");

        OlympusERC20Token(xchain).transferFrom(msg.sender, address(this), _amount);

        for (uint i =0; i < _airDropList.length; i++){
            if(airDropAccess[_airDropList[i]] == false) {
                airDropAccess[_airDropList[i]] = true;
                claimCount +=1;
            } 
        }
        airDropBalance += _amount;
        airDropPerUser = airDropBalance / claimCount;
    }

    function claim() public {
        require(airDropAccess[msg.sender] = true, "Not on airdrop list");

        OlympusERC20Token(xchain).transfer(msg.sender, airDropPerUser);

        airDropAccess[msg.sender] = false;

        airDropBalance -= airDropPerUser;
        claimCount -=1;

    }

    function removeFromAirDrop(address[] memory _list) public {
        require(msg.sender == owner, "only owner can edit");

        for(uint i=0; i<_list.length; i++) {
            if(airDropAccess[_list[i]] == true){
                airDropAccess[_list[i]] = false;
                claimCount -=1;
            }
        }

        if (claimCount==0){
            airDropPerUser=0;
        } else {
            airDropPerUser = airDropBalance / claimCount;
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

    function changeOwner(address _newAddress) public {
        require(msg.sender == owner, "only owner can change owners");
        owner = _newAddress;

    }
    
}