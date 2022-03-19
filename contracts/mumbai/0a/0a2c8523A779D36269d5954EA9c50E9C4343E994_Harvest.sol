pragma solidity ^0.8.12;

import "./mocks/interfaces/IxLLTH.sol";

contract Harvest {
    IxLLTH public llth;
    uint256 public currentHarvestFee;

    mapping(address => bool) public isStakable;
    mapping(address => bool) public paidFee;

    constructor(IxLLTH _llth) {
        llth = _llth;
    }

    function payFee() public payable {
        require(msg.value >= currentHarvestFee, "Harvest.payFee: Fee not paid");
        paidFee[msg.sender] = true;
    }

    function harvest(
        address _collection,
        uint256 _rewards,
        address _user
    ) public {

        require(
            isStakable[_collection],
            "Harvest.harvest: collection isn't stakable"
        );

        require(paidFee[_user], "Harvest.harvest: fee not paid");

        llth.mint(_user, _rewards * (10**18));

        paidFee[_user] = false;
    }

    function setCollection(
        address _collection,
        bool _isStakable
    ) public {
        isStakable[_collection] = _isStakable;
    }
}

pragma solidity ^0.8.11;

interface IxLLTH {
    function mint(address user, uint256 amount) external;
}