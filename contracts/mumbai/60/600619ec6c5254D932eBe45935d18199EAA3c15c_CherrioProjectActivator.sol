// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

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
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//interface ERC20 {
//    function approve(address spender, uint value) external returns (bool);
//    function transfer(address to, uint value) external returns (bool);
//    function transferFrom(address from, address to, uint value) external returns (bool);
//}

contract CherrioProjectActivator is Owner {
//    IERC20 token;
    uint256 public pool;

    struct Project {
        Stages stage;
        bool flag;
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
    mapping(address => address payable[]) public activators;

    modifier isProject(address _address) {
        require(projects[_address].flag);
        _;
    }

    event Activate(address project, address activator, uint256 amount);

    constructor() {
//        token = IERC20(0xC4Ee5dD245972F842DC76fCF5FccbCf4a6DB32ee);
    }

    function addProject(address _address, uint256 _activateSize, Stages _stage) external isOwner {
        require(!projects[_address].flag);

        projects[_address].flag = true;
        projects[_address].stage = _stage;
        projects[_address].activateSize = _activateSize;
        projects[_address].activatedAmount = 0;
    }

    function activateProject(address _address) external isOwner {
        require(projects[_address].flag);

        ICherrioProject(_address).activate();
    }

    function activate(address _address) public payable {
        require(projects[_address].flag);
        require(projects[_address].stage == Stages.Active);

        projects[_address].activators[msg.sender] += msg.value;
        projects[_address].activatedAmount += msg.value;

        if (projects[_address].activatedAmount >= projects[_address].activateSize) {
            projects[_address].stage = Stages.Ended;

            ICherrioProject(_address).activate();
        }

        activators[_address].push(payable(msg.sender));
        emit Activate(_address, msg.sender, msg.value);
    }

    function getProjectInfo(address _address) external view returns(Stages _stage, uint256 _activateSize, uint256 _activatedAmount) {
        require(projects[_address].flag);

        Project storage project = projects[_address];

        return (project.stage, project.activateSize, project.activatedAmount);
    }

    function getActivatedAmount(address _address, address _activator) external view returns(uint256 activatedAmount) {
        require(projects[_address].flag);

        Project storage project = projects[_address];

        return project.activators[_activator];
    }

    function refundToActivatorsManually(address _address) external isOwner {
        Project storage project = projects[_address];

        uint256 numOfActivators = activators[_address].length;
        for(uint256 i = 0; i < numOfActivators; i++) {
            activators[_address][i].transfer(project.activators[activators[_address][i]]);
        }
    }

    function refundToActivators() external isProject(msg.sender) {
        Project storage project = projects[msg.sender];

        uint256 numOfActivators = activators[msg.sender].length;
        for(uint256 i = 0; i < numOfActivators; i++) {
            activators[msg.sender][i].transfer(project.activators[activators[msg.sender][i]]);
        }
    }

    function sendReward(address _receiver, uint256 _amount) external {
        ICherrioToken(0xC4Ee5dD245972F842DC76fCF5FccbCf4a6DB32ee).transfer(_receiver, _amount);
    }

    function sendReward1(address _receiver, uint256 _amount) external {
        ICherrioToken(payable(0xC4Ee5dD245972F842DC76fCF5FccbCf4a6DB32ee)).transfer(_receiver, _amount);
    }

    function sendReward2(address _receiver, uint256 _amount) external {
//        token.transfer(_receiver, _amount);
    }
}