// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title NewTouchIdSafeAccountProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
/// @author modified by CandideWallet Team
contract BananaAccountProxy {
    // singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./BananaAccountProxy.sol";
import "./IProxyCreationCallback.sol";

/// @title Proxy Factory - Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
/// @author modified by CandideWallet Team
contract BananaAccountProxyFactory {
    event ProxyCreation(BananaAccountProxy proxy, address singleton);

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(BananaAccountProxy).creationCode;
    }

    /// @dev Allows to create a new proxy contract using CREATE2. Optionally executes an initializer call to a new proxy.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
    /// @param initializer Payload for a message call to be sent to a new proxy contract.
    /// @param salt Create2 salt to use for calculating the address of the new proxy contract.
    function deployProxy(address _singleton, bytes memory initializer, bytes32 salt) internal returns (BananaAccountProxy proxy) {
        require(isContract(_singleton), "Singleton contract not deployed");

        bytes memory deploymentData = abi.encodePacked(type(BananaAccountProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");

        if (initializer.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        }
    }

    /// @dev Allows to create a new proxy contract and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
    /// @param initializer Payload for a message call to be sent to a new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce) public returns (BananaAccountProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        proxy = deployProxy(_singleton, initializer, salt);
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create a new proxy contract that should exist only on 1 network (e.g. specific governance or admin accounts)
    ///      by including the chain id in the create2 salt. Such proxies cannot be created on other networks by replaying the transaction.
    /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
    /// @param initializer Payload for a message call to be sent to a new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createChainSpecificProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (BananaAccountProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce, getChainId()));
        proxy = deployProxy(_singleton, initializer, salt);
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create a new proxy contract, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract. Must be deployed at the time of execution.
    /// @param initializer Payload for a message call to be sent to a new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoked after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (BananaAccountProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev Returns true if `account` is a contract.
    /// @param account The address being queried
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

     function getBytecode(address _owner, uint _foo) public pure returns (bytes memory) {
        bytes memory bytecode = type(BananaAccountProxy).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_owner, _foo));
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(
        address _singleton,
        uint _salt,
        bytes memory initializer
    ) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), _salt));
        bytes memory bytecode = abi.encodePacked(type(BananaAccountProxy).creationCode, uint256(uint160(_singleton)));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./BananaAccountProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(BananaAccountProxy proxy, address _singleton, bytes calldata initializer, uint256 saltNonce) external;
}