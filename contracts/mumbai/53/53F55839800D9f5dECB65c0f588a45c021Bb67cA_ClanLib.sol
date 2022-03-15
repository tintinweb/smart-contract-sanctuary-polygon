// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library ClanLib {

    function c1Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusDmg) {
        uint256 _c1Count;
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 9 && _ownerTokens[i] < 1009) || _ownerTokens[i] == 1) {
                _c1Count += 1;
            }
        }
        //Every 3 owned of the same clan gives 5 bonus dmg
        uint256 _bonus = _c1Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus *5;
    }

    function c2Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusAgi) {
        uint256 _c2Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 1008 && _ownerTokens[i] < 2007) || _ownerTokens[i] == 2) {
               _c2Count++; 
           }
        }
        //Every 3 owned of the same clan gives 10 bonus agi to cooldown
        uint256 _bonus = _c2Count / 3;
        if(_bonus > 40) _bonus = 40; //bonus limit
        return _bonus * 10;
    }

    
    function c3Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusDex) {
        uint256 _c3Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 2006 && _ownerTokens[i] < 3006) || _ownerTokens[i] == 3) {
               _c3Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus dex
        uint256 _bonus = _c3Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }

    function c4Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusLuck) {
        uint256 _c4Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 3005 && _ownerTokens[i] < 4005) || _ownerTokens[i] == 4) {
               _c4Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus luck
        uint256 _bonus = _c4Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }
    
    function c5Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusInt) {
        uint256 _c5Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 4004 && _ownerTokens[i] < 5004) || _ownerTokens[i] == 5) {
               _c5Count++; 
           }
        }
        //Every 3 owned of the same clan gives 5 bonus intelligence
        uint256 _bonus = _c5Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }

    function c6Bonus(uint256[] memory _ownerTokens) public pure returns(int256 bonusDef) {
        int256 _c6Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 5003 && _ownerTokens[i] < 6003) || _ownerTokens[i] == 6) {
               _c6Count++; 
           }
        }
        //Every 3 owned of the same clan reduces dmg by 5
        int256 _bonus = _c6Count / 3;
        if(_bonus > 20) _bonus = 20; //bonus limit
        return _bonus * 5;
    }
    
    function c7Bonus(uint256[] memory _ownerTokens) public pure returns(int256 reduceHp) {
        int256 _c7Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 6002 && _ownerTokens[i] < 7002) || _ownerTokens[i] == 7) {
               _c7Count++; 
           }
        }
        //Every 3 owned of the same clan reduces the amount of hp of the enemy
        int256 _bonus = _c7Count / 3;
        if(_bonus > 60) _bonus = 60; //bonus limit
        return _bonus * 15;
    }

    function c8Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusBei) {
        uint256 _c8Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 7001 && _ownerTokens[i] < 8001) || _ownerTokens[i] == 8) {
               _c8Count++; 
           }
        }
        //Every 3 owned of the same clan grants 10 more Token per day when staking
        uint256 _bonus = _c8Count / 3;
        if(_bonus > 40) _bonus = 40; //bonus limit
        return _bonus * 10;
    }

    function c9Bonus(uint256[] memory _ownerTokens) public pure returns(uint256 bonusExp) {
        uint256 _c9Count; 
        for(uint256 i; i<_ownerTokens.length;i++) {
            if((_ownerTokens[i] > 8000 && _ownerTokens[i] < 9001) || _ownerTokens[i] == 9) {
               _c9Count++; 
           }
        }
        //Every 3 owned of the same clan increases exp per Attack
        uint256 _bonus = _c9Count / 3;
        if(_bonus > 400) _bonus = 400; //bonus limit
        return _bonus * 100;
    }
 
}