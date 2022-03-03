//     ___                         __ 
//    /   |  _____________  ____  / /_
//   / /| | / ___/ ___/ _ \/ __ \/ __/
//  / ___ |(__  |__  )  __/ / / / /_  
// /_/  |_/____/____/\___/_/ /_/\__/  
// 
// 2022 - Assent Protocol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IAssentVIP.sol";

contract AssentVIP is IAssentVIP, Ownable {

    struct UserData {
        bool VIPlisted;                     // User is in the VIP list
        address user;                       // User address
        uint dexFeeReduction;               // User actual reduction on dex swap fees : in %
        uint aUSDMarketFeeReduction;        // User actual reduction on aUSD market fees (borrow interests) : in %
        uint farmsDepFeeReduction;          // User actual reduction on farms and pools deposit fees : in %
        uint bondsReduction;                // User actual reduction on bonds discount : in %
        uint dexFeeReduceUntil;             // User reduction fee on dex swap fees until this timestamp
        uint aUSDMarketFeeReduceUntil;      // User reduction on aUSD market fees (borrow interests) until this timestamp
        uint farmsDepFeeReduceUntil;        // User reduction on farms and pools deposit fees until this timestamp
        uint bondsReduceUntil;              // User reduction on bonds discount until this timestamp
        bool lifeTimeReduction;             // User have a lifetime reduction on everything
        bool NFTHold;                       // User hold at least 1 Assent protocol NFT
    }

    uint public constant DEFAUTFEEREDUCTION = 0.1 ether; // 10%
    uint public constant MAXFEEREDUCTION = 0.8 ether; // 80%
    uint public constant DEFAUTDURATION = 864000; // 10 days

    mapping(address => bool) public operators;
    mapping(address => UserData) public userData; // user datas

    address[] public userList;  // user list

    event UserAddedWithDefaultValue(address indexed user);
    event UserAddedWithAllValue(address indexed user,
                                uint dexFeeReduction,
                                uint aUSDMarketFeeReduction,
                                uint farmsDepFeeReduction,
                                uint bondsReduction,
                                uint dexFeeReducDuration,
                                uint aUSDMarketFeeReducDuration,
                                uint farmsDepFeeReducDuration,
                                uint bondsReducDuration,
                                bool lifeTimeReduction,
                                bool NFTHold);    

    event UserRemoved(address indexed user);
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function simpleVIPUser(address _user) public override onlyOperator {
        if (_user != address(0) && userData[_user].VIPlisted == false) {
            // first time add the user into the list
            // set datas with default value
            userData[_user].VIPlisted = true;
            userData[_user].user = _user;
            userData[_user].dexFeeReduction = DEFAUTFEEREDUCTION;
            userData[_user].aUSDMarketFeeReduction = DEFAUTFEEREDUCTION;
            userData[_user].farmsDepFeeReduction = DEFAUTFEEREDUCTION;
            userData[_user].bondsReduction = DEFAUTFEEREDUCTION;
            userData[_user].dexFeeReduceUntil = block.timestamp + DEFAUTDURATION;
            userData[_user].aUSDMarketFeeReduceUntil = block.timestamp + DEFAUTDURATION;
            userData[_user].farmsDepFeeReduceUntil = block.timestamp + DEFAUTDURATION;
            userData[_user].bondsReduceUntil = block.timestamp + DEFAUTDURATION;            
            userData[_user].lifeTimeReduction = false;
            userData[_user].NFTHold = false;
            addUserList(_user);

            emit UserAddedWithDefaultValue(_user);
        }
    }

    function fullVIPUser(address _user,
                            uint _dexFeeReduction,
                            uint _aUSDMarketFeeReduction,
                            uint _farmsDepFeeReduction,
                            uint _bondsReduction,
                            uint _dexFeeReducDuration,
                            uint _aUSDMarketFeeReducDuration,
                            uint _farmsDepFeeReducDuration,
                            uint _bondsReducDuration,
                            bool _lifeTimeReduction,
                            bool _NFTHold) public override onlyOperator {
        if (_user != address(0) && userData[_user].VIPlisted == false) {
            // first time add the user into the list
            // set datas with params value
            userData[_user].VIPlisted = true;
            userData[_user].user = _user;
            require (_dexFeeReduction <= MAXFEEREDUCTION 
                    && _aUSDMarketFeeReduction <= MAXFEEREDUCTION 
                    && _farmsDepFeeReduction <= MAXFEEREDUCTION
                    && _bondsReduction <= MAXFEEREDUCTION, "Fee too high");
            userData[_user].dexFeeReduction = _dexFeeReduction;
            userData[_user].aUSDMarketFeeReduction = _aUSDMarketFeeReduction;
            userData[_user].farmsDepFeeReduction = _farmsDepFeeReduction;
            userData[_user].bondsReduction = _bondsReduction;
            userData[_user].dexFeeReduceUntil = block.timestamp + _dexFeeReducDuration;
            userData[_user].aUSDMarketFeeReduceUntil = block.timestamp + _aUSDMarketFeeReducDuration;
            userData[_user].farmsDepFeeReduceUntil = block.timestamp + _farmsDepFeeReducDuration;
            userData[_user].bondsReduceUntil = block.timestamp + _bondsReducDuration;
            userData[_user].lifeTimeReduction = _lifeTimeReduction;
            userData[_user].NFTHold = _NFTHold;
            addUserList(_user);

            emit UserAddedWithAllValue(_user,
                                        _dexFeeReduction,
                                        _aUSDMarketFeeReduction,
                                        _farmsDepFeeReduction,
                                        _bondsReduction,
                                        _dexFeeReducDuration,
                                        _aUSDMarketFeeReducDuration,
                                        _farmsDepFeeReducDuration,
                                        _bondsReducDuration,
                                        _lifeTimeReduction,
                                        _NFTHold);
            
        }
    }  

    function updateVIPUser(address _user,
                            uint _dexFeeReduction,
                            uint _aUSDMarketFeeReduction,
                            uint _farmsDepFeeReduction,
                            uint _bondsReduction,
                            uint _dexFeeReducDuration,
                            uint _aUSDMarketFeeReducDuration,
                            uint _farmsDepFeeReducDuration,
                            uint _bondsReducDuration,
                            bool _lifeTimeReduction,
                            bool _NFTHold) public override onlyOperator {
        if (userData[_user].VIPlisted) {
            require (_dexFeeReduction <= MAXFEEREDUCTION 
                    && _aUSDMarketFeeReduction <= MAXFEEREDUCTION 
                    && _farmsDepFeeReduction <= MAXFEEREDUCTION
                    && _bondsReduction <= MAXFEEREDUCTION, "Fee too high");
            userData[_user].dexFeeReduction = _dexFeeReduction;
            userData[_user].aUSDMarketFeeReduction = _aUSDMarketFeeReduction;
            userData[_user].farmsDepFeeReduction = _farmsDepFeeReduction;
            userData[_user].bondsReduction = _bondsReduction;            
            if (_dexFeeReducDuration > 0){
                userData[_user].dexFeeReduceUntil = block.timestamp + _dexFeeReducDuration;
            }
            if (_aUSDMarketFeeReducDuration > 0){
                userData[_user].aUSDMarketFeeReduceUntil = block.timestamp + _aUSDMarketFeeReducDuration;
            }
            if (_farmsDepFeeReducDuration > 0){
                userData[_user].farmsDepFeeReduceUntil = block.timestamp + _farmsDepFeeReducDuration;
            }    
            if (_bondsReducDuration > 0){
                userData[_user].bondsReduceUntil = block.timestamp + _bondsReducDuration;
            }                        
            userData[_user].lifeTimeReduction = _lifeTimeReduction;
            userData[_user].NFTHold = _NFTHold;

            emit UserAddedWithAllValue(_user,
                                        _dexFeeReduction,
                                        _aUSDMarketFeeReduction,
                                        _farmsDepFeeReduction,
                                        _bondsReduction,
                                        _dexFeeReducDuration,
                                        _aUSDMarketFeeReducDuration,
                                        _farmsDepFeeReducDuration,
                                        _bondsReducDuration,
                                        _lifeTimeReduction,
                                        _NFTHold);
        }
    }      

    function removeVIPUser(address _user) public override onlyOperator {
        if (userData[_user].VIPlisted) {
            delete userData[_user];
            removeUserList(_user);

            emit UserRemoved(_user);
        }
    }

    function getUserDatas(address _user) view public 
        returns(bool VIPlisted,
                uint dexFeeReduction,
                uint aUSDMarketFeeReduction,
                uint farmsDepFeeReduction,
                uint bondsReduction,
                uint dexFeeReduceUntil,
                uint aUSDMarketFeeReduceUntil,
                uint farmsDepFeeReduceUntil,
                uint bondsReduceUntil,
                bool lifeTimeReduction,
                bool NFTHold) {
        if (userData[_user].VIPlisted) {
            VIPlisted = true;
            dexFeeReduction = userData[_user].dexFeeReduction;
            aUSDMarketFeeReduction = userData[_user].aUSDMarketFeeReduction;
            farmsDepFeeReduction = userData[_user].farmsDepFeeReduction;
            bondsReduction = userData[_user].bondsReduction;
            dexFeeReduceUntil = userData[_user].dexFeeReduceUntil;
            aUSDMarketFeeReduceUntil = userData[_user].aUSDMarketFeeReduceUntil;
            farmsDepFeeReduceUntil = userData[_user].farmsDepFeeReduceUntil;
            bondsReduceUntil = userData[_user].bondsReduceUntil;
            lifeTimeReduction = userData[_user].lifeTimeReduction;
            NFTHold = userData[_user].NFTHold;
        }
        return (VIPlisted,
                dexFeeReduction,
                aUSDMarketFeeReduction,
                farmsDepFeeReduction,
                bondsReduction,
                dexFeeReduceUntil,
                aUSDMarketFeeReduceUntil,
                farmsDepFeeReduceUntil,
                bondsReduceUntil,
                lifeTimeReduction,
                NFTHold);
    }

    function getDexFeeReduction(address _user) view public returns(uint reduction) {
        bool VIPlisted;
        uint dexFeeReduction;
        uint dexFeeReduceUntil;
        bool lifeTimeReduction;
        (VIPlisted,dexFeeReduction,,,,dexFeeReduceUntil,,,,lifeTimeReduction,) = getUserDatas(_user);
        if (VIPlisted && (block.timestamp < dexFeeReduceUntil || lifeTimeReduction)) {
            reduction = dexFeeReduction;
        }
        reduction = reduction >= MAXFEEREDUCTION ? MAXFEEREDUCTION : reduction;
        return reduction;
    }

    function getMarketFeeReduction(address _user) view public returns(uint reduction) {
        bool VIPlisted;
        uint marketFeeReduction;
        uint marketFeeReduceUntil;
        bool lifeTimeReduction;
        (VIPlisted,,marketFeeReduction,,,,marketFeeReduceUntil,,,lifeTimeReduction,) = getUserDatas(_user);
        if (VIPlisted && (block.timestamp < marketFeeReduceUntil || lifeTimeReduction)) {
            reduction = marketFeeReduction;
        }
        reduction = reduction >= MAXFEEREDUCTION ? MAXFEEREDUCTION : reduction;
        return reduction;
    }

    function getFarmsDepFeeReduction(address _user) view public returns(uint reduction) {
        bool VIPlisted;
        uint farmsDepFeeReduction;
        uint farmsDepFeeReduceUntil;
        bool lifeTimeReduction;
        (VIPlisted,,,farmsDepFeeReduction,,,,farmsDepFeeReduceUntil,,lifeTimeReduction,) = getUserDatas(_user);
        if (VIPlisted && (block.timestamp < farmsDepFeeReduceUntil || lifeTimeReduction)) {
            reduction = farmsDepFeeReduction;
        }
        reduction = reduction >= MAXFEEREDUCTION ? MAXFEEREDUCTION : reduction;
        return reduction;
    }   

    function getBondsReduction(address _user) view public returns(uint reduction) {
        bool VIPlisted;
        uint bondsReduction;
        uint bondsReduceUntil;
        bool lifeTimeReduction;
        (VIPlisted,,,,bondsReduction,,,,bondsReduceUntil,lifeTimeReduction,) = getUserDatas(_user);
        if (VIPlisted && (block.timestamp < bondsReduceUntil || lifeTimeReduction)) {
            reduction = bondsReduction;
        }
        reduction = reduction >= MAXFEEREDUCTION ? MAXFEEREDUCTION : reduction;
        return reduction;
    }      

    function addUserList(address _user) internal {
        bool isInList;
        (isInList,) = isInUserList(_user);
        if (!isInList) {
            userList.push(_user);
        }
    }

    function removeUserList(address _user) internal {
        bool isInList;
        uint position;
        (isInList,position) = isInUserList(_user);        
        if (isInList) {
            //replace last entry at position
            userList[position] = userList[userList.length - 1];
            //delete last entry
            userList.pop();
        }
    }

    function isInUserList(address _user) view public returns(bool isInList,uint position) {
        for (uint i = 0; i < userList.length; i++) {
            if (userList[i] == _user) {
                isInList = true;
                position = i;
                i = userList.length;
            }
        }
        return (isInList,position);
    }

    function getUserListCount() view public returns(uint count) {
        return userList.length;
    }

    function getUserListFromTo(uint _from, uint _to) view public
        returns (
            address[] memory addresses
        ) {
        addresses = new address[](_to - _from);
        uint j = 0;
        for (uint i = _from; i < _to    ; i++) {
            addresses[j] = userList[i];
            j++;
        }
    }

    function isVIP() pure public returns(bool result) {
        return true;
    }

    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function getbackTokens(address _receiver, address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_receiver, _amount);
    }  

}