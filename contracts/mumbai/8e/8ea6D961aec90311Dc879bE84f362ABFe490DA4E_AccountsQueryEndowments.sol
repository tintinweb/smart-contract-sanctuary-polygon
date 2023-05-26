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
import {AccountStorage} from "../storage.sol";
import {AccountMessages} from "../message.sol";
import {RegistrarStorage} from "../../registrar/storage.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {IRegistrar} from "../../registrar/interfaces/IRegistrar.sol";

/**
 * @title AccountsQueryEndowments
 * @notice This contract facet queries for endowment and accounts config
 * @dev This contract facet queries for endowment and accounts config
 */
contract AccountsQueryEndowments {
    /**
     * @notice This function queries the balance of a token for an endowment
     * @dev This function queries the balance of a token for an endowment based on its type and address
     * @param id The id of the endowment
     * @param accountType The account type
     * @param tokenAddress The address of the token
     * @return tokenAmount balance of token
     */
    function queryTokenAmount(
        uint32 id,
        AngelCoreStruct.AccountType accountType,
        address tokenAddress
    ) public view returns (uint256 tokenAmount) {
        AccountStorage.State storage state = LibAccounts.diamondStorage();
        require(address(0) != tokenAddress, "Invalid token address");

        if (accountType == AngelCoreStruct.AccountType.Locked) {
            tokenAmount = state.STATES[id].balances.locked.balancesByToken[tokenAddress];
        } 
        else {
            tokenAmount = state.STATES[id].balances.liquid.balancesByToken[tokenAddress];
        }
    }

    /**
     * @notice queries the endowment details
     * @dev queries the endowment details
     * @param id The id of the endowment
     * @return endowment The endowment details
     */
    function queryEndowmentDetails(
        uint32 id
    ) public view returns (AccountStorage.Endowment memory endowment) {
        AccountStorage.State storage state = LibAccounts.diamondStorage();
        endowment = state.ENDOWMENTS[id];
    }

    /**
     * @notice queries the accounts contract config
     * @dev queries the accounts contract config
     * @return config The accounts contract config
     */
    function queryConfig()
        public
        view
        returns (AccountMessages.ConfigResponse memory config)
    {
        AccountStorage.State storage state = LibAccounts.diamondStorage();
        config = AccountMessages.ConfigResponse({
            owner: state.config.owner,
            version: state.config.version,
            registrarContract: state.config.registrarContract,
            nextAccountId: state.config.nextAccountId,
            maxGeneralCategoryId: state.config.maxGeneralCategoryId,
            subDao: state.config.subDao,
            gateway: state.config.gateway,
            gasReceiver: state.config.gasReceiver,
            earlyLockedWithdrawFee: state.config.earlyLockedWithdrawFee
        });
    }

    /**
     * @notice queries the endowment donations state
     * @dev queries the endowment state
     * @param id The id of the endowment
     * @return stateResponse The endowment state
     */
    function queryState(
        uint32 id
    ) public view returns (AccountMessages.StateResponse memory stateResponse) {
        AccountStorage.State storage state = LibAccounts.diamondStorage();
        stateResponse = AccountMessages.StateResponse({
            donationsReceived: state.STATES[id].donationsReceived,
            closingEndowment: state.STATES[id].closingEndowment,
            closingBeneficiary: state.STATES[id].closingBeneficiary
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccountStorage} from "../storage.sol";

library LibAccounts {
    bytes32 constant AP_ACCOUNTS_DIAMOND_STORAGE_POSITION =
        keccak256("accounts.diamond.storage");

    function diamondStorage()
        internal
        pure
        returns (AccountStorage.State storage ds)
    {
        bytes32 position = AP_ACCOUNTS_DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library Validator {

    function addressChecker(address addr1) internal pure returns(bool){
        if(addr1 == address(0)){
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
        address owner; // address that originally setup the endowment account
        bool withdrawBeforeMaturity; // endowment allowed to withdraw funds from locked acct before maturity date
        uint256 maturityTime; // datetime int of endowment maturity
        uint256 maturityHeight; // block equiv of the maturity_datetime
        string name; // name of the Endowment
        AngelCoreStruct.Categories categories; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
        uint256 tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
        AngelCoreStruct.EndowmentType endowType;
        string logo;
        string image;
        address[] members;
        bool kycDonorsOnly;
        uint256 threshold;
        AngelCoreStruct.Duration maxVotingPeriod;
        address[] allowlistedBeneficiaries;
        address[] allowlistedContributors;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        AngelCoreStruct.EndowmentFee earlyLockedWithdrawFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee balanceFee;
        AngelCoreStruct.DaoSetup dao;
        bool createDao;
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
        address owner; /// Option<String>,
        string name; /// Option<String>,
        AngelCoreStruct.Categories categories; /// Option<Categories>,
        string logo; /// Option<String>,
        string image; /// Option<String>,
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
        AngelCoreStruct.EndowmentFee earlyLockedWithdrawFee;
    }

    struct StateResponse {
        AngelCoreStruct.DonationsReceived donationsReceived;
        bool closingEndowment;
        AngelCoreStruct.Beneficiary closingBeneficiary;
    }

    struct EndowmentBalanceResponse {
        AngelCoreStruct.BalanceInfo tokensOnHand; //: BalanceInfo,
        address[] invested_locked_string; //: Vec<(String, Uint128)>,
        uint128[] invested_locked_amount;
        address[] invested_liquid_string; //: Vec<(String, Uint128)>,
        uint128[] invested_liquid_amount;
    }

    struct EndowmentEntry {
        uint32 id; // u32,
        address owner; // String,
        AngelCoreStruct.EndowmentType endowType; // EndowmentType,
        string name; // Option<String>,
        string logo; // Option<String>,
        string image; // Option<String>,
        AngelCoreStruct.Tier tier; // Option<Tier>,
        AngelCoreStruct.Categories categories; // Categories,
        string proposalLink; // Option<u64>,
    }

    struct EndowmentListResponse {
        EndowmentEntry[] endowments;
    }

    struct EndowmentDetailsResponse {
        address owner; //: Addr,
        address dao;
        address daoToken;
        string description;
        AngelCoreStruct.AccountStrategies strategies;
        AngelCoreStruct.EndowmentType endowType;
        uint256 maturityTime;
        AngelCoreStruct.OneOffVaults oneoffVaults;
        LocalRegistrarLib.RebalanceParams rebalance;
        address donationMatchContract;
        address[] maturityAllowlist;
        uint256 pendingRedemptions;
        string logo;
        string image;
        string name;
        AngelCoreStruct.Categories categories;
        uint256 tier;
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

    struct UpdateEndowmentFeeRequest {
        uint32 id;
        AngelCoreStruct.EndowmentFee earlyLockedWithdrawFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee balanceFee;
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
        AngelCoreStruct.EndowmentFee earlyLockedWithdrawFee;
    }

    struct Endowment {
        address owner;
        string name; // name of the Endowment
        AngelCoreStruct.Categories categories; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
        uint256 tier; // SHOULD NOT be editable for now (only the Config.owner, ie via the Gov contract or AP Team Multisig can set/update)
        AngelCoreStruct.EndowmentType endowType;
        string logo;
        string image;
        uint256 maturityTime; // datetime int of endowment maturity
        //OG:AngelCoreStruct.AccountStrategies
        // uint256 strategies; // vaults and percentages for locked/liquid accounts donations where auto_invest == TRUE
        AngelCoreStruct.AccountStrategies strategies;
        AngelCoreStruct.OneOffVaults oneoffVaults; // vaults not covered in account startegies (more efficient tracking of vaults vs. looking up allll vaults)
        LocalRegistrarLib.RebalanceParams rebalance; // parameters to guide rebalancing & harvesting of gains from locked/liquid accounts
        bool kycDonorsOnly; // allow owner to state a preference for receiving only kyc'd donations (where possible) //TODO:
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
        AngelCoreStruct.EndowmentFee earlyLockedWithdrawFee;
        AngelCoreStruct.EndowmentFee withdrawFee;
        AngelCoreStruct.EndowmentFee depositFee;
        AngelCoreStruct.EndowmentFee balanceFee;
        AngelCoreStruct.SettingsController settingsController;
        uint32 parent;
        bool ignoreUserSplits;
        AngelCoreStruct.SplitDetails splitToLiquid;
        uint256 referralId;
    }

    struct EndowmentState {
        AngelCoreStruct.DonationsReceived donationsReceived;
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
        Config config;
        // mapping(bytes4 => string) stratagyId;
        // mapping(uint32 => mapping(AngelCoreStruct.AccountType => mapping(string => uint256))) vaultBalance;
    }
}

contract Storage {
    AccountStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import { IVault } from "../../../interfaces/IVault.sol";
import {LocalRegistrarLib} from "../lib/LocalRegistrarLib.sol";
 
interface ILocalRegistrar {

    /*////////////////////////////////////////////////
                        EVENTS
    */////////////////////////////////////////////////
    event RebalanceParamsChanged(LocalRegistrarLib.RebalanceParams newRebalanceParams);
    event AngelProtocolParamsChanged(LocalRegistrarLib.AngelProtocolParams newAngelProtocolParams);
    event AccountsContractStorageChanged(
        string indexed chainName,
        string indexed accountsContractAddress
    );
    event TokenAcceptanceChanged(address indexed tokenAddr, bool isAccepted);
    event StrategyApprovalChanged(bytes4 indexed _strategyId, LocalRegistrarLib.StrategyApprovalState _approvalState);
    event StrategyParamsChanged(
        bytes4 indexed _strategyId,
        address indexed _lockAddr,
        address indexed _liqAddr,
        LocalRegistrarLib.StrategyApprovalState _approvalState
    );
    event GasFeeUpdated(address indexed _tokenAddr, uint256 _gasFee); 

    /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */////////////////////////////////////////////////

    // View methods for returning stored params
    function getRebalanceParams()
        external
        view
        returns (LocalRegistrarLib.RebalanceParams memory);

    function getAngelProtocolParams()
        external
        view
        returns (LocalRegistrarLib.AngelProtocolParams memory);

    function getAccountsContractAddressByChain(string calldata _targetChain) 
        external 
        view
        returns (string memory);

    function getStrategyParamsById(bytes4 _strategyId)
        external
        view
        returns (LocalRegistrarLib.StrategyParams memory);

    function isTokenAccepted(address _tokenAddr) external view returns (bool);

    function getGasByToken(address _tokenAddr) external view returns (uint256);

    function getStrategyApprovalState(bytes4 _strategyId)
        external
        view
        returns (LocalRegistrarLib.StrategyApprovalState);
    
    // Setter meothods for granular changes to specific params
    function setRebalanceParams(LocalRegistrarLib.RebalanceParams calldata _rebalanceParams)
        external;

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
    function setStrategyApprovalState(bytes4 _strategyId, LocalRegistrarLib.StrategyApprovalState _approvalState)
        external;

    /// @notice Change which pair of vault addresses a strategy points to
    /// @dev Set the approval bool and both locked/liq vault addrs for a specified strategyId.
    /// @param _strategyId a uid for each strategy set by:
    /// bytes4(keccak256("StrategyName"))
    /// @param _liqAddr address to a comptaible Liquid type Vault
    /// @param _lockAddr address to a compatible Locked type Vault
    function setStrategyParams(
        bytes4 _strategyId,
        address _liqAddr,
        address _lockAddr,
        LocalRegistrarLib.StrategyApprovalState _approvalState
    ) external;

    function setTokenAccepted(address _tokenAddr, bool _isAccepted) external;

    function setGasByToken(address _tokenAddr, uint256 _gasFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import {RegistrarStorage} from "../storage.sol";
import {RegistrarMessages} from "../message.sol";
import {AngelCoreStruct} from "../../struct.sol";
import {ILocalRegistrar} from "./ILocalRegistrar.sol";

interface IRegistrar is ILocalRegistrar {
    function updateConfig(
        RegistrarMessages.UpdateConfigRequest memory details
    ) external;

    function updateOwner(address newOwner) external;

    function updateFees(
        RegistrarMessages.UpdateFeeRequest memory details
    ) external;

    function vaultAdd(
        RegistrarMessages.VaultAddRequest memory details
    ) external;

    function vaultRemove(string memory _stratagyName) external;

    function vaultUpdate(
        string memory _stratagyName,
        bool approved,
        AngelCoreStruct.EndowmentType[] memory restrictedfrom
    ) external;

    function updateNetworkConnections(
        AngelCoreStruct.NetworkInfo memory networkInfo,
        string memory action
    ) external;

    // Query functions for contract

    function queryConfig()
        external
        view
        returns (RegistrarStorage.Config memory);

    function testQuery() external view returns (string[] memory);
    
    function queryAllStrategies() view external returns (bytes4[] memory allStrategies);

    // function testQueryStruct()
    //     external
    //     view
    //     returns (AngelCoreStruct.YieldVault[] memory);

    // function queryVaultListDep(
    //     uint256 network,
    //     AngelCoreStruct.EndowmentType endowmentType,
    //     AngelCoreStruct.AccountType accountType,
    //     AngelCoreStruct.VaultType vaultType,
    //     AngelCoreStruct.BoolOptional approved,
    //     uint256 startAfter,
    //     uint256 limit
    // ) external view returns (AngelCoreStruct.YieldVault[] memory);

    // function queryVaultList(
    //     uint256 network,
    //     AngelCoreStruct.EndowmentType endowmentType,
    //     AngelCoreStruct.AccountType accountType,
    //     AngelCoreStruct.VaultType vaultType,
    //     AngelCoreStruct.BoolOptional approved,
    //     uint256 startAfter,
    //     uint256 limit
    // ) external view returns (AngelCoreStruct.YieldVault[] memory);

    // function queryVaultDetails(
    //     string memory _stratagyName
    // ) external view returns (AngelCoreStruct.YieldVault memory response);

    function queryNetworkConnection(
        uint256 chainId
    ) external view returns (AngelCoreStruct.NetworkInfo memory response);

    function queryFee(
        string memory name
    ) external view returns (uint256 response);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import { IVault } from "../../../interfaces/IVault.sol";

library LocalRegistrarLib {

  /*////////////////////////////////////////////////
                      DEPLOYMENT DEFAULTS
  */////////////////////////////////////////////////
    bool constant REBALANCE_LIQUID_PROFITS = false;
    uint32 constant LOCKED_REBALANCE_TO_LIQUID = 75; // 75%
    uint32 constant INTEREST_DISTRIBUTION = 20;      // 20%
    bool constant LOCKED_PRINCIPLE_TO_LIQUID = false;
    uint32 constant PRINCIPLE_DISTRIBUTION = 0;
    uint32 constant BASIS = 100;

    // DEFAULT ANGEL PROTOCOL PARAMS
    uint32 constant PROTOCOL_TAX_RATE = 2;
    uint32 constant PROTOCOL_TAX_BASIS = 100;
    address constant PROTOCOL_TAX_COLLECTOR = address(0);
    address constant ROUTER_ADDRESS = address(0);
    address constant REFUND_ADDRESS = address(0);

  /*////////////////////////////////////////////////
                      CUSTOM TYPES
  */////////////////////////////////////////////////
    struct RebalanceParams { 
        bool rebalanceLiquidProfits;
        uint32 lockedRebalanceToLiquid;
        uint32 interestDistribution;
        bool lockedPrincipleToLiquid;
        uint32 principleDistribution;
        uint32 basis;
    }

    struct AngelProtocolParams { 
        uint32 protocolTaxRate;
        uint32 protocolTaxBasis;
        address protocolTaxCollector;
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
      RebalanceParams rebalanceParams;
      AngelProtocolParams angelProtocolParams;
      mapping(bytes32 => string) accountsContractByChain;
      mapping(bytes4 => StrategyParams) VaultsByStrategyId;
      mapping(address => bool) AcceptedTokens;
      mapping(address=> uint256) GasFeeByToken;
    }

    /*////////////////////////////////////////////////
                        STORAGE MGMT
    */////////////////////////////////////////////////
    bytes32 constant LOCAL_REGISTRAR_STORAGE_POSITION =
        keccak256("local.registrar.storage");

    function localRegistrarStorage()
        internal
        pure
        returns (LocalRegistrarStorage storage lrs)
    {
        bytes32 position = LOCAL_REGISTRAR_STORAGE_POSITION;
        assembly {
            lrs.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarMessages {
    struct InstantiateRequest {
        address treasury;
        // uint256 taxRate;
        // AngelCoreStruct.RebalanceDetails rebalance;
        AngelCoreStruct.SplitDetails splitToLiquid;
        // AngelCoreStruct.AcceptedTokens acceptedTokens;
        address router;
        address axelarGateway;
        address axelarGasRecv;
    }

    struct UpdateConfigRequest {
        address accountsContract;
        // uint256 taxRate;
        // AngelCoreStruct.RebalanceDetails rebalance;
        string[] approved_charities;
        uint256 splitMax;
        uint256 splitMin;
        uint256 splitDefault;
        uint256 collectorShare;
        // AngelCoreStruct.AcceptedTokens acceptedTokens;
        
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
        address applicationsReview;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address subdaoGovContract;
        address subdaoTokenContract;
        address subdaoBondingTokenContract;
        address subdaoCw900Contract;
        address subdaoDistributorContract;
        address subdaoEmitter;
        address donationMatchContract;
        address cw900lvAddress;
    }

    struct VaultAddRequest {
        // chainid of network
        uint256 network;
        string stratagyName;
        address inputDenom;
        address yieldToken;
        AngelCoreStruct.EndowmentType[] restrictedFrom;
        AngelCoreStruct.AccountType acctType;
        AngelCoreStruct.VaultType vaultType;
    }

    struct UpdateFeeRequest {
        string[] keys;
        uint256[] values;
    }

    struct ConfigResponse {
        uint256 version;
        address accountsContract;
        address treasury;
        // uint256 taxRate;
        // AngelCoreStruct.RebalanceDetails rebalance;
        address indexFund;
        // AngelCoreStruct.SplitDetails splitToLiquid;
        address haloToken;
        address govContract;
        address charitySharesContract;
        uint256 endowmentMultisigContract;
        // AngelCoreStruct.AcceptedTokens acceptedTokens;
        address applicationsReview;
        address swapsRouter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AngelCoreStruct} from "../struct.sol";

library RegistrarStorage {
    struct Config {
        //Application review multisig
        address applicationsReview; // Endowment application review team's multisig (set as owner to start). Owner can set and change/revoke.
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
        AngelCoreStruct.SplitDetails splitToLiquid; // set of max, min, and default Split paramenters to check user defined split input against
        //TODO: pending check
        address haloToken; // TerraSwap HALO token addr
        address haloTokenLpContract;
        address govContract; // AP governance contract
        uint256 collectorShare;
        address charitySharesContract;
        // AngelCoreStruct.AcceptedTokens acceptedTokens; // list of approved native and CW20 coins can accept inward
        //PROTOCOL LEVEL
        address fundraisingContract;
        // AngelCoreStruct.RebalanceDetails rebalance;
        address swapsRouter;
        address multisigFactory;
        address multisigEmitter;
        address charityProposal;
        address lockedWithdrawal;
        address proxyAdmin;
        address usdcAddress;
        address wethAddress;
        address cw900lvAddress;
    }

    struct State {
        Config config;
        bytes4[] STRATEGIES;
        mapping(string => uint256) FEES;
        mapping(uint256 => AngelCoreStruct.NetworkInfo) NETWORK_CONNECTIONS;
    }
}

contract Storage {
    RegistrarStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import {IAxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IVault} from "../../interfaces/IVault.sol";

interface IRouter is IAxelarExecutable {
    /*////////////////////////////////////////////////
                        EVENTS
    */////////////////////////////////////////////////

    event TokensSent(VaultActionData action, uint256 amount);
    event FallbackRefund(VaultActionData action, uint256 amount);
    event Deposit(VaultActionData action);
    event Redemption(VaultActionData action, uint256 amount);
    event Harvest(VaultActionData action);
    event LogError(VaultActionData action, string message);
    event LogErrorBytes(VaultActionData action, bytes data);

    /*////////////////////////////////////////////////
                    CUSTOM TYPES
    */////////////////////////////////////////////////

    /// @notice Gerneric AP Vault action data that can be packed and sent through the GMP
    /// @dev Data will arrive from the GMP encoded as a string of bytes. For internal methods/processing,
    /// we can restructure it to look like VaultActionData to improve readability.
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

    enum VaultActionStatus {
        UNPROCESSED,                // INIT state
        SUCCESS,                    // Ack 
        POSITION_EXITED,             // Position fully exited 
        FAIL_TOKENS_RETURNED,       // Tokens returned to accounts contract
        FAIL_TOKENS_FALLBACK       // Tokens failed to be returned to accounts contract
    }

    struct RedemptionResponse {
        uint256 amount; 
        VaultActionStatus status;
    }

    function executeLocal(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external returns (VaultActionData memory);

    function executeWithTokenLocal(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external returns (VaultActionData memory);
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

    struct Pair {
        //This should be asset info
        string[] asset;
        address contractAddress;
    }

    struct Asset {
        address addr;
        string name;
    }

    enum AssetInfoBase {
        Cw20,
        Native,
        None
    }

    struct AssetBase {
        AssetInfoBase info;
        uint256 amount;
        address addr;
        string name;
    }

    //By default array are empty
    struct Categories {
        uint256[] sdgs;
        uint256[] general;
    }

    enum EndowmentType {
        Charity,
        Normal
    }

    enum AllowanceAction {
        Add,
        Remove
    }

    struct AccountStrategies {
        string[] locked_vault;
        uint256[] lockedPercentage;
        string[] liquid_vault;
        uint256[] liquidPercentage;
    }

    function accountStratagyLiquidCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.liquid_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.liquid.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.liquid_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.liquid[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.liquid.push(strategies.liquid_vault[i]);
            }
        }
    }

    function accountStratagyLockedCheck(
        AccountStrategies storage strategies,
        OneOffVaults storage oneoffVaults
    ) public {
        for (uint256 i = 0; i < strategies.locked_vault.length; i++) {
            bool checkFlag = true;
            for (uint256 j = 0; j < oneoffVaults.locked.length; j++) {
                if (
                    keccak256(abi.encodePacked(strategies.locked_vault[i])) ==
                    keccak256(abi.encodePacked(oneoffVaults.locked[j]))
                ) {
                    checkFlag = false;
                }
            }

            if (checkFlag) {
                oneoffVaults.locked.push(strategies.locked_vault[i]);
            }
        }
    }

    function accountStrategiesDefaut()
        public
        pure
        returns (AccountStrategies memory)
    {
        AccountStrategies memory empty;
        return empty;
    }

    //TODO: handle the case when we invest into vault or redem from vault
    struct OneOffVaults {
        string[] locked;
        uint256[] lockedAmount;
        string[] liquid;
        uint256[] liquidAmount;
    }

    function removeLast(string[] storage vault, string memory remove) public {
        for (uint256 i = 0; i < vault.length - 1; i++) {
            if (
                keccak256(abi.encodePacked(vault[i])) ==
                keccak256(abi.encodePacked(remove))
            ) {
                vault[i] = vault[vault.length - 1];
                break;
            }
        }

        vault.pop();
    }

    function oneOffVaultsDefault() public pure returns (OneOffVaults memory) {
        OneOffVaults memory empty;
        return empty;
    }

    function checkTokenInOffVault(
        string[] storage availible,
        uint256[] storage cerAvailibleAmount, 
        string memory token
    ) public {
        bool check = true;
        for (uint8 j = 0; j < availible.length; j++) {
            if (
                keccak256(abi.encodePacked(availible[j])) ==
                keccak256(abi.encodePacked(token))
            ) {
                check = false;
            }
        }
        if (check) {
            availible.push(token);
            cerAvailibleAmount.push(0);
        }
    }

    // SHARED -- now defined by LocalRegistrar 
    // struct RebalanceDetails {
    //     bool rebalanceLiquidInvestedProfits; // should invested portions of the liquid account be rebalanced?
    //     bool lockedInterestsToLiquid; // should Locked acct interest earned be distributed to the Liquid Acct?
    //     ///TODO: Should be decimal type insted of uint256
    //     uint256 interest_distribution; // % of Locked acct interest earned to be distributed to the Liquid Acct
    //     bool lockedPrincipleToLiquid; // should Locked acct principle be distributed to the Liquid Acct?
    //     ///TODO: Should be decimal type insted of uint256
    //     uint256 principle_distribution; // % of Locked acct principle to be distributed to the Liquid Acct
    // }

    // function rebalanceDetailsDefaut()
    //     public
    //     pure
    //     returns (RebalanceDetails memory)
    // {
    //     RebalanceDetails memory _tempRebalanceDetails = RebalanceDetails({
    //         rebalanceLiquidInvestedProfits: false,
    //         lockedInterestsToLiquid: false,
    //         interest_distribution: 20,
    //         lockedPrincipleToLiquid: false,
    //         principle_distribution: 0
    //     });

    //     return _tempRebalanceDetails;
    // }

    struct DonationsReceived {
        uint256 locked;
        uint256 liquid;
    }

    function donationsReceivedDefault()
        public
        pure
        returns (DonationsReceived memory)
    {
        DonationsReceived memory empty;
        return empty;
    }

    struct Coin {
        string denom;
        uint128 amount;
    }

    struct CoinVerified {
        uint128 amount;
        address addr;
    }

    struct GenericBalance {
        uint256 coinNativeAmount;
        mapping(address => uint256) balancesByToken;
    }

    function addToken(
        GenericBalance storage temp,
        address tokenAddress,
        uint256 amount
    ) public {
        temp.balancesByToken[tokenAddress] += amount;
    }

    // function addTokenMem(
    //     GenericBalance memory temp,
    //     address tokenaddress,
    //     uint256 amount
    // ) public pure returns (GenericBalance memory) {
    //     bool notFound = true;
    //     for (uint8 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //         if (temp.CoinVerified_addr[i] == tokenaddress) {
    //             notFound = false;
    //             temp.CoinVerified_amount[i] += amount;
    //         }
    //     }
    //     if (notFound) {
    //         GenericBalance memory new_temp = GenericBalance({
    //             coinNativeAmount: temp.coinNativeAmount,
    //             CoinVerified_amount: new uint256[](
    //                 temp.CoinVerified_amount.length + 1
    //             ),
    //             CoinVerified_addr: new address[](
    //                 temp.CoinVerified_addr.length + 1
    //             )
    //         });
    //         for (uint256 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //             new_temp.CoinVerified_addr[i] = temp
    //                 .CoinVerified_addr[i];
    //             new_temp.CoinVerified_amount[i] = temp
    //                 .CoinVerified_amount[i];
    //         }
    //         new_temp.CoinVerified_addr[
    //             temp.CoinVerified_addr.length
    //         ] = tokenaddress;
    //         new_temp.CoinVerified_amount[
    //             temp.CoinVerified_amount.length
    //         ] = amount;
    //         return new_temp;
    //     } else return temp;
    // }

    function subToken(
        GenericBalance storage temp,
        address tokenAddress,
        uint256 amount
    ) public {
        temp.balancesByToken[tokenAddress] -= amount;
    }

    // function subTokenMem(
    //     GenericBalance memory temp,
    //     address tokenaddress,
    //     uint256 amount
    // ) public pure returns (GenericBalance memory) {
    //     for (uint8 i = 0; i < temp.CoinVerified_addr.length; i++) {
    //         if (temp.CoinVerified_addr[i] == tokenaddress) {
    //             temp.CoinVerified_amount[i] -= amount;
    //         }
    //     }
    //     return temp;
    // }

    // function splitBalance(
    //     uint256[] storage Coin,
    //     uint256 splitFactor
    // ) public view returns (uint256[] memory) {
    //     uint256[] memory temp = new uint256[](Coin.length);
    //     for (uint8 i = 0; i < Coin.length; i++) {
    //         uint256 result = SafeMath.div(Coin[i], splitFactor);
    //         temp[i] = result;
    //     }

    //     return temp;
    // }

    function receiveGenericBalance(
        address[] storage receiveaddr,
        uint256[] storage receiveamount,
        address[] storage senderaddr,
        uint256[] storage senderamount
    ) public {
        uint256 a = senderaddr.length;
        uint256 b = receiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (senderaddr[i] == receiveaddr[j]) {
                    flag = false;
                    receiveamount[j] += senderamount[i];
                }
            }

            if (flag) {
                receiveaddr.push(senderaddr[i]);
                receiveamount.push(senderamount[i]);
            }
        }
    }

    function receiveGenericBalanceModified(
        address[] storage receiveaddr,
        uint256[] storage receiveamount,
        address[] storage senderaddr,
        uint256[] memory senderamount
    ) public {
        uint256 a = senderaddr.length;
        uint256 b = receiveaddr.length;

        for (uint8 i = 0; i < a; i++) {
            bool flag = true;
            for (uint8 j = 0; j < b; j++) {
                if (senderaddr[i] == receiveaddr[j]) {
                    flag = false;
                    receiveamount[j] += senderamount[i];
                }
            }

            if (flag) {
                receiveaddr.push(senderaddr[i]);
                receiveamount.push(senderamount[i]);
            }
        }
    }

    function deductTokens(
        uint256 amount,
        uint256 deductamount
    ) public pure returns (uint256) {
        require(amount > deductamount, "Insufficient Funds");
        amount -= deductamount;
        return amount;
    }

    function getTokenAmount(
        address[] memory addresses,
        uint256[] memory amounts,
        address token
    ) public pure returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < addresses.length; i++) {
            if (addresses[i] == token) {
                amount = amounts[i];
            }
        }

        return amount;
    }

    // function genericBalanceDefault()
    //     public
    //     pure
    //     returns (GenericBalance memory)
    // {
    //     GenericBalance memory empty;
    //     return empty;
    // }

    struct BalanceInfo {
        GenericBalance locked;
        GenericBalance liquid;
    }

    ///TODO: need to test this same names already declared in other libraries
    struct EndowmentId {
        uint32 id;
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
        uint256 expiryHeight; // block equiv of the expiry_datetime
    }

    struct Wallet {
        string addr;
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

    function beneficiaryDefault() public pure returns (Beneficiary memory) {
        Beneficiary memory temp = Beneficiary({
            enumData: BeneficiaryEnum.None,
            data: BeneficiaryData({endowId: 0, fundId: 0, addr: address(0)})
        });

        return temp;
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

    struct Ibc {
        string ica;
    }

    ///TODO: need to check this and have a look at this
    enum VaultType {
        Native, // Juno native Vault contract
        Ibc, // the address of the Vault contract on it's Cosmos(non-Juno) chain
        Evm, // the address of the Vault contract on it's EVM chain
        None
    }

    enum BoolOptional {
        False,
        True,
        None
    }

    // struct YieldVault {
    //     string addr; // vault's contract address on chain where the Registrar lives/??
    //     uint256 network; // Points to key in NetworkConnections storage map
    //     address inputDenom; //?
    //     address yieldToken; //?
    //     bool approved;
    //     EndowmentType[] restrictedFrom;
    //     AccountType acctType;
    //     VaultType vaultType;
    // }

    struct Member {
        address addr;
        uint256 weight;
    }

    struct DurationData {
        uint256 height;
        uint256 time;
    }

    enum DurationEnum {
        Height,
        Time
    }

    struct Duration {
        DurationEnum enumData;
        DurationData data;
    }

    enum ExpirationEnum {
        atHeight,
        atTime,
        Never
    }

    struct ExpirationData {
        uint256 height;
        uint256 time;
    }

    struct Expiration {
        ExpirationEnum enumData;
        ExpirationData data;
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

    function canTakeAction(
        Delegate storage delegate,
        address sender,
        uint256 envTime
    ) public view returns (bool) {
        return (
            delegate.addr != address(0) &&
            sender == delegate.addr &&
            (delegate.expires == 0 || envTime <= delegate.expires)
        );
    }

    function canChange(
        SettingsPermission storage permissions,
        address sender,
        address owner,
        uint256 envTime
    ) public view returns (bool) {
        // can be changed if:
        // 1. sender is a valid delegate address and their powers have not expired
        // 2. sender is the endow owner && (no set delegate || an expired delegate) (ie. owner must first revoke their delegation)
        return !permissions.locked || canTakeAction(permissions.delegate, sender, envTime) || sender == owner;
    }

    struct SettingsPermission {
        bool locked;
        Delegate delegate;
    }

    struct SettingsController {
        SettingsPermission strategies;
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
        SettingsPermission categories;
        SettingsPermission splitToLiquid;
        SettingsPermission ignoreUserSplits;
    }

    enum ControllerSettingOption {
        Strategies,
        lockedInvestmentManagement,
        liquidInvestmentManagement,
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
        Categories,
        SplitToLiquid,
        IgnoreUserSplits
    }

    struct EndowmentFee {
        address payoutAddress;
        uint256 percentage;
    }

    uint256 constant FEE_BASIS = 1000;      // gives 0.1% precision for fees
    uint256 constant PERCENT_BASIS = 100;   // gives 1% precision for declared percentages

    enum Status {
        None,
        Pending,
        Open,
        Rejected,
        Passed,
        Executed
    }
    enum Vote {
        Yes,
        No,
        Abstain,
        Veto
    }
}

// SPDX-License-Identifier: UNLICENSED
// author: @stevieraykatz
pragma solidity >=0.8.0;

import "../core/router/IRouter.sol";

abstract contract IVault {
    
    /// @notice Angel Protocol Vault Type 
    /// @dev Vaults have different behavior depending on type. Specifically access to redemptions and 
    /// principle balance
    enum VaultType {
        LOCKED,
        LIQUID
    }

    /// @notice Event emited on each Deposit call
    /// @dev Upon deposit, emit this event. Index the account and staking contract for analytics 
    event DepositMade(
        uint32 indexed accountId, 
        VaultType vaultType, 
        address tokenDeposited, 
        uint256 amtDeposited); 

    /// @notice Event emited on each Redemption call 
    /// @dev Upon redemption, emit this event. Index the account and staking contract for analytics 
    event Redemption(
        uint32 indexed accountId, 
        VaultType vaultType, 
        address tokenRedeemed, 
        uint256 amtRedeemed);

    /// @notice Event emited on each Harvest call
    /// @dev Upon harvest, emit this event. Index the accounts harvested for. 
    /// Rewards that are re-staked or otherwise reinvested will call other methods which will emit events
    /// with specific yield/value details
    /// @param accountIds a list of the Accounts harvested for
    event Harvest(uint32[] indexed accountIds);

    /*////////////////////////////////////////////////
                    EXTERNAL METHODS
    */////////////////////////////////////////////////

    /// @notice returns the vault type
    /// @dev a vault must declare its Type upon initialization/construction 
    function getVaultType() external view virtual returns (VaultType);

    /// @notice deposit tokens into vault position of specified Account 
    /// @dev the deposit method allows the Vault contract to create or add to an existing 
    /// position for the specified Account. In the case that multiple different tokens can be deposited,
    /// the method requires the deposit token address and amount. The transfer of tokens to the Vault 
    /// contract must occur before the deposit method is called.   
    /// @param accountId a unique Id for each Angel Protocol account
    /// @param token the deposited token
    /// @param amt the amount of the deposited token 
    function deposit(uint32 accountId, address token, uint256 amt) payable external virtual;

    /// @notice redeem value from the vault contract
    /// @dev allows an Account to redeem from its staked value. The behavior is different dependent on VaultType.
    /// Before returning the redemption amt, the vault must approve the Router to spend the tokens. 
    /// @param accountId a unique Id for each Angel Protocol account
    /// @param token the deposited token
    /// @param amt the amount of the deposited token 
    /// @return redemptionAmt returns the number of tokens redeemed by the call; this may differ from 
    /// the called `amt` due to slippage/trading/fees
    function redeem(uint32 accountId, address token, uint256 amt) payable external virtual returns (IRouter.RedemptionResponse memory);

    /// @notice redeem all of the value from the vault contract
    /// @dev allows an Account to redeem all of its staked value. Good for rebasing tokens wherein the value isn't
    /// known explicitly. Before returning the redemption amt, the vault must approve the Router to spend the tokens.
    /// @param accountId a unique Id for each Angel Protocol account
    /// @return redemptionAmt returns the number of tokens redeemed by the call
    function redeemAll(uint32 accountId) payable external virtual returns (uint256); 

    /// @notice restricted method for harvesting accrued rewards 
    /// @dev Claim reward tokens accumulated to the staked value. The underlying behavior will vary depending 
    /// on the target yield strategy and VaultType. Only callable by an Angel Protocol Keeper
    /// @param accountIds Used to specify which accounts to call harvest against. Structured so that this can
    /// be called in batches to avoid running out of gas.
    function harvest(uint32[] calldata accountIds) external virtual;

    /*////////////////////////////////////////////////
                INTERNAL HELPER METHODS
    */////////////////////////////////////////////////

    /// @notice nternal method for validating that calls came from the approved AP router 
    /// @dev The registrar will hold a record of the approved Router address. This method must implement a method of 
    /// checking that the msg.sender == ApprovedRouter
    function _isApprovedRouter() internal virtual returns (bool);
}