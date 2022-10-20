// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
    address private owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface ICherrioProject {
    function activate() external;
}

interface ICherrioToken {
    function transfer(address to, uint value) external returns (bool);
}

contract CherrioProjectActivator is Owner {
    ICherrioToken public token;
    uint256 public pool;
    uint256 public reward = 150; // 1.5%

    struct Project {
        Stages stage;
        bool flag;
        bool rewarded;
        uint256 activateSize;
        uint256 activatedAmount;
        mapping(address => uint256) activators;
    }

    enum Stages {
        Pending,
        Active,
        Ended
    }

    mapping(address => Project) public projects;
    mapping(address => address[]) public activators;

    modifier isProject(address _address) {
        require(projects[_address].flag);
        _;
    }

    event ActivateProject(address indexed project, address activator, uint256 amount);
    event NewProject(address indexed project, uint256 activateSize, Stages stage);

    constructor() {
        token = ICherrioToken(0xC4Ee5dD245972F842DC76fCF5FccbCf4a6DB32ee);
    }

    function newProject(address _address, uint256 _activateSize, Stages _stage) external isOwner {
        require(!projects[_address].flag);

        projects[_address].flag = true;
        projects[_address].rewarded = false;
        projects[_address].stage = _stage;
        projects[_address].activateSize = _activateSize;
        projects[_address].activatedAmount = 0;

        emit NewProject(_address, _activateSize, _stage);
    }

    function activateProject(address _address) public payable isProject(_address) {
        require(projects[_address].stage == Stages.Active);

        if (projects[_address].activators[msg.sender] == 0) {
            activators[_address].push(msg.sender);
        }

        projects[_address].activators[msg.sender] += msg.value;
        projects[_address].activatedAmount += msg.value;

        if (projects[_address].activatedAmount >= projects[_address].activateSize) {
            projects[_address].stage = Stages.Ended;

            ICherrioProject(_address).activate();
        }

        emit ActivateProject(_address, msg.sender, msg.value);
    }

    function getProject(address _address) external view isProject(_address) returns(Stages _stage, uint256 _activateSize, uint256 _activatedAmount) {
        Project storage project = projects[_address];

        return (project.stage, project.activateSize, project.activatedAmount);
    }

    function getActivatedAmount(address _address, address _activator) external view isProject(_address) returns(uint256 activatedAmount) {
        return projects[_address].activators[_activator];
    }

    function sendRewardManually(address _address) external isOwner isProject(_address) {
        _sendRefundAndReward(_address);
    }

    function sendReward() external isProject(msg.sender) {
        _sendRefundAndReward(msg.sender);
    }

    function _sendRefundAndReward(address _address) internal {
        Project storage project = projects[_address];
        uint256 numOfActivators = activators[_address].length;

        require(!project.rewarded && numOfActivators > 0);

        for(uint256 i = 0; i < numOfActivators; i++) {
            payable(activators[_address][i]).transfer(project.activators[activators[_address][i]]);
            token.transfer(activators[_address][i], ((project.activators[activators[_address][i]])*reward/100)/100);
        }

        project.rewarded = true;
    }
}