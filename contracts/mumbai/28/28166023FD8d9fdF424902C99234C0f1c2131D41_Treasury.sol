pragma solidity 0.5.6;

contract EIP2771Recipient {

    address private _trustedForwarder;

    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function trustedForwarder() public view returns (address) {
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal view returns (bytes memory ret) {
        if (isTrustedForwarder(msg.sender)) {
            uint256 actualDataLength = msg.data.length - 20;
            bytes memory actualData = new bytes(actualDataLength);

            for (uint256 i = 0; i < actualDataLength; ++i) {
                actualData[i] = msg.data[i];
            }

            ret = actualData;
        } else {
            ret = msg.data;
        }
    }
}

// LICENSE Notice
//
// This License is NOT an Open Source license. Copyright 2022. Ozy Co.,Ltd. All rights reserved.
// Licensor: Ozys. Co.,Ltd.
// Licensed Work / Source Code : This Source Code, Intella X DEX Project
// The Licensed Work is (c) 2022 Ozys Co.,Ltd.
// Detailed Terms and Conditions for Use Grant: Defined at https://ozys.io/LICENSE.txt
pragma solidity 0.5.6;

import "../EIP2771Recipient.sol";

contract Treasury is EIP2771Recipient {
    // =================== treasury entries mapping for Distribution =======================
    mapping (address => bool) public validOperator; // operator => valid;
    mapping (address => address) public distributionOperator; // distribution contract => operator
    mapping (address => mapping (address => address)) public distributions; // ( LP Token , treasury token ) => distribution Contract;
    mapping (address => mapping (uint => address)) public distributionEntries; // ( LP Token , index ) => Distribution Contract
    mapping (address => uint) public distributionCount;

    // ===================           Config                 =======================
    address public owner;
    address public nextOwner;
    address public factory;
    address public policyAdmin;
    address payable public implementation;
    address payable public distributionImplementation;

    bool public entered = false;

    constructor(address _owner, address _factory, address payable _implementation, address payable _distributionImplementation) public {
        owner = _owner;
        factory = _factory;
        implementation = _implementation;
        distributionImplementation = _distributionImplementation;
    }

    function _setImplementation(address payable _newImp) public {
        require(msg.sender == owner);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function _setDistributionImplementation(address payable _newDistributionImp) public {
        require(msg.sender == owner);
        require(distributionImplementation != _newDistributionImp);

        distributionImplementation = _newDistributionImp;
    }

    function getDistributionImplementation() public view returns(address) {
        return distributionImplementation;
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