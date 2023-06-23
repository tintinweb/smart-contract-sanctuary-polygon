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

pragma solidity ^0.8.19;

contract TokenRegistryEvent {
  event TokenAddressUpdated(address newTokenAddress);
  event RolesAddressUpdated(address newRoleAddress);
  event RegistryAddressUpdated(address newRoleAddress);
  event SetSettlementToken(address settlementToken);

  // ---- TokenRegistry ---- //

  event AddTokenInReg(address key, string symbol);
  event DelTokenInReg(address key);
  event PauseTokenInReg(address key);
  event UnPauseTokenInReg(address key);
  event BlockListToken(address key);
  event UnBlockListToken(address key);
}

pragma solidity ^0.8.19;

/**
 * @title IAddressRegistry
 * @dev IAddressRegistry contract
 *
 * @author surname name - <>
 * SPDX-License-Identifier: MIT
 *
 * Error messages
 * ADDR01: Cannot set the same value as new value
 *
 */

interface IAddressRegistry {
  function REGISTRY_MANAGEMENT_ROLE() external view returns (bytes32);

  function getCrowdsaleFactAddr() external view returns (address);

  function getTokenFactAddr() external view returns (address);

  function getCrowdsaleEventAddr() external view returns (address);

  function getSettlementEventAddr() external view returns (address);

  function getStableSwapEvent() external view returns (address);

  function getMarketAddr() external view returns (address);

  function getPriceFeedAddr() external view returns (address);

  function getRoleRegAddr() external view returns (address);

  function getPairFactoryAddr() external view returns (address);

  function getTokenRegAddr() external view returns (address);

  function getUserRegAddr() external view returns (address);

  function setCrowdsaleFactAddr(address newAddr) external;

  function setTokenFactAddr(address newAddr) external;

  function setCrowdsaleEventAddr(address newAddr) external;

  function setMarketAddr(address newAddr) external;

  function setPriceFeedAddr(address newAddr) external;

  function setRoleRegAddr(address newAddr) external;

  function setPairFactoryAddr(address newAddr) external;

  function setTokenRegAddr(address newAddr) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./event/TokenRegistryEvent.sol";
import "../roles/interface/IAccessControl.sol";
import "../registry/interface/IAddressRegistry.sol";
import { ItMapStable } from "./utils/ItMapStable.sol";
import { ItMapSecTok } from "./utils/ItMapSecTok.sol";

/**
 * TOKR01: Invalid token address
 */
contract TokenRegistry is TokenRegistryEvent {
  using ItMapSecTok for ItMapSecTok.SecTokMap;
  using ItMapStable for ItMapStable.StabMap;

  ItMapSecTok.SecTokMap private secTokMap;
  ItMapStable.StabMap private stabMap;

  address private _addressRegistry;
  address private settlementToken;

  bytes32 public constant ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");

  constructor(
    address addressRegistry_,
    address settlementToken_,
    address kchf_,
    address keur_,
    address kusd_,
    address usdt_
  ) {
    _addressRegistry = addressRegistry_;
    settlementToken = settlementToken_;
    _add(kchf_, true);
    _add(keur_, true);
    _add(kusd_, true);
    _add(usdt_, true);
  }

  modifier onlyRole(bytes32 _role) {
    address _roleAddress = getRoleAddr();
    require((IAccessControl(_roleAddress).hasRole(_role, msg.sender)));
    _;
  }

  // ---- Public manager restricted entrypoints ---- //

  function add(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    _add(key, isStab);
  }

  function remove(address key, string memory symbol, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.del(key, symbol) : secTokMap.del(key);
    emit DelTokenInReg(key);
  }

  function pause(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    require(key != address(0), "TOKR01");
    isStab ? stabMap.pause(key) : secTokMap.pause(key);
    emit PauseTokenInReg(key);
  }

  function unPause(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.unPause(key) : secTokMap.unPause(key);
    emit UnPauseTokenInReg(key);
  }

  function blockList(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.blockList(key) : secTokMap.blockList(key);
    emit BlockListToken(key);
  }

  function unBlockList(address key, bool isStab) public onlyRole(ORACLE_ADMIN_ROLE) {
    isStab ? stabMap.unBlockList(key) : secTokMap.unBlockList(key);
    emit UnBlockListToken(key);
  }

  function setSettlementTokenAddress(address addr) public onlyRole(ORACLE_ADMIN_ROLE) {
    _setSettlementTokenAddress(addr);
  }

  // ---- Public view entrypoints ---- //

  function getTokenState(address key, bool isStab) public view returns (bool, bool) {
    return isStab ? stabMap.getTokenState(key) : secTokMap.getTokenState(key);
  }

  function securityTokenExists(address key) public view returns (bool) {
    return secTokMap.tokenExists(key);
  }

  function getSettlementAddr() public view returns (address) {
    return settlementToken;
  }

  function getTokenAddrAtIndex(uint256 id, bool isStab) public view returns (address) {
    return isStab ? stabMap.getKeyAtIndex(id) : secTokMap.getKeyAtIndex(id);
  }

  function getStabArrSize(bool isStab) public view returns (uint256) {
    return isStab ? stabMap.size() : secTokMap.size();
  }

  function getStableAddress(string calldata symbol) public view returns (address) {
    return stabMap.getBySymbol(symbol);
  }

  function getDecimals(address token) public view returns (uint8) {
    uint8 decimals = IERC20Metadata(token).decimals();
    return decimals;
  }

  function getRoleAddr() public view returns (address) {
    return IAddressRegistry(_addressRegistry).getRoleRegAddr();
  }

  function _setSettlementTokenAddress(address addr) private {
    settlementToken = addr;
    emit SetSettlementToken(addr);
  }

  function _add(address key, bool isStab) private {
    require(key != address(0), "TOKR01");
    // convert in bytes32 = keccak
    // After more easily and gas saver to call ( like roles )
    string memory symbol = IERC20Metadata(key).symbol();
    isStab ? stabMap.add(key, symbol) : secTokMap.add(key);
    emit AddTokenInReg(key, symbol);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library ItMapSecTok {
  struct SecTokMap {
    address[] keys;
    mapping(address => bool) isPaused;
    mapping(address => bool) isBlocklisted;
    mapping(address => uint256) indexOf;
    mapping(address => bool) isExists;
  }

  function add(SecTokMap storage map, address key) public {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
        map.isExists[key] = true;
      }
    }
  }

  function del(SecTokMap storage map, address key) public {
    if (map.indexOf[key] == 0) {
      return;
    }
    delete map.isPaused[key];
    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];
    map.indexOf[lastKey] = index;
    delete map.indexOf[key];
    map.keys[index] = lastKey;
    map.keys.pop();
    map.isExists[key] = false;
  }

