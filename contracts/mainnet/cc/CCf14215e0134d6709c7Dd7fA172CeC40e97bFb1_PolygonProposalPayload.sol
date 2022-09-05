// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from './interfaces/IERC20.sol';
import {ICollectorController} from './interfaces/ICollectorController.sol';
import {IInitializableAdminUpgradeabilityProxy} from './interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {IProposalGenericExecutor} from './IProposalGenericExecutor.sol';

contract PolygonProposalPayload is IProposalGenericExecutor {
  address public constant AAVE_COMPANIES_ADDRESS = 0x48B9e6E865eBff2B76d9a85c10b7FA6772607F0b;

  ICollectorController public constant CONTROLLER_OF_COLLECTOR =
    ICollectorController(0xDB89487A449274478e984665b8692AfC67459deF);

  address public constant COLLECTOR_ADDRESS = 0x7734280A4337F37Fbf4651073Db7c28C80B339e9;
  address public constant COLLECTOR_ADDRESS_V3 = 0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383;
  address public constant COLLECTOR_IMPLEMENTATION_ADDRESS =
    0xC773bf5a987b29DdEAC77cf1D48a22a4Ce5B0577;

  function execute() external override {
    // 1. Upgrade of Collector V2 and V3
    bytes memory initData = abi.encodeWithSignature('initialize(address)', CONTROLLER_OF_COLLECTOR);
    IInitializableAdminUpgradeabilityProxy(COLLECTOR_ADDRESS).upgradeToAndCall(
      COLLECTOR_IMPLEMENTATION_ADDRESS,
      initData
    );
    IInitializableAdminUpgradeabilityProxy(COLLECTOR_ADDRESS_V3).upgradeToAndCall(
      COLLECTOR_IMPLEMENTATION_ADDRESS,
      initData
    );

    // 2. Transfer Collector assets
    address[2] memory ASSETS_V2 = [
      0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4, // amWMATIC
      0x5c2ed810328349100A66B82b78a1791B101C9D61 // amWBTC
    ];
    uint256[] memory ASSETS_V2_AMOUNTS = new uint256[](2);
    ASSETS_V2_AMOUNTS[0] = 850000000000000000000000; // 850000.000000000000000000 amWMATIC
    ASSETS_V2_AMOUNTS[1] = 1665609037; // 16.65609037 amWBTC

    for (uint256 i = 0; i < ASSETS_V2.length; i++) {
      CONTROLLER_OF_COLLECTOR.transfer(
        COLLECTOR_ADDRESS,
        IERC20(ASSETS_V2[i]),
        AAVE_COMPANIES_ADDRESS,
        ASSETS_V2_AMOUNTS[i]
      );
    }

    emit ProposalExecuted();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface ICollectorController {
  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param collector The address of the collector contract to retrieve funds from (e.g. Aave ecosystem reserve)
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    address collector,
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IInitializableAdminUpgradeabilityProxy {
  function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

  function upgradeTo(address newImplementation) external payable;

  function admin() external returns (address);

  function implementation() external returns (address);

  function changeAdmin(address newAdmin) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IProposalGenericExecutor {
  function execute() external;

  event ProposalExecuted();
}