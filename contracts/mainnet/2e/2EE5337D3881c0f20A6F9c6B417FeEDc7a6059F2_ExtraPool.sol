// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./XDataStorage.sol";

contract ExtraPool is XDataStorage{

    address public repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyrePoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

    function distribute(uint256 MATIC_USD) public onlyrePoint {
        uint256 count = extraRewardReceiversCount();
        uint256 _balance = balance();
        if(count > 0) {
            uint256 balanceUSD = _balance * MATIC_USD/10**18;
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned_USD[userAddr] += earning * MATIC_USD/10**18;
                payable(userAddr).transfer(earning);
            }
            allPayments_USD += balanceUSD;
            allPayments_MATIC += _balance;
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyrePoint {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }

    receive() external payable{}

    function panicWithdraw() public onlyrePoint {
        payable(repoint).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract XDataStorage {
    
    uint256 erIndex;
    uint256 epIndex;

    mapping(uint256 => address[]) _extraRewardReceivers;
    mapping(uint256 => mapping(address => uint256)) _userExtraPoints;

    function _resetExtraPoints() internal {
        epIndex ++;
    }
    function _resetExtraRewardReceivers() internal {
        erIndex++;
    }

    function extraRewardReceivers() public view returns(address[] memory addr) {
        uint256 len = _extraRewardReceivers[erIndex].length;
        addr = new address[](len);

        for(uint256 i; i < len; i++) {
            addr[i] = _extraRewardReceivers[erIndex][i];
        }
    }

    function extraRewardReceiversCount() public view returns(uint256) {
        return _extraRewardReceivers[erIndex].length;
    }

    function userExtraPoints(address userAddr) public view returns(uint256) {
        return _userExtraPoints[epIndex][userAddr];
    }

    mapping(address => uint256) public _userAllEarned_USD;

    uint256 public allPayments_USD;
    uint256 public allPayments_MATIC;
    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        uint256 denom = extraPointCount;
        if(denom == 0) {denom = 1;}
        return balance() / denom;
    }
}