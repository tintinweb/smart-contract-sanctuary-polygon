// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizationUtilsV0.sol";
import "./ITemplateUtilsV0.sol";
import "./IWithdrawalUtilsV0.sol";

interface IAirnodeRrpV0 is
    IAuthorizationUtilsV0,
    ITemplateUtilsV0,
    IWithdrawalUtilsV0
{
    event SetSponsorshipStatus(
        address indexed sponsor,
        address indexed requester,
        bool sponsorshipStatus
    );

    event MadeTemplateRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event MadeFullRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        uint256 requesterRequestCount,
        uint256 chainId,
        address requester,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes parameters
    );

    event FulfilledRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        bytes data
    );

    event FailedRequest(
        address indexed airnode,
        bytes32 indexed requestId,
        string errorMessage
    );

    function setSponsorshipStatus(address requester, bool sponsorshipStatus)
        external;

    function makeTemplateRequest(
        bytes32 templateId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function makeFullRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata parameters
    ) external returns (bytes32 requestId);

    function fulfill(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool callSuccess, bytes memory callData);

    function fail(
        bytes32 requestId,
        address airnode,
        address fulfillAddress,
        bytes4 fulfillFunctionId,
        string calldata errorMessage
    ) external;

    function sponsorToRequesterToSponsorshipStatus(
        address sponsor,
        address requester
    ) external view returns (bool sponsorshipStatus);

    function requesterToRequestCountPlusOne(address requester)
        external
        view
        returns (uint256 requestCountPlusOne);

    function requestIsAwaitingFulfillment(bytes32 requestId)
        external
        view
        returns (bool isAwaitingFulfillment);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthorizationUtilsV0 {
    function checkAuthorizationStatus(
        address[] calldata authorizers,
        address airnode,
        bytes32 requestId,
        bytes32 endpointId,
        address sponsor,
        address requester
    ) external view returns (bool status);

    function checkAuthorizationStatuses(
        address[] calldata authorizers,
        address airnode,
        bytes32[] calldata requestIds,
        bytes32[] calldata endpointIds,
        address[] calldata sponsors,
        address[] calldata requesters
    ) external view returns (bool[] memory statuses);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITemplateUtilsV0 {
    event CreatedTemplate(
        bytes32 indexed templateId,
        address airnode,
        bytes32 endpointId,
        bytes parameters
    );

    function createTemplate(
        address airnode,
        bytes32 endpointId,
        bytes calldata parameters
    ) external returns (bytes32 templateId);

    function getTemplates(bytes32[] calldata templateIds)
        external
        view
        returns (
            address[] memory airnodes,
            bytes32[] memory endpointIds,
            bytes[] memory parameters
        );

    function templates(bytes32 templateId)
        external
        view
        returns (
            address airnode,
            bytes32 endpointId,
            bytes memory parameters
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalUtilsV0 {
    event RequestedWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet
    );

    event FulfilledWithdrawal(
        address indexed airnode,
        address indexed sponsor,
        bytes32 indexed withdrawalRequestId,
        address sponsorWallet,
        uint256 amount
    );

    function requestWithdrawal(address airnode, address sponsorWallet) external;

    function fulfillWithdrawal(
        bytes32 withdrawalRequestId,
        address airnode,
        address sponsor
    ) external payable;

    function sponsorToWithdrawalRequestCount(address sponsor)
        external
        view
        returns (uint256 withdrawalRequestCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAirnodeRrpV0.sol";

/// @title The contract to be inherited to make Airnode RRP requests
contract RrpRequesterV0 {
    IAirnodeRrpV0 public immutable airnodeRrp;

    /// @dev Reverts if the caller is not the Airnode RRP contract.
    /// Use it as a modifier for fulfill and error callback methods, but also
    /// check `requestId`.
    modifier onlyAirnodeRrp() {
        require(msg.sender == address(airnodeRrp), "Caller not Airnode RRP");
        _;
    }

    /// @dev Airnode RRP address is set at deployment and is immutable.
    /// RrpRequester is made its own sponsor by default. RrpRequester can also
    /// be sponsored by others and use these sponsorships while making
    /// requests, i.e., using this default sponsorship is optional.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp) {
        airnodeRrp = IAirnodeRrpV0(_airnodeRrp);
        IAirnodeRrpV0(_airnodeRrp).setSponsorshipStatus(address(this), true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract test is RrpRequesterV0, Ownable {
    address immutable airnodeAddress = 0x6238772544f029ecaBfDED4300f13A3c4FE84E1D;
    bytes32 immutable endpointId = 0x27cc2713e7f968e4e86ed274a051a5c8aaee9cca66946f23af6f29ecea9704c3;

    address payable public sponsorWallet;

    mapping(bytes32 => bool) public pendingRequestIds;

    uint256[] public nums;
    bool flag = true;

    constructor(address _airnodeRrpAddress)
        RrpRequesterV0(_airnodeRrpAddress){
            flag = false;
        }

    function setSponsorWallet(address payable _sponsorWallet)
        external
        onlyOwner
    {
        sponsorWallet = _sponsorWallet;
    }

    function gen() external payable  {
        require(msg.value >= 0.01 ether, "Please top up sponsor wallet"); // user needs to send 0.01 ether with the transaction
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnodeAddress,
            endpointId,
            address(this),
            sponsorWallet,
            address(this),
            this.get.selector,
            ""
        );
        pendingRequestIds[requestId] = true;
        bool sent = sponsorWallet.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function get(
        bytes32 requestId,
        bytes calldata data
    ) external
        onlyAirnodeRrp {
        require(pendingRequestIds[requestId], "No such request made");
        // delete pendingRequestIds[requestId]; // If the request has been responded to, remove it from the pendingRequestIds mapping

        nums = abi.decode(data, (uint256[]));
    }
}