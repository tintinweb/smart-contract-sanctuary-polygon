// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IInitializable.sol";  

contract RoboFiFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    mapping(address => address) public masterContractOf; // Mapping from clone contracts to their masterContract

    // Deploys a given master Contract as a clone.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address) {
        require(masterContract != address(0), "Factory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        address cloneAddress; // Address where the clone contract will reside.

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;

        IInitializable(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);

        return cloneAddress;
    }
}

contract ERC20Factory {

    RoboFiFactory private factory;

    constructor (RoboFiFactory factory_) {
        factory = factory_;
    }

    function deploy(string memory name_, 
                    string memory symbol_, 
                    uint256 initAmount_,
                    address holder_,
                    address master_) public payable {
        bytes memory data = abi.encode(name_, symbol_, initAmount_, holder_);
        factory.deploy(master_, data, true);
        // *
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInitializable {
    function init(bytes calldata data) external payable;
}