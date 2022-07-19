// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Campaign.sol";

contract CampaignFactory {
    Campaign[] public deployedCampaign;
    uint256 public count;

    event CreateNewCampaign(uint256 aNumber, address bAddress);
    event Abc(uint256 length);

    function createCampaign(uint256 _a, address _b) public {
        Campaign campaign = new Campaign(_a, _b);
        deployedCampaign.push(campaign);
        emit CreateNewCampaign(_a, _b);
    }

    function abc() public returns(uint256) {
        count += 1;
        emit Abc(count);
        return count;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Campaign {
    uint256 public a;
    address public b;

    event MultipleCampaign(uint256 aNumber, uint256 kNumber, uint256 resNumber);

    constructor(uint256 _a, address _b){
        a = _a;
        b = _b;
    }

    function multiple(uint256 _k) public returns(uint256)  {
        uint256 res = a*_k;
        emit MultipleCampaign(a, _k, res);
        return res;
    }
}