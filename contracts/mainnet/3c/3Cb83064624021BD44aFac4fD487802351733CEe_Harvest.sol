pragma solidity ^0.8.12;

import "./mocks/interfaces/IxLLTH.sol";

contract Harvest {
    IxLLTH public llth;
    uint256 public currentHarvestFee;

    mapping(address => bool) public isStakable;
    mapping(address => bool) public paidFee;
    mapping(address => bool) public managers;

    modifier onlyManager() {
        require(managers[msg.sender], "msg.sender isn't manager");
        _;
    }

    constructor(IxLLTH _llth) {
        llth = _llth;
        managers[msg.sender] = true;
    }    

    function payFee() public payable {
        require(msg.value >= currentHarvestFee, "Harvest.payFee: Fee not paid");
        paidFee[msg.sender] = true;
    }

    function harvest(
        address _collection,
        uint256 _rewards,
        address _user
    ) public onlyManager {
        require(
            isStakable[_collection],
            "Harvest.harvest: collection isn't stakable"
        );
        require(paidFee[_user], "Harvest.harvest: fee not paid");

        paidFee[_user] = false;

        llth.mint(_user, _rewards * (10**18));
    }

    function setCollection(address _collection, bool _isStakable)
        public
        onlyManager
    {
        isStakable[_collection] = _isStakable;
    }

    function setManager(address _manager, bool _value) public onlyManager {
        managers[_manager] = _value;
    }

    function setFee(uint256 _value) public onlyManager {
        currentHarvestFee = _value;
    }

    function setLlth(IxLLTH _newLlth) public onlyManager {
        llth = _newLlth;
    }
}

pragma solidity ^0.8.11;

interface IxLLTH {
    function mint(address user, uint256 amount) external;
}