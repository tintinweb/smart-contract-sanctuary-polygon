/**
 *Submitted for verification at polygonscan.com on 2022-07-08
*/

// File: contracts/Factory.sol

/**
 *Submitted for verification at polygonscan.com on 2022-05-25
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract Factory {
    // ======== Construction & Init ========
    address public owner;
    address public nextOwner;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public ERC20;
    address public router;
    address public USDC;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    mapping(address => mapping(address => address)) public tokenToPool;

    // ======== Administration ========

    uint public createFee;
    bool public entered;

    constructor(
        address payable _implementation, 
        address payable _exchangeImplementation, 
        address payable _USDC, 
        address payable _ERC20
    ) public {
        owner = msg.sender;
        implementation = _implementation;
        USDC = _USDC;
        exchangeImplementation = _exchangeImplementation;

        ERC20 = _ERC20;
    }
    
    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setExchangeImplementation(address payable _newExImp) public {
        require(msg.sender == owner);
        require(exchangeImplementation != _newExImp);
        exchangeImplementation = _newExImp;
    }

    function getExchangeImplementation() public view returns (address) {
        return exchangeImplementation;
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