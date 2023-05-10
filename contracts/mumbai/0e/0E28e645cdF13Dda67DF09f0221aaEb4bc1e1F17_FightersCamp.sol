// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract FightersCamp {


    event NewFighter(uint id, string name);

    struct Fighter {
        string name;  
    }

   
    Fighter[] public fighters;

    mapping (uint => address) public fighterToOwner;
    mapping (address => uint) ownerFighterCount;

    function _createFighter(string memory _name) private {
        uint id = fighters.length;
        fighters.push(Fighter(_name));
        fighterToOwner[id] = msg.sender;
        ownerFighterCount[msg.sender]++;
        emit NewFighter(id, _name);
    }
    

    function createRandomFighter (string memory _name) public {
        require(ownerFighterCount[msg.sender] == 0);
        _createFighter(_name);
    }

    function getFightersByOwner(address _owner) external view returns(uint[] memory){
        uint[] memory result = new uint[](ownerFighterCount[_owner]);
        uint counter = 0;
        for  (uint i = 0; i < fighters.length; i++){
            if(fighterToOwner[i] == _owner){
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }


}