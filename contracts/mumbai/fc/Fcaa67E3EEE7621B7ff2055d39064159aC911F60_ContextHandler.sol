// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPolicy.sol";
contract ContextHandler {

    event ContextHandler_Request(address indexed _from, bool indexed _result, string _to, uint time);

    uint256 nonce = 29;

    mapping (string => address) public fileToPolicy;

    function evaluate (string memory filename, address userAddress) public view returns (bool) {
        // Check if file has any policy set
        address policyAddress = fileToPolicy[filename];

        if(policyAddress == address(0)) {
            return true;
        } else {
            bool result = IPolicy(policyAddress).evaluate(userAddress);
            return result;
        }
    }

    function callEvent(string memory filename, address userAddress, bool result) public {
        emit ContextHandler_Request(userAddress, result, filename, block.timestamp);
    }
    function setPolicy(string memory filename, address policyAddress) public {
        fileToPolicy[filename] = policyAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPolicy {
    function evaluate(address userAddress) external view returns (bool);
}