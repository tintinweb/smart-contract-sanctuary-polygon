// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from './IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";
import {AccountMessages} from "../message.sol";
import {Validator} from "../../validator.sol";
import {IRegistrar} from "../../registrar/interfaces/IRegistrar.sol";
import {Array} from "../../../lib/array.sol";
import {ReentrancyGuardFacet} from "./ReentrancyGuardFacet.sol";
import {IAccountsEvents} from "../interfaces/IAccountsEvents.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IAccountsUpdateEndowments} from "../interfaces/IAccountsUpdateEndowments.sol";

/**
 * @title AccountsUpdateEndowments
 * @notice This contract facet updates the endowments
 * @dev This contract facet updates the endowments, updates rights are with owner of accounts contracts (AP Team Multisig) and the endowment owner
 */
contract AccountsUpdateEndowments is
  IAccountsUpdateEndowments,
  ReentrancyGuardFacet,
  IAccountsEvents
{
  /**
    @notice Updates the endowment details.
    @dev This function allows the Endowment owner to update the endowment details like owner & rebalance and allows them or their Delegate(s) to update name, sdgs, logo, and image.
    @param details UpdateEndowmentDetailsRequest struct containing the updated endowment details.
    */
  function updateEndowmentDetails(
    AccountMessages.UpdateEndowmentDetailsRequest memory details
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[details.id];

    require(!state.STATES[details.id].closingEndowment, "UpdatesAfterClosed");

    if (
      Validator.canChange(
        tempEndowment.settingsController.name,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.name = details.name;
    }

    if (
      Validator.canChange(
        tempEndowment.settingsController.sdgs,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      if (
        details.sdgs.length == 0 && tempEndowment.endowType == LibAccounts.EndowmentType.Charity
      ) {
        revert("InvalidInputs");
      }
      if (details.sdgs.length != 0) {
        details.sdgs = Array.sort(details.sdgs);
        for (uint256 i = 0; i < details.sdgs.length; i++) {
          if (details.sdgs[i] > 17 || details.sdgs[i] == 0) {
            revert("InvalidInputs");
          }
        }
      }
      tempEndowment.sdgs = details.sdgs;
    }

    if (
      Validator.canChange(
        tempEndowment.settingsController.logo,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.logo = details.logo;
    }

    if (
      Validator.canChange(
        tempEndowment.settingsController.image,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.image = details.image;
    }

    // there are several fields that are restricted to changing only by the Endowment Owner
    if (msg.sender == tempEndowment.owner) {
      // Field `owner` MUST be updated *last*, as otherwise no other endowment field would be updateable due to following:
      // 1. Current owner (multisig) sends request to update endowment owner to DAO address and let's say it
      // also wants to update `image`
      // 2. Field `image` has no delegate and is unlocked, so only `owner` can update it
      // 3. Owner update check passes and is updated to DAO address
      // 4. Contract gets to updating `image`, but first needs to check whether the field can be updated
      // 5. It sees that the current sender (previous owner, Multisig) is NOT the current owner of the endowment
      //    (as it was updated in the previous step to DAO address)
      // 6. Check for `image` fails and the update is skipped
      if (
        details.owner != address(0) &&
        (details.owner == tempEndowment.dao || details.owner == tempEndowment.multisig)
      ) {
        tempEndowment.owner = details.owner;
      }

      if (tempEndowment.endowType != LibAccounts.EndowmentType.Charity) {
        tempEndowment.rebalance = details.rebalance;
      }
    }

    state.ENDOWMENTS[details.id] = tempEndowment;
    emit EndowmentUpdated(details.id);
  }

  /**
    @notice Updates the delegate for a specific endowment setting
    @dev This function allows authorized users to update the delegate for a specific endowment setting
    @param id The ID of the endowment
    @param setting The setting for which to update the delegate
    @param action The action to perform (set/revoke)
    @param delegateAddress The address of the delegate to add/revoke
    @param delegateExpiry The timestamp at which the delegate's permission expires
    */
  function updateDelegate(
    uint32 id,
    ControllerSettingOption setting,
    LibAccounts.DelegateAction action,
    address delegateAddress,
    uint256 delegateExpiry
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[id];

    require(!state.STATES[id].closingEndowment, "UpdatesAfterClosed");

    LibAccounts.Delegate memory newDelegate;
    if (action == LibAccounts.DelegateAction.Set) {
      newDelegate = LibAccounts.Delegate({addr: delegateAddress, expires: delegateExpiry});
    } else if (action == LibAccounts.DelegateAction.Revoke) {
      newDelegate = LibAccounts.Delegate({addr: address(0), expires: 0});
    } else {
      revert("Invalid action passed");
    }

    if (setting == ControllerSettingOption.LockedInvestmentManagement) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.lockedInvestmentManagement,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.lockedInvestmentManagement.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.LiquidInvestmentManagement) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.liquidInvestmentManagement,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.liquidInvestmentManagement.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.AcceptedTokens) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.acceptedTokens,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.acceptedTokens.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.AllowlistedBeneficiaries) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.allowlistedBeneficiaries,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.allowlistedBeneficiaries.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.AllowlistedContributors) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.allowlistedContributors,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.allowlistedContributors.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.MaturityAllowlist) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.maturityAllowlist,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.maturityAllowlist.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.MaturityTime) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.maturityTime,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.maturityTime.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.WithdrawFee) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.withdrawFee,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.withdrawFee.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.EarlyLockedWithdrawFee) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.earlyLockedWithdrawFee,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.earlyLockedWithdrawFee.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.DepositFee) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.depositFee,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.depositFee.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.BalanceFee) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.balanceFee,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.balanceFee.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.Name) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.name,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.name.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.Image) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.image,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.image.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.Logo) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.logo,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.logo.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.Sdgs) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.sdgs,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.sdgs.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.SplitToLiquid) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.splitToLiquid,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.splitToLiquid.delegate = newDelegate;
    } else if (setting == ControllerSettingOption.IgnoreUserSplits) {
      require(
        Validator.canChange(
          tempEndowment.settingsController.ignoreUserSplits,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        ),
        "Unauthorized"
      );
      tempEndowment.settingsController.ignoreUserSplits.delegate = newDelegate;
    } else {
      revert("Invalid setting input");
    }
    state.ENDOWMENTS[id] = tempEndowment;
    emit EndowmentUpdated(id);
  }

  /**
    @notice Updates the endowment-level list of accepted tokens with a status for the given ERC20 Token address & Chainlink Price Feed contract address.
    @dev This function allows the Endowment owner, or a valid delegate, to add/update accepted tokens for an Endowment's Deposits & Withdrawals.
    * @param endowId Endowment ID
    * @param tokenAddr Token address to add/update in AcceptedTokens
    * @param priceFeedAddr Chainlink Price Feed contract address for accepted token to fetch USD price data
    * @param tokenStatus Boolean status to set for the token Address in AcceptedTokens
    */
  function updateAcceptedToken(
    uint32 endowId,
    address tokenAddr,
    address priceFeedAddr,
    bool tokenStatus
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[endowId];

    require(tokenAddr != address(0), "Invalid token address passed");
    require(priceFeedAddr != address(0), "Invalid priceFeed address passed");
    require(!state.STATES[endowId].closingEndowment, "UpdatesAfterClosed");
    require(
      Validator.canChange(
        tempEndowment.settingsController.acceptedTokens,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      ),
      "Unauthorized"
    );
    // Check that the deposited token is NOT in the protocol-level accepted tokens list in the Registrar Contract
    // These are globally set and cannot be modified/overridden by endowments
    require(
      !IRegistrar(state.config.registrarContract).isTokenAccepted(tokenAddr),
      "Cannot add tokens already in the Registrar AcceptedTokens list"
    );
    // check that the price feed contract address supports ERC-165
    require(
      ERC165Checker.supportsInterface(priceFeedAddr, LibAccounts.InterfaceId_ERC165),
      "Price Feed contract is not a valid ERC-165 interface"
    );
    state.PriceFeeds[endowId][tokenAddr] = priceFeedAddr;
    state.AcceptedTokens[endowId][tokenAddr] = tokenStatus;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (SEity/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";

/**
 * @title ReentrancyGuardFacet
 *
 * @notice This contract facet prevents reentrancy attacks
 * @dev Uses a global mutex and prevents reentrancy.
 */
abstract contract ReentrancyGuardFacet {
  // bool private constant _NOT_ENTERED = false;
  // bool private constant _ENTERED = true;

  // Allows rentrant calls from self
  modifier nonReentrant() {
    _nonReentrantBefore();
    _;
    _nonReentrantAfter();
  }

  /**
   * @notice Prevents a contract from calling itself, directly or indirectly.
   * @dev To be called when entering a function that uses nonReentrant.
   */
  function _nonReentrantBefore() private {
    // On the first call to nonReentrant, _status will be _NOT_ENTERED
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    require(
      !state.config.reentrancyGuardLocked || (address(this) == msg.sender),
      "ReentrancyGuard: reentrant call"
    );

    // Any calls to nonReentrant after this point will fail
    if (address(this) != msg.sender) {
      state.config.reentrancyGuardLocked = true;
    }
  }

  /**
   * @notice Prevents a contract from calling itself, directly or indirectly.
   * @dev To be called when exiting a function that uses nonReentrant.
   */
  function _nonReentrantAfter() private {
    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    AccountStorage.State storage state = LibAccounts.diamondStorage();

    if (address(this) != msg.sender) {
      state.config.reentrancyGuardLocked = false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {LibAccounts} from "../lib/LibAccounts.sol";

interface IAccountsEvents {
  event DaoContractCreated(uint32 endowId, address daoAddress);
  event DonationDeposited(uint256 endowId, address tokenAddress, uint256 amount);
  event DonationWithdrawn(uint256 endowId, address recipient, address tokenAddress, uint256 amount);
  event AllowanceSpent(uint256 endowId, address spender, address tokenAddress, uint256 amount);
  event AllowanceUpdated(
    uint256 endowId,
    address spender,
    address tokenAddress,
    uint256 newBalance,
    uint256 added,
    uint256 deducted
  );
  event EndowmentCreated(uint256 endowId, LibAccounts.EndowmentType endowType);
  event EndowmentUpdated(uint256 endowId);
  event EndowmentClosed(uint256 endowId);
  event EndowmentDeposit(
    uint256 endowId,
    address tokenAddress,
    uint256 amountLocked,
    uint256 amountLiquid
  );
  event EndowmentWithdraw(
    uint256 endowId,
    address tokenAddress,
    uint256 amount,
    IVault.VaultType accountType,
    address beneficiaryAddress,
    uint32 beneficiaryEndowId
  );
  event ConfigUpdated();
  event OwnerUpdated(address owner);
  event DonationMatchCreated(uint256 endowId, address donationMatchContract);
  event TokenSwapped(
    uint256 endowId,
    IVault.VaultType accountType,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOut
  );
  event EndowmentSettingUpdated(uint256 endowId, string setting);
  event EndowmentInvested(IVault.VaultActionStatus);
  event EndowmentRedeemed(IVault.VaultActionStatus);
  event RefundNeeded(IVault.VaultActionData);
  event UnexpectedTokens(IVault.VaultActionData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {AccountMessages} from "../message.sol";

/**
 * @title AccountsStrategy
 */
interface IAccountsStrategy {
  error InvestFailed(IVault.VaultActionStatus);
  error RedeemFailed(IVault.VaultActionStatus);
  error RedeemAllFailed(IVault.VaultActionStatus);
  error UnexpectedResponse(IVault.VaultActionData);
  error UnexpectedCaller(IVault.VaultActionData, string, string);

  struct NetworkInfo {
    uint256 chainId;
    address router; //SHARED
    address axelarGateway;
    string ibcChannel; // Should be removed
    string transferChannel;
    address gasReceiver;
    uint256 gasLimit; // Should be used to set gas limit
  }

  /**
   * @notice This function that allows users to deposit into a yield strategy using tokens from their locked or liquid account in an endowment.
   * @dev Allows the owner of an endowment to invest tokens into specified yield vaults.
   * @param id The endowment id
   */
  function strategyInvest(uint32 id, AccountMessages.InvestRequest memory investRequest) external;

  /**
   * @notice Allows an endowment owner to redeem their funds from multiple yield strategies.
   * @param id  The endowment ID
   */
  function strategyRedeem(uint32 id, AccountMessages.RedeemRequest memory redeemRequest) external;

  /**
   * @notice Allows an endowment owner to redeem their funds from multiple yield strategies.
   * @param id  The endowment ID
   */
  function strategyRedeemAll(
    uint32 id,
    AccountMessages.RedeemAllRequest memory redeemAllRequest
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountMessages} from "../message.sol";
import {LibAccounts} from "../lib/LibAccounts.sol";

/**
 * @title AccountsUpdateEndowments
 * @notice This contract facet updates the endowments
 * @dev This contract facet updates the endowments, updates rights are with owner of accounts contracts (AP Team Multisig) and the endowment owner
 */
interface IAccountsUpdateEndowments {
  enum ControllerSettingOption {
    AcceptedTokens,
    LockedInvestmentManagement,
    LiquidInvestmentManagement,
    AllowlistedBeneficiaries,
    AllowlistedContributors,
    MaturityAllowlist,
    EarlyLockedWithdrawFee,
    MaturityTime,
    WithdrawFee,
    DepositFee,
    BalanceFee,
    Name,
    Image,
    Logo,
    Sdgs,
    SplitToLiquid,
    IgnoreUserSplits
  }

  /**
    @notice Updates the endowment details.
    @dev This function allows the Endowment owner to update the endowment details like owner & rebalance and allows them or their Delegate(s) to update name, sdgs, logo, and image.
    @param details UpdateEndowmentDetailsRequest struct containing the updated endowment details.
    */
  function updateEndowmentDetails(
    AccountMessages.UpdateEndowmentDetailsRequest memory details
  ) external;

  /**
    @notice Updates the delegate for a specific endowment setting
    @dev This function allows authorized users to update the delegate for a specific endowment setting
    @param id The ID of the endowment
    @param setting The setting for which to update the delegate
    @param action The action to perform (set/revoke)
    @param delegateAddress The address of the delegate to add/revoke
    @param delegateExpiry The timestamp at which the delegate's permission expires
    */
  function updateDelegate(
    uint32 id,
    ControllerSettingOption setting,
    LibAccounts.DelegateAction action,
    address delegateAddress,
    uint256 delegateExpiry
  ) external;

  /**
    @notice Updates the endowment-level list of accepted tokens with a status for the given ERC20 Token address & Chainlink Price Feed contract address.
    @dev This function allows the Endowment owner, or a valid delegate, to add/update accepted tokens for an Endowment's Deposits & Withdrawals.
    * @param endowId Endowment ID
    * @param tokenAddr Token address to add/update in AcceptedTokens
    * @param priceFeedAddr Chainlink Price Feed contract address for accepted token to fetch USD price data
    * @param tokenStatus Boolean status to set for the token Address in AcceptedTokens
    */
  function updateAcceptedToken(
    uint32 endowId,
    address tokenAddr,
    address priceFeedAddr,
    bool tokenStatus
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountStorage} from "../storage.sol";

library LibAccounts {
  bytes32 constant AP_ACCOUNTS_DIAMOND_STORAGE_POSITION = keccak256("accounts.diamond.storage");

  function diamondStorage() internal pure returns (AccountStorage.State storage ds) {
    bytes32 position = AP_ACCOUNTS_DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  enum EndowmentType {
    Charity,
    Normal
  }

  enum Tier {
    None,
    Level1,
    Level2,
    Level3
  }

  struct BalanceInfo {
    mapping(address => uint256) locked;
    mapping(address => uint256) liquid;
  }

  struct BeneficiaryData {
    uint32 endowId;
    uint256 fundId;
    address addr;
  }

  enum BeneficiaryEnum {
    EndowmentId,
    IndexFund,
    Wallet,
    None
  }

  struct Beneficiary {
    BeneficiaryData data;
    BeneficiaryEnum enumData;
  }

  struct SplitDetails {
    uint256 max;
    uint256 min;
    uint256 defaultSplit; // for when a user splits are not used
  }

  struct Delegate {
    address addr;
    uint256 expires; // datetime int of delegation expiry
  }

  enum DelegateAction {
    Set,
    Revoke
  }

  struct SettingsPermission {
    bool locked;
    Delegate delegate;
  }

  struct SettingsController {
    SettingsPermission acceptedTokens;
    SettingsPermission lockedInvestmentManagement;
    SettingsPermission liquidInvestmentManagement;
    SettingsPermission allowlistedBeneficiaries;
    SettingsPermission allowlistedContributors;
    SettingsPermission maturityAllowlist;
    SettingsPermission maturityTime;
    SettingsPermission earlyLockedWithdrawFee;
    SettingsPermission withdrawFee;
    SettingsPermission depositFee;
    SettingsPermission balanceFee;
    SettingsPermission name;
    SettingsPermission image;
    SettingsPermission logo;
    SettingsPermission sdgs;
    SettingsPermission splitToLiquid;
    SettingsPermission ignoreUserSplits;
  }

  enum FeeTypes {
    Default,
    Harvest,
    WithdrawCharity,
    WithdrawNormal,
    EarlyLockedWithdrawCharity,
    EarlyLockedWithdrawNormal
  }

  struct FeeSetting {
    address payoutAddress;
    uint256 bps;
  }

  uint256 constant FEE_BASIS = 10000; // gives 0.01% precision for fees (ie. Basis Points)
  uint256 constant PERCENT_BASIS = 100; // gives 1% precision for declared percentages
  uint256 constant BIG_NUMBA_BASIS = 1e24;

  // Interface IDs
  bytes4 constant InterfaceId_Invalid = 0xffffffff;
  bytes4 constant InterfaceId_ERC165 = 0x01ffc9a7;
  bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "./lib/LibAccounts.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountMessages {
  struct CreateEndowmentRequest {
    bool withdrawBeforeMaturity;
    uint256 maturityTime;
    string name;
    uint256[] sdgs;
    LibAccounts.Tier tier;
    LibAccounts.EndowmentType endowType;
    string logo;
    string image;
    address[] members;
    uint256 threshold;
    uint256 duration;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    LibAccounts.FeeSetting earlyLockedWithdrawFee;
    LibAccounts.FeeSetting withdrawFee;
    LibAccounts.FeeSetting depositFee;
    LibAccounts.FeeSetting balanceFee;
    uint256 proposalLink;
    LibAccounts.SettingsController settingsController;
    uint32 parent;
    address[] maturityAllowlist;
    bool ignoreUserSplits;
    LibAccounts.SplitDetails splitToLiquid;
    uint256 referralId;
  }

  struct UpdateEndowmentSettingsRequest {
    uint32 id;
    bool donationMatchActive;
    uint256 maturityTime;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    address[] maturity_allowlist_add;
    address[] maturity_allowlist_remove;
    LibAccounts.SplitDetails splitToLiquid;
    bool ignoreUserSplits;
  }

  struct UpdateEndowmentControllerRequest {
    uint32 id;
    LibAccounts.SettingsController settingsController;
  }

  struct UpdateEndowmentDetailsRequest {
    uint32 id;
    address owner;
    string name;
    uint256[] sdgs;
    string logo;
    string image;
    LocalRegistrarLib.RebalanceParams rebalance;
  }

  struct Strategy {
    string vault; // Vault SC Address
    uint256 percentage; // percentage of funds to invest
  }

  struct UpdateProfileRequest {
    uint32 id;
    string overview;
    string url;
    string registrationNumber;
    string countryOfOrigin;
    string streetAddress;
    string contactEmail;
    string facebook;
    string twitter;
    string linkedin;
    uint16 numberOfEmployees;
    string averageAnnualBudget;
    string annualRevenue;
    string charityNavigatorRating;
  }

  ///TODO: response struct should be below this

  struct ConfigResponse {
    address owner;
    string version;
    address registrarContract;
    uint256 nextAccountId;
    uint256 maxGeneralCategoryId;
    address subDao;
    address gateway;
    address gasReceiver;
    LibAccounts.FeeSetting earlyLockedWithdrawFee;
  }

  struct StateResponse {
    bool closingEndowment;
    LibAccounts.Beneficiary closingBeneficiary;
  }

  struct EndowmentDetailsResponse {
    address owner;
    address dao;
    address daoToken;
    string description;
    LibAccounts.EndowmentType endowType;
    uint256 maturityTime;
    LocalRegistrarLib.RebalanceParams rebalance;
    address donationMatchContract;
    address[] maturityAllowlist;
    string logo;
    string image;
    string name;
    uint256[] sdgs;
    LibAccounts.Tier tier;
    uint256 copycatStrategy;
    uint256 proposalLink;
    uint256 parent;
    LibAccounts.SettingsController settingsController;
  }

  struct DepositRequest {
    uint32 id;
    uint256 lockedPercentage;
    uint256 liquidPercentage;
  }

  struct InvestRequest {
    bytes4 strategy;
    string token;
    uint256 lockAmt;
    uint256 liquidAmt;
    uint256 gasFee;
  }

  struct RedeemRequest {
    bytes4 strategy;
    string token;
    uint256 lockAmt;
    uint256 liquidAmt;
    uint256 gasFee;
  }

  struct RedeemAllRequest {
    bytes4 strategy;
    string token;
    bool redeemLocked;
    bool redeemLiquid;
    uint256 gasFee;
  }

  struct UpdateFeeSettingRequest {
    uint32 id;
    LibAccounts.FeeSetting earlyLockedWithdrawFee;
    LibAccounts.FeeSetting depositFee;
    LibAccounts.FeeSetting withdrawFee;
    LibAccounts.FeeSetting balanceFee;
  }

  enum DonationMatchEnum {
    HaloTokenReserve,
    Cw20TokenReserve
  }

  struct DonationMatchData {
    address reserveToken;
    address uniswapFactory;
    uint24 poolFee;
  }

  struct DonationMatch {
    DonationMatchEnum enumData;
    DonationMatchData data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "./lib/LibAccounts.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountStorage {
  struct Config {
    address owner;
    string version;
    string networkName;
    address registrarContract;
    uint32 nextAccountId;
    uint256 maxGeneralCategoryId;
    address subDao;
    address gateway;
    address gasReceiver;
    bool reentrancyGuardLocked;
    LibAccounts.FeeSetting earlyLockedWithdrawFee;
  }

  struct Endowment {
    address owner;
    string name; // name of the Endowment
    uint256[] sdgs;
    LibAccounts.Tier tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
    LibAccounts.EndowmentType endowType;
    string logo;
    string image;
    uint256 maturityTime; // datetime int of endowment maturity
    LocalRegistrarLib.RebalanceParams rebalance; // parameters to guide rebalancing & harvesting of gains from locked/liquid accounts
    uint256 proposalLink; // link back the Applications Team Multisig Proposal that created an endowment (if a Charity)
    address multisig;
    address dao;
    address daoToken;
    bool donationMatchActive;
    address donationMatchContract;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    address[] maturityAllowlist;
    LibAccounts.FeeSetting earlyLockedWithdrawFee;
    LibAccounts.FeeSetting withdrawFee;
    LibAccounts.FeeSetting depositFee;
    LibAccounts.FeeSetting balanceFee;
    LibAccounts.SettingsController settingsController;
    uint32 parent;
    bool ignoreUserSplits;
    LibAccounts.SplitDetails splitToLiquid;
    uint256 referralId;
    address gasFwd;
  }

  struct EndowmentState {
    LibAccounts.BalanceInfo balances;
    bool closingEndowment;
    LibAccounts.Beneficiary closingBeneficiary;
    mapping(bytes4 => bool) activeStrategies;
  }

  struct TokenAllowances {
    uint256 totalOutstanding;
    // spender Addr -> amount
    mapping(address => uint256) bySpender;
  }

  struct State {
    mapping(uint32 => uint256) DAOTOKENBALANCE;
    mapping(uint32 => EndowmentState) STATES;
    mapping(uint32 => Endowment) ENDOWMENTS;
    // endow ID -> token Addr -> TokenAllowances
    mapping(uint32 => mapping(address => TokenAllowances)) ALLOWANCES;
    // endow ID -> token Addr -> bool
    mapping(uint32 => mapping(address => bool)) AcceptedTokens;
    // endow ID -> token Addr -> Price Feed Addr
    mapping(uint32 => mapping(address => address)) PriceFeeds;
    Config config;
  }
}

contract Storage {
  AccountStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {LocalRegistrarLib} from "../lib/LocalRegistrarLib.sol";
import {LibAccounts} from "../../accounts/lib/LibAccounts.sol";

interface ILocalRegistrar {
  /*////////////////////////////////////////////////
                        EVENTS
    */ ////////////////////////////////////////////////
  event RebalanceParamsUpdated();
  event AngelProtocolParamsUpdated();
  event AccountsContractStorageUpdated(string _chainName, string _accountsContractAddress);
  event TokenAcceptanceUpdated(address _tokenAddr, bool _isAccepted);
  event StrategyApprovalUpdated(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event StrategyParamsUpdated(
    bytes4 _strategyId,
    string _network,
    address _lockAddr,
    address _liqAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  );
  event GasFeeUpdated(address _tokenAddr, uint256 _gasFee);
  event FeeSettingsUpdated(LibAccounts.FeeTypes _feeType, uint256 _bpsRate, address _payoutAddress);

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */ ////////////////////////////////////////////////

  // View methods for returning stored params
  function getRebalanceParams() external view returns (LocalRegistrarLib.RebalanceParams memory);

  function getAngelProtocolParams()
    external
    view
    returns (LocalRegistrarLib.AngelProtocolParams memory);

  function getAccountsContractAddressByChain(
    string calldata _targetChain
  ) external view returns (string memory);

  function getStrategyParamsById(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyParams memory);

  function isTokenAccepted(address _tokenAddr) external view returns (bool);

  function getGasByToken(address _tokenAddr) external view returns (uint256);

  function getStrategyApprovalState(
    bytes4 _strategyId
  ) external view returns (LocalRegistrarLib.StrategyApprovalState);

  function getFeeSettingsByFeeType(
    LibAccounts.FeeTypes _feeType
  ) external view returns (LibAccounts.FeeSetting memory);

  function getVaultOperatorApproved(address _operator) external view returns (bool);

  // Setter methods for granular changes to specific params
  function setRebalanceParams(LocalRegistrarLib.RebalanceParams calldata _rebalanceParams) external;

  function setAngelProtocolParams(
    LocalRegistrarLib.AngelProtocolParams calldata _angelProtocolParams
  ) external;

  function setAccountsContractAddressByChain(
    string memory _chainName,
    string memory _accountsContractAddress
  ) external;

  /// @notice Change whether a strategy is approved
  /// @dev Set the approval bool for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  function setStrategyApprovalState(
    bytes4 _strategyId,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  /// @notice Change which pair of vault addresses a strategy points to
  /// @dev Set the approval bool and both locked/liq vault addrs for a specified strategyId.
  /// @param _strategyId a uid for each strategy set by:
  /// bytes4(keccak256("StrategyName"))
  /// @param _liqAddr address to a comptaible Liquid type Vault
  /// @param _lockAddr address to a compatible Locked type Vault
  function setStrategyParams(
    bytes4 _strategyId,
    string memory _network,
    address _liqAddr,
    address _lockAddr,
    LocalRegistrarLib.StrategyApprovalState _approvalState
  ) external;

  function setTokenAccepted(address _tokenAddr, bool _isAccepted) external;

  function setGasByToken(address _tokenAddr, uint256 _gasFee) external;

  function setFeeSettingsByFeesType(
    LibAccounts.FeeTypes _feeType,
    uint256 _rate,
    address _payout
  ) external;

  function setVaultOperatorApproved(address _operator, bool _isApproved) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {ILocalRegistrar} from "./ILocalRegistrar.sol";
import {IAccountsStrategy} from "../../accounts/interfaces/IAccountsStrategy.sol";

interface IRegistrar is ILocalRegistrar {
  function updateConfig(RegistrarMessages.UpdateConfigRequest memory details) external;

  function updateOwner(address newOwner) external;

  function updateTokenPriceFeed(address token, address priceFeed) external;

  function updateNetworkConnections(
    string memory networkName,
    IAccountsStrategy.NetworkInfo memory networkInfo,
    string memory action
  ) external;

  // Query functions for contract

  function queryConfig() external view returns (RegistrarStorage.Config memory);

  function queryTokenPriceFeed(address token) external view returns (address);

  function queryAllStrategies() external view returns (bytes4[] memory allStrategies);

  function queryNetworkConnection(
    string memory networkName
  ) external view returns (IAccountsStrategy.NetworkInfo memory response);

  function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IVault} from "../../vault/interfaces/IVault.sol";
import {LibAccounts} from "../../accounts/lib/LibAccounts.sol";

library LocalRegistrarLib {
  /*////////////////////////////////////////////////
                      DEPLOYMENT DEFAULTS
  */ ////////////////////////////////////////////////
  bool constant REBALANCE_LIQUID_PROFITS = false;
  uint32 constant LOCKED_REBALANCE_TO_LIQUID = 75; // 75%
  uint32 constant INTEREST_DISTRIBUTION = 20; // 20%
  bool constant LOCKED_PRINCIPLE_TO_LIQUID = false;
  uint32 constant PRINCIPLE_DISTRIBUTION = 0;
  uint32 constant BASIS = 100;

  // DEFAULT ANGEL PROTOCOL PARAMS
  address constant ROUTER_ADDRESS = address(0);
  address constant REFUND_ADDRESS = address(0);

  /*////////////////////////////////////////////////
                      CUSTOM TYPES
  */ ////////////////////////////////////////////////
  struct RebalanceParams {
    bool rebalanceLiquidProfits;
    uint32 lockedRebalanceToLiquid;
    uint32 interestDistribution;
    bool lockedPrincipleToLiquid;
    uint32 principleDistribution;
    uint32 basis;
  }

  struct AngelProtocolParams {
    address routerAddr;
    address refundAddr;
  }

  enum StrategyApprovalState {
    NOT_APPROVED,
    APPROVED,
    WITHDRAW_ONLY,
    DEPRECATED
  }

  struct StrategyParams {
    StrategyApprovalState approvalState;
    string network;
    VaultParams Locked;
    VaultParams Liquid;
  }

  struct VaultParams {
    IVault.VaultType Type;
    address vaultAddr;
  }

  struct LocalRegistrarStorage {
    address uniswapRouter;
    address uniswapFactory;
    RebalanceParams rebalanceParams;
    AngelProtocolParams angelProtocolParams;
    mapping(bytes32 => string) AccountsContractByChain;
    mapping(bytes4 => StrategyParams) VaultsByStrategyId;
    mapping(address => bool) AcceptedTokens;
    mapping(address => uint256) GasFeeByToken;
    mapping(LibAccounts.FeeTypes => LibAccounts.FeeSetting) FeeSettingsByFeeType;
    mapping(address => bool) ApprovedVaultOperators;
  }

  /*////////////////////////////////////////////////
                        STORAGE MGMT
    */ ////////////////////////////////////////////////
  bytes32 constant LOCAL_REGISTRAR_STORAGE_POSITION = keccak256("local.registrar.storage");

  function localRegistrarStorage() internal pure returns (LocalRegistrarStorage storage lrs) {
    bytes32 position = LOCAL_REGISTRAR_STORAGE_POSITION;
    assembly {
      lrs.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../accounts/lib/LibAccounts.sol";
import {IVault} from "../vault/interfaces/IVault.sol";

library RegistrarMessages {
  struct InstantiateRequest {
    address treasury;
    LibAccounts.SplitDetails splitToLiquid;
    address router;
    address axelarGateway;
    address axelarGasRecv;
  }

  struct UpdateConfigRequest {
    address accountsContract;
    uint256 splitMax;
    uint256 splitMin;
    uint256 splitDefault;
    uint256 collectorShare;
    // CONTRACT ADDRESSES
    address indexFundContract;
    address govContract;
    address treasury;
    address donationMatchCharitesContract;
    address donationMatchEmitter;
    address haloToken;
    address haloTokenLpContract;
    address charitySharesContract;
    address fundraisingContract;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityApplications;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address subdaoGovContract;
    address subdaoTokenContract;
    address subdaoBondingTokenContract;
    address subdaoCw900Contract;
    address subdaoDistributorContract;
    address subdaoEmitter;
    address donationMatchContract;
    address cw900lvAddress;
    address gasFwdFactory;
  }

  struct UpdateFeeRequest {
    LibAccounts.FeeTypes feeType;
    address payout;
    uint256 rate;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../accounts/lib/LibAccounts.sol";
import {IAccountsStrategy} from "../accounts/interfaces/IAccountsStrategy.sol";

library RegistrarStorage {
  struct Config {
    address indexFundContract;
    address accountsContract;
    address treasury;
    address subdaoGovContract; // subdao gov wasm code
    address subdaoTokenContract; // subdao gov cw20 token wasm code
    address subdaoBondingTokenContract; // subdao gov bonding ve token wasm code
    address subdaoCw900Contract; // subdao gov ve-vE contract for locked token voting
    address subdaoDistributorContract; // subdao gov fee distributor wasm code
    address subdaoEmitter;
    address donationMatchContract; // donation matching contract wasm code
    address donationMatchCharitesContract; // donation matching contract address for "Charities" endowments
    address donationMatchEmitter;
    LibAccounts.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
    //TODO: pending check
    address haloToken; // TerraSwap HALO token addr
    address haloTokenLpContract;
    address govContract; // AP governance contract
    uint256 collectorShare;
    address charitySharesContract;
    //PROTOCOL LEVEL
    address fundraisingContract;
    address uniswapRouter;
    address uniswapFactory;
    address multisigFactory;
    address multisigEmitter;
    address charityApplications;
    address lockedWithdrawal;
    address proxyAdmin;
    address usdcAddress;
    address wMaticAddress;
    address cw900lvAddress;
    address gasFwdFactory;
  }

  struct State {
    Config config;
    bytes4[] STRATEGIES;
    mapping(LibAccounts.FeeTypes => LibAccounts.FeeSetting) FeeSettingsByFeeType;
    mapping(string => IAccountsStrategy.NetworkInfo) NETWORK_CONNECTIONS;
    mapping(address => address) PriceFeeds;
  }
}

contract Storage {
  RegistrarStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IVault} from "../vault/interfaces/IVault.sol";

interface IRouter is IAxelarExecutable {
  /*////////////////////////////////////////////////
                        EVENTS
  */ ////////////////////////////////////////////////

  event Transfer(IVault.VaultActionData action, uint256 amount);
  event Refund(IVault.VaultActionData action, uint256 amount);
  event Deposit(IVault.VaultActionData action);
  event Redeem(IVault.VaultActionData action, uint256 amount);
  event RewardsHarvested(IVault.VaultActionData action);
  event ErrorLogged(IVault.VaultActionData action, string message);
  event ErrorBytesLogged(IVault.VaultActionData action, bytes data);

  /*////////////////////////////////////////////////
                    CUSTOM TYPES
  */ ////////////////////////////////////////////////

  function executeLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload
  ) external returns (IVault.VaultActionData memory);

  function executeWithTokenLocal(
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes calldata payload,
    string calldata tokenSymbol,
    uint256 amount
  ) external returns (IVault.VaultActionData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {LibAccounts} from "./accounts/lib/LibAccounts.sol";

library Validator {
  function addressChecker(address addr) internal pure returns (bool) {
    if (addr == address(0)) {
      return false;
    }
    return true;
  }

  function splitChecker(LibAccounts.SplitDetails memory split) internal pure returns (bool) {
    if ((split.max > 100) || (split.min > 100) || (split.defaultSplit > 100)) {
      return false;
    } else if (
      !(split.max >= split.min &&
        split.defaultSplit <= split.max &&
        split.defaultSplit >= split.min)
    ) {
      return false;
    } else {
      return true;
    }
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function delegateIsValid(
    LibAccounts.Delegate memory delegate,
    address sender,
    uint256 envTime
  ) internal pure returns (bool) {
    return (delegate.addr != address(0) &&
      sender == delegate.addr &&
      (delegate.expires == 0 || envTime <= delegate.expires));
  }

  function canChange(
    LibAccounts.SettingsPermission memory permissions,
    address sender,
    address owner,
    uint256 envTime
  ) internal pure returns (bool) {
    // Can be changed if both critera are satisfied:
    // 1. permission is not locked forever (read: `locked` == true)
    // 2. sender is a valid delegate address and their powers have not expired OR
    //    sender is the endow owner (ie. owner must first revoke their delegation)
    return (!permissions.locked &&
      (delegateIsValid(permissions.delegate, sender, envTime) || sender == owner));
  }

  function validateFee(LibAccounts.FeeSetting memory fee) internal pure {
    if (fee.bps > 0 && fee.payoutAddress == address(0)) {
      revert("Invalid fee payout zero address given");
    } else if (fee.bps > LibAccounts.FEE_BASIS) {
      revert("Invalid fee basis points given. Should be between 0 and 10000.");
    }
  }

  function checkSplits(
    LibAccounts.SplitDetails memory splits,
    uint256 userLocked,
    uint256 userLiquid,
    bool userOverride
  ) internal pure returns (uint256, uint256) {
    // check that the split provided by a user meets the endowment's
    // requirements for splits (set per Endowment)
    if (userOverride) {
      // ignore user splits and use the endowment's default split
      return (100 - splits.defaultSplit, splits.defaultSplit);
    } else if (userLiquid > splits.max) {
      // adjust upper range up within the max split threshold
      return (splits.max, 100 - splits.max);
    } else if (userLiquid < splits.min) {
      // adjust lower range up within the min split threshold
      return (100 - splits.min, splits.min);
    } else {
      // use the user entered split as is
      return (userLocked, userLiquid);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import "../../../core/router/IRouter.sol";

abstract contract IVault {
  /*////////////////////////////////////////////////
                    CUSTOM TYPES
  */ ////////////////////////////////////////////////
  uint256 constant PRECISION = 10 ** 24;

  /// @notice Angel Protocol Vault Type
  /// @dev Vaults have different behavior depending on type. Specifically access to redemptions and
  /// principle balance
  enum VaultType {
    LOCKED,
    LIQUID
  }

  struct VaultConfig {
    VaultType vaultType;
    bytes4 strategySelector;
    address strategy;
    address registrar;
    address baseToken;
    address yieldToken;
    string apTokenName;
    string apTokenSymbol;
    address admin;
  }

  /// @notice Gerneric AP Vault action data
  /// @param destinationChain The Axelar string name of the blockchain that will receive redemptions/refunds
  /// @param strategyId The 4 byte truncated keccak256 hash of the strategy name, i.e. bytes4(keccak256("Goldfinch"))
  /// @param selector The Vault method that should be called
  /// @param accountId The endowment uid
  /// @param token The token (if any) that was forwarded along with the calldata packet by GMP
  /// @param lockAmt The amount of said token that is intended to interact with the locked vault
  /// @param liqAmt The amount of said token that is intended to interact with the liquid vault
  struct VaultActionData {
    string destinationChain;
    bytes4 strategyId;
    bytes4 selector;
    uint32[] accountIds;
    address token;
    uint256 lockAmt;
    uint256 liqAmt;
    VaultActionStatus status;
  }

  /// @notice Structure for storing account principle information necessary for yield calculations
  /// @param baseToken The qty of base tokens deposited into the vault
  /// @param costBasis_withPrecision The cost per share for entry into the vault (baseToken / share)
  struct Principle {
    uint256 baseToken;
    uint256 costBasis_withPrecision;
  }

  enum VaultActionStatus {
    UNPROCESSED, // INIT state
    SUCCESS, // Ack
    POSITION_EXITED, // Position fully exited
    FAIL_TOKENS_RETURNED, // Tokens returned to accounts contract
    FAIL_TOKENS_FALLBACK // Tokens failed to be returned to accounts contract
  }

  struct RedemptionResponse {
    uint256 amount;
    VaultActionStatus status;
  }

  /*////////////////////////////////////////////////
                        EVENTS
  */ ////////////////////////////////////////////////

  /// @notice Event emited on each Deposit call
  /// @dev Upon deposit, emit this event. Index the account and staking contract for analytics
  event Deposit(
    uint32 accountId,
    VaultType vaultType,
    address tokenDeposited,
    uint256 amtDeposited
  );

  /// @notice Event emited on each Redemption call
  /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics
  event Redeem(uint32 accountId, VaultType vaultType, address tokenRedeemed, uint256 amtRedeemed);

  /// @notice Event emited on each Harvest call
  /// @dev Upon harvest, emit this event. Index the accounts harvested for.
  /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
  /// with specific yield/value details
  /// @param accountIds a list of the Accounts harvested for
  event RewardsHarvested(uint32[] accountIds);

  /*////////////////////////////////////////////////
                        ERRORS
  */ ////////////////////////////////////////////////
  error OnlyAdmin();
  error OnlyRouter();
  error OnlyApproved();
  error OnlyBaseToken();
  error OnlyNotPaused();
  error ApproveFailed();
  error TransferFailed();

  /*////////////////////////////////////////////////
                    EXTERNAL METHODS
  */ ////////////////////////////////////////////////

  /// @notice returns the vault config
  function getVaultConfig() external view virtual returns (VaultConfig memory);

  /// @notice set the vault config
  function setVaultConfig(VaultConfig memory _newConfig) external virtual;

  /// @notice deposit tokens into vault position of specified Account
  /// @dev the deposit method allows the Vault contract to create or add to an existing
  /// position for the specified Account. In the case that multiple different tokens can be deposited,
  /// the method requires the deposit token address and amount. The transfer of tokens to the Vault
  /// contract must occur before the deposit method is called.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param token the deposited token
  /// @param amt the amount of the deposited token
  function deposit(uint32 accountId, address token, uint256 amt) external payable virtual;

  /// @notice redeem value from the vault contract
  /// @dev allows an Account to redeem from its staked value. The behavior is different dependent on VaultType.
  /// Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @param amt the amount of shares to redeem
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeem(
    uint32 accountId,
    uint256 amt
  ) external payable virtual returns (RedemptionResponse memory);

  /// @notice redeem all of the value from the vault contract
  /// @dev allows an Account to redeem all of its staked value. Good for rebasing tokens wherein the value isn't
  /// known explicitly. Before returning the redemption amt, the vault must approve the Router to spend the tokens.
  /// @param accountId a unique Id for each Angel Protocol account
  /// @return RedemptionResponse returns the number of base tokens redeemed by the call and the status
  function redeemAll(uint32 accountId) external payable virtual returns (RedemptionResponse memory);

  /// @notice restricted method for harvesting accrued rewards
  /// @dev Claim reward tokens accumulated to the staked value. The underlying behavior will vary depending
  /// on the target yield strategy and VaultType. Only callable by an Angel Protocol Keeper
  /// @param accountIds Used to specify which accounts to call harvest against. Structured so that this can
  /// be called in batches to avoid running out of gas.
  function harvest(uint32[] calldata accountIds) external virtual;

  /*////////////////////////////////////////////////
                INTERNAL HELPER METHODS
    */ ////////////////////////////////////////////////

  /// @notice internal method for validating that calls came from the approved AP router
  /// @dev The registrar will hold a record of the approved Router address. This method must implement a method of
  /// checking that the msg.sender == ApprovedRouter
  function _isApprovedRouter() internal view virtual returns (bool);

  /// @notice internal method for checking whether the caller is the paired locked/liquid vault
  /// @dev can be used for more gas efficient rebalancing between the two sibling vaults
  function _isSiblingVault() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Array {
  function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }

  function sort(uint256[] memory data) internal pure returns (uint256[] memory) {
    quickSort(data, int256(0), int256(data.length - 1));
    return data;
  }

  function max(uint256[] memory data) internal pure returns (uint256) {
    uint256 maxVal = data[0];
    for (uint256 i = 1; i < data.length; i++) {
      if (maxVal < data[i]) {
        maxVal = data[i];
      }
    }

    return maxVal;
  }

  // function min(uint256[] memory data) internal pure returns (uint256) {
  //     uint256 min = data[0];
  //     for (uint256 i = 1; i < data.length; i++) {
  //         if (min > data[i]) {
  //             min = data[i];
  //         }
  //     }

  //     return min;
  // }

  function indexOf(uint256[] memory arr, uint256 searchFor) internal pure returns (uint256, bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return (i, true);
      }
    }
    // not found
    return (0, false);
  }

  function remove(uint256[] storage data, uint256 index) internal returns (uint256[] memory) {
    if (index >= data.length) {
      revert("Error in remove: internal");
    }

    for (uint256 i = index; i < data.length - 1; i++) {
      data[i] = data[i + 1];
    }
    data.pop();
    return data;
  }
}

library Array32 {
  function indexOf(uint32[] memory arr, uint32 searchFor) internal pure returns (uint32, bool) {
    for (uint32 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return (i, true);
      }
    }
    // not found
    return (0, false);
  }

  function remove(uint32[] storage data, uint32 index) internal returns (uint32[] memory) {
    if (index >= data.length) {
      revert("Error in remove: internal");
    }

    for (uint32 i = index; i < data.length - 1; i++) {
      data[i] = data[i + 1];
    }
    data.pop();
    return data;
  }
}