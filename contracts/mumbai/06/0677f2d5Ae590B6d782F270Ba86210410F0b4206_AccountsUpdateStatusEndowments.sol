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
pragma solidity ^0.8.16;

import {LibAccounts} from "../lib/LibAccounts.sol";
import {AccountStorage} from "../storage.sol";
import {RegistrarStorage} from "../../registrar/storage.sol";
import {IRegistrar} from "../../registrar/interfaces/IRegistrar.sol";
import {IIndexFund} from "../../index-fund/IIndexFund.sol";
import {ReentrancyGuardFacet} from "./ReentrancyGuardFacet.sol";
import {IAccountsEvents} from "../interfaces/IAccountsEvents.sol";
import {IAccountsUpdateStatusEndowments} from "../interfaces/IAccountsUpdateStatusEndowments.sol";

/**
 * @title AccountsUpdateStatusEndowments
 * @notice This contract facet updates the endowments status
 * @dev This contract facet updates the endowments status, updates rights are with owner of accounts contracts (AP Team Multisig)
 */
contract AccountsUpdateStatusEndowments is
  IAccountsUpdateStatusEndowments,
  ReentrancyGuardFacet,
  IAccountsEvents
{
  /**
   * @notice Closes an endowment, setting the endowment state to "closingEndowment" and the closing beneficiary to the provided beneficiary.
   * @param id The ID of the endowment to be closed.
   * @param beneficiary The beneficiary that will receive any remaining funds in the endowment.
   * @dev The function will revert if a redemption is rently in progress.
   * @dev Emits an `EndowmentStateUpdated` event with the updated state of the endowment.
   */
  function closeEndowment(
    uint32 id,
    LibAccounts.Beneficiary memory beneficiary
  ) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    AccountStorage.Endowment storage tempEndowment = state.ENDOWMENTS[id];

    require(msg.sender == tempEndowment.owner, "Unauthorized");
    require(!state.STATES[id].closingEndowment, "Endowment is closed");
    require(checkFullyExited(id), "Not fully exited");

    RegistrarStorage.Config memory registrar_config = IRegistrar(state.config.registrarContract)
      .queryConfig();

    require(
      beneficiary.enumData != LibAccounts.BeneficiaryEnum.None ||
        registrar_config.indexFundContract != address(0),
      "Beneficiary is NONE & Index Fund Contract is not configured in Registrar"
    );

    // If NONE was passed for beneficiary, send balance to the AP Treasury (if not in any funds)
    // or send to the first index fund if it is in one.
    IIndexFund.IndexFund[] memory funds = IIndexFund(registrar_config.indexFundContract)
      .queryInvolvedFunds(id);
    if (beneficiary.enumData == LibAccounts.BeneficiaryEnum.None) {
      if (funds.length == 0) {
        beneficiary = LibAccounts.Beneficiary({
          data: LibAccounts.BeneficiaryData({
            endowId: 0,
            fundId: 0,
            addr: registrar_config.treasury
          }),
          enumData: LibAccounts.BeneficiaryEnum.Wallet
        });
      } else {
        beneficiary = LibAccounts.Beneficiary({
          data: LibAccounts.BeneficiaryData({endowId: 0, fundId: funds[0].id, addr: address(0)}),
          enumData: LibAccounts.BeneficiaryEnum.IndexFund
        });
        // remove closing endowment from all Index Funds that it is in
        IIndexFund(registrar_config.indexFundContract).removeMember(id);
      }
    }

    state.STATES[id].closingEndowment = true;
    state.STATES[id].closingBeneficiary = beneficiary;
    emit EndowmentClosed(id);
  }

  function checkFullyExited(uint32 id) internal view returns (bool) {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    bytes4[] memory allStrategies = IRegistrar(state.config.registrarContract).queryAllStrategies();
    for (uint256 i; i < allStrategies.length; i++) {
      if (state.STATES[id].activeStrategies[allStrategies[i]]) {
        return false;
      }
    }
    return true;
  }

  /**
   * @notice Force a strategy inactive for `checkFullyExited` to pass
   * @dev We optimistically expect that a cross-chain `deposit` call will be successful
   * and then set the strategy active accordingly. In the event that a strategy is erroneously active,
   * we need a hook for an endow owner to close out.
   * @param id The ID of the endowment to be closed.
   * @param strategySelector The `stuck state` strategy
   */
  function forceSetStrategyInactive(uint32 id, bytes4 strategySelector) public {
    AccountStorage.State storage state = LibAccounts.diamondStorage();
    require(msg.sender == state.ENDOWMENTS[id].owner, "Unauthorized");
    state.STATES[id].activeStrategies[strategySelector] = false;
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

import {LibAccounts} from "../lib/LibAccounts.sol";

/**
 * @title AccountsUpdateStatusEndowments
 * @notice This contract facet updates the endowments status
 * @dev This contract facet updates the endowments status, updates rights are with owner of accounts contracts (AP Team Multisig)
 */
interface IAccountsUpdateStatusEndowments {
  /**
   * @notice Closes an endowment, setting the endowment state to "closingEndowment" and the closing beneficiary to the provided beneficiary.
   * @param id The ID of the endowment to be closed.
   * @param beneficiary The beneficiary that will receive any remaining funds in the endowment.
   * @dev The function will revert if a redemption is rently in progress.
   * @dev Emits an `UpdateEndowmentState` event with the updated state of the endowment.
   */
  function closeEndowment(uint32 id, LibAccounts.Beneficiary memory beneficiary) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IIndexFund {
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

  function queryFundDetails(uint256 fundId) external view returns (IndexFund memory);

  function queryInvolvedFunds(uint32 endowmentId) external view returns (IndexFund[] memory);

  function removeMember(uint32 member) external returns (bool);
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