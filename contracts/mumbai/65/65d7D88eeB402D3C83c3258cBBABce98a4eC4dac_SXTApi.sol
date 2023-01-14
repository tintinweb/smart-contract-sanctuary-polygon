// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Admin related functionalities
/// @dev This conntract is abstract. It is inherited in SXTApi and SXTValidator to set and handle admin only functions

abstract contract Admin {
    /// @dev Address of admin set by inheriting contracts
    address public admin;

    /// @notice Modifier for checking if Admin address has called the function
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    /**
     * @notice Get the address of Admin wallet
     * @return adminAddress Address of Admin wallet set in the contract
     */
    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    /**
     * @notice Set the address of Admin wallet
     * @param  adminAddress Address of Admin wallet to be set in the contract
     */
    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Initializer for inheriting contracts
/// @dev This conntract is abstract. It is inherited in SXTApi for initializing Validator contract for now. But will be used more in future

abstract contract Initializer {

    /// @dev stores if the inheriting contract has been initialized or not
    bool private _isInitialized;

    /// @notice Modifier for checking if the inheriting contract has been already initialized or not before initializing.
    modifier initializer() {
        require(!_isInitialized, "Initializer: already initialized");
        _;
        _isInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTApi {
    /**
     * @notice Event emitted when a new query request is registered in SXTValidator Contract
     * @param requestId ID generated for new request
     * @param requester Address of UserClient contract
     * @param paramHash Hash of request parameters
     * @param sqlTextData SQL query in bytes format
     * @param resourceIdData Resource ID in bytes format 
     * @param biscuitIdData Biscuit ID for authorization in bytes format 
     * @param isPrepaid Specify if the request registered is prepaid or postpaid
     */
    event SxTRequestQueryV1(
        bytes32 indexed requestId,
        address requester,
        bytes paramHash,
        bytes sqlTextData, 
        bytes resourceIdData,
        bytes biscuitIdData,
        bool isPrepaid
    );

    /**
     * @notice Event emitted when a new view request is registered in SXTValidator Contract
     * @param requestId ID generated for new request
     * @param requester Address of UserClient contract
     * @param paramHash Hash of request parameters
     * @param viewNameData View name in bytes format
     * @param biscuitIdData Biscuit ID for authorization in bytes format 
     * @param isPrepaid Specify if the request registered is prepaid or postpaid
     */
    event SxTRequestViewV1(
        bytes32 indexed requestId,
        address requester,
        bytes paramHash,
        bytes viewNameData, 
        bytes biscuitIdData,
        bool isPrepaid
    );

    /**
     * @notice Event emitted when new SXTValidator Contract is updated in SXTApi contract
     * @param validator Address of validator contract set in the contract
     */
    event SXTValidatorRegistered(address indexed validator);

    /**
     * @notice Event emitted when new SXTPayment Contract is updated in SXTApi contract
     * @param payment Address of payment contract set in the contract
     */
    event SXTPaymentRegistered(address indexed payment);

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SXTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node srevice
     * @param resourceId ID for selecting cluster on Gateway
     * @param sqlText SQL Query for executing
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQuery(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) external returns (bytes32);

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SXTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node srevice
     * @param resourceId ID for selecting cluster on Gateway
     * @param sqlText SQL Query for executing
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryPayable(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SXTValidator
     * @dev  SXTRequestViewV1 event emitted in this function which is listened by Oracle node srevice
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) external returns (bytes32);

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SXTValidator
     * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node srevice
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeViewPayable(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title SXTApi handles request from SXTClient
/// @dev This conntract will be deployed by SXT team, used to emit event which will be listened by Oracle node

interface ISXTPayment {

    /**
     * @notice Function to add price of a token address
     * @param  tokenAddress Token address to set the price
     * @param  tokenPrice Price for the token
     */
    function setTokenPrice(
        address tokenAddress,
        uint128 tokenPrice
    ) external;

    /**
     * @notice Function to get price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function getTokenPrice(
        address tokenAddress
    ) external returns (uint128);

    /**
     * @notice Function to add Price of a token address
     * @param  tokenAddress ID for selecting cluster on Gateway
     */
    function hasTokenPrice(
        address tokenAddress
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTValidator {

    // Structure for storing request data
    struct SXTRequest {
        bytes32 requestId;
        uint128 createdAt;
        uint128 expiredAt;
        bytes4 callbackFunctionSignature;
        address callbackAddress;
    }

    // Structure for storing signer data
    struct Signer {
        bool active;
        // Index of oracle in signersList/transmittersList
        uint8 index;
    }

    // Structure for storing config arguments of SXTValidator Contract
    struct ValidatorConfigArgs {
        address[] signers;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }
    /**
     * Function for registering a new request in SXTValidator
     * @param callbackAddress Address of user smart contract which sent the request
     * @param callbackFunctionSignature Signature of the callback function from user contract, which SXTValiddator should call for returning response
     */    
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SXTRequest memory, bytes memory);

    /**
     * Set maximum number of oracles to allow
     * @param count New maximum number of oracles to allow
     * @param oracleMask New Oracle mask to check the signature duplication
     */
    function setMaxOracleCount(uint64 count, uint256 oracleMask ) external;

    /**
     * Event emitted when new SXTApi Contract is updated in contract
     * @param sxtApi Address of new SXTApi contract
     */    
     event SXTApiRegistered(address indexed sxtApi);

    /**
     * Event emitted when new request expiry duration is updated in contract
     * @param expireTime Duration of seconds in which a request should expire
     */
    event SXTRequestExpireTimeRegistered(uint256 expireTime);
    
    /**
     * Event emitted when Maximum number of possible oracles is updated in contract
     * @param count New maximum number of oracles to allow
     */
    event SXTMaximumOracleCountRegistered(uint64 count);

    /**
     * Event emitted when the response is received by SXTValidator contract, for a request
     * @param requestId Request ID for which response received
     * @param data Response received in encoded format
     */
    event SXTResponseRegistered(bytes32 indexed requestId, bytes data);

    /**
     * Event emitted when config arguments are updated in the contract
     * @param prevConfigBlockNumber block numberi which previous config was set
     * @param configCount Number of times the contract config is updated till now
     * @param signers Array of list of valid signers for a response
     * @param onchainConfig Encoded version of config args stored onchain
     * @param offchainConfigVersion Version of latest config
     * @param offchainConfig Encoded version of config args stored offchain
     */
    event SXTConfigRegistered(
        uint32 prevConfigBlockNumber,
        uint64 configCount,
        address[] signers,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstract/Admin.sol";
import "./abstract/Initializer.sol";

import "./interfaces/ISXTApi.sol";
import "./interfaces/ISXTPayment.sol";
import "./interfaces/ISXTValidator.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SXTApi handles request from SXTClient
/// @dev This conntract will be deployed by SXT team, used to emit event which will be listened by Oracle node

contract SXTApi is Admin, Initializer, Pausable, ISXTApi {

    // Address to represent Native Currency in the contract
    address constant private NATIVE_CURRENCY = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    /// @dev Instance of sxtValidator to intteract with
    ISXTValidator public sxtValidator;

    /// @dev Instance of sxtPayment to intteract with
    ISXTPayment public sxtPayment;

    /// @notice constructor sets the admin address of contract
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Initialize the validator and payment contract addresses in SXTApi contract 
     * @param  validator Address of validator contract to be set in the contract
     * @param  payment Address of payment contract to be set in the contract
     */
    function initialize(address validator, address payment)
        external
        initializer
        onlyAdmin
    {
        setSXTValidator(validator);
        setSXTPayment(payment);
    }

    /**
     * @notice Set the address of validator contract 
     * @param  validator Address of validator contract to be set in the contract
     */
    function setSXTValidator(address validator) public onlyAdmin {
        sxtValidator = ISXTValidator(validator);
        emit SXTValidatorRegistered(validator);
    }

    /**
     * @notice Set the address of payment contract 
     * @param  payment Address of payment contract to be set in the contract
     */
    function setSXTPayment(address payment) public onlyAdmin {
        sxtPayment = ISXTPayment(payment);
        emit SXTPaymentRegistered(payment);
    }
    
    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SXTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node srevice
     * @param  resourceId ID for selecting cluster on Gateway
     * @param  sqlText SQL Query for executing
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to ZERO Address for postpaid request
     */
    function executeQuery(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) external override whenNotPaused returns (bytes32) {
        bool isPrepaid;
        if( paymentToken != ZERO_ADDRESS ){
            IERC20 token = IERC20( paymentToken );
            require( sxtPayment.hasTokenPrice( paymentToken ) , "SXTApi: Token not allowed" );
            uint128 price = sxtPayment.getTokenPrice( paymentToken );
            require( checkAllowance( uint256(price), token ), "SXTApi: Insufficient Allowance" );
            require( token.transferFrom(tx.origin, address(this), uint256(price)), "SXTApi: Could not tranfer payment");
            isPrepaid = true;
        }
        (bytes32 requestId, bytes memory paramHash, bytes memory sqlTextData, bytes memory resourceIdData, bytes memory biscuitIdData) = _registerQueryRequest(
            resourceId,
            sqlText,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestQueryV1(requestId, msg.sender, paramHash, sqlTextData, resourceIdData, biscuitIdData, true);
        return requestId;

    }

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SXTValidator
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid request
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node srevice
     * @param  resourceId ID for selecting cluster on Gateway
     * @param  sqlText SQL Query for executing
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryPayable(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable override whenNotPaused returns (bytes32) {
        require( msg.value >= uint256(sxtPayment.getTokenPrice( NATIVE_CURRENCY )), "SXTApi: Insufficient Native currency payment");
        (bytes32 requestId, bytes memory paramHash, bytes memory sqlTextData, bytes memory resourceIdData, bytes memory biscuitIdData) = _registerQueryRequest(
            resourceId,
            sqlText,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestQueryV1(requestId, msg.sender, paramHash, sqlTextData, resourceIdData, biscuitIdData, true);
        return requestId;
    }

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SXTValidator
     * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node srevice
     * @param  viewName View name for fetching response data
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @notice paymentToken should be equal to ZERO Address for postpaid request
     */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) external override whenNotPaused returns (bytes32) {
        bool isPrepaid;
        if( paymentToken != ZERO_ADDRESS ){
            IERC20 token = IERC20( paymentToken );
            require( sxtPayment.hasTokenPrice( paymentToken ) , "SXTApi: Token not allowed" );
            uint128 price = sxtPayment.getTokenPrice( paymentToken );
            require( checkAllowance( uint256(price), token ), "SXTApi: Insufficient Allowance" );
            require( token.transferFrom(tx.origin, address(this), uint256(price)), "SXTApi: Could not tranfer payment");
            isPrepaid = true;
        }
        (bytes32 requestId, bytes memory paramHash, bytes memory viewNameData, bytes memory biscuitIdData) = _registerViewRequest(
            viewName,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestViewV1(requestId, msg.sender, paramHash, viewNameData, biscuitIdData, isPrepaid);
        return requestId;

    }

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SXTValidator
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid request
     * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node srevice
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeViewPayable(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable override whenNotPaused returns (bytes32) {
        require( msg.value >= uint256(sxtPayment.getTokenPrice( NATIVE_CURRENCY )), "SXTApi: Insufficient Native currency payment");
        (bytes32 requestId, bytes memory paramHash, bytes memory viewNameData, bytes memory biscuitIdData) = _registerViewRequest(
            viewName,
            biscuitId,
            callbackFunctionSignature
        );
        emit SxTRequestViewV1(requestId, msg.sender, paramHash, viewNameData, biscuitIdData, true);
        return requestId;
    }

    /**
     * @notice Function to register Query request in SXTValidator
     * @notice Internal function. Cannot be called by user directly
     * @param  resourceId ID for selecting cluster on Gateway
     * @param  sqlText SQL Query for executing
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function _registerQueryRequest( 
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32, bytes memory, bytes memory, bytes memory, bytes memory ){
        (
            ISXTValidator.SXTRequest memory request,
            bytes memory paramHash
        ) = sxtValidator.registerSXTRequest(
                msg.sender,
                callbackFunctionSignature
            );

        bytes memory sqlTextData = bytes(sqlText);
        bytes memory resourceIdData = bytes(resourceId);
        bytes memory biscuitIdData = bytes(biscuitId);

        return (request.requestId, paramHash, sqlTextData, resourceIdData, biscuitIdData);
    }
    
    /**
     * @notice Function to register View request in SXTValidator
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function _registerViewRequest( 
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32, bytes memory, bytes memory, bytes memory ){
        (
            ISXTValidator.SXTRequest memory request,
            bytes memory paramHash
        ) = sxtValidator.registerSXTRequest(
                msg.sender,
                callbackFunctionSignature
            );

        bytes memory viewNameData = bytes(viewName);
        bytes memory biscuitIdData = bytes(biscuitId);

        return (request.requestId, paramHash, viewNameData, biscuitIdData);
    }

    /**
     * @notice Function to pause the contract
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Function to unpause the contract
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    function checkAllowance(uint256 amount, IERC20 token) internal view returns (bool success){
        success = token.allowance(tx.origin, address(this)) >= amount;  
    }
}