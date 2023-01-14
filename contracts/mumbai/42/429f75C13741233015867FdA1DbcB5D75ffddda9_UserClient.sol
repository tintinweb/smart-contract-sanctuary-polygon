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

import "../interfaces/ISXTApi.sol";
import "../interfaces/ISXTValidator.sol";

/// @title SXTClient to be inherited for sending request to SXT 
/// @dev This conntract is abstract. It is inherited in UserClient contract, used to send request and record its fulfillment

abstract contract SXTClient {

    /// @dev SXTApi contract address
    ISXTApi public sxtApi;

    /// @dev SXTApi contract address
    ISXTValidator public sxtValidator;

    /// @dev Pending requestIds
    mapping(bytes32 => bool) public pendingRequests;
    
    /**
     * @notice Event emitted when SXTApi contract address is set in contract
     * @param sxtApi contract address of SXTApi contract
     */
    event SXTApiRegistered(address indexed sxtApi);

    /**
     * @notice Event emitted when SXTValidator contract address is set in contract
     * @param sxtValidator contract address of SXTValidator contract
     */
    event SXTValidatorRegistered(address indexed sxtValidator);

    /**
     * @notice Event emitted when a new request is added to pending requests in contract
     * @param requestId ID of newly added request
     */
    event SXTRequested(bytes32 indexed requestId);

    /**
     * @notice Event emitted when a request is removed from pending requests after fulfillmet by SXTValidator
     * @param requestId ID of newly added request
     */
    event SXTFulfilled(bytes32 indexed requestId);

    /**
     * @notice Set SXTApi contract address
     * @param api contract address
     */
    function _setSXTApi(address api) internal {
        sxtApi = ISXTApi(api);
        emit SXTApiRegistered(api);
    }

    /**
     * @notice Set SXTValidator contract address
     * @param validator contract address
     */
    function _setSXTValidator(address validator) internal {
        sxtValidator = ISXTValidator(validator);
        emit SXTValidatorRegistered(validator);
    }

    /**
     * @notice Execute sql query to SXTApi contract
     * @notice Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to ZERO Address for postpaid query
     */
    function _executeQuery(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtApi.executeQuery(resourceId, sqlText, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice Execute sql query to SXTApi contract
     * @notice Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     */
    function _executeQueryPayable(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtApi.executeQueryPayable{value: msg.value}(resourceId, sqlText, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice send execute view request to SXTApi contract
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to ZERO Address for postpaid query
     */
    function _executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        address paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtApi.executeView(viewName, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice send execute view request to SXTApi contract
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function _executeViewPayable(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtApi.executeViewPayable{value: msg.value}(viewName, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice modifier to check if request is pending and delete after fulfillment
     * @param requestId SXT requestId
     */
    modifier recordSXTFulfillment(bytes32 requestId) {
        require(
            pendingRequests[requestId],
            "SXTClient: Only pending request can be fulfilled"
        );
        delete pendingRequests[requestId];
        emit SXTFulfilled(requestId);
        _;
    }

    /// @notice modifier to check if calling contract is sxtValidator or not
    modifier onlySxTValidator() {
        require(ISXTValidator(msg.sender) == sxtValidator, "Only callable by Validator");
        _;
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

import "./abstract/SXTClient.sol";
import "./interfaces/ISXTApi.sol";

/// @title UserClient sample user contract
/// @dev This conntract will be deployed by User
/// @dev Should inherit SXTClient
/// @dev Request will be sent and response recieved to this contract

contract UserClient is SXTClient {

    /// Current reqest ID for which response is recieved
    bytes32 public currentRequestId;

    /// Response for latest request
    string[][] public currentResponse;

    /// @dev The constructor sets the SxTApi and SXTValidator contract address
    constructor (address api, address validator){
        _setSXTApi(api);
        _setSXTValidator(validator);
    }

    /**
     * @notice Set the address of SXTApi contract 
     * @param  api Address of SXTApi contract to be set in the contract
     */
    function setSXTApi(address api) external {
        _setSXTApi(api);
    }

    /**
     * @notice Set the address of validator contract 
     * @param  validator Address of validator contract to be set in the contract
     */    
     function setSXTValidator(address validator) external {
        _setSXTValidator(validator);
    }

    /**
     * @notice Create new query Request in SXTApi
     * @notice To be used in case of Postpaid query or Fungible Token prepaid query
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice pass paymentToken = ZERO Address for postpaid query
     */
    function executeQuery(string memory resourceId, string memory sqlText, string memory biscuitId, address paymentToken) external {
        currentRequestId = _executeQuery(resourceId, sqlText, biscuitId, this.saveResponse.selector, paymentToken);
    }

    /**
     * @notice Create new query Request in SXTApi
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid query
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeQueryPayable(string memory resourceId, string memory sqlText, string memory biscuitId) external payable {
        currentRequestId = _executeQueryPayable(resourceId, sqlText, biscuitId, this.saveResponse.selector);
    }

    /**
     * @notice Create new view Request in SXTApi
     * @notice To be used in case of Postpaid request or Fungible Token prepaid request
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice pass paymentToken = ZERO Address for postpaid request
     */
    function executeView(string memory viewName, string memory biscuitId, address paymentToken) external {
        currentRequestId = _executeView(viewName, biscuitId, this.saveResponse.selector, paymentToken);
    }

    /**
     * @notice Create new view Request in SXTApi
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid request
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeViewPayable(string memory viewName, string memory biscuitId) external payable {
        currentRequestId = _executeViewPayable(viewName, biscuitId, this.saveResponse.selector);
    }
    /**
     * @notice Callback function for storing response sent by SXTValidator
     * @dev can only be called by SXTValidator
     * @param requestId ID of request to fulfill
     * @param response 2D response of string type
     */
    function saveResponse(bytes32 requestId, string[][] calldata response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
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