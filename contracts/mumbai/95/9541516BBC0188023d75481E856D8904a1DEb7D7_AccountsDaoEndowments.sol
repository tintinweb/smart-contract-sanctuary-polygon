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
import {SubDaoLib} from "../../../normalized_endowment/subdao/message.sol";
import {IAccountsDeployContract} from "../interfaces/IAccountsDeployContract.sol";
import {IAccountsDaoEndowments} from "../interfaces/IAccountsDaoEndowments.sol";
import {SubDaoMessages} from "../../../normalized_endowment/subdao/message.sol";
import {ISubDao} from "../../../normalized_endowment/subdao/ISubDao.sol";
import {ReentrancyGuardFacet} from "./ReentrancyGuardFacet.sol";
import {IAccountsEvents} from "../interfaces/IAccountsEvents.sol";

/**
 * @title AccountsDaoEndowments
 * @dev This contract facet manages the creation contracts required for DAO Functioning
 */
contract AccountsDaoEndowments is IAccountsDaoEndowments, ReentrancyGuardFacet, IAccountsEvents {
  /**
   * @notice This function creates a DAO for an endowment
   * @dev creates a DAO for an endowment based on parameters
   * @param id The id of the endowment
   * @param details The details of the DAO
   */
  function setupDao(uint32 id, SubDaoLib.DaoSetup memory details) public nonReentrant {
    AccountStorage.State storage state = LibAccounts.diamondStorage();

    AccountStorage.Endowment memory tempEndowment = state.ENDOWMENTS[id];
    // AccountStorage.Config memory tempConfig = state.config;

    require(tempEndowment.owner == msg.sender, "Unauthorized");
    require(tempEndowment.dao == address(0), "AD E01"); // A DAO already exists for this Endowment

    SubDaoMessages.InstantiateMsg memory createDaoMessage = SubDaoMessages.InstantiateMsg({
      id: id,
      quorum: details.quorum,
      owner: tempEndowment.owner,
      threshold: details.threshold,
      votingPeriod: details.votingPeriod,
      timelockPeriod: details.timelockPeriod,
      expirationPeriod: details.expirationPeriod,
      proposalDeposit: details.proposalDeposit,
      snapshotPeriod: details.snapshotPeriod,
      token: details.token,
      endowType: tempEndowment.endowType,
      endowOwner: tempEndowment.owner,
      registrarContract: state.config.registrarContract
    });

    address daoAddress = IAccountsDeployContract(address(this)).createDaoContract(createDaoMessage);

    tempEndowment.dao = daoAddress;

    SubDaoMessages.QueryConfigResponse memory subDaoConfid = ISubDao(daoAddress).queryConfig();

    tempEndowment.daoToken = subDaoConfid.daoToken;

    state.ENDOWMENTS[id] = tempEndowment;
    emit EndowmentUpdated(id);
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

import {SubDaoLib} from "../../../normalized_endowment/subdao/message.sol";

/**
 * @title AccountsDaoEndowments
 * @dev This contract facet manages the creation contracts required for DAO Functioning
 */
interface IAccountsDaoEndowments {
  /**
   * @notice This function creates a DAO for an endowment
   * @dev creates a DAO for an endowment based on parameters
   * @param id The id of the endowment
   * @param details The details of the DAO
   */
  function setupDao(uint32 id, SubDaoLib.DaoSetup memory details) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SubDaoMessages} from "../../../normalized_endowment/subdao/message.sol";

interface IAccountsDeployContract {
  function createDaoContract(
    SubDaoMessages.InstantiateMsg memory createdaomessage
  ) external returns (address daoAddress);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface QueryIIncentivisedVotingLockup {
  function balanceOf(address owner) external view returns (uint256);

  function balanceOfAt(address owner, uint256 blocknumber) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalSupplyAt(uint256 blocknumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SubDaoMessages} from "./message.sol";
import {SubDaoStorage} from "./storage.sol";
import {Array} from "../../lib/array.sol";

import {IRegistrar} from "../../core/registrar/interfaces/IRegistrar.sol";

interface ISubDao {
  function registerContracts(address vetoken, address swapfactory) external;

  function updateConfig(
    address owner,
    uint256 quorum,
    uint256 threshold,
    uint256 votingperiod,
    uint256 timelockperiod,
    uint256 expirationperiod,
    uint256 proposaldeposit,
    uint256 snapshotperiod
  ) external;

  function createPoll(
    address proposer,
    uint256 depositamount,
    string memory title,
    string memory description,
    string memory link,
    SubDaoStorage.ExecuteData memory executeMsgs
  ) external;

  function endPoll(uint256 pollid) external;

  function executePoll(uint256 pollid) external;

  function expirePoll(uint256 pollid) external;

  function castVote(uint256 pollid, SubDaoStorage.VoteOption vote) external;

  function queryConfig() external view returns (SubDaoMessages.QueryConfigResponse memory);

  function queryState() external view returns (SubDaoStorage.State memory);

  function buildDaoTokenMesage(SubDaoMessages.InstantiateMsg memory msg) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibAccounts} from "../../core/accounts/lib/LibAccounts.sol";
import {SubDaoLib} from "./SubDaoLib.sol";

library SubDaoMessages {
  struct InstantiateMsg {
    uint32 id;
    address owner;
    uint256 quorum;
    uint256 threshold;
    uint256 votingPeriod;
    uint256 timelockPeriod;
    uint256 expirationPeriod;
    uint256 proposalDeposit;
    uint256 snapshotPeriod;
    SubDaoLib.DaoToken token;
    LibAccounts.EndowmentType endowType;
    address endowOwner;
    address registrarContract;
  }

  struct QueryConfigResponse {
    address owner;
    address daoToken;
    address veToken;
    address swapFactory;
    uint256 quorum;
    uint256 threshold;
    uint256 votingPeriod;
    uint256 timelockPeriod;
    uint256 expirationPeriod;
    uint256 proposalDeposit;
    uint256 snapshotPeriod;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library SubDaoStorage {
  struct Config {
    address registrarContract;
    address owner;
    address daoToken;
    address veToken;
    address swapFactory;
    uint256 quorum;
    uint256 threshold;
    uint256 votingPeriod;
    uint256 timelockPeriod;
    uint256 expirationPeriod;
    uint256 proposalDeposit;
    uint256 snapshotPeriod;
  }

  struct State {
    uint256 pollCount;
    uint256 totalShare;
    uint256 totalDeposit;
  }

  enum VoteOption {
    Yes,
    No
  }

  struct VoterInfo {
    VoteOption vote;
    uint256 balance;
    bool voted;
  }

  // struct TokenManager {
  //     uint256 share;                        // total staked balance
  //     VoterInfo lockedBalance; // maps pollId to weight voted
  // }

  struct ExecuteData {
    uint256[] order;
    address[] contractAddress;
    bytes[] execution_message;
  }

  enum PollStatus {
    InProgress,
    Passed,
    Rejected,
    Executed,
    Expired
  }

  struct Poll {
    uint256 id;
    address creator;
    PollStatus status;
    uint256 yesVotes;
    uint256 noVotes;
    uint256 startBlock;
    uint256 startTime;
    uint256 endHeight;
    string title;
    string description;
    string link;
    ExecuteData executeData;
    uint256 depositAmount;
    /// Total balance at the end poll
    uint256 totalBalanceAtEndPoll;
    uint256 stakedAmount;
  }
}

contract Storage {
  SubDaoStorage.Config config;
  SubDaoStorage.State state;

  mapping(uint256 => SubDaoStorage.Poll) poll;
  mapping(uint256 => SubDaoStorage.PollStatus) poll_status;

  mapping(uint256 => mapping(address => SubDaoStorage.VoterInfo)) voting_status;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {QueryIIncentivisedVotingLockup} from "./../incentivised-voting/interfaces/QueryIIncentivisedVotingLockup.sol";

library SubDaoLib {
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

  uint256 constant MIN_TITLE_LENGTH = 4;
  uint256 constant MAX_TITLE_LENGTH = 64;
  uint256 constant MIN_DESC_LENGTH = 4;
  uint256 constant MAX_DESC_LENGTH = 1024;
  uint256 constant MIN_LINK_LENGTH = 12;
  uint256 constant MAX_LINK_LENGTH = 128;

  /**
   * @dev internal function returns length of utf string
   * @param str string to be checked
   */
  function utfStringLength(string memory str) public pure returns (uint256 length) {
    uint256 i = 0;
    bytes memory string_rep = bytes(str);

    while (i < string_rep.length) {
      if (string_rep[i] >> 7 == 0) i += 1;
      else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
      else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
      else if (string_rep[i] >> 3 == bytes1(uint8(0x1E))) i += 4;
      else i += 1;

      length++;
    }
  }

  /**
   * @notice function used to validate title
   * @dev validate title
   * @param title title to be validated
   */
  function validateTitle(string memory title) public pure returns (bool) {
    require(utfStringLength(title) > MIN_TITLE_LENGTH, "Title too short");

    require(utfStringLength(title) < MAX_TITLE_LENGTH, "Title too long");

    return true;
  }

  /**
   * @notice function used to validate description
   * @dev validate description
   * @param description description to be validated
   */
  function validateDescription(string memory description) public pure returns (bool) {
    require(utfStringLength(description) > MIN_DESC_LENGTH, "Description too short");

    require(utfStringLength(description) < MAX_DESC_LENGTH, "Description too long");

    return true;
  }

  /**
   * @notice function used to validate link
   * @dev validate link
   * @param link link to be validated
   */

  function validateLink(string memory link) public pure returns (bool) {
    require(utfStringLength(link) > MIN_LINK_LENGTH, "Link too short");

    require(utfStringLength(link) < MAX_LINK_LENGTH, "Link too long");

    return true;
  }

  /**
   * @notice function used to validate quorum
   * @dev validate quorum
   * @param quorum quorum to be validated
   */
  function validateQuorum(uint256 quorum) public pure returns (bool) {
    require(quorum < 100, "quorum must be 0 to 100");

    return true;
  }

  /**
   * @notice function used to validate threshold
   * @dev validate threshold
   * @param threshold threshold to be validated
   */
  function validateThreshold(uint256 threshold) public pure returns (bool) {
    require(threshold < 100, "threshold must be 0 to 100");

    return true;
  }

  /**
   * @notice function used to query voting balance of an address
   * @dev query voting balance of an address
   * @param veAddr ve address
   * @param targetAddr address to be queried
   * @param blocknumber block number to be queried
   */
  function queryAddressVotingBalanceAtBlock(
    address veAddr,
    address targetAddr,
    uint256 blocknumber
  ) public view returns (uint256) {
    // return IERC20(veaddr).balanceOf(addr);
    return QueryIIncentivisedVotingLockup(veAddr).balanceOfAt(targetAddr, blocknumber);
  }

  /**
   * @notice function used to query total voting balance
   * @dev query total voting balance
   * @param veaddr ve address
   * @param blocknumber block number to be queried
   */
  function queryTotalVotingBalanceAtBlock(
    address veaddr,
    uint256 blocknumber
  ) public view returns (uint256) {
    return QueryIIncentivisedVotingLockup(veaddr).totalSupplyAt(blocknumber);
  }
}