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

    /// @dev SxTRelay contract address
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
    event SXTRequested(bytes32 indexed requestId);

    /**
     * @notice Event emitted when a request is removed from pending requests after fulfillment by SxTValidator
     * @param requestId ID of newly added request
     */
    event SXTFulfilled(bytes32 indexed requestId);

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
     * @notice Execute sql query to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
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
        emit SXTRequested(requestId);
    }

    /**
     * @notice Execute sql query to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature callback function selector
     * @param paymentToken Address of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to ZERO Address for postpaid query
     */
    function _executeQueryERC20(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string memory paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeQueryERC20(resourceId, sqlText, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }
    
    /**
     * @notice Execute sql query to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
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
        emit SXTRequested(requestId);
    }

    /**
     * @notice send execute view request to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function _executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeView(viewName, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice send execute view request to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     * @param paymentToken Symbol of Fungible Token to pay request fees 
     * @notice paymentToken should be equal to ZERO Address for postpaid query
     */
    function _executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string memory paymentToken
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeViewERC20(viewName, biscuitId, callbackFunctionSignature, paymentToken);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice send execute view request to SxTRelay contract
     * @notice Internal function. Cannot be called by user directly
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param  callbackFunctionSignature Callback function signature from UserClient contract
     */
    function _executeViewNative(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) internal returns (bytes32 requestId) {
        requestId = sxtRelay.executeViewNative{value: msg.value}(viewName, biscuitId, callbackFunctionSignature);
        pendingRequests[requestId] = true;
        emit SXTRequested(requestId);
    }

    /**
     * @notice modifier to check if request is pending and delete after fulfillment
     * @param requestId SxT requestId
     */
    modifier recordSXTFulfillment(bytes32 requestId) {
        require(
            pendingRequests[requestId],
            "SxTClient: Only pending request can be fulfilled"
        );
        delete pendingRequests[requestId];
        emit SXTFulfilled(requestId);
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
     * @notice Event emitted when new SxTPaymentLedger Contract is updated in SxTRelay contract
     * @param payment Address of payment contract set in the contract
     */
    event SxTPaymentLedgerRegistered(address indexed payment);

    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
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
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param paymentCurrency Address of Fungible Token to pay request fees 
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryERC20(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external returns (bytes32);
    /**
     * @notice Function to get Query Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SxTRequestQueryV1 event emitted in this function which is listened by Oracle node service
     * @param sqlText SQL Query for executing
     * @param resourceId ID for selecting cluster on Gateway
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeQueryNative(
        string memory sqlText,
        string memory resourceId,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external payable returns (bytes32);

    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
     * @dev  SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
     * @param viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param callbackFunctionSignature Callback function signature from UserClient contract
     */
    function executeView(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature
    ) external returns (bytes32);

    /**
    * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
    * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
    * @param  viewName View name for fetching response data
    * @param  callbackFunctionSignature Callback function signature from UserClient contract
    * @param paymentCurrency Address of Fungible Token to pay request fees
    * @param biscuitId Biscuit ID for authorization of request in Gateway
    * @notice paymentToken should be equal to ZERO Address for postpaid request
    */
    function executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        bytes4 callbackFunctionSignature,
        string calldata paymentCurrency
    ) external returns (bytes32);
    
    /**
     * @notice Function to get View Request parameters from UserClient and pass on to register in SxTValidator
     * @dev SXTRequestViewV1 event emitted in this function which is listened by Oracle node service
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
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SXTRequest memory, bytes memory);

    /**
     * Event emitted when new SxTRelay Contract is updated in contract
     * @param sxtRelay Address of new SxTRelay contract
     */    
    event SxTRelayRegistered(address indexed sxtRelay);

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
     * Event emitted when the response is received by SxTValidator contract, for a request
     * @param requestId Request ID for which response received
     * @param data Response received in encoded format
     */
    event SXTResponseRegistered(bytes32 indexed requestId, bytes data);

    /**
     * Event emitted when config arguments are updated in the contract
     * @param prevConfigBlockNumber block number which previous config was set
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
pragma solidity 0.8.7;

import "./abstract/SxTClient.sol";
import "./interfaces/ISxTRelay.sol";

/// @title UserClient sample user contract
/// @dev This contract will be deployed by User
/// @dev Should inherit SxTClient
/// @dev Request will be sent and response received to this contract

contract UserClientMulti is SxTClient {
    /// Current request ID for which response is received
    bytes32 public currentRequestId;

    /// Response for latest request
    uint256 public currentUintResponse;
    int256 public currentIntResponse;
    string public currentStringResponse;
    bool public currentBoolResponse;
    bytes32 public currentBytes32Response;
    bytes public currentBytesResponse;
    string[][] public currentString2DResponse;
    uint256 public currentResponse1;
    uint256 public currentResponse2;
    address public currentAddressResponse;

    /// @dev The constructor sets the SxTRelay and SxTValidator contract address
    constructor(address relay, address validator) {
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
     * @notice Create new query Request in SxTRelay
     * @notice To be used in case of Postpaid query
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeQuery(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId
    ) external {
        currentRequestId = _executeQuery(
            resourceId,
            sqlText,
            biscuitId,
            this.saveStringResponse.selector
        );
    }

    /**
     * @notice Create new query Request in SxTRelay
     * @notice To be used in case of prepaid ERC20 payment request
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Symbol of Fungible Token to pay request fees
     * @notice pass paymentToken = ZERO Address for postpaid query
     */
    function executeQueryERC20(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId,
        string memory paymentToken
    ) external {
        currentRequestId = _executeQueryERC20(
            resourceId,
            sqlText,
            biscuitId,
            this.saveString2DResponse.selector,
            paymentToken
        );
    }

    /**
     * @notice Create new query Request in SxTRelay
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid query
     * @param resourceId Resource ID to identify database cluster on gateway
     * @param sqlText SQL Query text
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeQueryNative(
        string memory resourceId,
        string memory sqlText,
        string memory biscuitId
    ) external payable {
        currentRequestId = _executeQueryNative(
            resourceId,
            sqlText,
            biscuitId,
            this.saveString2DResponse.selector
        );
    }

    /**
     * @notice Create new view Request in SxTRelay
     * @notice To be used in case of prepaid ERC20 payment request
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     * @param paymentToken Symbol of Fungible Token to pay request fees
     * @notice pass paymentToken = ZERO Address for postpaid request
     */
    function executeViewERC20(
        string memory viewName,
        string memory biscuitId,
        string memory paymentToken
    ) external {
        currentRequestId = _executeViewERC20(
            viewName,
            biscuitId,
            this.saveString2DResponse.selector,
            paymentToken
        );
    }

    /**
     * @notice Create new view Request in SxTRelay
     * @notice Payable function. Need to send native currency as value
     * @notice To be used in case of Native currency prepaid request
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeViewNative(string memory viewName, string memory biscuitId)
        external
        payable
    {
        currentRequestId = _executeViewNative(
            viewName,
            biscuitId,
            this.saveString2DResponse.selector
        );
    }

    /**
     * @notice Create new view Request in SxTRelay
     * @notice To be used in case of Postpaid view request
     * @param  viewName View name for fetching response data
     * @param biscuitId Biscuit ID for authorization of request in Gateway
     */
    function executeViewInt(string memory viewName, string memory biscuitId)
        external
    {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveUintResponse.selector
        );
    }

    function executeViewString(string memory viewName, string memory biscuitId)
        external
    {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveStringResponse.selector
        );
    }

    function executeViewBool(string memory viewName, string memory biscuitId)
        external
    {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveBoolResponse.selector
        );
    }

    function executeViewBytes32(string memory viewName, string memory biscuitId)
        external
    {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveBytes32Response.selector
        );
    }

    function executeViewString2D(
        string memory viewName,
        string memory biscuitId
    ) external {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveString2DResponse.selector
        );
    }

    function executeViewMultiWord(
        string memory viewName,
        string memory biscuitId
    ) external {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveMultiWordResponse.selector
        );
    }

    function executeViewAddress(
        string memory viewName,
        string memory biscuitId
    ) external {
        currentRequestId = _executeView(
            viewName,
            biscuitId,
            this.saveAddressResponse.selector
        );
    }

    function saveUintResponse(bytes32 requestId, uint256 response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentUintResponse = response;
    }

    function saveIntResponse(bytes32 requestId, int256 response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentIntResponse = response;
    }

    function saveStringResponse(bytes32 requestId, string memory response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentStringResponse = response;
    }

    function saveBoolResponse(bytes32 requestId, bool response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentBoolResponse = response;
    }

    function saveBytes32Response(bytes32 requestId, bytes32 response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentBytes32Response = response;
    }


    function saveBytesResponse(bytes32 requestId, bytes memory response)
        external
        onlySxTValidator
        recordSXTFulfillment(requestId)
    {
        require(currentRequestId == requestId, "Invalid request");
        currentBytesResponse = response;
    }

    /**
     * @notice Callback function for storing response sent by SxTValidator
     * @dev can only be called by SxTValidator
     * @param requestId ID of request to fulfill
     * @param response 2D response of string type
     */
    function saveString2DResponse(
        bytes32 requestId,
        string[][] calldata response
    ) external onlySxTValidator recordSXTFulfillment(requestId) {
        require(currentRequestId == requestId, "Invalid request");
        delete currentString2DResponse;
        uint256 length = response.length;
        // Store response
        for (uint256 i = 0; i < length; i++) {
            uint256 inLength = response[i].length;
            string[] memory row = new string[](inLength);
            for (uint256 j = 0; j < inLength; j++) {
                row[j] = response[i][j];
            }
            currentString2DResponse.push(row);
        }
    }

    function saveMultiWordResponse(
        bytes32 requestId,
        uint256 response1,
        uint256 response2
    ) external onlySxTValidator recordSXTFulfillment(requestId) {
        require(currentRequestId == requestId, "Invalid request");
        currentResponse1 = response1;
        currentResponse2 = response2;
    }

    function saveAddressResponse(
        bytes32 requestId,
        address response
    ) external onlySxTValidator recordSXTFulfillment(requestId) {
        require(currentRequestId == requestId, "Invalid request");
        currentAddressResponse = response;
    }
    
}