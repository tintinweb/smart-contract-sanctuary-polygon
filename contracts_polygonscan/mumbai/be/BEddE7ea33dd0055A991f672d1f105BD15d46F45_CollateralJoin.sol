/**
 *Submitted for verification at polygonscan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File contracts/CollateralJoin.sol
pragma solidity ^0.8.2;

interface TokenLike {
  function decimals() external view returns (uint8);

  function transfer(address, uint256) external returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);
}

interface LedgerLike {
  function modifyCollateral(
    bytes32,
    address,
    int256
  ) external;
}

contract CollateralJoin is Initializable {
  mapping(address => uint256) public authorizedAccounts;
  LedgerLike public ledger; // CDP Engine
  bytes32 public collateralType; // Collateral Type
  TokenLike public collateral;
  uint256 public decimals;
  uint256 public live; // Active Flag

  // --- Events ---
  event GrantAuthorization(address indexed account);
  event RevokeAuthorization(address indexed account);
  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  function initialize(
    address ledger_,
    bytes32 collateralType_,
    address collateral_
  ) public initializer {
    authorizedAccounts[msg.sender] = 1;
    live = 1;
    ledger = LedgerLike(ledger_);
    collateralType = collateralType_;
    collateral = TokenLike(collateral_);
    decimals = collateral.decimals();
    emit GrantAuthorization(msg.sender);
  }

  // --- Auth ---
  function grantAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 1;
    emit GrantAuthorization(user);
  }

  function revokeAuthorization(address user) external isAuthorized {
    authorizedAccounts[user] = 0;
    emit RevokeAuthorization(user);
  }

  modifier isAuthorized() {
    require(
      authorizedAccounts[msg.sender] == 1,
      "CollateralJoin/not-authorized"
    );
    _;
  }

  function shutdown() external isAuthorized {
    live = 0;
  }

  function deposit(address user, uint256 wad) external {
    require(live == 1, "CollateralJoin/not-live");
    require(int256(wad) >= 0, "CollateralJoin/overflow");
    ledger.modifyCollateral(collateralType, user, int256(wad));
    require(
      collateral.transferFrom(msg.sender, address(this), wad),
      "CollateralJoin/failed-transfer"
    );
    emit Deposit(user, wad);
  }

  function withdraw(address user, uint256 wad) external {
    require(wad <= 2**255, "CollateralJoin/overflow");
    ledger.modifyCollateral(collateralType, msg.sender, -int256(wad));
    require(collateral.transfer(user, wad), "CollateralJoin/failed-transfer");
    emit Withdraw(user, wad);
  }
}