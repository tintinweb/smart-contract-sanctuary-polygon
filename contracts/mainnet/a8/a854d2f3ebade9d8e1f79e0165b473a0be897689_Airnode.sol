/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// File: contracts/contracts/interfaces/ITemplateStore.sol


pragma solidity 0.6.12;


interface ITemplateStore {
    event TemplateCreated(
        bytes32 indexed templateId,
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
        );

    function createTemplate(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        returns (bytes32 templateId);

    function getTemplate(bytes32 templateId)
        external
        view
        returns (
            bytes32 providerId,
            bytes32 endpointId,
            uint256 requesterIndex,
            address designatedWallet,
            address fulfillAddress,
            bytes4 fulfillFunctionId,
            bytes memory parameters
        );
}

// File: contracts/contracts/TemplateStore.sol


pragma solidity 0.6.12;



/// @title The contract where request templates are stored
/// @notice Most requests are repeated many times with the same parameters.
/// This contract allows the requester to announce their parameters once, then
/// refer to that announcement when they are making a request, instead of
/// passing the same parameters repeatedly.
/// @dev A template is composed of two groups of parameters. The first group is
/// requester-agnostic (providerId, endpointInd, parameters), while the second
/// group is requester-specific (requesterIndex, designatedWallet, fulfillAddress,
/// fulfillFunctionId). Short requests refer to a template and use both of
/// these groups of parameters. Regular requests refer to a template, but only
/// use the requester-agnostic parameters of it, and require the client to
/// provide the requester-specific parameters. In addition, both regular and
/// short requests can overwrite parameters encoded in the parameters field of
/// the template at request-time. See Airnode.sol for more information
/// (specifically makeShortRequest() and makeRequest()).
contract TemplateStore is ITemplateStore {
    struct Template {
        bytes32 providerId;
        bytes32 endpointId;
        uint256 requesterIndex;
        address designatedWallet;
        address fulfillAddress;
        bytes4 fulfillFunctionId;
        bytes parameters;
        }

    mapping(bytes32 => Template) internal templates;


    /// @notice Creates a request template with the given parameters,
    /// addressable by the ID it returns
    /// @dev A specific set of request parameters will always have
    /// the same ID. This means a few things: (1) You can compute the expected
    /// ID of a set of parameters off-chain, (2) creating a new template with
    /// the same parameters will overwrite the old one and return the same
    /// template ID, (3) after you query a template with its ID, you can verify
    /// its integrity by applying the hash and comparing the result with the
    /// ID.
    /// @param providerId Provider ID from ProviderStore
    /// @param endpointId Endpoint ID from EndpointStore
    /// @param requesterIndex Requester index from RequesterStore
    /// @param designatedWallet Designated wallet that is requested to fulfill
    /// the request
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param parameters Static request parameters (i.e., parameters that will
    /// not change between requests, unlike the dynamic parameters determined
    /// at runtime)
    /// @return templateId Request template ID
    function createTemplate(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        override
        returns (bytes32 templateId)
    {
        templateId = keccak256(abi.encode(
            providerId,
            endpointId,
            requesterIndex,
            designatedWallet,
            fulfillAddress,
            fulfillFunctionId,
            parameters
            ));
        templates[templateId] = Template({
            providerId: providerId,
            endpointId: endpointId,
            requesterIndex: requesterIndex,
            designatedWallet: designatedWallet,
            fulfillAddress: fulfillAddress,
            fulfillFunctionId: fulfillFunctionId,
            parameters: parameters
        });
        emit TemplateCreated(
          templateId,
          providerId,
          endpointId,
          requesterIndex,
          designatedWallet,
          fulfillAddress,
          fulfillFunctionId,
          parameters
          );
    }

    /// @notice Retrieves request parameters addressed by the ID
    /// @param templateId Request template ID
    /// @return providerId Provider ID from ProviderStore
    /// @return endpointId Endpoint ID from EndpointStore
    /// @return requesterIndex Requester index from RequesterStore
    /// @return designatedWallet Designated wallet that is requested to fulfill
    /// the request
    /// @return fulfillAddress Address that will be called to fulfill
    /// @return fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @return parameters Static request parameters (i.e., parameters that will
    /// not change between requests, unlike the dynamic parameters determined
    /// at runtime)
    function getTemplate(bytes32 templateId)
        external
        view
        override
        returns (
            bytes32 providerId,
            bytes32 endpointId,
            uint256 requesterIndex,
            address designatedWallet,
            address fulfillAddress,
            bytes4 fulfillFunctionId,
            bytes memory parameters
        )
    {
        providerId = templates[templateId].providerId;
        endpointId = templates[templateId].endpointId;
        requesterIndex = templates[templateId].requesterIndex;
        designatedWallet = templates[templateId].designatedWallet;
        fulfillAddress = templates[templateId].fulfillAddress;
        fulfillFunctionId = templates[templateId].fulfillFunctionId;
        parameters = templates[templateId].parameters;
    }
}

// File: contracts/contracts/interfaces/IRequesterStore.sol


pragma solidity 0.6.12;


interface IRequesterStore {
    event RequesterCreated(
        uint256 indexed requesterIndex,
        address admin
        );

    event RequesterUpdated(
        uint256 indexed requesterIndex,
        address admin
        );

    event ClientEndorsementStatusUpdated(
        uint256 indexed requesterIndex,
        address indexed clientAddress,
        bool endorsementStatus
        );

    function createRequester(address admin)
        external
        returns (uint256 requesterIndex);

    function updateRequesterAdmin(
        uint256 requesterIndex,
        address admin
        )
        external;

    function updateClientEndorsementStatus(
        uint256 requesterIndex,
        address clientAddress,
        bool endorsementStatus
        )
        external;
}

// File: contracts/contracts/RequesterStore.sol


pragma solidity 0.6.12;



/// @title The contract where the requesters are stored
/// @notice This contract is used by requesters to manage their endorsemenets.
/// A requester endorsing a client means that the client can request their
/// requests to be fulfilled by the respective requester's designated wallets.
contract RequesterStore is IRequesterStore {
    mapping(uint256 => address) public requesterIndexToAdmin;
    mapping(uint256 => mapping(address => bool)) public requesterIndexToClientAddressToEndorsementStatus;
    uint256 private noRequesters = 1;


    /// @notice Creates a requester with the given parameters, addressable by
    /// the index it returns
    /// @param admin Requester admin
    /// @return requesterIndex Requester index
    function createRequester(address admin)
        external
        override
        returns (uint256 requesterIndex)
    {
        requesterIndex = noRequesters++;
        requesterIndexToAdmin[requesterIndex] = admin;
        emit RequesterCreated(
            requesterIndex,
            admin
            );
    }

    /// @notice Updates the requester admin
    /// @param requesterIndex Requester index
    /// @param admin Requester admin
    function updateRequesterAdmin(
        uint256 requesterIndex,
        address admin
        )
        external
        override
        onlyRequesterAdmin(requesterIndex)
    {
        requesterIndexToAdmin[requesterIndex] = admin;
        emit RequesterUpdated(
            requesterIndex,
            admin
            );
    }

    /// @notice Called by the requester admin to endorse a client, i.e., allow
    /// a client to use its designated wallets
    /// @dev This is not provider specific, i.e., the requester allows the
    /// client's requests to be fulfilled through its designated wallets across
    /// all providers
    /// @param requesterIndex Requester index
    /// @param clientAddress Client address
    function updateClientEndorsementStatus(
        uint256 requesterIndex,
        address clientAddress,
        bool endorsementStatus
        )
        external
        override
        onlyRequesterAdmin(requesterIndex)
    {
        requesterIndexToClientAddressToEndorsementStatus[requesterIndex][clientAddress] = endorsementStatus;
        emit ClientEndorsementStatusUpdated(
            requesterIndex,
            clientAddress,
            endorsementStatus
            );
    }

    /// @dev Reverts if the caller is not the requester admin
    /// @param requesterIndex Requester index
    modifier onlyRequesterAdmin(uint256 requesterIndex)
    {
        require(
            msg.sender == requesterIndexToAdmin[requesterIndex],
            "Caller is not requester admin"
            );
        _;
    }
}

// File: contracts/contracts/interfaces/IProviderStore.sol


pragma solidity 0.6.12;



interface IProviderStore is IRequesterStore {
    event ProviderCreated(
        bytes32 indexed providerId,
        address admin,
        string xpub
        );

    event ProviderUpdated(
        bytes32 indexed providerId,
        address admin
        );

    event WithdrawalRequested(
        bytes32 indexed providerId,
        uint256 indexed requesterIndex,
        bytes32 indexed withdrawalRequestId,
        address designatedWallet,
        address destination
        );

    event WithdrawalFulfilled(
        bytes32 indexed providerId,
        uint256 indexed requesterIndex,
        bytes32 indexed withdrawalRequestId,
        address designatedWallet,
        address destination,
        uint256 amount
        );

    function createProvider(
        address admin,
        string calldata xpub
        )
        external
        payable
        returns (bytes32 providerId);

    function updateProvider(
        bytes32 providerId,
        address admin
        )
        external;

    function requestWithdrawal(
        bytes32 providerId,
        uint256 requesterIndex,
        address designatedWallet,
        address destination
    )
        external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        bytes32 providerId,
        uint256 requesterIndex,
        address destination
        )
        external
        payable;

    function getProvider(bytes32 providerId)
        external
        view
        returns (
            address admin,
            string memory xpub
        );
}

// File: contracts/contracts/ProviderStore.sol


pragma solidity 0.6.12;




/// @title The contract where the providers are stored
contract ProviderStore is RequesterStore, IProviderStore {
    struct Provider {
        address admin;
        string xpub;
        }

    mapping(bytes32 => Provider) internal providers;
    mapping(bytes32 => bytes32) private withdrawalRequestIdToParameters;
    uint256 private noWithdrawalRequests = 0;


    /// @notice Allows the master wallet (m) of the provider to create a
    /// provider record on this chain
    /// @dev The oracle node should calculate their providerId off-chain and
    /// retrieve its details with a getProvider() call. If the xpub is does not
    /// match, it should call this method to update the provider record.
    /// Note that the provider private key can be used to update admin through
    /// this method. This is allowed on purpose, as the provider private key is
    /// more privileged than the provider admin account.
    /// @param admin Provider admin
    /// @param xpub Master public key of the provider node
    /// @return providerId Provider ID
    function createProvider(
        address admin,
        string calldata xpub
        )
        external
        payable
        override
        returns (bytes32 providerId)
    {
        providerId = keccak256(abi.encode(msg.sender));
        providers[providerId] = Provider({
            admin: admin,
            xpub: xpub
            });
        emit ProviderCreated(
            providerId,
            admin,
            xpub
            );
        if (msg.value > 0)
        {
            (bool success, ) = admin.call{ value: msg.value }("");  // solhint-disable-line
            require(success, "Transfer failed");
        }
    }

    /// @notice Updates the provider
    /// @param providerId Provider ID
    /// @param admin Provider admin
    function updateProvider(
        bytes32 providerId,
        address admin
        )
        external
        override
        onlyProviderAdmin(providerId)
    {
        providers[providerId].admin = admin;
        emit ProviderUpdated(
            providerId,
            admin
            );
    }

    /// @notice Called by the requester admin to create a request for the
    /// provider to send the funds kept in their designated wallet to
    /// destination
    /// @param providerId Provider ID
    /// @param requesterIndex Requester index from RequesterStore
    /// @param designatedWallet Designated wallet that the withdrawal is
    /// requested from
    /// @param destination Withdrawal destination
    function requestWithdrawal(
        bytes32 providerId,
        uint256 requesterIndex,
        address designatedWallet,
        address destination
    )
        external
        override
        onlyRequesterAdmin(requesterIndex)
    {
        bytes32 withdrawalRequestId = keccak256(abi.encodePacked(
            this,
            noWithdrawalRequests++
            ));
        bytes32 withdrawalParameters = keccak256(abi.encodePacked(
            providerId,
            requesterIndex,
            designatedWallet,
            destination
            ));
        withdrawalRequestIdToParameters[withdrawalRequestId] = withdrawalParameters;
        emit WithdrawalRequested(
            providerId,
            requesterIndex,
            withdrawalRequestId,
            designatedWallet,
            destination
            );
    }

    /// @notice Called by the designated wallet to fulfill the withdrawal
    /// request made by the requester
    /// @dev The oracle node sends the funds through this method to emit an
    /// event that indicates that the withdrawal request has been fulfilled
    /// @param providerId Provider ID
    /// @param requesterIndex Requester index from RequesterStore
    /// @param destination Withdrawal destination
    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        bytes32 providerId,
        uint256 requesterIndex,
        address destination
        )
        external
        payable
        override
    {
        bytes32 withdrawalParameters = keccak256(abi.encodePacked(
            providerId,
            requesterIndex,
            msg.sender,
            destination
            ));
        require(
            withdrawalRequestIdToParameters[withdrawalRequestId] == withdrawalParameters,
            "No such withdrawal request"
            );
        delete withdrawalRequestIdToParameters[withdrawalRequestId];
        emit WithdrawalFulfilled(
            providerId,
            requesterIndex,
            withdrawalRequestId,
            msg.sender,
            destination,
            msg.value
            );
        (bool success, ) = destination.call{ value: msg.value }("");  // solhint-disable-line
        require(success, "Transfer failed");
    }

    /// @notice Retrieves provider parameters addressed by the ID
    /// @param providerId Provider ID
    /// @return admin Provider admin
    /// @return xpub Master public key of the provider node
    function getProvider(bytes32 providerId)
        external
        view
        override
        returns (
            address admin,
            string memory xpub
        )
    {
        admin = providers[providerId].admin;
        xpub = providers[providerId].xpub;
    }

    /// @dev Reverts if the caller is not the provider admin
    /// @param providerId Provider ID
    modifier onlyProviderAdmin(bytes32 providerId)
    {
        require(
            msg.sender == providers[providerId].admin,
            "Caller is not provider admin"
            );
        _;
    }
}

// File: contracts/contracts/interfaces/IEndpointStore.sol


pragma solidity 0.6.12;



interface IEndpointStore is IProviderStore {
    event EndpointUpdated(
        bytes32 indexed providerId,
        bytes32 indexed endpointId,
        address[] authorizers
        );

