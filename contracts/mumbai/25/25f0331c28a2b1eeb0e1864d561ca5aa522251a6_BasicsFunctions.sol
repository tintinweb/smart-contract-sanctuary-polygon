/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

contract BasicsFunctions{
    string coinName = "MY COIN";
    uint public myBalance = 1000;

    struct Coin{ 
        string name;
        string symbol;
        uint supply;                                                                                    
    }

    mapping(address => Coin) internal myCoins;

    function guessNumber(uint _guess) public pure returns (bool){
        if(_guess == 4){
            return true;
        }
        else{
            return false;
        }
    }

    function getCoinName() public view returns (string memory){
        return coinName;
    }

    function multiply(uint _factor) external {
        myBalance *= _factor;
    }

    function findCoinIndex(string[] memory _myCoins, string memory _find, uint _startFrom) public pure returns (uint) {
        for(uint i = _startFrom; i < _myCoins.length; i++){
            string memory _myCoin = _myCoins[i];
            if(keccak256(abi.encodePacked(_myCoin)) == keccak256(abi.encodePacked(_find))){
                return i;
            }
        }
        return 99999;
    }

    function addCoin(string memory _name, string memory _symbol, uint _supply) external{
        myCoins[msg.sender] = Coin(_name, _symbol, _supply);
    }

    function getMyCoin() public view returns (Coin memory) {
        return myCoins[msg.sender];
    }
}