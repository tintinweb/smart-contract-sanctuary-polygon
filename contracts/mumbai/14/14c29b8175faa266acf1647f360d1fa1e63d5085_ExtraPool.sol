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

// -----------------------------------------------------------------------------------------

    mapping(address => uint256) public userAllEarned;

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

    address polygonSb;

    constructor (address _polygonSb) {
        polygonSb = _polygonSb;
    }

    modifier onlyPolygonSb() {
        require(msg.sender == polygonSb, "only polygonSb can call this function");
        _;
    }

/// bayad check she
    function distribute() public onlyPolygonSb {
        uint256 count = extraRewardReceiversCount();
        if(count > 0) {
            uint256 _exPointValue = exPointValue();
            for(uint256 i; i < count; i++) {
                address userAddr = _extraRewardReceivers[erIndex][i];
                uint256 earning = _userExtraPoints[epIndex][userAddr] * _exPointValue;
                userAllEarned[userAddr] += earning;
                payable(userAddr).transfer(earning);
            }
        } else {
        }
        delete extraPointCount;
        _resetExtraPoints();
        _resetExtraRewardReceivers();
    }

    function addAddr(address userAddr) public onlyPolygonSb {
        if(_userExtraPoints[epIndex][userAddr] == 0) {
            _extraRewardReceivers[erIndex].push(userAddr);
        }
        extraPointCount ++;
        _userExtraPoints[epIndex][userAddr] ++;
    }
}