    function updateEndpointAuthorizers(
        bytes32 providerId,
        bytes32 endpointId,
        address[] calldata authorizers
        )
        external;

    function getEndpointAuthorizers(
        bytes32 providerId,
        bytes32 endpointId
        )
        external
        view
        returns(address[] memory authorizers);
}

// File: contracts/contracts/EndpointStore.sol


pragma solidity 0.6.12;




/// @title The contract where the endpoints are stored
/// @notice This contract is used by the provider admin to associate their
/// endpoints with authorization policies, which both the oracle node and the
/// requester can check to verify authorization.
contract EndpointStore is ProviderStore, IEndpointStore {
    mapping(bytes32 => mapping(bytes32 => address[])) private providerIdToEndpointIdToAuthorizers;


    /// @notice Updates the endpoint authorizers of a provider
    /// @param providerId Provider ID from ProviderStore
    /// @param endpointId Endpoint ID
    /// @param authorizers Authorizer contract addresses
    function updateEndpointAuthorizers(
        bytes32 providerId,
        bytes32 endpointId,
        address[] calldata authorizers
        )
        external
        override
        onlyProviderAdmin(providerId)
    {
        providerIdToEndpointIdToAuthorizers[providerId][endpointId] = authorizers;
        emit EndpointUpdated(
            providerId,
            endpointId,
            authorizers
            );
    }

    /// @notice Retrieves the endpoint parameters addressed by the ID
    /// @param providerId Provider ID from ProviderStore
    /// @param endpointId Endpoint ID
    /// @return authorizers Authorizer contract addresses
    function getEndpointAuthorizers(
        bytes32 providerId,
        bytes32 endpointId
        )
        external
        view
        override
        returns(address[] memory authorizers)
    {
        authorizers = providerIdToEndpointIdToAuthorizers[providerId][endpointId];
    }
}

// File: contracts/contracts/interfaces/IAirnode.sol


pragma solidity 0.6.12;




interface IAirnode is IEndpointStore, ITemplateStore {
    event ClientRequestCreated(
        bytes32 indexed providerId,
        bytes32 indexed requestId,
        uint256 noRequests,
        address clientAddress,
        bytes32 templateId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
        );

