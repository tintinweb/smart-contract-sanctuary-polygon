/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

pragma solidity 0.5.6;

interface ImplGetter {
    function _setImplementation(address payable) external;
    function _setExchangeImplementation(address payable) external;
}

contract Governance {
    address public owner;
    address public nextOwner;
    address public implAdmin;
    address public executor;
    address public teamAdmin;

    address public factory;
    address public mesh;
    address public votingMESH;
    address public poolVoting;
    address public treasury;
    address public buyback;
    address public governor;
    address public ecoPotVoting;
    address public singlePoolFactory;

    address payable public implementation; 
    uint public vMESHMiningRate = 0; 
    uint public feeShareRate = 0;

    bool public isInitialized = false;
    bool public entered = false;

    uint public transactionCount = 0;
    mapping (uint => bool) public transactionExecuted;
    mapping (uint => address) public transactionDestination;
    mapping (uint => uint) public transactionValue;
    mapping (uint => bytes) public transactionData;

    uint public interval;
    uint public nextTime;
    uint public prevTime;
    uint public epoch;
    mapping(uint => uint) public epochMined;
    mapping(address => uint) public lastEpoch;
    mapping(uint => mapping(address => uint)) public epochRates;

    uint public singlePoolMiningRate;

    uint public miningShareRate;
    uint public rateNumerator;

    constructor(address payable _implementation, address _owner, address _implAdmin, address _executor) public {
        implementation = _implementation;
        owner = _owner;
        implAdmin = _implAdmin;
        executor = _executor;
    }

    modifier onlyImplAdmin { // owner or implOwner or onlyWallet
        require(msg.sender == owner
                || msg.sender == implAdmin
                || msg.sender == address(this));
        _;
    }

    function _setImplementation(address payable _newImp) public onlyImplAdmin {
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setFactoryImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(factory)._setImplementation(_newImp);
    }

    function _setExchangeImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(factory)._setExchangeImplementation(_newImp);
    }

    function _setVotingMESHImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(votingMESH)._setImplementation(_newImp); 
    }

    function _setPoolVotingImplementation(address payable _newImp) public onlyImplAdmin {
        ImplGetter(poolVoting)._setImplementation(_newImp); 
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