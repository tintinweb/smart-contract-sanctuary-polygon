// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import {VaultDeployer} from "../../abstracts/VaultDeployer.sol";
import {LibSSTORE2} from "../../libraries/LibSSTORE2.sol";
import {IERC20Metadata} from
  "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BorrowingVaultFactory is VaultDeployer {
  error BorrowingVaultFactory__deployVault_failed();

  event DeployBorrowingVault(
    address indexed vault,
    address indexed asset,
    address indexed debtAsset,
    string name,
    string symbol,
    bytes32 salt
  );

  uint256 public nonce;

  address public creationAddress;

  constructor(address _chief) VaultDeployer(_chief) {}

  /**
   * Deploys a new "BorrowingVault".
   * @param deployData The encoded data containing asset, debtAsset and oracle.
   */
  function deployVault(bytes memory deployData) external onlyChief returns (address vault) {
    (address asset, address debtAsset, address oracle) =
      abi.decode(deployData, (address, address, address));

    string memory assetSymbol = IERC20Metadata(asset).symbol();
    string memory debtSymbol = IERC20Metadata(debtAsset).symbol();

    // name_, ex: Fuji-V2 WETH-DAI BorrowingVault
    string memory name =
      string(abi.encodePacked("Fuji-V2 ", assetSymbol, "-", debtSymbol, " BorrowingVault"));
    // symbol_, ex: fbvWETHDAI
    string memory symbol = string(abi.encodePacked("fbv", assetSymbol, debtSymbol));

    bytes32 salt = keccak256(abi.encode(deployData, nonce));
    nonce++;

    bytes memory bytecode = abi.encodePacked(
      LibSSTORE2.read(creationAddress), abi.encode(asset, debtAsset, oracle, chief, name, symbol)
    );

    assembly {
      vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    if (vault == address(0)) revert BorrowingVaultFactory__deployVault_failed();

    _registerVault(vault, asset, salt);

    emit DeployBorrowingVault(vault, asset, debtAsset, name, symbol, salt);
  }

  /**
   * Sets the bytecode for the BorrowingVault.
   * @param creationCode The creationCode for the vault contract.
   */
  function setContractCode(bytes calldata creationCode) external onlyTimelock {
    creationAddress = LibSSTORE2.write(creationCode);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import {IChief} from "../interfaces/IChief.sol";

/// @notice Vault deployer for whitelisted template factories.
abstract contract VaultDeployer {
  error VaultDeployer__onlyChief_notAuthorized();
  error VaultDeployer__onlyTimelock_notAuthorized();
  error VaultDeployer__zeroAddress();

  /**
   * @dev Emit when a vault is registered
   * @param vault address
   * @param asset address
   * @param salt used for address generation
   */
  event VaultRegistered(address vault, address asset, bytes32 salt);

  address public immutable chief;

  mapping(address => address[]) public vaultsByAsset;
  mapping(bytes32 => address) public configAddress;

  modifier onlyChief() {
    if (msg.sender != chief) {
      revert VaultDeployer__onlyChief_notAuthorized();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != IChief(chief).timelock()) {
      revert VaultDeployer__onlyTimelock_notAuthorized();
    }
    _;
  }

  constructor(address _chief) {
    if (_chief == address(0)) {
      revert VaultDeployer__zeroAddress();
    }
    chief = _chief;
  }

  function _registerVault(address vault, address asset, bytes32 salt) internal onlyChief {
    // Store the address of the deployed contract.
    configAddress[salt] = vault;
    vaultsByAsset[asset].push(vault);
    emit VaultRegistered(vault, asset, salt);
  }

  function vaultsCount(address asset) external view returns (uint256 count) {
    count = vaultsByAsset[asset].length;
  }

  function getVaults(
    address asset,
    uint256 startIndex,
    uint256 count
  )
    external
    view
    returns (address[] memory vaults)
  {
    vaults = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      vaults[i] = vaultsByAsset[asset][startIndex + i];
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.15;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library LibSSTORE2 {
  uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

  /*//////////////////////////////////////////////////////////////
    WRITE LOGIC
  //////////////////////////////////////////////////////////////*/

  function write(bytes memory data) internal returns (address pointer) {
    // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
    bytes memory runtimeCode = abi.encodePacked(hex"00", data);

    bytes memory creationCode = abi.encodePacked(
      //---------------------------------------------------------------------------------------------------------------//
      // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
      //---------------------------------------------------------------------------------------------------------------//
      // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
      // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
      // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
      // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
      // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
      // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
      // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
      // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
      // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
      // 0xf3    |  0xf3               | RETURN       |                                                                //
      //---------------------------------------------------------------------------------------------------------------//
      hex"600B5981380380925939F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
      runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
    );

    /// @solidity memory-safe-assembly
    assembly {
      // Deploy a new contract with the generated creation code.
      // We start 32 bytes into the code to avoid copying the byte length.
      pointer := create(0, add(creationCode, 32), mload(creationCode))
    }

    require(pointer != address(0), "DEPLOYMENT_FAILED");
  }

  /*//////////////////////////////////////////////////////////////
    READ LOGIC
  //////////////////////////////////////////////////////////////*/

  function read(address pointer) internal view returns (bytes memory) {
    return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
  }

  function read(address pointer, uint256 start) internal view returns (bytes memory) {
    start += DATA_OFFSET;

    return readBytecode(pointer, start, pointer.code.length - start);
  }

  function read(address pointer, uint256 start, uint256 end) internal view returns (bytes memory) {
    start += DATA_OFFSET;
    end += DATA_OFFSET;

    require(pointer.code.length >= end, "OUT_OF_BOUNDS");

    return readBytecode(pointer, start, end - start);
  }

  /*//////////////////////////////////////////////////////////////
    INTERNAL HELPER LOGIC
  //////////////////////////////////////////////////////////////*/

  function readBytecode(
    address pointer,
    uint256 start,
    uint256 size
  )
    private
    view
    returns (bytes memory data)
  {
    /// @solidity memory-safe-assembly
    assembly {
      // Get a pointer to some free memory.
      data := mload(0x40)

      // Update the free memory pointer to prevent overriding our data.
      // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
      // Adding 31 to size and running the result through the logic above ensures
      // the memory pointer remains word-aligned, following the Solidity convention.
      mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

      // Store the size of the data in the first 32 byte chunk of free memory.
      mstore(data, size)

      // Copy the code into memory right after the 32 bytes we used to store the size.
      extcodecopy(pointer, add(data, 32), start, size)
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Chief helper interface.
 * @author Fujidao Labs
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  function timelock() external view returns (address);

  function addrMapper() external view returns (address);

  function allowedFlasher(address flasher) external view returns (bool);
}

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}