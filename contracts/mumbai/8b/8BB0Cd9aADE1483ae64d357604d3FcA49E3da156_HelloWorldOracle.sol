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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryAccess {
    
    function getContractFromRegistry(bytes32 _contractName) 
        external 
        view 
        returns (address _contractAddress);
}