/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract VotingMESH {
    // ======== ERC20 ========
    event Transfer(address indexed from, address indexed to, uint amount);
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;
    mapping(address => uint) public balanceOf;

    address public governance;
    address payable public implementation;

    // ======== Staking ========
    mapping(address => uint) public lockedMESH;
    mapping(address => uint) public unlockTime;
    mapping(address => uint) public lockPeriod;

    mapping(address => uint) public snapShotCount;
    mapping(address => mapping(uint => uint)) public snapShotBlock;
    mapping(address => mapping(uint => uint)) public snapShotBalance;

    // ======== Mining ========
    uint public mining;
    uint public lastMined;
    uint public miningIndex;
    mapping(address => uint) public userLastIndex;
    mapping(address => uint) public userRewardSum;

    bool public entered = false;
    
    address public policyAdmin;
    bool public paused = false;
    
    constructor(string memory _name, string memory _symbol, address payable _implementation, address _governance) public {
        name = _name;
        symbol = _symbol;
        implementation = _implementation;
        governance = _governance;
        policyAdmin = msg.sender;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == governance);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}