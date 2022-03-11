pragma solidity ^0.8.12;

import "./mocks/interfaces/IxLLTH.sol";

contract Harvest {
    struct CollectionInfo {
        uint256 harvestCooldown;
        bool isStakable;
    }

    IxLLTH public llth;
    uint256 public currentHarvestFee;

    mapping(uint256 => CollectionInfo) public collectionInfo;
    mapping(address => bool) public paidFee;

    constructor(IxLLTH _llth) {
        llth = _llth;
    }

    function payFee() public payable {
        require(msg.value >= currentHarvestFee, "Harvest.payFee: Fee not paid");
        paidFee[msg.sender] = true;
    }

    function harvest(
        uint256 _cid,
        uint256 _stakingTimestamp,
        uint256 _rewards,
        address _user
    ) public {
        CollectionInfo storage collection = collectionInfo[_cid];

        require(
            collection.isStakable,
            "Harvest.harvest: collection isn't stakable"
        );

        require(
            ((block.timestamp - _stakingTimestamp) / 60 / 60 / 24) >
                collection.harvestCooldown,
            "Harvest.harvest: You are on cooldown"
        );

        require(paidFee[_user], "Harvest.harvest: fee not paid");

        llth.mint(_user, _rewards * (10**18));

        paidFee[_user] == false;
    }

    function setCollection(
        uint256 _cid,
        uint256 _harvestCooldown,
        bool _isStakable
    ) public {
        CollectionInfo storage collection = collectionInfo[_cid];
        collection.harvestCooldown = _harvestCooldown;
        collection.isStakable = _isStakable;
    }
}

pragma solidity ^0.8.11;

interface IxLLTH {
    function mint(address user, uint256 amount) external;
}