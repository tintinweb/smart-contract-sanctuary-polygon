//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Privileges.sol";

contract UserListPrivileges is Privileges {

    struct Info{
        bool listed;
        uint256 mintCount;
    }

    mapping(address => Info) addresses;

    constructor(uint256 _price, address[] memory _addresses, uint256 _limitPerWallet, uint256 _allowedLimit ,uint _startTime, uint _endTime) Privileges(_price, _limitPerWallet, _allowedLimit, _startTime, _endTime){
        for(uint32 i = 0; i < _addresses.length; i++){
            addresses[_addresses[i]] = Info(true, 0);
        }
    }

    function updateLimit(address userAddress, uint256 minted) external override {
        uint256 previous = addresses[userAddress].mintCount; 
        addresses[userAddress].mintCount = previous + minted;
        totalMinted = totalMinted + minted;
    }

    function isUserEligible(address userAddress) external override view returns(bool){
        return addresses[userAddress].listed;
    }

    function userLimit(address userAddress) external override view returns(uint256){
        return limitPerWallet - addresses[userAddress].mintCount;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IPrivileges.sol";

abstract contract Privileges is IPrivileges {

    uint256 internal price;
    uint internal startTime;
    uint internal endTime;
    uint256 internal limitPerWallet;
    uint256 private allowedLimit;
    uint256 internal totalMinted;

    constructor(uint256 _price, uint256 _limitPerWallet, uint256 _allowedLimit, uint _startTime, uint _endTime){
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        limitPerWallet = _limitPerWallet;
        allowedLimit = _allowedLimit;
    }

    function availableLimit() external view returns(uint256){
        return allowedLimit - totalMinted;
    }

    function getPrice() external view override returns(uint256){
        return price;
    }

    function hasSaleStarted() external view returns(bool){
        return block.timestamp >= startTime;
    }

    function hasSaleEnded() external view returns(bool){
        return block.timestamp >= endTime;
    }

    function updateLimit(address userAddress, uint256 minted) external virtual;

    function userLimit(address userAddress) external virtual view returns(uint256);

    function isUserEligible(address userAddress) external virtual view returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IPrivileges {
    function getPrice() external view returns(uint256);

    function hasSaleStarted() external view returns(bool);

    function hasSaleEnded() external view returns(bool);

    function updateLimit(address userAddress, uint256 minted) external;

    function userLimit(address userAddress) external view returns(uint256);

    function availableLimit() external view returns(uint256);

    function isUserEligible(address userAddress) external view returns(bool);
}