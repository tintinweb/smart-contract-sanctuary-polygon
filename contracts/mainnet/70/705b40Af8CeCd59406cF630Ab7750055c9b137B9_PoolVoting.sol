/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract PoolVoting {
    uint public constant MAX_VOTING_POOL_COUNT = 10;

    mapping(address => mapping(uint => address)) public userVotingPoolAddress;
    mapping(address => mapping(uint => uint)) public userVotingPoolAmount;
    mapping(address => uint) public userVotingPoolCount;

    mapping(address => uint) public poolAmount;
    mapping(uint => address) public poolRanking;
    uint public poolCount = 0;

    mapping(address => uint) public marketIndex0;
    mapping(address => uint) public marketIndex1;
    mapping(address => mapping(address => uint)) public userLastIndex0;
    mapping(address => mapping(address => uint)) public userLastIndex1;
    mapping(address => mapping(address => uint)) public userRewardSum0;
    mapping(address => mapping(address => uint)) public userRewardSum1;

    address public validPoolOperator;

    uint public totalVotingAmount;
    mapping (uint => mapping (address => uint)) public prevPoolAmount;

    mapping (address => bool) public poolRankingExist;
    mapping (uint => uint) public prevTotalAmount;

    mapping (address => bool) public isValidToken;
    mapping (address => bool) public isBoostingToken;

    uint public boostingPowerMESH_A;
    uint public boostingPowerA_A;
    uint public boostingPowerMESH_B;
    uint public boostingPowerA_B;

    mapping (address => uint) public boostingAmount;
    mapping (uint => mapping (address => uint)) public prevBoostingAmount;
    mapping (address => mapping (uint => mapping (address => bool))) public epochVoted;
    
    bool public entered = false;

    address public governance;
    address payable public implementation;

    constructor(address payable _implementation, address _governance) public {
        implementation = _implementation;
        governance = _governance;
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