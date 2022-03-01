pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./IGainAAVEIRS.sol";

contract iGainAAVEIRSFactory {
    address immutable template;

    address internal owner;

    address[] public terms;

    event NewTermCreated(address term);

    function getNumberOfIGains() external view returns (uint256) {
        return terms.length;
    }

    function newIGain() external returns (address igain) {
        igain = createClone(template);
        terms.push(igain);
        emit NewTermCreated(igain);
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    constructor(address _template) {
        template = address(_template);
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        require(newOwner != address(0));
        owner = newOwner;
    }

}