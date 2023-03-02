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
pragma solidity 0.8.7;

import "../interfaces/ISxTRelay.sol";
import "../interfaces/ISxTValidator.sol";

/// @title SxTClient to be inherited for sending request to SxT 
/// @dev This contract is abstract. It is inherited in UserClient contract, used to send request and record its fulfillment

abstract contract SxTClient {

    /// @dev SxTRelay contract address
    ISxTRelay public sxtRelay;

    /// @dev SxTValidator contract address
    ISxTValidator public sxtValidator;

    /// @dev Pending requestIds
    mapping(bytes32 => bool) public pendingRequests;
    
    /**
     * @notice Event emitted when SxTRelay contract address is set in contract
     * @param sxtRelay contract address of SxTRelay contract
     */
    event SxTRelayRegistered(address indexed sxtRelay);

    /**
     * @notice Event emitted when SxTValidator contract address is set in contract
     * @param sxtValidator contract address of SxTValidator contract
     */
    event SxTValidatorRegistered(address indexed sxtValidator);

    /**
     * @notice Event emitted when a new request is added to pending requests in contract
     * @param requestId ID of newly added request
     */
    event SxTRequested(bytes32 indexed requestId);

    /**
     * @notice Event emitted when a request is removed from pending requests after fulfillment by SxTValidator
     * @param requestId ID of newly added request
     */
    event SxTFulfilled(bytes32 indexed requestId);

    /**
     * @notice Set SxTRelay contract address
     * @param relay contract address
     */
    function _setSxTRelay(address relay) internal {
        sxtRelay = ISxTRelay(relay);
        emit SxTRelayRegistered(relay);
    }

    /**
     * @notice Set SxTValidator contract address
     * @param validator contract address
     */
    function _setSxTValidator(address validator) internal {
        sxtValidator = ISxTValidator(validator);
        emit SxTValidatorRegistered(validator);
    }

    /**
     * @notice Pass the request sql query to SxTRelay contract with fee payment in Native currency of chain (ETH in case of ethereum).
     * @dev To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @dev To be used in case of Native currency 'pay as you go' request model     
     * @dev Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     */
    function _executeQuery(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeQuery(resourceId, sqlText, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }

    /**
     * @notice Pass the request sql view to SxTRelay contract without any fee payment deduction in contract. 
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @dev Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector     
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to address of valid ERC20 token acceptable by SxT
     */
    function _executeQueryERC20(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeQueryERC20(resourceId, sqlText, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }
    
    /**
     * @notice Pass the request sql query to SxTRelay contract with fee payment in Native currency of chain (ETH in case of ethereum).
     * @dev To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @dev To be used in case of Native currency 'pay as you go' request model     
     * @dev Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     */
    function _executeQueryNative(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeQueryNative{value: msg.value}(resourceId, sqlText, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }

    /**
     * @notice Pass the request sql view to SxTRelay contract without any fee payment deduction in contract. 
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @dev Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     */
    function _executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeView(viewName, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }

    /**
     * @notice Pass the request sql view to SxTRelay contract with fee payment in ERC20 token.
     * @dev To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used when fee not prepaid on dapp.
     * @dev To be used in case of ERC20 Token 'pay as you go' request model
     * @dev Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     * @param paymentToken Symbol of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to address of valid ERC20 token acceptable by SxT
     */
    function _executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeViewERC20(viewName, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }

    /**
     * @notice Pass the request sql view to SxTRelay contract with fee payment in Native currency of chain (ETH in case of ethereum).
     * @dev To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @dev To be used in case of Native currency 'pay as you go' request model     
     * @dev Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     */
    function _executeViewNative(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeViewNative{value: msg.value}(viewName, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SxTRequested(requestId);
    }

    /**
     * @notice modifier to check if request is pending and delete after fulfillment
     * @param requestId SxT requestId
     */
    modifier recordSxTFulfillment(bytes32 requestId) {
        require(
            pendingRequests[requestId],
            "SxTClient: Only pending request can be fulfilled"
        );
        delete pendingRequests[requestId];
        emit SxTFulfilled(requestId);
        _;
    }

    /// @notice modifier to check if calling contract is sxtValidator or not
    modifier onlySxTValidator() {
        require(ISxTValidator(msg.sender) == sxtValidator, "Only callable by Validator");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTRelay {
    /**
     * @notice Event emitted when a new query request is registered in SxTValidator Contract
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
     * @notice Event emitted when a new view request is registered in SxTValidator Contract
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
     * @notice Event emitted when new SxTValidator Contract is updated in SxTRelay contract
     * @param validator Address of validator contract set in the contract
     */
    event SxTValidatorRegistered(address indexed validator);

    /**
     * @notice Event emitted when new SxTPaymentManager Contract is updated in SxTRelay contract
     * @param payment Address of payment contract set in the contract
     */
    event SxTPaymentManagerRegistered(address indexed payment);

    /**
     * @notice Function to get 'prepaid' Query Request parameters from UserClient
     * @dev Pass on the request to register in SxTValidator
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQuery(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);

    /**
     * @notice Function to get 'pay as you go' Query Request parameters from UserClient with fee payment in ERC20 token.
     * @dev To be called if SxTPaymentManager contract needs to deduct fee at the time of request registration. Can be used when fee not prepaid on dapp.
     * @dev To be used in case of ERC20 Token 'pay as you go' request model
     * @param sqlText SQL Query text
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentCurrency Address of Fungible Token to pay request fees 
     * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeQueryERC20(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentCurrency
    ) external returns (bytes32);

    /**
     * @notice Function to get 'prepaid' View Request parameters from UserClient
     * @dev Pass on the request to register in SxTValidator
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
    */
    function executeQueryNative(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);

    /**
     * @notice Function to get 'prepaid' View Request parameters from UserClient
     * @dev Pass on the request to register in SxTValidator
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model    
     * @dev SxTRequestViewV1 event emitted in this function which is listened by Oracle node service
     * @param  viewName View name for fetching response data
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     * @param biscuitId Biscuit ID for authorization of request in Gateway
    */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);

    /**
     * @notice Function to get 'pay as you go' Query Request parameters from UserClient with fee payment in ERC20 token.
     * @dev To be called if SxTPaymentManager contract needs to deduct fee at the time of request registration. Can be used when fee not prepaid on dapp.
     * @dev To be used in case of ERC20 Token 'pay as you go' request model
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentCurrency Address of Fungible Token to pay request fees 
     * @notice paymentCurrency should be equal to address of valid ERC20 token acceptable by SxT
    */
    function executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentCurrency
    ) external returns (bytes32);

    /**
     * @notice Function to get 'pay as you go' Query Request parameters from UserClient with fee payment in Native currency of chain.
     * @dev To be called if contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @dev Payable function. Need to send native currency as value
     * @dev To be used in case of Native currency 'pay as you go' request model 
     * @dev SxTRequestViewV1 event emitted in this function which is listened by Oracle node service
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
    */
    function executeViewNative(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTValidator {

    // Structure for storing request data
    struct SxTRequest {
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

    // Structure for storing config arguments of SxTValidator Contract
    struct ValidatorConfigArgs {
        address[] signers;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }
    /**
     * Function for registering a new request in SxTValidator
     * @param callbackAddress Address of user smart contract which sent the request
     * @param callbackFunctionSignature Signature of the callback function from user contract, which SxTValidator should call for returning response
     */    
    function registerSxTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SxTRequest memory, bytes memory);

    /**
     * Event emitted when new SxTRelay Contract is updated in contract
     * @param sxtRelay Address of new SxTRelay contract
     */    
    event SxTRelayRegistered(address indexed sxtRelay);

    /**
     * Event emitted when new request expiry duration is updated in contract
     * @param expireTime Duration of seconds in which a request should expire
     */
    event SxTRequestExpireTimeRegistered(uint256 expireTime);
    
    /**
     * Event emitted when Maximum number of possible oracles is updated in contract
     * @param count New maximum number of oracles to allow
     */
    event SxTMaximumOracleCountRegistered(uint64 count);

    /**
     * Event emitted when the response is received by SxTValidator contract, for a request
     * @param requestId Request ID for which response received
     * @param data Response received in encoded format
     */
    event SxTResponseRegistered(bytes32 indexed requestId, bytes data);

    /**
     * Event emitted when config arguments are updated in the contract
     * @param prevConfigBlockNumber block number which previous config was set
     * @param configCount Number of times the contract config is updated till now
     * @param signers Array of list of valid signers for a response
     * @param onchainConfig Encoded version of config args stored onchain
     * @param offchainConfigVersion Version of latest config
     * @param offchainConfig Encoded version of config args stored offchain
     */
    event SxTConfigRegistered(
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
pragma solidity 0.8.7;

import "./abstract/SxTClient.sol";
import "./interfaces/ISxTRelay.sol";

/// @title UserClient sample user contract
/// @dev This contract will be deployed by User
/// @dev Should inherit SxTClient
/// @dev Request will be sent and response received to this contract

contract UserClient is SxTClient {

    /// Current request ID for which response is received
    bytes32 public currentRequestId;

    /// Response for latest request
    string[][] public currentResponse;

    /// @dev The constructor sets the SxTRelay and SxTValidator contract address
    constructor (address relay, address validator){
        _setSxTRelay(relay);
        _setSxTValidator(validator);
    }

    /**
     * @notice Set the address of SxTRelay contract 
     * @param  relay Address of SxTRelay contract to be set in the contract
     */
    function setSxTRelay(address relay) external {
        _setSxTRelay(relay);
    }

    /**
     * @notice Set the address of validator contract 
     * @param  validator Address of validator contract to be set in the contract
     */    
     function setSxTValidator(address validator) external {
        _setSxTValidator(validator);
    }

    /**
     * @notice Create new 'prepaid' query Request in SxTRelay without any on-contract fee acceptance
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeQuery(string memory resourceId, string memory sqlText, string memory biscuitId) external {
        currentRequestId = _executeQuery(resourceId, sqlText, biscuitId, this.saveResponse.selector);
    }

    /**
     * @notice Create new query Request in SxTRelay contract with fee payment acceptance in ERC20 token.
     * @notice To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used when fee not prepaid on dapp.
     * @notice To be used in case of ERC20 Token 'pay as you go' request model
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to address of valid ERC20 token acceptable by SxT
     */
    function executeQueryERC20(string memory resourceId, string memory sqlText, string memory biscuitId, address paymentToken) external {
        currentRequestId = _executeQueryERC20(resourceId, sqlText, biscuitId, this.saveResponse.selector, paymentToken);
    }

    /**
     * @notice Create new query Request in SxTRelay contract with fee payment in Native currency of chain (ETH in case of ethereum).
     * @notice To be called if SxTPaymentManager contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @notice To be used in case of Native currency 'pay as you go' request model
     * @notice Payable function. Need to send native currency as value
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeQueryNative(string memory resourceId, string memory sqlText, string memory biscuitId) external payable {
        currentRequestId = _executeQueryNative(resourceId, sqlText, biscuitId, this.saveResponse.selector);
    }

    /**
     * @notice Create new 'prepaid' view Request in SxTRelay without any on-contract fee acceptance
     * @dev To be called if prepaid fee on dapp i.e. 'prepaid' request model
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeView(string memory viewName, string memory biscuitId) external {
        currentRequestId = _executeView(viewName, biscuitId, this.saveResponse.selector);
    }

    /**
     * @notice Create new view Request in SxTRelay contract with fee payment acceptance in ERC20 token.
     * @notice To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used when fee not prepaid on dapp.
     * @notice To be used in case of ERC20 Token 'pay as you go' request model
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to address of valid ERC20 token acceptable by SxT
     */
    function executeViewERC20(string memory viewName, string memory biscuitId, address paymentToken) external {
        currentRequestId = _executeViewERC20(viewName, biscuitId, this.saveResponse.selector, paymentToken);
    }

    /**
     * @notice Create new view Request in SxTRelay contract with fee payment in Native currency of chain (ETH in case of ethereum).
     * @notice To be called if SxTPaymentLedger contract needs to deduct fee at the time of request registration. Can be used if fee not prepaid on dapp
     * @notice To be used in case of Native currency 'pay as you go' request model     
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeViewNative(string memory viewName, string memory biscuitId) external payable {
        currentRequestId = _executeViewNative(viewName, biscuitId, this.saveResponse.selector);
    }
    
    /**
     * @notice Callback function for storing response sent by SxTValidator
     * @dev can only be called by SxTValidator
     * @param requestId ID of request to fulfill
     * @param response 2D response of string type
     */
    function saveResponse(bytes32 requestId, string[][] calldata response)
        external
        onlySxTValidator
        recordSxTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        delete currentResponse;
        uint256 length = response.length;
        // Store response
        for (uint256 i = 0; i < length; i++) {
            uint256 inLength = response[i].length;
            string[] memory row = new string[](inLength);
            for (uint256 j = 0; j < inLength; j++) {
                row[j] = response[i][j];
            }
            currentResponse.push(row);
        }
    }
}