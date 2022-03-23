// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Product.sol";
import "IHelloWorldInsurance.sol";
import "HelloWorldOracle.sol";


contract HelloWorldInsurance is IHelloWorldInsurance, Product {

    bytes32 public constant VERSION = "0.0.1";
    bytes32 public constant POLICY_FLOW = "PolicyFlowDefault";

    uint256 public constant MIN_PREMIUM = 10 * 10**16;
    uint256 public constant MAX_PREMIUM = 1500 * 10**16;

    uint256 public constant PAYOUT_FACTOR_RUDE_RESPONSE = 3;
    uint256 public constant PAYOUT_FACTOR_NO_RESPONSE = 1;
    uint256 public constant PAYOUT_FACTOR_KIND_RESPONSE = 0;

    uint16 public constant MAX_LENGTH_GREETING = 32;
    string public constant CALLBACK_METHOD_NAME = "greetingCallback";

    uint256 public uniqueIndex;
    bytes32 public greetingsOracleType;
    uint256 public greetingsOracleId;

    mapping(bytes32 => address) public policyIdToAddress;
    mapping(address => bytes32[]) public addressToPolicyIds;

    constructor(
        address gifProductService,
        bytes32 productName,
        bytes32 oracleType,
        uint256 oracleId
    )
        Product(gifProductService, productName, POLICY_FLOW)
    {
        greetingsOracleType = oracleType;
        greetingsOracleId = oracleId;
    }

    function applyForPolicy() external payable override returns (bytes32 policyId) {

        address payable policyHolder = payable(msg.sender);
        uint256 premium = _getValue();

        // Create new ID for this policy
        policyId = _uniqueId(policyHolder);

        // Validate input parameters
        require(premium >= MIN_PREMIUM, "ERROR:HWI-001:INVALID_PREMIUM");
        require(premium <= MAX_PREMIUM, "ERROR:HWI-002:INVALID_PREMIUM");

        // Create and underwrite new application
        _newApplication(policyId, abi.encode(premium, policyHolder));
        _underwrite(policyId);

        emit LogHelloWorldPolicyCreated(policyId);

        // Book keeping to simplify lookup
        policyIdToAddress[policyId] = policyHolder;
        addressToPolicyIds[policyHolder].push(policyId);
    }

    function greet(bytes32 policyId, string calldata greeting) external override {

        // Validate input parameters
        require(policyIdToAddress[policyId] == msg.sender, "ERROR:HWI-003:INVALID_POLICY_OR_HOLDER");
        require(bytes(greeting).length <= MAX_LENGTH_GREETING, "ERROR:HWI-004:GREETING_TOO_LONG");

        emit LogHelloWorldGreetingReceived(policyId, greeting);

        // request response to greeting via oracle call
        uint256 requestId = _request(
            policyId,
            abi.encode(greeting),
            CALLBACK_METHOD_NAME,
            greetingsOracleType,
            greetingsOracleId
        );

        emit LogHelloWorldGreetingCompleted(requestId, policyId, greeting);
    }

    function greetingCallback(uint256 requestId, bytes32 policyId, bytes calldata response)
        external
        onlyOracle
    {
        // get policy data for oracle response
        (uint256 premium, address payable policyHolder) = abi.decode(
            _getApplicationData(policyId), (uint256, address));

        // get oracle response data
        (HelloWorldOracle.AnswerType answer) = abi.decode(response, (HelloWorldOracle.AnswerType));

        // claim handling based on reponse to greeting provided by oracle 
        _handleClaim(policyId, policyHolder, premium, answer);
        
        // policy only covers a single greeting/response pair
        // policy can therefore be expired
        _expire(policyId);

        emit LogHelloWorldCallbackCompleted(requestId, policyId, response);
}

    function withdraw(uint256 amount) external override onlyOwner {
        require(amount <= address(this).balance);

        address payable receiver;
        receiver = payable(owner());
        receiver.transfer(amount);
    }

    function _getValue() internal returns(uint256 premium) { premium = msg.value; }

    function _uniqueId(address senderAddress) internal returns (bytes32 uniqueId) {
        uniqueIndex += 1;
        return keccak256(abi.encode(senderAddress, productId, uniqueIndex));
    }

    function _handleClaim(
        bytes32 policyId, 
        address payable policyHolder, 
        uint256 premium, 
        HelloWorldOracle.AnswerType answer
    ) 
        internal 
    {
        uint256 payoutAmount = _calculatePayoutAmount(premium, answer);

        // no claims handling for payouts == 0
        if (payoutAmount > 0) {
            uint256 claimId = _newClaim(policyId, abi.encode(payoutAmount));
            uint256 payoutId = _confirmClaim(policyId, claimId, abi.encode(payoutAmount));

            _payout(policyId, payoutId, true, abi.encode(payoutAmount));

            // actual transfer of funds for payout of claim
            policyHolder.transfer(payoutAmount);

            emit LogHelloWorldPayoutExecuted(policyId, claimId, payoutId, payoutAmount);
        }
    }

    function _calculatePayoutAmount(uint256 premium, HelloWorldOracle.AnswerType answer) 
        internal 
        pure 
        returns(uint256 payoutAmount) 
    {
        if (answer == HelloWorldOracle.AnswerType.Rude) {
            payoutAmount = PAYOUT_FACTOR_RUDE_RESPONSE * premium;
        } else if (answer == HelloWorldOracle.AnswerType.None) { 
            payoutAmount = PAYOUT_FACTOR_NO_RESPONSE * premium;
        } else { 
            // for kind response, all is well, no payout
            payoutAmount = 0;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "RBAC.sol";
import "IProductService.sol";
import "IRegistryAccess.sol";

abstract contract Product is RBAC {

    bool public developmentMode = false;
    bool public maintenanceMode = false;
    bool public onChainPaymentMode = false;
    uint256 public productId;

    IProductService public productService;
    IRegistryAccess public registryAccess;

    modifier onlySandbox {
        require(
            msg.sender == registryAccess.getContractFromRegistry("Sandbox"),
            "ERROR:PRO-001:ACCESS_DENIED"
        );
        _;
    }

    modifier onlyOracle {
        require(
            msg.sender == registryAccess.getContractFromRegistry("Query"),
            "ERROR:PRO-002:ACCESS_DENIED"
        );
        _;
    }

    constructor(address _productService, bytes32 _name, bytes32 _policyFlow)
    {
        productService = IProductService(_productService);
        registryAccess = IRegistryAccess(_productService);

        productId = _proposeProduct(_name, _policyFlow);
    }

    function getId() public view returns(uint256) { return productId; }

    function setDevelopmentMode(bool _newMode) internal {
        developmentMode = _newMode;
    }

    function setMaintenanceMode(bool _newMode) internal {
        maintenanceMode = _newMode;
    }

    function setOnChainPaymentMode(bool _newMode) internal {
        onChainPaymentMode = _newMode;
    }

    function _proposeProduct(bytes32 _productName, bytes32 _policyFlow)
        internal
        returns (uint256 _productId)
    {
        _productId = productService.proposeProduct(_productName, _policyFlow);
    }

    function _newApplication(
        bytes32 _bpKey,
        bytes memory _data
    )
        internal
    {
        productService.newApplication(_bpKey, _data);
    }

    function _underwrite(
        bytes32 _bpKey
    )
        internal
    {
        productService.underwrite(_bpKey);
    }

    function _decline(
        bytes32 _bpKey
    )
        internal
    {
        productService.decline(_bpKey);
    }

    function _newClaim(
        bytes32 _bpKey,
        bytes memory _data
    )
        internal
        returns (uint256 _claimId)
    {
        _claimId = productService.newClaim(_bpKey, _data);
    }

    function _confirmClaim(
        bytes32 _bpKey,
        uint256 _claimId,
        bytes memory _data
    )
        internal
        returns (uint256 _payoutId)
    {
        _payoutId = productService.confirmClaim(_bpKey, _claimId, _data);
    }

    function _declineClaim(
        bytes32 _bpKey,
        uint256 _claimId
    )
        internal
    {
        productService.declineClaim(_bpKey, _claimId);
    }

    function _expire(
        bytes32 _bpKey
    )
        internal
    {
        productService.expire(_bpKey);
    }

    function _payout(
        bytes32 _bpKey,
        uint256 _payoutId,
        bool _complete,
        bytes memory _data
    )
        internal
    {
        productService.payout(_bpKey, _payoutId, _complete, _data);
    }

    function _request(
        bytes32 _bpKey,
        bytes memory _input,
        string memory _callbackMethodName,
        bytes32 _oracleTypeName,
        uint256 _responsibleOracleId
    )
        internal
        returns (uint256 _requestId)
    {
        _requestId = productService.request(
            _bpKey,
            _input,
            _callbackMethodName,
            address(this),
            _oracleTypeName,
            _responsibleOracleId
        );
    }

    function _getApplicationData(bytes32 _bpKey) internal view returns (bytes memory _data) {
        return productService.getApplicationData(_bpKey);
    }

    function _getClaimData(bytes32 _bpKey, uint256 _claimId) internal view returns (bytes memory _data) {
        return productService.getClaimData(_bpKey, _claimId);
    }

    function _getApplicationData(bytes32 _bpKey, uint256 _payoutId) internal view returns (bytes memory _data) {
        return productService.getPayoutData(_bpKey, _payoutId);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Ownable.sol";

contract RBAC is Ownable {
    mapping(bytes32 => uint256) public roles;
    bytes32[] public rolesKeys;

    mapping(address => uint256) public permissions;

    modifier onlyWithRole(bytes32 _role) {
        require(hasRole(msg.sender, _role));
        _;
    }

    function createRole(bytes32 _role) public onlyOwner {
        require(roles[_role] == 0);
        // todo: check overflow
        roles[_role] = 1 << rolesKeys.length;
        rolesKeys.push(_role);
    }

    function addRoleToAccount(address _address, bytes32 _role)
        public
        onlyOwner
    {
        require(roles[_role] != 0);

        permissions[_address] = permissions[_address] | roles[_role];
    }

    function cleanRolesForAccount(address _address) public onlyOwner {
        delete permissions[_address];
    }

    function hasRole(address _address, bytes32 _role)
        public
        view
        returns (bool _hasRole)
    {
        _hasRole = (permissions[_address] & roles[_role]) > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IProductService {
    
    function proposeProduct(bytes32 _productName, bytes32 _policyFlow) external returns (uint256 _productId);
    function newApplication(bytes32 _bpKey, bytes calldata _data) external;
    function underwrite(bytes32 _bpKey) external;
    function decline(bytes32 _bpKey) external;
    function newClaim(bytes32 _bpKey, bytes calldata _data) external returns (uint256 _claimId);
    function confirmClaim(bytes32 _bpKey, uint256 _claimId, bytes calldata _data) external returns (uint256 _payoutId);
    function declineClaim(bytes32 _bpKey, uint256 _claimId) external;
    function expire(bytes32 _bpKey) external;
    function payout(bytes32 _bpKey, uint256 _payoutId, bool _complete, bytes calldata _data) external;
    function getApplicationData(bytes32 _bpKey) external view returns (bytes memory _data);
    function getClaimData(bytes32 _bpKey, uint256 _claimId) external view returns (bytes memory _data);
    function getPayoutData(bytes32 _bpKey, uint256 _payoutId) external view returns (bytes memory _data);

    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        bytes32 _oracleTypeName,
        uint256 _responsibleOracleId
    ) external returns (uint256 _requestId);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryAccess {
    
    function getContractFromRegistry(bytes32 _contractName) 
        external 
        view 
        returns (address _contractAddress);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;


interface IHelloWorldInsurance {

    // events
    event LogHelloWorldPolicyCreated(bytes32 policyId);
    event LogHelloWorldGreetingReceived(bytes32 policyId, string greeting);
    event LogHelloWorldGreetingCompleted(uint256 requestId, bytes32 policyId, string greeting);
    event LogHelloWorldPayoutExecuted(bytes32 policyId, uint256 claimId, uint256 payoutId, uint256 amount);
    event LogHelloWorldCallbackCompleted(uint256 requestId, bytes32 policyId, bytes response);

    // functions
    function applyForPolicy() external payable returns (bytes32 policyId);
    function greet(bytes32 policyId, string calldata greeting) external;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Oracle.sol";


contract HelloWorldOracle is Oracle {

    bytes1 public constant RESPONSE_CODE_KIND = "K";
    bytes1 public constant RESPONSE_CODE_NONE = "N";
    bytes1 public constant RESPONSE_CODE_RUDE = "R";

    uint256 private _requestCounter;

    event LogHelloWorldOracleRequestReceived(uint256 requestId, string greeting);
    event LogHelloWorldOracleResponseHandled(uint256 requestId, AnswerType answer);

    enum AnswerType {Kind, None, Rude}

    constructor(
        address gifOracleService,
        address gifOracleOwnerService,
        bytes32 oracleTypeName,
        bytes32 oracleName
    )
        Oracle(gifOracleService, gifOracleOwnerService, oracleTypeName, oracleName)
    { }

    function request(uint256 requestId, bytes calldata input) 
        external 
        override 
        onlyQuery
    {
        // decode oracle input data
        (string memory input_greeting) = abi.decode(input, (string));
        emit LogHelloWorldOracleRequestReceived(requestId, input_greeting);

        // calculate and encode oracle output (response) data
        AnswerType output_answer = _oracleBusinessLogic(input_greeting);
        bytes memory output = abi.encode(AnswerType(output_answer));

        // trigger inherited response handling
        _respond(requestId, output);
        emit LogHelloWorldOracleResponseHandled(requestId, output_answer);
    }

    // this is just a toy example
    // real oracle implementations will get the output from some 
    // off chain component providing the outcome of the business logic
    function _oracleBusinessLogic(string memory greeting) 
        internal
        returns (AnswerType answer)
    {
        bytes memory bGreeting = bytes(greeting);
        bytes1 bH = bytes1('h');

        if (bGreeting.length == 0) {
            answer = AnswerType.None;
        } else if (bGreeting[0] == bytes1('h')) {
            answer = AnswerType.Kind;
        } else {
            answer = AnswerType.Rude;
        }
    }

    function getAnswerCodeKind() public pure returns (bytes1 code) { return RESPONSE_CODE_KIND; }
    function getAnswerCodeNone() public pure returns (bytes1 code) { return RESPONSE_CODE_NONE; }
    function getAnswerCodeRude() public pure returns (bytes1 code) { return RESPONSE_CODE_RUDE; }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IOracle.sol";
import "RBAC.sol";
import "IOracleService.sol";
import "IOracleOwnerService.sol";
import "IRegistryAccess.sol";

abstract contract Oracle is IOracle, RBAC {
    IOracleService public oracleService;
    IOracleOwnerService public oracleOwnerService;
    IRegistryAccess public registryAccess;
    uint256 public oracleId;

    modifier onlyQuery {
        require(
            msg.sender == registryAccess.getContractFromRegistry("Query"),
            "ERROR:ORA-001:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        address _oracleService,
        address _oracleOwnerService,
        bytes32 _oracleTypeName,
        bytes32 _oracleName
    )
    {
        oracleService = IOracleService(_oracleService);
        oracleOwnerService = IOracleOwnerService(_oracleOwnerService);
        registryAccess = IRegistryAccess(_oracleService);

        oracleId = oracleOwnerService.proposeOracle(_oracleName);
        oracleOwnerService.proposeOracleToOracleType(_oracleTypeName, oracleId);
    }

    function getId() public view returns(uint256) { return oracleId; }

    function _respond(uint256 _requestId, bytes memory _data) internal {
        oracleService.respond(_requestId, _data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// If this interface is changed, the respective interface in the GIF Core Contracts package needs to be changed as well.
interface IOracle {
    function request(uint256 _requestId, bytes calldata _input) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOracleService {

    function respond(uint256 _requestId, bytes calldata _data) external;

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IOracleOwnerService {

    function proposeOracleType(
        bytes32 _oracleTypeName,
        string calldata _inputFormat,
        string calldata _callbackFormat
    ) external;

    function proposeOracle(
        bytes32 _oracleName
    ) external returns (uint256 _oracleId);

    function proposeOracleToOracleType(
        bytes32 _oracleTypeName,
        uint256 _oracleId
    ) external;

}