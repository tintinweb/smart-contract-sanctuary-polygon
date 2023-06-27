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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {Validator} from "../lib/validator.sol";
import {AddressArray} from "../../../lib/address/array.sol";
import {AccountStorage} from "../storage.sol";
import {AccountMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {ReentrancyGuardFacet} from "./ReentrancyGuardFacet.sol";
import {IAccountsEvents} from "../interfaces/IAccountsEvents.sol";
import {IAccountsUpdateEndowmentSettingsController} from "../interfaces/IAccountsUpdateEndowmentSettingsController.sol";

/**
 * @title AccountsUpdateEndowmentSettingsController
 * @notice This contract facet is used to manage updates via the endowment settings controller
 * @dev This contract facet is used to manage updates via the endowment settings controller
 */
contract AccountsUpdateEndowmentSettingsController is
  IAccountsUpdateEndowmentSettingsController,
  ReentrancyGuardFacet,
  IAccountsEvents
{
  /**
    @dev Updates the settings of an endowment.
    @param details Object containing the updated details of the endowment settings.
    @param details.id The ID of the endowment to update.
    @param details.allowlistedBeneficiaries The updated list of allowlisted beneficiaries.
    @param details.allowlistedContributors The updated list of allowlisted contributors.
    @param details.maturity_allowlist_add The addresses to add to the maturity allowlist.
    @param details.maturity_allowlist_remove The addresses to remove from the maturity allowlist.
    @param details.splitToLiquid The updated split to liquid ratio.
    @param details.ignoreUserSplits Whether or not to ignore user splits.
    Emits a EndowmentSettingUpdated event for each setting that has been updated.
    Emits an EndowmentUpdated event after the endowment has been updated.
    Throws an error if the endowment is closing.
    */
  function updateEndowmentSettings(
    AccountMessages.UpdateEndowmentSettingsRequest memory details
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[details.id];

    require(!state.STATES[details.id].closingEndowment, "UpdatesAfterClosed");

    if (tempEndowment.endowType != AngelCoreStruct.EndowmentType.Charity) {
      if (
        AngelCoreStruct.canChange(
          tempEndowment.settingsController.maturityTime,
          msg.sender,
          tempEndowment.owner,
          block.timestamp
        )
      ) {
        tempEndowment.maturityTime = details.maturityTime;
        emit EndowmentSettingUpdated(details.id, "maturityTime");
      }
      if (tempEndowment.maturityTime <= 0 || tempEndowment.maturityTime > block.timestamp) {
        if (
          AngelCoreStruct.canChange(
            tempEndowment.settingsController.allowlistedBeneficiaries,
            msg.sender,
            tempEndowment.owner,
            block.timestamp
          )
        ) {
          tempEndowment.allowlistedBeneficiaries = details.allowlistedBeneficiaries;
          // IS EMITTING THIS EVENT FOR EACH UPDATED FIELD A GENERAL PRACTICE?
          // I SEE THE BENEFIT, JUST NOT SURE ABOUT GAS EFFICIENCY AND USEFULNESS
          emit EndowmentSettingUpdated(details.id, "allowlistedBeneficiaries");
        }

        if (
          AngelCoreStruct.canChange(
            tempEndowment.settingsController.allowlistedContributors,
            msg.sender,
            tempEndowment.owner,
            block.timestamp
          )
        ) {
          tempEndowment.allowlistedContributors = details.allowlistedContributors;
          emit EndowmentSettingUpdated(details.id, "allowlistedContributors");
        }
        if (
          AngelCoreStruct.canChange(
            tempEndowment.settingsController.maturityAllowlist,
            msg.sender,
            tempEndowment.owner,
            block.timestamp
          )
        ) {
          for (uint256 i = 0; i < details.maturity_allowlist_add.length; i++) {
            require(Validator.addressChecker(details.maturity_allowlist_add[i]), "InvalidAddress");
            (, bool found) = AddressArray.indexOf(
              tempEndowment.maturityAllowlist,
              details.maturity_allowlist_add[i]
            );
            if (!found) tempEndowment.maturityAllowlist.push(details.maturity_allowlist_add[i]);
          }
          for (uint256 i = 0; i < details.maturity_allowlist_remove.length; i++) {
            (uint256 index, bool found) = AddressArray.indexOf(
              tempEndowment.maturityAllowlist,
              details.maturity_allowlist_remove[i]
            );
            if (found)
              tempEndowment.maturityAllowlist = AddressArray.remove(
                tempEndowment.maturityAllowlist,
                index
              );
          }
          emit EndowmentSettingUpdated(details.id, "maturityAllowlist");
        }
      }
    }

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.splitToLiquid,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.splitToLiquid = details.splitToLiquid;
      emit EndowmentSettingUpdated(details.id, "splitToLiquid");
    }

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.ignoreUserSplits,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.ignoreUserSplits = details.ignoreUserSplits;
      emit EndowmentSettingUpdated(details.id, "ignoreUserSplits");
    }
    state.ENDOWMENTS[details.id] = tempEndowment;
    emit EndowmentUpdated(details.id);
  }

  /**
    @notice Updates the controller of the specified endowment
    @dev Only the endowment owner can call this function
    @param details The updated details of the endowment controller
    @param details.id The ID of the endowment
    */
  function updateEndowmentController(
    AccountMessages.UpdateEndowmentControllerRequest memory details
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[details.id];

    require(!state.STATES[details.id].closingEndowment, "UpdatesAfterClosed");
    require(msg.sender == tempEndowment.owner, "Unauthorized");

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.lockedInvestmentManagement,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.lockedInvestmentManagement = details
        .settingsController
        .lockedInvestmentManagement;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.liquidInvestmentManagement,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.liquidInvestmentManagement = details
        .settingsController
        .liquidInvestmentManagement;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.acceptedTokens,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.acceptedTokens = details.settingsController.acceptedTokens;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.allowlistedBeneficiaries,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.allowlistedBeneficiaries = details
        .settingsController
        .allowlistedBeneficiaries;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.allowlistedContributors,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.allowlistedContributors = details
        .settingsController
        .allowlistedContributors;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.maturityAllowlist,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.maturityAllowlist = details
        .settingsController
        .maturityAllowlist;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.maturityTime,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.maturityTime = details.settingsController.maturityTime;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.withdrawFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.withdrawFee = details.settingsController.withdrawFee;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.depositFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.depositFee = details.settingsController.depositFee;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.balanceFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.balanceFee = details.settingsController.balanceFee;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.name,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.name = details.settingsController.name;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.image,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.image = details.settingsController.image;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.logo,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.logo = details.settingsController.logo;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.sdgs,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.sdgs = details.settingsController.sdgs;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.splitToLiquid,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.splitToLiquid = details.settingsController.splitToLiquid;
    }
    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.ignoreUserSplits,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      tempEndowment.settingsController.ignoreUserSplits = details
        .settingsController
        .ignoreUserSplits;
    }
    state.ENDOWMENTS[details.id] = tempEndowment;
    emit EndowmentSettingUpdated(details.id, "endowmentController");
    emit EndowmentUpdated(details.id);
  }

  /**
    @notice Allows the owner or DAO to update the fees for a given endowment.
    @dev Only the fees that the caller is authorized to update will be updated.
    @param details The details of the fee update request, including the endowment ID, new fees, and the caller's signature.
    @dev Emits an EndowmentUpdated event containing the updated endowment details.
    @dev Reverts if the endowment is of type Charity, as charity endowments may not change fees.
    */
  function updateFeeSettings(
    AccountMessages.UpdateFeeSettingRequest memory details
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[details.id];

    require(
      tempEndowment.endowType != AngelCoreStruct.EndowmentType.Charity,
      "Charity Endowments may not change endowment fees"
    );
    require(!state.STATES[details.id].closingEndowment, "UpdatesAfterClosed");

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.earlyLockedWithdrawFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      AngelCoreStruct.validateFee(details.earlyLockedWithdrawFee);
      tempEndowment.earlyLockedWithdrawFee = details.earlyLockedWithdrawFee;
    }

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.depositFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      AngelCoreStruct.validateFee(details.depositFee);
      tempEndowment.depositFee = details.depositFee;
    }

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.withdrawFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      AngelCoreStruct.validateFee(details.withdrawFee);
      tempEndowment.withdrawFee = details.withdrawFee;
    }

    if (
      AngelCoreStruct.canChange(
        tempEndowment.settingsController.balanceFee,
        msg.sender,
        tempEndowment.owner,
        block.timestamp
      )
    ) {
      AngelCoreStruct.validateFee(details.balanceFee);
      tempEndowment.balanceFee = details.balanceFee;
    }

    state.ENDOWMENTS[details.id] = tempEndowment;
    emit EndowmentUpdated(details.id);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (SEity/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";

/**
 * @title ReentrancyGuardFacet
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

import {AngelCoreStruct} from "../../struct.sol";

interface IAccountsEvents {
  event DaoContractCreated(uint32 endowId, address daoAddress);
  event DonationDeposited(uint256 endowId, address tokenAddress, uint256 amount);
  event DonationWithdrawn(uint256 endowId, address recipient, address tokenAddress, uint256 amount);
  event AllowanceRemoved(address sender, address spender, address tokenAddress);
  event AllowanceUpdated(address sender, address spender, address tokenAddress, uint256 allowance);
  event EndowmentCreated(uint256 endowId);
  event EndowmentUpdated(uint256 endowId);
  event ConfigUpdated();
  event OwnerUpdated(address owner);
  event DonationMatchCreated(uint256 endowId, address donationMatchContract);
  event TokenSwapped(
    uint256 endowId,
    AngelCoreStruct.AccountType accountType,
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    uint256 amountOut
  );
  event EndowmentSettingUpdated(uint256 endowId, string setting);
  // event EndowmentStateUpdated(uint256 endowId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountMessages} from "../message.sol";

/**
 * @title AccountsUpdateEndowmentSettingsController
 * @notice This contract facet is used to manage updates via the endowment settings controller
 * @dev This contract facet is used to manage updates via the endowment settings controller
 */
interface IAccountsUpdateEndowmentSettingsController {
  /**
    @dev Updates the settings of an endowment.
    @param details Object containing the updated details of the endowment settings.
    @param details.id The ID of the endowment to update.
    @param details.allowlistedBeneficiaries The updated list of allowlisted beneficiaries.
    @param details.allowlistedContributors The updated list of allowlisted contributors.
    @param details.maturity_allowlist_add The addresses to add to the maturity allowlist.
    @param details.maturity_allowlist_remove The addresses to remove from the maturity allowlist.
    @param details.splitToLiquid The updated split to liquid ratio.
    @param details.ignoreUserSplits Whether or not to ignore user splits.
    Emits a EndowmentSettingUpdated event for each setting that has been updated.
    Emits an UpdateEndowment event after the endowment has been updated.
    Throws an error if the endowment is closing.
    */
  function updateEndowmentSettings(
    AccountMessages.UpdateEndowmentSettingsRequest memory details
  ) external;

  /**
    @notice Updates the controller of the specified endowment
    @dev Only the endowment owner can call this function
    @param details The updated details of the endowment controller
    @param details.id The ID of the endowment
    */
  function updateEndowmentController(
    AccountMessages.UpdateEndowmentControllerRequest memory details
  ) external;

  /**
    @notice Allows the owner or DAO to update the fees for a given endowment.
    @dev Only the fees that the caller is authorized to update will be updated.
    @param details The details of the fee update request, including the endowment ID, new fees, and the caller's signature.
    @dev Emits an UpdateEndowment event containing the updated endowment details.
    @dev Reverts if the endowment is of type Charity, as charity endowments may not change fees.
    */
  function updateFeeSettings(AccountMessages.UpdateFeeSettingRequest memory details) external;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Validator {
  function addressChecker(address addr1) internal pure returns (bool) {
    if (addr1 == address(0)) {
      return false;
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountMessages {
  struct CreateEndowmentRequest {
    bool withdrawBeforeMaturity;
    uint256 maturityTime;
    string name;
    uint256[] sdgs;
    AngelCoreStruct.Tier tier;
    AngelCoreStruct.EndowmentType endowType;
    string logo;
    string image;
    address[] members;
    uint256 threshold;
    uint256 duration;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting balanceFee;
    uint256 proposalLink;
    AngelCoreStruct.SettingsController settingsController;
    uint32 parent;
    address[] maturityAllowlist;
    bool ignoreUserSplits;
    AngelCoreStruct.SplitDetails splitToLiquid;
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
    AngelCoreStruct.SplitDetails splitToLiquid;
    bool ignoreUserSplits;
  }

  struct UpdateEndowmentControllerRequest {
    uint32 id;
    AngelCoreStruct.SettingsController settingsController;
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
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
  }

  struct StateResponse {
    bool closingEndowment;
    AngelCoreStruct.Beneficiary closingBeneficiary;
  }

  struct EndowmentDetailsResponse {
    address owner;
    address dao;
    address daoToken;
    string description;
    AngelCoreStruct.EndowmentType endowType;
    uint256 maturityTime;
    LocalRegistrarLib.RebalanceParams rebalance;
    address donationMatchContract;
    address[] maturityAllowlist;
    uint256 pendingRedemptions;
    string logo;
    string image;
    string name;
    uint256[] sdgs;
    AngelCoreStruct.Tier tier;
    uint256 copycatStrategy;
    uint256 proposalLink;
    uint256 parent;
    AngelCoreStruct.SettingsController settingsController;
  }

  struct DepositRequest {
    uint32 id;
    uint256 lockedPercentage;
    uint256 liquidPercentage;
  }

  struct UpdateFeeSettingRequest {
    uint32 id;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting balanceFee;
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

import {AngelCoreStruct} from "../struct.sol";
import {LocalRegistrarLib} from "../registrar/lib/LocalRegistrarLib.sol";

library AccountStorage {
  struct Config {
    address owner;
    string version;
    address registrarContract;
    uint32 nextAccountId;
    uint256 maxGeneralCategoryId;
    address subDao;
    address gateway;
    address gasReceiver;
    bool reentrancyGuardLocked;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
  }

  struct Endowment {
    address owner;
    string name; // name of the Endowment
    uint256[] sdgs;
    AngelCoreStruct.Tier tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
    AngelCoreStruct.EndowmentType endowType;
    string logo;
    string image;
    uint256 maturityTime; // datetime int of endowment maturity
    LocalRegistrarLib.RebalanceParams rebalance; // parameters to guide rebalancing & harvesting of gains from locked/liquid accounts
    uint256 pendingRedemptions; // number of vault redemptions rently pending for this endowment
    uint256 proposalLink; // link back the Applications Team Multisig Proposal that created an endowment (if a Charity)
    address multisig;
    address dao;
    address daoToken;
    bool donationMatchActive;
    address donationMatchContract;
    address[] allowlistedBeneficiaries;
    address[] allowlistedContributors;
    address[] maturityAllowlist;
    AngelCoreStruct.FeeSetting earlyLockedWithdrawFee;
    AngelCoreStruct.FeeSetting withdrawFee;
    AngelCoreStruct.FeeSetting depositFee;
    AngelCoreStruct.FeeSetting balanceFee;
    AngelCoreStruct.SettingsController settingsController;
    uint32 parent;
    bool ignoreUserSplits;
    AngelCoreStruct.SplitDetails splitToLiquid;
    uint256 referralId;
  }

  struct EndowmentState {
    AngelCoreStruct.BalanceInfo balances;
    bool closingEndowment;
    AngelCoreStruct.Beneficiary closingBeneficiary;
    mapping(bytes4 => bool) activeStrategies;
  }

  struct State {
    mapping(uint32 => uint256) DAOTOKENBALANCE;
    mapping(uint32 => EndowmentState) STATES;
    mapping(uint32 => Endowment) ENDOWMENTS;
    // endow ID -> spender Addr -> token Addr -> amount
    mapping(uint32 => mapping(address => mapping(address => uint256))) ALLOWANCES;
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

import {IVault} from "../../vault/interfaces/IVault.sol";
import {AngelCoreStruct} from "../../struct.sol";

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
    mapping(AngelCoreStruct.FeeTypes => AngelCoreStruct.FeeSetting) FeeSettingsByFeeType;
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library AngelCoreStruct {
  enum AccountType {
    Locked,
    Liquid
  }

  enum Tier {
    None,
    Level1,
    Level2,
    Level3
  }

  enum EndowmentType {
    Charity,
    Normal
  }

  enum AllowanceAction {
    Add,
    Remove
  }

  struct TokenInfo {
    address addr;
    uint256 amnt;
  }

  struct BalanceInfo {
    mapping(address => uint256) locked;
    mapping(address => uint256) liquid;
  }

  struct IndexFund {
    uint256 id;
    string name;
    string description;
    uint32[] members;
    //Fund Specific: over-riding SC level setting to handle a fixed split value
    // Defines the % to split off into liquid account, and if defined overrides all other splits
    uint256 splitToLiquid;
    // Used for one-off funds that have an end date (ex. disaster recovery funds)
    uint256 expiryTime; // datetime int of index fund expiry
  }

  ///TODO: need to test this same names already declared in other libraries
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

  function checkSplits(
    SplitDetails memory splits,
    uint256 userLocked,
    uint256 userLiquid,
    bool userOverride
  ) public pure returns (uint256, uint256) {
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

  struct NetworkInfo {
    string name;
    uint256 chainId;
    address router; //SHARED
    address axelarGateway;
    string ibcChannel; // Should be removed
    string transferChannel;
    address gasReceiver; // Should be removed
    uint256 gasLimit; // Should be used to set gas limit
  }

  ///TODO: need to check this and have a look at this
  enum VaultType {
    Native, // Juno native Vault contract
    Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
    Evm, // the address of the Vault contract on it's EVM chain
    None
  }

  enum veTypeEnum {
    Constant,
    Linear,
    SquarRoot
  }

  struct veTypeData {
    uint128 value;
    uint256 scale;
    uint128 slope;
    uint128 power;
  }

  struct veType {
    veTypeEnum ve_type;
    veTypeData data;
  }

  enum TokenType {
    Existing,
    New,
    VeBonding
  }

  struct DaoTokenData {
    address existingData;
    uint256 newInitialSupply;
    string newName;
    string newSymbol;
    veType veBondingType;
    string veBondingName;
    string veBondingSymbol;
    uint256 veBondingDecimals;
    address veBondingReserveDenom;
    uint256 veBondingReserveDecimals;
    uint256 veBondingPeriod;
  }

  struct DaoToken {
    TokenType token;
    DaoTokenData data;
  }

  struct DaoSetup {
    uint256 quorum; //: Decimal,
    uint256 threshold; //: Decimal,
    uint256 votingPeriod; //: u64,
    uint256 timelockPeriod; //: u64,
    uint256 expirationPeriod; //: u64,
    uint128 proposalDeposit; //: Uint128,
    uint256 snapshotPeriod; //: u64,
    DaoToken token; //: DaoToken,
  }

  struct Delegate {
    address addr;
    uint256 expires; // datetime int of delegation expiry
  }

  enum DelegateAction {
    Set,
    Revoke
  }

  function delegateIsValid(
    Delegate storage delegate,
    address sender,
    uint256 envTime
  ) public view returns (bool) {
    return (delegate.addr != address(0) &&
      sender == delegate.addr &&
      (delegate.expires == 0 || envTime <= delegate.expires));
  }

  function canChange(
    SettingsPermission storage permissions,
    address sender,
    address owner,
    uint256 envTime
  ) public view returns (bool) {
    // Can be changed if both critera are satisfied:
    // 1. permission is not locked forever (read: `locked` == true)
    // 2. sender is a valid delegate address and their powers have not expired OR
    //    sender is the endow owner (ie. owner must first revoke their delegation)
    return (!permissions.locked &&
      (delegateIsValid(permissions.delegate, sender, envTime) || sender == owner));
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

  function validateFee(FeeSetting memory fee) public pure {
    if (fee.bps > 0 && fee.payoutAddress == address(0)) {
      revert("Invalid fee payout zero address given");
    } else if (fee.bps > FEE_BASIS) {
      revert("Invalid fee basis points given. Should be between 0 and 10000.");
    }
  }

  uint256 constant FEE_BASIS = 10000; // gives 0.01% precision for fees (ie. Basis Points)
  uint256 constant PERCENT_BASIS = 100; // gives 1% precision for declared percentages
  uint256 constant BIG_NUMBA_BASIS = 1e24;

  // Interface IDs
  bytes4 constant InterfaceId_Invalid = 0xffffffff;
  bytes4 constant InterfaceId_ERC165 = 0x01ffc9a7;
  bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;
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

library AddressArray {
  function indexOf(address[] memory arr, address searchFor) internal pure returns (uint256, bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return (i, true);
      }
    }
    // not found
    return (0, false);
  }

  function remove(address[] storage data, uint256 index) internal returns (address[] memory) {
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