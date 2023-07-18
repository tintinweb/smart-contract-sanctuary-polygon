// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/FreeClaimFactory.sol";
import "../@openzeppelin/contracts/proxy/Clones.sol";

contract $FreeClaimFactory is FreeClaimFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _setting, address _verifier, address _osbFreeClaimLib) FreeClaimFactory(_setting, _verifier, _osbFreeClaimLib) {}

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSBFreeClaim.sol";

abstract contract $IOSBFreeClaim is IOSBFreeClaim {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/ISetting.sol";

abstract contract $ISetting is ISetting {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ISetting.sol";
import "./interfaces/IOSBFreeClaim.sol";

contract FreeClaimFactory is Context {
    ISetting public setting;

    address public verifier;
    address public osbFreeClaimLib;

    mapping(uint256 => address) public contracts;

    using Counters for Counters.Counter;
    Counters.Counter public lastId;

    // ============ ERRORS ============
    error AddressIsZero();
    error InvalidExpTime();

    // ============ EVENTS ============

    /// @dev Emit an event when the contract is deployed.
    event ContractDeployed(address indexed setting, address indexed verifier, address indexed osbFreeClaimLib);

    /// @dev Emit an event when setVerifier success.
    event SetVerifier(address indexed oldVerifier, address indexed newVerifier);

    /// @dev Emit an event when the OSBFreeClaim is created.
    event CreateOSBFreeClaim(
        uint256 indexed id,
        address indexed owner,
        address indexed tokenDistribution,
        address contractDeployed,
        uint256 expTime
    );

    /// @dev Emit an event when the osbFreeClaimLib is updated.
    event SetOSBFreeClaimLib(address indexed oldLib, address indexed newLib);

    /**
     * @notice Setting states initial when deploy contract and only called once.
     * @param _setting The address of the Setting contract.
     * @param _verifier The address responsible for signing the signature for the claimer.
     * @param _osbFreeClaimLib The OSBFreeClaim address has been deployed.
     */
    constructor(address _setting, address _verifier, address _osbFreeClaimLib) {
        setting = ISetting(_setting);
        verifier = _verifier;
        osbFreeClaimLib = _osbFreeClaimLib;
        emit ContractDeployed(_setting, _verifier, _osbFreeClaimLib);
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier onlySuperAdmin() {
        setting.checkOnlySuperAdmin(_msgSender());
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS =============

    /**
     * @notice Update the new verifier address.
     * @param _newVerifier Verifier address.
     */
    function setVerifier(address _newVerifier) external onlySuperAdmin {
        if (_newVerifier == address(0)) revert AddressIsZero();
        address oldVerifier = verifier;
        verifier = _newVerifier;
        emit SetVerifier(oldVerifier, _newVerifier);
    }

    /**
     * @notice Update the new OSBFreeClaim library address.
     * @param _newLib Library address.
     */
    function setOSBFreeClaimLib(address _newLib) external onlySuperAdmin {
        if (_newLib == address(0)) revert AddressIsZero();
        address oldLib = osbFreeClaimLib;
        osbFreeClaimLib = _newLib;
        emit SetOSBFreeClaimLib(oldLib, _newLib);
    }

    // ============ PUBLIC FUNCTIONS FOR CREATING =============

    /**
     * @notice Creates a new contract OSBFreeClaim.
     * @param _token The address of the token contract.
     * @param _expTime From this timestamp onwards, the user will not be allowed to claim.
     * If left as 0, it represents an unlimited maximum _expTime.
     */
    function createOSBFreeClaim(address _token, uint256 _expTime) external {
        if (_token == address(0)) revert AddressIsZero();
        if (_expTime > 0 && _expTime <= block.timestamp) revert InvalidExpTime();
        lastId.increment();

        //Clone new contract.
        bytes32 salt = keccak256(abi.encodePacked(lastId.current()));
        address deployedContract = Clones.cloneDeterministic(osbFreeClaimLib, salt);
        IOSBFreeClaim(deployedContract).initialize(_msgSender(), _token, _expTime);

        //Update storage
        contracts[lastId.current()] = deployedContract;

        emit CreateOSBFreeClaim(lastId.current(), _msgSender(), _token, deployedContract, _expTime);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBFreeClaim {
    function initialize(address _owner, address _token, uint256 _expTime) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISetting {
    function checkOnlySuperAdmin(address _caller) external view;

    function checkOnlyAdmin(address _caller) external view;

    function checkOnlySuperAdminOrController(address _caller) external view;

    function checkOnlyController(address _caller) external view;

    function isAdmin(address _account) external view returns (bool);

    function isSuperAdmin(address _account) external view returns (bool);

    function getSuperAdmin() external view returns (address);
}

error CallerIsNotTheSuperAdmin();
error CallerIsNotTheAdmin();