  function pause(SecTokMap storage map, address key) public {
    map.isPaused[key] = true;
  }

  function unPause(SecTokMap storage map, address key) public {
    map.isPaused[key] = false;
  }

  function blockList(SecTokMap storage map, address key) public {
    map.isBlocklisted[key] = true;
  }

  function unBlockList(SecTokMap storage map, address key) public {
    map.isBlocklisted[key] = false;
  }

  function tokenExists(SecTokMap storage map, address key) public view returns (bool) {
    return map.isExists[key];
  }

  function getTokenState(SecTokMap storage map, address key) public view returns (bool isPaused, bool isBlocklisted) {
    isPaused = map.isPaused[key];
    isBlocklisted = map.isBlocklisted[key];

    return (isPaused, isBlocklisted);
  }

  function getIndexOfKey(SecTokMap storage map, address key) public view returns (int) {
    if (map.indexOf[key] == 0) {
      return -1;
    }
    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(SecTokMap storage map, uint256 index) public view returns (address) {
    return map.keys[index];
  }

  function size(SecTokMap storage map) public view returns (uint256) {
    return map.keys.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library ItMapStable {
  struct StabMap {
    address[] keys;
    mapping(string => address) symbol; // to easily find stable
    mapping(address => bool) isPaused;
    mapping(address => bool) isBlocklisted;
    mapping(address => uint256) indexOf;
  }

  function add(StabMap storage map, address key, string memory symbol) public {
    if (map.indexOf[key] == 0) {
      if (map.keys.length == 0 || map.keys[0] != key) {
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
      }
    }
    map.symbol[symbol] = key;
  }

  function del(StabMap storage map, address key, string memory symbol) public {
    if (map.indexOf[key] == 0) {
      return;
    }
    delete map.symbol[symbol];
    delete map.isPaused[key];
    uint index = map.indexOf[key];
    uint lastIndex = map.keys.length - 1;
    address lastKey = map.keys[lastIndex];
    map.indexOf[lastKey] = index;
    delete map.indexOf[key];
    map.keys[index] = lastKey;
    map.keys.pop();
  }

  function update(StabMap storage map, address key, string memory symbol) public {
    map.symbol[symbol] = key;
  }

  function pause(StabMap storage map, address key) public {
    map.isPaused[key] = true;
  }

  function unPause(StabMap storage map, address key) public {
    map.isPaused[key] = false;
  }

  function blockList(StabMap storage map, address key) public {
    map.isBlocklisted[key] = true;
  }

  function unBlockList(StabMap storage map, address key) public {
    map.isBlocklisted[key] = false;
  }

  function getTokenState(StabMap storage map, address key) public view returns (bool isPaused, bool isBlocklisted) {
    isPaused = map.isPaused[key];
    isBlocklisted = map.isBlocklisted[key];

    return (isPaused, isBlocklisted);
  }

  function getBySymbol(StabMap storage map, string memory symbol) external view returns (address) {
    return map.symbol[symbol];
  }

  function getIndexOfKey(StabMap storage map, address key) public view returns (int) {
    if (map.indexOf[key] == 0) {
      return -1;
    }
    return int(map.indexOf[key]);
  }

  function getKeyAtIndex(StabMap storage map, uint256 index) public view returns (address) {
    return map.keys[index];
  }

  function size(StabMap storage map) public view returns (uint256) {
    return map.keys.length;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.7;

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

  function grantRoleByAdministrator(bytes32 role, address account) external;

  function revokeRoleByAdministrator(bytes32 role, address account) external;

  function convertIntoBytes(string memory role) external view returns (bytes32);
}