    event ClientShortRequestCreated(
        bytes32 indexed providerId,
        bytes32 indexed requestId,
        uint256 noRequests,
        address clientAddress,
        bytes32 templateId,
        bytes parameters
        );

    event ClientFullRequestCreated(
        bytes32 indexed providerId,
        bytes32 indexed requestId,
        uint256 noRequests,
        address clientAddress,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
        );

    event ClientRequestFulfilled(
        bytes32 indexed providerId,
        bytes32 indexed requestId,
        uint256 statusCode,
        bytes32 data
        );

    event ClientRequestFulfilledWithBytes(
        bytes32 indexed providerId,
        bytes32 indexed requestId,
        uint256 statusCode,
        bytes data
        );

    event ClientRequestFailed(
        bytes32 indexed providerId,
        bytes32 indexed requestId
        );

    function makeRequest(
        bytes32 templateId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        returns (bytes32 requestId);

    function makeShortRequest(
        bytes32 templateId,
        bytes calldata parameters
        )
        external
        returns (bytes32 requestId);

    function makeFullRequest(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        bytes32 providerId,
        uint256 statusCode,
        bytes32 data,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external
        returns(
            bool callSuccess,
            bytes memory callData
        );

    function fulfillBytes(
        bytes32 requestId,
        bytes32 providerId,
        uint256 statusCode,
        bytes calldata data,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external
        returns(
            bool callSuccess,
            bytes memory callData
        );

    function fail(
        bytes32 requestId,
        bytes32 providerId,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external;
}

// File: contracts/contracts/Airnode.sol


pragma solidity 0.6.12;





/// @title The contract used to make and fulfill requests
/// @notice Clients use this contract to make requests that follow a
/// request-response scheme. In addition, it inherits from contracts that keep
/// records of providers, requesters, endpoints, etc.
contract Airnode is EndpointStore, TemplateStore, IAirnode {
    mapping(bytes32 => bytes32) private requestIdToFulfillmentParameters;
    mapping(bytes32 => bool) public requestWithIdHasFailed;
    uint256 private noRequests = 0;


    /// @notice Called by the client to make a regular request. A regular
    /// request refers to a template for the requester-agnostic parameters, but
    /// requires the client to provide the requester-specific parameters.
    /// @dev This is the recommended way of making a request in most cases. Use
    /// makeShortRequest() if gas efficiency is critical.
    /// @param templateId Template ID from TemplateStore
    /// @param requesterIndex Requester index from RequesterStore
    /// @param designatedWallet Designated wallet that is requested to fulfill
    /// the request
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param parameters Dynamic request parameters (i.e., parameters that are
    /// determined at runtime, unlike the static parameters stored in the
    /// template)
    /// @return requestId Request ID
    function makeRequest(
        bytes32 templateId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        override
        returns (bytes32 requestId)
    {
        require(
            requesterIndexToClientAddressToEndorsementStatus[requesterIndex][msg.sender],
            "Client not endorsed by requester"
            );
        requestId = keccak256(abi.encode(
            noRequests,
            templateId,
            parameters
            ));
        bytes32 providerId = templates[templateId].providerId;
        requestIdToFulfillmentParameters[requestId] = keccak256(abi.encodePacked(
            providerId,
            designatedWallet,
            fulfillAddress,
            fulfillFunctionId
            ));
        emit ClientRequestCreated(
            providerId,
            requestId,
            noRequests,
            msg.sender,
            templateId,
            requesterIndex,
            designatedWallet,
            fulfillAddress,
            fulfillFunctionId,
            parameters
        );
        noRequests++;
    }

    /// @notice Called by the requester to make a short request. A short
    /// request refers to a template, which the provider will use to get both
    /// requester-agnostic and requester-specific parameters
    /// @dev Use this if gas efficiency is critical
    /// @param templateId Template ID from TemplateStore
    /// @param parameters Dynamic request parameters (i.e., parameters that are
    /// determined at runtime, unlike the static parameters stored in the
    /// template)
    /// @return requestId Request ID
    function makeShortRequest(
        bytes32 templateId,
        bytes calldata parameters
        )
        external
        override
        returns (bytes32 requestId)
    {
        Template storage template = templates[templateId];
        require(
            requesterIndexToClientAddressToEndorsementStatus[template.requesterIndex][msg.sender],
            "Client not endorsed by requester"
            );
        requestId = keccak256(abi.encode(
            noRequests,
            templateId,
            parameters
            ));
        requestIdToFulfillmentParameters[requestId] = keccak256(abi.encodePacked(
            template.providerId,
            template.designatedWallet,
            template.fulfillAddress,
            template.fulfillFunctionId
            ));
        emit ClientShortRequestCreated(
            templates[templateId].providerId,
            requestId,
            noRequests,
            msg.sender,
            templateId,
            parameters
        );
        noRequests++;
    }

    /// @notice Called by the requester to make a full request. A full request
    /// does not refer to a template, meaning that it passes all the parameters
    /// in the request. It does not require a template to be created
    /// beforehand, which provides extra flexibility compared to makeRequest()
    /// and makeShortRequest().
    /// @dev This is the least gas efficient way of making a request. Do not
    /// use it unless you have a good reason.
    /// @param providerId Provider ID from ProviderStore
    /// @param endpointId Endpoint ID from EndpointStore
    /// @param requesterIndex Requester index from RequesterStore
    /// @param designatedWallet Designated wallet that is requested to fulfill
    /// the request
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @param parameters All request parameters
    /// @return requestId Request ID
    function makeFullRequest(
        bytes32 providerId,
        bytes32 endpointId,
        uint256 requesterIndex,
        address designatedWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
        )
        external
        override
        returns (bytes32 requestId)
    {
        require(
            requesterIndexToClientAddressToEndorsementStatus[requesterIndex][msg.sender],
            "Client not endorsed by requester"
            );
        requestId = keccak256(abi.encode(
            noRequests,
            providerId,
            endpointId,
            parameters
            ));
        requestIdToFulfillmentParameters[requestId] = keccak256(abi.encodePacked(
            providerId,
            designatedWallet,
            fulfillAddress,
            fulfillFunctionId
            ));
        emit ClientFullRequestCreated(
            providerId,
            requestId,
            noRequests,
            msg.sender,
            endpointId,
            requesterIndex,
            designatedWallet,
            fulfillAddress,
            fulfillFunctionId,
            parameters
        );
        noRequests++;
    }

    /// @notice Called by the oracle node to fulfill individual requests
    /// (including regular, short and full requests)
    /// @param requestId Request ID
    /// @param providerId Provider ID from ProviderStore
    /// @param statusCode Status code of the fulfillment
    /// @param data Fulfillment data
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @return callSuccess If the fulfillment call succeeded
    /// @return callData Data returned by the fulfillment call (if there is
    /// any)
    function fulfill(
        bytes32 requestId,
        bytes32 providerId,
        uint256 statusCode,
        bytes32 data,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external
        override
        onlyCorrectFulfillmentParameters(
            requestId,
            providerId,
            fulfillAddress,
            fulfillFunctionId
            )
        returns(
            bool callSuccess,
            bytes memory callData
        )
    {
        delete requestIdToFulfillmentParameters[requestId];
        emit ClientRequestFulfilled(
            providerId,
            requestId,
            statusCode,
            data
            );
        (callSuccess, callData) = fulfillAddress.call(  // solhint-disable-line
            abi.encodeWithSelector(fulfillFunctionId, requestId, statusCode, data)
            );
    }

    /// @notice Called by the oracle node to fulfill individual requests
    /// (including regular, short and full requests) with a bytes type response
    /// @dev The oracle uses this method to fulfill if the requester has
    /// specifically asked for a bytes type response
    /// @param requestId Request ID
    /// @param providerId Provider ID from ProviderStore
    /// @param statusCode Status code of the fulfillment
    /// @param data Fulfillment data of type bytes
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    /// @return callSuccess If the fulfillment call succeeded
    /// @return callData Data returned by the fulfillment call (if there is
    /// any)
    function fulfillBytes(
        bytes32 requestId,
        bytes32 providerId,
        uint256 statusCode,
        bytes calldata data,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external
        override
        onlyCorrectFulfillmentParameters(
            requestId,
            providerId,
            fulfillAddress,
            fulfillFunctionId
            )
        returns(
            bool callSuccess,
            bytes memory callData
        )
    {
        delete requestIdToFulfillmentParameters[requestId];
        emit ClientRequestFulfilledWithBytes(
            providerId,
            requestId,
            statusCode,
            data
            );
        (callSuccess, callData) = fulfillAddress.call(  // solhint-disable-line
            abi.encodeWithSelector(fulfillFunctionId, requestId, statusCode, data)
            );
    }

    /// @notice Called by the oracle node if a request cannot be fulfilled
    /// @dev The oracle should fall back to this if a request cannot be
    /// fulfilled because fulfill() reverts
    /// @param requestId Request ID
    /// @param providerId Provider ID from ProviderStore
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    function fail(
        bytes32 requestId,
        bytes32 providerId,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
        external
        override
        onlyCorrectFulfillmentParameters(
            requestId,
            providerId,
            fulfillAddress,
            fulfillFunctionId
            )
    {
        delete requestIdToFulfillmentParameters[requestId];
        // Failure is recorded so that it can be checked externally
        requestWithIdHasFailed[requestId] = true;
        emit ClientRequestFailed(
            providerId,
            requestId
            );
    }

    /// @dev Reverts unless the incoming fulfillment parameters do not match
    /// the ones provided in the request
    /// @param requestId Request ID
    /// @param providerId Provider ID from ProviderStore
    /// @param fulfillAddress Address that will be called to fulfill
    /// @param fulfillFunctionId Signature of the function that will be called
    /// to fulfill
    modifier onlyCorrectFulfillmentParameters(
        bytes32 requestId,
        bytes32 providerId,
        address fulfillAddress,
        bytes4 fulfillFunctionId
        )
    {
        bytes32 incomingFulfillmentParameters = keccak256(abi.encodePacked(
            providerId,
            msg.sender,
            fulfillAddress,
            fulfillFunctionId
            ));
        require(
            incomingFulfillmentParameters == requestIdToFulfillmentParameters[requestId],
            "Incorrect fulfillment parameters"
            );
        _;
    }
}