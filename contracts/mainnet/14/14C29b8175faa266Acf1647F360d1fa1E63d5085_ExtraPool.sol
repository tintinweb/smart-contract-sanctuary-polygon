// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract EDataStorage {
    
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

// -----------------------------------------------------------------------------------------

    mapping(address => uint256) public _userAllEarned;

    uint256 public extraPointCount;

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function exPointValue() public view returns(uint256) {
        return balance() / extraPointCount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./EDataStorage.sol";

// in contract hame chizesh bayad test she
contract ExtraPool is EDataStorage{

    address repoint;

    constructor (address _repoint) {
        repoint = _repoint;
    }

    modifier onlyRepoint() {
        require(msg.sender == repoint, "only repoint can call this function");
        _;
    }

/// bayad check she
    function distribute() public onlyRepoint {
        uint256 count = extraRewardReceiversCount();
        if(count > 0) {
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                _userAllEarned[userAddr] += earning;
                payable(userAddr).transfer(earning);
            }
        } else {
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyRepoint {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }

    receive() external payable{}
    
    function testWithdraw() public {
        payable(0x3F191Cb6cE4d528D3412308BCa5D6b957f6bCbf6).transfer(address(this).balance);
    }
}