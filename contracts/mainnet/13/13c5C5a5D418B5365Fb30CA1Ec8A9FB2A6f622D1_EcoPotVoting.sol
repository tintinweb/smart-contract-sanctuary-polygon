/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract EcoPotVoting {
    uint public constant MAX_VOTING_POT_COUNT = 10;

    mapping(uint => address) public ecoPotList;
    mapping(address => bool) public ecoPotExist;

    mapping(address => mapping(uint => address)) public userVotingPotAddress;
    mapping(address => mapping(uint => uint)) public userVotingPotAmount;
    mapping(address => uint) public userVotingPotCount;
    mapping(address => uint) public potTotalVotedAmount;

    uint public ecoPotCount;

    address public governance;
    address payable public implementation;
    address payable public ecoPotImplementation;

    address public owner;
    address public nextOwner;

    bool public entered = false;
    address public policyAdmin;

    mapping(address => address) operatorToEcoPot; 

    constructor(address _owner, address payable _implementation, address payable _ecoPotImpl, address _governance) public {
        owner = _owner;
        implementation = _implementation;
        ecoPotImplementation = _ecoPotImpl;
        governance = _governance;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setEcoPotImplementation(address payable _newEcoPotImpl) public {
        require(msg.sender == owner);
        require(ecoPotImplementation != _newEcoPotImpl);
        
        ecoPotImplementation = _newEcoPotImpl;
    }

    function getEcoPotImplementation() public view returns (address) {
        return ecoPotImplementation;
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