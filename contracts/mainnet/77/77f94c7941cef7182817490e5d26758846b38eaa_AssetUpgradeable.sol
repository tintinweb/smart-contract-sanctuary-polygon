// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Manageable} from './Manageable.sol';
import {Permit} from './libraries/Permit.sol';
import {LedgerLike, WrappedErc20Like} from './interfaces/Common.sol';

contract Asset is Manageable {
  /// @dev Reference to Ledger contract
  LedgerLike public ledger;

  /// @dev Reference to asset contract
  WrappedErc20Like public asset;

  /// @dev Flag if the asset is wrapped
  uint256 public wrapped;

  // --- errors

  /// @dev Throws when uint265 value overflow
  error UintOverflow();

  /// @dev Throws when transfer is failed
  error TransferFailed(address src, address dst, address asset, uint256 value);

  /// @dev Throws when called wrapped associated function on the non-wrapped asset
  error NonWrappedAsset();

  /// @dev Throws when invalid value provided
  error InvalidValue();

  // --- events

  /// @dev Emitted when asset joined
  event Join(address src, uint256 value);

  /// @dev Emitted when asset has been withdrawn
  event Exit(address dst, uint256 value);

  constructor(
    address _ledger,
    address _asset,
    uint256 _wrapped
  ) {
    auth[msg.sender] = 1;
    live = 1;
    ledger = LedgerLike(_ledger);
    wrapped = _wrapped;
    asset = WrappedErc20Like(_asset);
    emit Rely(msg.sender);
  }

  function _join(
    address src,
    address dst,
    uint256 value
  ) internal {
    if (int256(value) < 0) {
      revert UintOverflow();
    }
    ledger.add(dst, address(asset), int256(value));
    if (src != address(this)) {
      if (!asset.transferFrom(src, address(this), value)) {
        revert TransferFailed(src, dst, address(asset), value);
      }
    }
    emit Join(dst, value);
  }

  /// @dev Joins ERC20 compatible assets directly from sender
  /// @param dst Asset destination address (balance owner)
  /// @param value Asset value
  function join(address dst, uint256 value) external onlyLive {
    _join(msg.sender, dst, value);
  }

  /// @dev Joins ERC20 compatible assets directly from known address
  /// @param src Asset owner address
  /// @param dst Asset destination address (balance owner)
  /// @param value Asset value
  function join(
    address src,
    address dst,
    uint256 value
  ) external onlyLive {
    _join(src, dst, value);
  }

  /// @dev Joins ERC20 compatible assets directly from known address with permit
  /// @param src Asset owner address
  /// @param dst Asset destination address (balance owner)
  /// @param value Asset value
  function join(
    address src,
    address dst,
    uint256 value,
    Permit.EIP2612Permit calldata permit
  ) external onlyLive {
    asset.permit(src, address(this), value, permit.deadline, permit.v, permit.r, permit.s);
    _join(src, dst, value);
  }

  /// @dev Joins ERC20 compatible assets directly from sender
  /// @param dst Asset destination address (balance owner)
  /// @param value Asset value
  function joinWrapped(address dst, uint256 value) external payable onlyLive {
    if (wrapped == 0) {
      revert NonWrappedAsset();
    }
    if (msg.value != value) {
      revert InvalidValue();
    }
    asset.deposit{value: msg.value}();
    _join(address(this), dst, value);
  }

  /// @dev Withdraws funds
  /// @param dst Asset destination address (balance owner)
  /// @param value Asset value
  function exit(address dst, uint256 value) external onlyLive {
    if (value > 2**255) {
      revert UintOverflow();
    }
    ledger.add(msg.sender, address(asset), -int256(value));
    if (!asset.transfer(dst, value)) {
      revert TransferFailed(address(this), dst, address(asset), value);
    }
    emit Exit(dst, value);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

abstract contract Manageable {
  /// @dev Active flag
  uint256 public live;

  /// @dev Authorized parties
  mapping(address => uint256) public auth;

  // -- errors

  /// @dev Throws if the contract called when it is not live
  error NotLive();

  /// @dev Throws when action is not authorized
  error NotAuthorized();

  // -- events

  /// @dev Emitted when the contract live flag is changed
  event Live(uint256 live);

  /// @dev Emitted when a party is authorized
  event Rely(address party);

  /// @dev Emitted when a party is denied
  event Deny(address party);

  // --- modifiers

  /// @dev Checks if the sender is authorized
  modifier authorized() {
    if (auth[msg.sender] != 1) {
      revert NotAuthorized();
    }
    _;
  }

  /// @dev Checks is the contract live
  modifier onlyLive() {
    if (live == 0) {
      revert NotLive();
    }
    _;
  }

  // --- admin

  /// @dev Toggles the contract live flag
  function toggle() external authorized {
    if (live == 1) {
      live = 0;
    } else {
      live = 1;
    }
    emit Live(live);
  }

  /// @dev Adds authorized party
  function rely(address party) external authorized {
    auth[party] = 1;
    emit Rely(party);
  }

  /// @dev Removes authorized party
  function deny(address party) external authorized {
    auth[party] = 0;
    emit Deny(party);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

library Permit {
  struct EIP2612Permit {
    address owner;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Permit} from '../libraries/Permit.sol';

interface LedgerLike {
  function balances(address dst, address asset) external returns (uint256);

  function add(
    address,
    address,
    int256
  ) external;

  function move(
    address src,
    address dst,
    address asset,
    uint256 value
  ) external;
}

interface Erc20Like {
  function decimals() external view returns (uint256);

  function transfer(address, uint256) external returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

interface WrappedErc20Like is Erc20Like {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

interface AssetLike {
  function ledger() external returns (address);

  function asset() external returns (address);

  function wrapped() external returns (uint256);

  function join(address dst, uint256 value) external;

  function join(
    address src,
    address dst,
    uint256 value
  ) external;

  function join(
    address src,
    address dst,
    uint256 value,
    Permit.EIP2612Permit memory permit
  ) external;

  function joinWrapped(address dst, uint256 value) external payable;

  function exit(address dst, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Asset} from '../Asset.sol';
import {LedgerLike, WrappedErc20Like} from '../interfaces/Common.sol';
import {Upgradeable} from './Upgradeable.sol';

contract AssetUpgradeable is Upgradeable, Asset {
  constructor(
    address _ledger,
    address _asset,
    uint256 _wrapped
  ) Asset(_ledger, _asset, _wrapped) {}

  function postUpgrade(
    address _ledger,
    address _asset,
    uint256 _wrapped
  ) public onlyUpgrader {
    auth[msg.sender] = 1;
    live = 1;
    ledger = LedgerLike(_ledger);
    wrapped = _wrapped;
    asset = WrappedErc20Like(_asset);
    emit Rely(msg.sender);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

abstract contract Upgradeable {
  address public upgrader;

  /// @dev Throws when function called not by upgrader
  error NotUpgrader();

  /// @dev Checks is the caller is upgrader
  modifier onlyUpgrader() {
    if (upgrader == address(0)) {
      upgrader = msg.sender;
    }
    if (msg.sender != upgrader) {
      revert NotUpgrader();
    }
    _;
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {WinPay} from '../WinPay.sol';
import {Upgradeable} from './Upgradeable.sol';
import {LedgerLike} from '../interfaces/Common.sol';

contract WinPayUpgradeable is Upgradeable, WinPay {
  constructor(address _ledger) WinPay(_ledger) {}

  function postUpgrade(address _ledger) public onlyUpgrader {
    auth[msg.sender] = 1;
    live = 1;
    ledger = LedgerLike(_ledger);
    emit Rely(msg.sender);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Manageable} from './Manageable.sol';
import {Permit} from './libraries/Permit.sol';
import {AssetLike, WrappedErc20Like, LedgerLike} from './interfaces/Common.sol';

contract WinPay is Manageable {
  enum State {
    UNINITIALIZED,
    PAID,
    REFUNDED
  }

  struct DealStorage {
    bytes32 provider;
    address customer;
    address asset;
    uint256 value;
    State state;
  }

  /// @dev Reference to Ledger contract
  LedgerLike public ledger;

  /// @dev Service providers registry
  mapping(bytes32 => address) public providers; // provider => EOA

  /// @dev Deals registry
  mapping(bytes32 => DealStorage) public deals; // serviceId => DealStorage

  // -- errors

  /// @dev Throws when provider is already registered
  error ProviderExists();

  /// @dev Throws when provider not found
  error ProviderNotFound(bytes32 provider);

  /// @dev Throws when the deal is already initialized
  error DealExists(bytes32 serviceId);

  /// @dev Throws when the deal not found
  error DealNotFound(bytes32 serviceId);

  /// @dev Throws when the deal is expired
  error DealExpired(bytes32 serviceId, uint256 expiry);

  /// @dev Throws when the deal is already refunded
  error DealAlreadyRefunded(bytes32 serviceId);

  /// @dev Throws when invalid value provided
  error InvalidValue();

  /// @dev Throws when balance not enough for payment
  error BalanceNotEnough();

  // -- events

  /// @dev Emitted when the provider is registered or changed
  event Provider(bytes32 provider, address wallet);

  /// @dev Emitted when deal is occurred
  event Deal(bytes32 provider, bytes32 serviceId);

  /// @dev Emitted when deal is refunded
  event Refund(bytes32 provider, bytes32 serviceId);

  constructor(address _ledger) {
    auth[msg.sender] = 1;
    live = 1;
    ledger = LedgerLike(_ledger);
    emit Rely(msg.sender);
  }

  /// @dev Register a new provider
  /// @param provider Unique provider Id
  /// @param wallet Provider's wallet
  function register(bytes32 provider, address wallet) external onlyLive {
    if (providers[provider] != address(0)) {
      revert ProviderExists();
    }
    providers[provider] = wallet;
    emit Provider(provider, wallet);
  }

  /// @dev Update the provider
  /// @param provider Unique provider Id
  /// @param wallet Provider's wallet
  function updateProvider(bytes32 provider, address wallet) external onlyLive {
    if (msg.sender != providers[provider]) {
      revert NotAuthorized();
    }
    providers[provider] = wallet;
    emit Provider(provider, wallet);
  }

  // --- deals

  /// @dev Makes a deal
  /// @param provider Unique provider Id
  /// @param serviceId Unique service Id
  /// @param expiry The timestamp at which the deal is no longer valid
  /// @param asset The address of the proper Asset implementation
  /// @param permit Data required for making of payment with tokens using permit
  function _deal(
    bytes32 provider,
    bytes32 serviceId,
    uint256 expiry,
    address asset,
    uint256 value,
    Permit.EIP2612Permit memory permit
  ) internal onlyLive {
    // make sure provider registered
    if (providers[provider] == address(0)) {
      revert ProviderNotFound(provider);
    }

    DealStorage storage dealStorage = deals[serviceId];

    // make sure the deal has not been created before
    if (dealStorage.state != State.UNINITIALIZED) {
      revert DealExists(serviceId);
    }

    // make sure the deal is not expired
    if (expiry < block.timestamp) {
      revert DealExpired(serviceId, expiry);
    }

    AssetLike assetInstance = AssetLike(asset);
    address assetAddress = assetInstance.asset();

    // when asset is `wrapped` we should try to `wrap` native tokens
    if (assetInstance.wrapped() > 0 && msg.value > 0) {
      if (msg.value != value) {
        revert InvalidValue();
      }
      assetInstance.joinWrapped{value: msg.value}(providers[provider], value);
    } else if (permit.owner != address(0)) {
      // we have a permission from the customer, so, use it
      assetInstance.join(msg.sender, providers[provider], value, permit);
    } else {
      // normal asset joining
      assetInstance.join(msg.sender, providers[provider], value);
    }

    dealStorage.provider = provider;
    dealStorage.customer = msg.sender;
    dealStorage.asset = assetAddress;
    dealStorage.value = value;
    dealStorage.state = State.PAID;

    emit Deal(provider, serviceId);
  }

  // `deal` version without `permit` functionality
  function deal(
    bytes32 provider,
    bytes32 serviceId,
    uint256 expiry,
    address asset,
    uint256 value
  ) external payable onlyLive {
    _deal(provider, serviceId, expiry, asset, value, Permit.EIP2612Permit(address(0), 0, 0, bytes32(0), bytes32(0)));
  }

  // `deal` version with `permit`
  function deal(
    bytes32 provider,
    bytes32 serviceId,
    uint256 expiry,
    address asset,
    uint256 value,
    Permit.EIP2612Permit memory permit
  ) external onlyLive {
    _deal(provider, serviceId, expiry, asset, value, permit);
  }

  /// @dev Refunds a deal
  /// @param serviceId Unique service Id
  /// @param asset The Asset contract reference
  function refund(bytes32 serviceId, address asset) external onlyLive {
    DealStorage storage dealStorage = deals[serviceId];

    // make sure the deal is exists
    if (dealStorage.state == State.UNINITIALIZED) {
      revert DealNotFound(serviceId);
    }

    // make sure function called by the proper provider
    if (msg.sender != providers[dealStorage.provider]) {
      revert NotAuthorized();
    }

    // make sure the deal has not been refunded
    if (dealStorage.state == State.REFUNDED) {
      revert DealAlreadyRefunded(serviceId);
    }

    // check provider's balance
    if (ledger.balances(providers[dealStorage.provider], dealStorage.asset) < dealStorage.value) {
      revert BalanceNotEnough();
    }

    // finalize the deal state
    dealStorage.state = State.REFUNDED;

    // take funds from the providers' account to the WinPay contract
    ledger.move(providers[dealStorage.provider], address(this), dealStorage.asset, dealStorage.value);
    // ...and send them to the customer
    AssetLike(asset).exit(dealStorage.customer, dealStorage.value);

    emit Refund(dealStorage.provider, serviceId);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Manageable} from './Manageable.sol';

contract Ledger is Manageable {
  /// @dev Balances
  mapping(address => mapping(address => uint256)) public balances; // EOA => asset address => balance

  constructor() {
    auth[msg.sender] = 1;
    live = 1;
    emit Rely(msg.sender);
  }

  /// @dev Adds or subtract value of the asset
  /// @param dest Balance owner address
  /// @param asset Asset contract address
  /// @param value Asset value
  function add(
    address dest,
    address asset,
    int256 value
  ) external onlyLive authorized {
    balances[dest][asset] = _add(balances[dest][asset], value);
  }

  /// @dev Move balance from the source to destination
  /// @param src Balance owner address
  /// @param dest Destination address
  /// @param asset Asset contract address
  /// @param value Asset value
  function move(
    address src,
    address dest,
    address asset,
    uint256 value
  ) external onlyLive authorized {
    balances[src][asset] = _add(balances[src][asset], -int256(value));
    balances[dest][asset] = _add(balances[dest][asset], int256(value));
  }

  // --- helpers
  function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x + uint256(y);
      require(y >= 0 || z <= x);
      require(y <= 0 || z >= x);
    }
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {Ledger} from '../Ledger.sol';
import {Upgradeable} from './Upgradeable.sol';

contract LedgerUpgradeable is Upgradeable, Ledger {
  constructor() Ledger() {}

  function postUpgrade() public onlyUpgrader {
    auth[msg.sender] = 1;
    live = 1;
    emit Rely(msg.sender);
  }

  uint256[50] private __gap;
}