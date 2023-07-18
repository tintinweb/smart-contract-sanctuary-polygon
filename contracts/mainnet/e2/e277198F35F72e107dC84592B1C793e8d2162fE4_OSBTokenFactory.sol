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

import "../../contracts/interfaces/IOSBLimitedToken.sol";

abstract contract $IOSBLimitedToken is IOSBLimitedToken {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSBTokenFactory.sol";

contract $IOSBTokenFactory is IOSBTokenFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IOSBUnlimitedToken.sol";

abstract contract $IOSBUnlimitedToken is IOSBUnlimitedToken {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/OSBTokenFactory.sol";
import "../@openzeppelin/contracts/proxy/Clones.sol";

contract $OSBTokenFactory is OSBTokenFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _setting, address _osbLimitedTokenLib, address _osbUnlimitedTokenLib) OSBTokenFactory(_setting, _osbLimitedTokenLib, _osbUnlimitedTokenLib) {}

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBLimitedToken {
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _issueAmount,
        uint256 _maxTotalSupply
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBTokenFactory {}

struct ContractInfo {
    uint256 id;
    bool isLimited;
    address owner;
    address token;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IOSBUnlimitedToken {
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _issueAmount
    ) external;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ISetting.sol";
import "./interfaces/IOSBTokenFactory.sol";
import "./interfaces/IOSBLimitedToken.sol";
import "./interfaces/IOSBUnlimitedToken.sol";

contract OSBTokenFactory is IOSBTokenFactory, Context {
    ISetting public setting;

    address public osbLimitedTokenLib;
    address public osbUnlimitedTokenLib;

    using Counters for Counters.Counter;
    Counters.Counter public lastId;

    /// @dev Keep track of contract info from created ID.
    mapping(uint256 => ContractInfo) public contractInfos;

    // ============ ERRORS ============
    error AddressIsZero();

    // ============ EVENTS ============
    /// @dev Emit an event when the contract is deployed.
    event ContractDeployed(
        address indexed setting,
        address indexed osbLimitedTokenLib,
        address indexed osbUnlimitedTokenLib
    );

    /// @dev Emit an event when the osbLimitedTokenLib is updated.
    event SetOSBLimitedTokenLib(address indexed oldAddress, address indexed newAddress);

    /// @dev Emit an event when the osbUnlimitedTokenLib is updated.
    event SetOSBUnlimitedTokenLib(address indexed oldAddress, address indexed newAddress);

    /// @dev Emit an event when a contract created.
    event ContractCreated(uint256 indexed id, bool isLimited, address indexed owner, address indexed deployedContract);

    /**
     * @notice Setting states initial when deploy contract and only called once.
     * @param _setting Setting contract address.
     * @param _osbLimitedTokenLib OSBLimitedToken library address.
     * @param _osbUnlimitedTokenLib OSBUnlimitedToken library address.
     */
    constructor(address _setting, address _osbLimitedTokenLib, address _osbUnlimitedTokenLib) {
        setting = ISetting(_setting);
        osbLimitedTokenLib = _osbLimitedTokenLib;
        osbUnlimitedTokenLib = _osbUnlimitedTokenLib;
        emit ContractDeployed(_setting, _osbLimitedTokenLib, _osbUnlimitedTokenLib);
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============
    modifier onlySuperAdmin() {
        setting.checkOnlySuperAdmin(_msgSender());
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS =============
    /**
     * @notice Update the new OSBLimitedToken library address.
     * @param _library Library address.
     */
    function setOSBLimitedToken(address _library) external onlySuperAdmin {
        if (_library == address(0)) revert AddressIsZero();
        address oldAddress = osbLimitedTokenLib;
        osbLimitedTokenLib = _library;
        emit SetOSBLimitedTokenLib(oldAddress, _library);
    }

    /**
     * @notice Update the new OSBUnlimitedToken library address.
     * @param _library Library address.
     */
    function setOSBUnlimitedToken(address _library) external onlySuperAdmin {
        if (_library == address(0)) revert AddressIsZero();
        address oldAddress = osbUnlimitedTokenLib;
        osbUnlimitedTokenLib = _library;
        emit SetOSBUnlimitedTokenLib(oldAddress, _library);
    }

    // ============ EXTERNAL FUNCTIONS FOR CREATING AND MINT =============
    /**
     * @dev Creates a new ERC20 token contract and initializes it with the specified parameters.
     * @param _owner The owner of the contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _decimals The number of decimals used to get its user representation.
     * @param _issueAmount The initial amount of tokens to be issued.
     * @param _maxTotalSupply The maximum total supply of tokens.
     * @return deployedContract The address of the deployed token contract.
     */
    function createOSBLimitedToken(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _issueAmount,
        uint256 _maxTotalSupply
    ) public returns (address deployedContract) {
        deployedContract = _createContract(true, _owner);
        IOSBLimitedToken(deployedContract).initialize(_owner, _name, _symbol, _decimals, _issueAmount, _maxTotalSupply);
    }

    /**
     * @dev Creates a new ERC20 token contract and initializes it with the specified parameters.
     * @param _owner The owner of the contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _decimals The number of decimals used to get its user representation.
     * @param _issueAmount The initial amount of tokens to be issued.
     * @return deployedContract The address of the deployed token contract.
     */
    function createOSBUnlimitedToken(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _issueAmount
    ) public returns (address deployedContract) {
        deployedContract = _createContract(false, _owner);
        IOSBUnlimitedToken(deployedContract).initialize(_owner, _name, _symbol, _decimals, _issueAmount);
    }

    // ============ PRIVATE FUNCTIONS =============
    function _createContract(bool _isLimited, address _owner) private returns (address deployedContract) {
        lastId.increment();
        uint256 currentId = lastId.current();
        bytes32 salt = keccak256(abi.encodePacked(currentId));
        address lib = _isLimited ? osbLimitedTokenLib : osbUnlimitedTokenLib;

        deployedContract = Clones.cloneDeterministic(lib, salt);
        contractInfos[currentId] = ContractInfo({
            id: currentId,
            isLimited: _isLimited,
            owner: _owner,
            token: deployedContract
        });

        emit ContractCreated(currentId, _isLimited, _owner, deployedContract);
    }
}