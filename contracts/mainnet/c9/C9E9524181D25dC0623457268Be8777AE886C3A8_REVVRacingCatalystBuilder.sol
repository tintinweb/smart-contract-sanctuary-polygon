// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AccessControlBase} from "./base/AccessControlBase.sol";
import {ContractOwnership} from "./ContractOwnership.sol";

/// @title Access control via roles management (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract AccessControl is AccessControlBase, ContractOwnership {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ContractOwnershipStorage} from "./libraries/ContractOwnershipStorage.sol";
import {ContractOwnershipBase} from "./base/ContractOwnershipBase.sol";
import {InterfaceDetection} from "./../introspection/InterfaceDetection.sol";

/// @title ERC173 Contract Ownership Standard (immutable version).
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract ContractOwnership is ContractOwnershipBase, InterfaceDetection {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Initializes the storage with an initial contract owner.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner the initial contract owner.
    constructor(address initialOwner) {
        ContractOwnershipStorage.layout().constructorInit(initialOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AccessControlStorage} from "./../libraries/AccessControlStorage.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title Access control via roles management (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract AccessControlBase is Context {
    using AccessControlStorage for AccessControlStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Emitted when a role is granted.
    /// @param role the granted role.
    /// @param account the account granted with the role.
    /// @param operator the initiator of the grant.
    event RoleGranted(bytes32 role, address account, address operator);

    /// @notice Emitted when a role is revoked or renounced.
    /// @param role the revoked or renounced role.
    /// @param account the account losing the role.
    /// @param operator the initiator of the revocation, or identical to `account` for a renouncement.
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    function grantRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().grantRole(role, account, operator);
    }

    /// @notice Revokes a role from an account.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    function revokeRole(bytes32 role, address account) external {
        address operator = _msgSender();
        ContractOwnershipStorage.layout().enforceIsContractOwner(operator);
        AccessControlStorage.layout().revokeRole(role, account, operator);
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if the sender does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param role The role to renounce.
    function renounceRole(bytes32 role) external {
        AccessControlStorage.layout().renounceRole(_msgSender(), role);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(bytes32 role, address account) external view returns (bool) {
        return AccessControlStorage.layout().hasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC173} from "./../interfaces/IERC173.sol";
import {ContractOwnershipStorage} from "./../libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC173 Contract Ownership Standard (proxiable version).
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ContractOwnershipBase is Context, IERC173 {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @inheritdoc IERC173
    function owner() public view virtual override returns (address) {
        return ContractOwnershipStorage.layout().owner();
    }

    /// @inheritdoc IERC173
    function transferOwnership(address newOwner) public virtual override {
        ContractOwnershipStorage.layout().transferOwnership(_msgSender(), newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @notice Emitted when the contract ownership changes.
    /// @param previousOwner the previous contract owner.
    /// @param newOwner the new contract owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(address newOwner) external;

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner() external view returns (address contractOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Bytes32} from "./../../utils/libraries/Bytes32.sol";

library AccessControlStorage {
    using Bytes32 for bytes32;
    using AccessControlStorage for AccessControlStorage.Layout;

    struct Layout {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.AccessControl.storage")) - 1);

    event RoleGranted(bytes32 role, address account, address operator);
    event RoleRevoked(bytes32 role, address account, address operator);

    /// @notice Grants a role to an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleGranted} event if the account did not previously have the role.
    /// @param role The role to grant.
    /// @param account The account to grant the role to.
    /// @param operator The account requesting the role change.
    function grantRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (!s.hasRole(role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, operator);
        }
    }

    /// @notice Revokes a role from an account.
    /// @dev Note: Call to this function should be properly access controlled.
    /// @dev Emits a {RoleRevoked} event if the account previously had the role.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    /// @param operator The account requesting the role change.
    function revokeRole(Layout storage s, bytes32 role, address account, address operator) internal {
        if (s.hasRole(role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, operator);
        }
    }

    /// @notice Renounces a role by the sender.
    /// @dev Reverts if `sender` does not have `role`.
    /// @dev Emits a {RoleRevoked} event.
    /// @param sender The message sender.
    /// @param role The role to renounce.
    function renounceRole(Layout storage s, address sender, bytes32 role) internal {
        s.enforceHasRole(role, sender);
        s.roles[role][sender] = false;
        emit RoleRevoked(role, sender, sender);
    }

    /// @notice Retrieves whether an account has a role.
    /// @param role The role.
    /// @param account The account.
    /// @return whether `account` has `role`.
    function hasRole(Layout storage s, bytes32 role, address account) internal view returns (bool) {
        return s.roles[role][account];
    }

    /// @notice Ensures that an account has a role.
    /// @dev Reverts if `account` does not have `role`.
    /// @param role The role.
    /// @param account The account.
    function enforceHasRole(Layout storage s, bytes32 role, address account) internal view {
        if (!s.hasRole(role, account)) {
            revert(string(abi.encodePacked("AccessControl: missing '", role.toASCIIString(), "' role")));
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC173} from "./../interfaces/IERC173.sol";
import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../introspection/libraries/InterfaceDetectionStorage.sol";

library ContractOwnershipStorage {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        address contractOwner;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.phase")) - 1);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Initializes the storage with an initial contract owner (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function constructorInit(Layout storage s, address initialOwner) internal {
        if (initialOwner != address(0)) {
            s.contractOwner = initialOwner;
            emit OwnershipTransferred(address(0), initialOwner);
        }
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC173).interfaceId, true);
    }

    /// @notice Initializes the storage with an initial contract owner (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function proxyInit(Layout storage s, address initialOwner) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialOwner);
    }

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if `sender` is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(Layout storage s, address sender, address newOwner) internal {
        address previousOwner = s.contractOwner;
        require(sender == previousOwner, "Ownership: not the owner");
        if (previousOwner != newOwner) {
            s.contractOwner = newOwner;
            emit OwnershipTransferred(previousOwner, newOwner);
        }
    }

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner(Layout storage s) internal view returns (address contractOwner) {
        return s.contractOwner;
    }

    /// @notice Ensures that an account is the contract owner.
    /// @dev Reverts if `account` is not the contract owner.
    /// @param account The account.
    function enforceIsContractOwner(Layout storage s, address account) internal view {
        require(account == s.contractOwner, "Ownership: not the owner");
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC165} from "./interfaces/IERC165.sol";
import {InterfaceDetectionStorage} from "./libraries/InterfaceDetectionStorage.sol";

/// @title ERC165 Interface Detection Standard (immutable or proxiable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) or proxied implementation.
abstract contract InterfaceDetection is IERC165 {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return InterfaceDetectionStorage.layout().supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC165 Interface Detection Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-165.
/// @dev Note: The ERC-165 identifier for this interface is 0x01ffc9a7.
interface IERC165 {
    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId the interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(bytes4 interfaceId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC165} from "./../interfaces/IERC165.sol";

library InterfaceDetectionStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.introspection.InterfaceDetection.storage")) - 1);

    bytes4 internal constant ILLEGAL_INTERFACE_ID = 0xffffffff;

    /// @notice Sets or unsets an ERC165 interface.
    /// @dev Reverts if `interfaceId` is `0xffffffff`.
    /// @param interfaceId the interface identifier.
    /// @param supported True to set the interface, false to unset it.
    function setSupportedInterface(Layout storage s, bytes4 interfaceId, bool supported) internal {
        require(interfaceId != ILLEGAL_INTERFACE_ID, "InterfaceDetection: wrong value");
        s.supportedInterfaces[interfaceId] = supported;
    }

    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId The interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(Layout storage s, bytes4 interfaceId) internal view returns (bool supported) {
        if (interfaceId == ILLEGAL_INTERFACE_ID) {
            return false;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        return s.supportedInterfaces[interfaceId];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Multiple calls protection for storage-modifying proxy initialization functions.
library ProxyInitialization {
    /// @notice Sets the initialization phase during a storage-modifying proxy initialization function.
    /// @dev Reverts if `phase` has been reached already.
    /// @param storageSlot the storage slot where `phase` is stored.
    /// @param phase the initialization phase.
    function setPhase(bytes32 storageSlot, uint256 phase) internal {
        StorageSlot.Uint256Slot storage currentVersion = StorageSlot.getUint256Slot(storageSlot);
        require(currentVersion.value < phase, "Storage: phase reached");
        currentVersion.value = phase;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {TokenRecoveryBase} from "./base/TokenRecoveryBase.sol";
import {ContractOwnership} from "./../access/ContractOwnership.sol";

/// @title Recovery mechanism for ETH/ERC20/ERC721 tokens accidentally sent to this contract (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract TokenRecovery is TokenRecoveryBase, ContractOwnership {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "./../../token/ERC721/interfaces/IERC721.sol";
import {ContractOwnershipStorage} from "./../../access/libraries/ContractOwnershipStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title Recovery mechanism for ETH/ERC20/ERC721 tokens accidentally sent to this contract (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
contract TokenRecoveryBase is Context {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Extract ETH tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Note: While contracts can generally prevent accidental ETH transfer by implementating a reverting
    ///  `receive()` function, this can still be bypassed in a `selfdestruct(address)` scenario.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ETH tokens
    ///  so that the extraction is limited to only amounts sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ETH transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param amounts the list of token amounts to transfer.
    function recoverETH(address payable[] calldata accounts, uint256[] calldata amounts) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == amounts.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                accounts[i].sendValue(amounts[i]);
            }
        }
    }

    /// @notice Extract ERC20 tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ERC20 tokens
    ///  so that the extraction is limited to only amounts sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts`, `tokens` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ERC20 transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param tokens the list of ERC20 token addresses.
    /// @param amounts the list of token amounts to transfer.
    function recoverERC20s(address[] calldata accounts, IERC20[] calldata tokens, uint256[] calldata amounts) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                tokens[i].safeTransfer(accounts[i], amounts[i]);
            }
        }
    }

    /// @notice Extract ERC721 tokens which were accidentally sent to the contract to a list of accounts.
    /// @dev Warning: this function should be overriden for contracts which are supposed to hold ERC721 tokens
    ///  so that the extraction is limited to only tokens sent accidentally.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Reverts if `accounts`, `contracts` and `amounts` do not have the same length.
    /// @dev Reverts if one of the ERC721 transfers fails for any reason.
    /// @param accounts the list of accounts to transfer the tokens to.
    /// @param contracts the list of ERC721 contract addresses.
    /// @param tokenIds the list of token ids to transfer.
    function recoverERC721s(address[] calldata accounts, IERC721[] calldata contracts, uint256[] calldata tokenIds) external virtual {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recovery: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                contracts[i].transferFrom(address(this), accounts[i], tokenIds[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Receiver} from "./interfaces/IERC20Receiver.sol";
import {InterfaceDetectionStorage} from "../../introspection/libraries/InterfaceDetectionStorage.sol";
import {InterfaceDetection} from "../../introspection/InterfaceDetection.sol";

/// @title ERC20 Fungible Token Standard, Receiver (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract ERC20Receiver is IERC20Receiver, InterfaceDetection {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Receiver.
    constructor() {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Receiver).interfaceId, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, basic interface.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
interface IERC20 {
    /// @notice Emitted when tokens are transferred, including zero value transfers.
    /// @param from The account where the transferred tokens are withdrawn from.
    /// @param to The account where the transferred tokens are deposited to.
    /// @param value The amount of tokens being transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when an approval is set.
    /// @param owner The account granting an allowance to `spender`.
    /// @param spender The account being granted an allowance from `owner`.
    /// @param value The allowance amount being granted.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Sets the allowance to an account from the sender.
    /// @notice Warning: Beware that changing an allowance with this method brings the risk that someone may use both the old and
    ///  the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce
    ///  the spender's allowance to 0 and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param spender The account being granted the allowance by the message caller.
    /// @param value The allowance amount to grant.
    /// @return result Whether the operation succeeded.
    function approve(address spender, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from the sender.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transfer(address to, uint256 value) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @return result Whether the operation succeeded.
    function transferFrom(address from, address to, uint256 value) external returns (bool result);

    /// @notice Gets the total token supply.
    /// @return supply The total token supply.
    function totalSupply() external view returns (uint256 supply);

    /// @notice Gets an account balance.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Allowance.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x9d075186.
interface IERC20Allowance {
    /// @notice Increases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by the sender overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    /// @return result Whether the operation succeeded.
    function increaseAllowance(address spender, uint256 value) external returns (bool result);

    /// @notice Decreases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by the sender.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    /// @return result Whether the operation succeeded.
    function decreaseAllowance(address spender, uint256 value) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Batch Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0xc05327e6.
interface IERC20BatchTransfers {
    /// @notice Transfers multiple amounts of tokens to multiple recipients from the sender.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the sender does not have at least `sum(values)` of balance.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external returns (bool result);

    /// @notice Transfers multiple amounts of tokens to multiple recipients from a specified address.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to be transferred.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransferFrom(address from, address[] calldata recipients, uint256[] calldata values) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x3b5a0bf8.
interface IERC20Burnable {
    /// @notice Burns an amount of tokens from the sender, decreasing the total supply.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burn(uint256 value) external returns (bool result);

    /// @notice Burns an amount of tokens from a specified address, decreasing the total supply.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burnFrom(address from, uint256 value) external returns (bool result);

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if the sender is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if the sender is not this `owner` (non-standard).
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    /// @return result Whether the operation succeeded.
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x28963e1e.
interface IERC20Mintable {
    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(address to, uint256 value) external;

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(address[] calldata recipients, uint256[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC20 contracts with the Safe Transfers extension.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x4fc35859.
interface IERC20Receiver {
    /// @notice Handles the receipt of ERC20 tokens.
    /// @dev Note: this function is called by an {ERC20SafeTransfer} contract after a safe transfer.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous tokens owner.
    /// @param value The amount of tokens transferred.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` (`0x4fc35859`) to accept, any other value to refuse.
    function onERC20Received(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Safe Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x53f41a97.
interface IERC20SafeTransfers {
    /// @notice Transfers an amount of tokens to a recipient from the sender. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransfer(address to, uint256 value, bytes calldata data) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransferFrom(address from, address to, uint256 value, bytes calldata data) external returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from "./../interfaces/IERC20.sol";
import {IERC20Allowance} from "./../interfaces/IERC20Allowance.sol";
import {IERC20BatchTransfers} from "./../interfaces/IERC20BatchTransfers.sol";
import {IERC20SafeTransfers} from "./../interfaces/IERC20SafeTransfers.sol";
import {IERC20Mintable} from "./../interfaces/IERC20Mintable.sol";
import {IERC20Burnable} from "./../interfaces/IERC20Burnable.sol";
import {IERC20Receiver} from "./../interfaces/IERC20Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20Storage {
    using Address for address;
    using ERC20Storage for ERC20Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 supply;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20.storage")) - 1);

    bytes4 internal constant ERC20_RECEIVED = IERC20Receiver.onERC20Received.selector;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20, ERC20Allowance.
    function init() internal {
        InterfaceDetectionStorage.Layout storage erc165Layout = InterfaceDetectionStorage.layout();
        erc165Layout.setSupportedInterface(type(IERC20).interfaceId, true);
        erc165Layout.setSupportedInterface(type(IERC20Allowance).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20BatchTransfers.
    function initERC20BatchTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20BatchTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20SafeTransfers.
    function initERC20SafeTransfers() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20SafeTransfers).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Mintable.
    function initERC20Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Burnable.
    function initERC20Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Burnable).interfaceId, true);
    }

    /// @notice Sets the allowance to an account by an owner.
    /// @dev Note: This function implements {ERC20-approve(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Emits an {Approval} event.
    /// @param owner The account to set the allowance from.
    /// @param spender The account being granted the allowance by `owner`.
    /// @param value The allowance amount to grant.
    function approve(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        s.allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /// @notice Increases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-increaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by `owner` overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account increasing the allowance.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    function increaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];
        if (value != 0) {
            unchecked {
                uint256 newAllowance = allowance_ + value;
                require(newAllowance > allowance_, "ERC20: allowance overflow");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Decreases the allowance granted to an account by an owner.
    /// @dev Note: This function implements {ERC20Allowance-decreaseAllowance(address,uint256)}.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by `owner`.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by `owner`.
    /// @param owner The account decreasing the allowance.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    function decreaseAllowance(Layout storage s, address owner, address spender, uint256 value) internal {
        require(spender != address(0), "ERC20: approval to address(0)");
        uint256 allowance_ = s.allowances[owner][spender];

        if (allowance_ != type(uint256).max && value != 0) {
            unchecked {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                uint256 newAllowance = allowance_ - value;
                require(newAllowance < allowance_, "ERC20: insufficient allowance");
                s.allowances[owner][spender] = newAllowance;
                allowance_ = newAllowance;
            }
        }
        emit Approval(owner, spender, allowance_);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient.
    /// @dev Note: This function implements {ERC20-transfer(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transfer(Layout storage s, address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to address(0)");

        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                if (from != to) {
                    s.balances[from] = newBalance;
                    s.balances[to] += value;
                }
            }
        }

        emit Transfer(from, to, value);
    }

    /// @notice Transfers an amount of tokens from an account to a recipient by a sender.
    /// @dev Note: This function implements {ERC20-transferFrom(address,address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from`.
    /// @param sender The message sender.
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    function transferFrom(Layout storage s, address sender, address from, address to, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.transfer(from, to, value);
    }

    //================================================= Batch Transfers ==================================================//

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransfer(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransfer(Layout storage s, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }
                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }
    }

    /// @notice Transfers multiple amounts of tokens from an account to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC20BatchTransfers-batchTransferFrom(address,address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits a {Transfer} event for each transfer.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    function batchTransferFrom(Layout storage s, address sender, address from, address[] calldata recipients, uint256[] calldata values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 balance = s.balances[from];

        uint256 totalValue;
        uint256 selfTransferTotalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: transfer to address(0)");

                uint256 value = values[i];

                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    if (from != to) {
                        s.balances[to] += value;
                    } else {
                        require(value <= balance, "ERC20: insufficient balance");
                        selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true
                    }
                }

                emit Transfer(from, to, value);
            }

            if (totalValue != 0 && totalValue != selfTransferTotalValue) {
                uint256 newBalance = balance - totalValue;
                require(newBalance < balance, "ERC20: insufficient balance"); // balance must be sufficient, including self-transfers
                s.balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance
            }
        }

        if (from != sender) {
            s.decreaseAllowance(from, sender, totalValue);
        }
    }

    //================================================= Safe Transfers ==================================================//

    /// @notice Transfers an amount of tokens from an account to a recipient. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransfer(address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransfer(Layout storage s, address from, address to, uint256 value, bytes calldata data) internal {
        s.transfer(from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(from, from, to, value, data);
        }
    }

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Note: This function implements {ERC20SafeTransfers-safeTransferFrom(address,address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account transferring the tokens.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 value, bytes calldata data) internal {
        s.transferFrom(sender, from, to, value);
        if (to.isContract()) {
            _callOnERC20Received(sender, from, to, value, data);
        }
    }

    //================================================= Minting ==================================================//

    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-mint(address,uint256)}.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(Layout storage s, address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to address(0)");
        if (value != 0) {
            uint256 supply = s.supply;
            unchecked {
                uint256 newSupply = supply + value;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
                s.balances[to] += value; // balance cannot overflow if supply does not
            }
        }
        emit Transfer(address(0), to, value);
    }

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Note: This function implements {ERC20Mintable-batchMint(address[],uint256[])}.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits a {Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(Layout storage s, address[] memory recipients, uint256[] memory values) internal {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC20: mint to address(0)");

                uint256 value = values[i];
                if (value != 0) {
                    uint256 newTotalValue = totalValue + value;
                    require(newTotalValue > totalValue, "ERC20: values overflow");
                    totalValue = newTotalValue;
                    s.balances[to] += value; // balance cannot overflow if supply does not
                }
                emit Transfer(address(0), to, value);
            }

            if (totalValue != 0) {
                uint256 supply = s.supply;
                uint256 newSupply = supply + totalValue;
                require(newSupply > supply, "ERC20: supply overflow");
                s.supply = newSupply;
            }
        }
    }

    //================================================= Burning ==================================================//

    /// @notice Burns an amount of tokens from an account, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burn(uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @param from The account burning the tokens.
    /// @param value The amount of tokens to burn.
    function burn(Layout storage s, address from, uint256 value) internal {
        if (value != 0) {
            uint256 balance = s.balances[from];
            unchecked {
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC20: insufficient balance");
                s.balances[from] = newBalance;
                s.supply -= value; // will not underflow if balance does not
            }
        }

        emit Transfer(from, address(0), value);
    }

    /// @notice Burns an amount of tokens from an account by a sender, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-burnFrom(address,uint256)}.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if `sender` is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if `sender` is not `from` (non-standard).
    /// @param sender The message sender.
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 value) internal {
        if (from != sender) {
            s.decreaseAllowance(from, sender, value);
        }
        s.burn(from, value);
    }

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Note: This function implements {ERC20Burnable-batchBurnFrom(address,address[],uint256[])}.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if `sender` is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits a {Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if `sender` is not this `owner` (non-standard).
    /// @param sender The message sender.
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address[] calldata owners, uint256[] calldata values) internal {
        uint256 length = owners.length;
        require(length == values.length, "ERC20: inconsistent arrays");

        if (length == 0) return;

        uint256 totalValue;
        unchecked {
            for (uint256 i; i != length; ++i) {
                address from = owners[i];
                uint256 value = values[i];

                if (from != sender) {
                    s.decreaseAllowance(from, sender, value);
                }

                if (value != 0) {
                    uint256 balance = s.balances[from];
                    uint256 newBalance = balance - value;
                    require(newBalance < balance, "ERC20: insufficient balance");
                    s.balances[from] = newBalance;
                    totalValue += value; // totalValue cannot overflow if the individual balances do not underflow
                }

                emit Transfer(from, address(0), value);
            }

            if (totalValue != 0) {
                s.supply -= totalValue; // _totalSupply cannot underfow as balances do not underflow
            }
        }
    }

    /// @notice Gets the total token supply.
    /// @dev Note: This function implements {ERC20-totalSupply()}.
    /// @return supply The total token supply.
    function totalSupply(Layout storage s) internal view returns (uint256 supply) {
        return s.supply;
    }

    /// @notice Gets an account balance.
    /// @dev Note: This function implements {ERC20-balanceOf(address)}.
    /// @param owner The account whose balance will be returned.
    /// @return balance The account balance.
    function balanceOf(Layout storage s, address owner) internal view returns (uint256 balance) {
        return s.balances[owner];
    }

    /// @notice Gets the amount that an account is allowed to spend on behalf of another.
    /// @dev Note: This function implements {ERC20-allowance(address,address)}.
    /// @param owner The account that has granted an allowance to `spender`.
    /// @param spender The account that was granted an allowance by `owner`.
    /// @return value The amount which `spender` is allowed to spend on behalf of `owner`.
    function allowance(Layout storage s, address owner, address spender) internal view returns (uint256 value) {
        return s.allowances[owner][spender];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Calls {IERC20Receiver-onERC20Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param value The value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC20Received(address sender, address from, address to, uint256 value, bytes memory data) private {
        require(IERC20Receiver(to).onERC20Received(sender, from, value, data) == ERC20_RECEIVED, "ERC20: safe transfer rejected");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, basic interface (functions).
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev This interface only contains the standard functions. See IERC721Events for the events.
/// @dev Note: The ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 {
    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: There can only be one approved address per token at a given time.
    /// @dev Note: A token approval gets reset when this token is transferred, including a self-transfer.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if the sender is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(address to, uint256 tokenId) external;

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Reverts if the sender is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Unsafely transfers the ownership of a token to a recipient.
    /// @dev Note: Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer. Self-transfers are possible.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Gets the balance of an address.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the owner of a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token identifier.
    function ownerOf(uint256 tokenId) external view returns (address tokenOwner);

    /// @notice Gets the approved address for a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(uint256 tokenId) external view returns (address approved);

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(address owner, address operator) external view returns (bool approvedForAll);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Bytes32 {
    /// @notice Converts bytes32 to base32 string.
    /// @param value value to convert.
    /// @return the converted base32 string.
    function toBase32String(bytes32 value) internal pure returns (string memory) {
        unchecked {
            bytes32 base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;
            uint256 i = uint256(value);
            uint256 k = 52;
            bytes memory bstr = new bytes(k);
            bstr[--k] = base32Alphabet[uint8((i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (i % (2**s)) << (5-s)
            i /= 8;
            while (k > 0) {
                bstr[--k] = base32Alphabet[i % 32];
                i /= 32;
            }
            return string(bstr);
        }
    }

    /// @notice Converts a bytes32 value to an ASCII string, trimming the tailing zeros.
    /// @param value value to convert.
    /// @return the converted ASCII string.
    function toASCIIString(bytes32 value) internal pure returns (string memory) {
        unchecked {
            if (value == 0x00) return "";
            bytes memory bytesString = bytes(abi.encodePacked(value));
            uint256 pos = 31;
            while (true) {
                if (bytesString[pos] != 0) break;
                --pos;
            }
            bytes memory asciiString = new bytes(pos + 1);
            for (uint256 i; i <= pos; ++i) {
                asciiString[i] = bytesString[i];
            }
            return string(asciiString);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20Receiver} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Receiver.sol";
import {IERC20Burnable} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Burnable.sol";
import {IERC20Mintable} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Mintable.sol";
import {IERC20Receiver} from "@animoca/ethereum-contracts/contracts/token/ERC20/interfaces/IERC20Receiver.sol";
import {ERC20Storage} from "@animoca/ethereum-contracts/contracts/token/ERC20/libraries/ERC20Storage.sol";
import {InterfaceDetectionStorage} from "@animoca/ethereum-contracts/contracts/introspection/libraries/InterfaceDetectionStorage.sol";
import {AccessControlStorage} from "@animoca/ethereum-contracts/contracts/access/libraries/AccessControlStorage.sol";
import {ERC20Receiver} from "@animoca/ethereum-contracts/contracts/token/ERC20/ERC20Receiver.sol";
import {ContractOwnership} from "@animoca/ethereum-contracts/contracts/access/ContractOwnership.sol";
import {AccessControl} from "@animoca/ethereum-contracts/contracts/access/AccessControl.sol";
import {TokenRecovery} from "@animoca/ethereum-contracts/contracts/security/TokenRecovery.sol";

/// @title REVV Racing Catalysts Builder which converts SHRD into CATA.
contract REVVRacingCatalystBuilder is ERC20Receiver, AccessControl, TokenRecovery {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant RATE_MANAGER_ROLE = "RATE_MANAGER";

    IERC20Burnable public immutable shards;
    IERC20Mintable public immutable catalysts;

    uint256 public conversionRate; // number of shard necessary to build a catalyst

    event ConversionRateUpdated(uint256 conversionRate);

    constructor(IERC20Burnable shards_, IERC20Mintable catalysts_) ContractOwnership(msg.sender) {
        shards = shards_;
        catalysts = catalysts_;
        emit ConversionRateUpdated(0);
    }

    //==================================================== ERC20Receiver ====================================================//

    /// @notice On safe reception of shards, converts them into catalysts based on the current conversion rate.
    /// @dev Reverts if the sender is not the shards contract.
    /// @dev Reverts if the conversion rate is currently set to zero.
    /// @inheritdoc IERC20Receiver
    function onERC20Received(address /*sender,*/, address from, uint256 value, bytes memory /*data*/) public virtual override returns (bytes4) {
        require(msg.sender == address(shards), "CatalystBuilder: wrong sender");

        uint256 rate = conversionRate;
        require(rate != 0, "CatalystBuilder: rate not set");

        shards.burn(value);
        catalysts.mint(from, value / rate);

        return ERC20Storage.ERC20_RECEIVED;
    }

    //=================================================== CatalystBuilder ===================================================//

    /// @notice Sets the conversion rate.
    /// @dev Reverts if not sent by a RATE_MANAGER.
    /// @dev Emits a ConversionRateUpdated event.
    /// @param conversionRate_ the new conversion rate. A zero value disables the conversion.
    function setConversionRate(uint256 conversionRate_) external {
        AccessControlStorage.layout().enforceHasRole(RATE_MANAGER_ROLE, _msgSender());
        conversionRate = conversionRate_;
        emit ConversionRateUpdated(conversionRate_);
    }
}