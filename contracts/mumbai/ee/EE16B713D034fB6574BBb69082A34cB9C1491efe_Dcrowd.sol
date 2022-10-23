// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDcrowd.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dcrowd is IDcrowd, Ownable, ReentrancyGuard {
    //----------------------------------------------------- constants

    uint16 public constant FEE_DENOMINATOR = 10000;

    //----------------------------------------------------- storage

    uint256 private _projectCounter;

    uint256 private _feeBalance;

    uint64 private _maxFundingPeriod;

    uint16 private _platformFee;

    // project ID -> project info
    mapping(uint256 => ProjectInfo) private _projectInfos;

    // project ID -> project uri
    mapping(uint256 => string) private _uris;

    // funder address -> project ID -> amount funded
    mapping(address => mapping(uint256 => uint256)) private _fundings;

    // creator address -> rating
    mapping(address => uint8) private _creatorRatings;

    //----------------------------------------------------- misc functions

    constructor() {
        _projectCounter = 0;
        _maxFundingPeriod = 100 days;
        _platformFee = 0;
    }

    //----------------------------------------------------- creator functions

    function createProject(
        uint64 expires,
        uint256 goal,
        string calldata uri
    ) external override returns (uint256) {
        // expires valid
        if (expires < block.timestamp || block.timestamp + _maxFundingPeriod < expires)
            revert Dcrowd_InvalidExpires(expires);
        // store project
        uint256 projectId = _projectCounter++;
        _projectInfos[projectId] = ProjectInfo({
            creator: _msgSender(),
            expires: expires,
            funded: false,
            goal: goal,
            balance: 0
        });
        _uris[projectId] = uri;
        // emit and return
        emit ProjectCreated(projectId, _msgSender(), expires, goal, uri);
        return projectId;
    }

    function collectFunds(uint256 projectId) external override nonReentrant {
        ProjectInfo memory project = _projectInfos[projectId];
        // sender is creator
        if (_msgSender() != project.creator) revert Dcrowd_NotProjectCreator(_msgSender());
        // project is fully funded
        if (project.balance < project.goal) revert Dcrowd_ProjectNotFunded(projectId);
        // funds have not already been collected
        if (project.funded) revert Dcrowd_ProjectAlreadyFunded(projectId);
        // update storage
        _projectInfos[projectId].funded = true;
        // compute fees
        uint256 fees = (project.balance * _platformFee) / FEE_DENOMINATOR;
        uint256 valueToCreator = project.balance - fees;
        // transfer funds
        (bool success, ) = project.creator.call{value: valueToCreator, gas: 2300}("");
        if (!success) revert Dcrowd_TransferFailed(project.creator, valueToCreator);
        _feeBalance += fees;
        emit FundsCollected(projectId, project.creator, valueToCreator);
    }

    //----------------------------------------------------- funder functions

    function fundProject(uint256 projectId) external payable override {
        ProjectInfo memory project = _projectInfos[projectId];
        // value is sent
        if (msg.value == 0) revert Dcrowd_InsufficientAmount(msg.value, 1);
        // project exists
        if (project.creator == address(0)) revert Dcrowd_ProjectNotExists(projectId);
        // project not funded
        if (project.goal <= project.balance || project.funded)
            revert Dcrowd_ProjectAlreadyFunded(projectId);
        // funding not expired
        if (project.expires < block.timestamp) revert Dcrowd_ProjectFundingExpired(projectId);
        // update storage
        _projectInfos[projectId].balance += msg.value;
        _fundings[_msgSender()][projectId] += msg.value;
        emit ProjectFunded(projectId, _msgSender(), msg.value);
    }

    function cancelFunding(uint256 projectId, uint256 amount) external override {
        ProjectInfo memory project = _projectInfos[projectId];
        uint256 funding_ = _fundings[_msgSender()][projectId];
        // project exists
        if (project.creator == address(0)) revert Dcrowd_ProjectNotExists(projectId);
        // project not funded
        if (project.funded) revert Dcrowd_ProjectAlreadyFunded(projectId);
        // sender has funded
        if (funding_ < amount || amount == 0) revert Dcrowd_InsufficientAmount(amount, funding_);
        // transfer funds
        (bool success, ) = _msgSender().call{value: amount, gas: 2300}("");
        if (!success) revert Dcrowd_TransferFailed(_msgSender(), amount);
        emit FundingCancelled(projectId, _msgSender(), amount);
    }

    //----------------------------------------------------- owner functions

    function withdrawFees(address to) external override onlyOwner {
        // there are fees to transfer
        uint256 balance = _feeBalance;
        if (balance == 0) revert Dcrowd_InsufficientAmount(balance, 1);
        // cannot transfer to zero address
        if (to == address(0)) revert Dcrowd_InvalidAddress(to);
        _feeBalance = 0;
        // transfer fees
        (bool success, ) = to.call{value: balance, gas: 2300}("");
        if (!success) revert Dcrowd_TransferFailed(to, balance);
        emit FeesWithdrawn(to, balance);
    }

    function updateCreatorRating(address creator, uint8 rating) external override onlyOwner {
        _creatorRatings[creator] = rating;
        emit CreatorRatingUpdated(creator, rating);
    }

    function updateMaxFundingPeriod(uint64 newMaxFundingPeriod) external override onlyOwner {
        _maxFundingPeriod = newMaxFundingPeriod;
    }

    function updatePlatformFee(uint16 newPlatformFee) external override onlyOwner {
        if (FEE_DENOMINATOR < newPlatformFee) revert();
        _platformFee = newPlatformFee;
    }

    //----------------------------------------------------- accessor functions

    function feeBalance() external view override returns (uint256) {
        return _feeBalance;
    }

    function creatorRating(address creator) external view override returns (uint8) {
        return _creatorRatings[creator];
    }

    function projectCounter() external view override returns (uint256) {
        return _projectCounter;
    }

    function projectInfo(uint256 projectId) external view override returns (ProjectInfo memory) {
        return _projectInfos[projectId];
    }

    function projectURI(uint256 projectId) external view override returns (string memory) {
        return _uris[projectId];
    }

    function funding(address funder, uint256 projectId) external view override returns (uint256) {
        return _fundings[funder][projectId];
    }

    function maxFundingPeriod() external view override returns (uint64) {
        return _maxFundingPeriod;
    }

    function platformFee() external view override returns (uint16) {
        return _platformFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Dcrowd_InvalidExpires(uint256 expires);
error Dcrowd_ProjectNotExists(uint256 projectId);
error Dcrowd_ProjectAlreadyFunded(uint256 projectId);
error Dcrowd_NotProjectCreator(address sender);
error Dcrowd_ProjectNotFunded(uint256 projectId);
error Dcrowd_TransferFailed(address to, uint256 value);
error Dcrowd_ProjectFundingExpired(uint256 projectId);
error Dcrowd_InsufficientAmount(uint256 actual, uint256 expected);
error Dcrowd_InvalidAddress(address addr);

/// @title Crowd Funding Contract
/// @author Nicolas Bayle
interface IDcrowd {
    //----------------------------------------------------- structs

    struct ProjectInfo {
        // creator of the project
        address creator;
        // UNIX timestamp, given by `block.timestamp`, end of funding period
        uint64 expires;
        // if the funds have been transferred to the project creator
        bool funded;
        // project funds goal
        uint256 goal;
        // current funds of the project
        uint256 balance;
    }

    //----------------------------------------------------- events

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed creator,
        uint64 indexed expires,
        uint256 goal,
        string uri
    );

    event FundsCollected(uint256 indexed projectId, address indexed creator, uint256 funds);

    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);

    event FundingCancelled(uint256 indexed projectId, address indexed funder, uint256 amount);

    event CreatorRatingUpdated(address indexed creator, uint8 rating);

    event FeesWithdrawn(address indexed to, uint256 amount);

    //----------------------------------------------------- creator functions

    /// @param expires UNIX timextamp, end of the funding period of the project.
    /// @return Project ID
    function createProject(
        uint64 expires,
        uint256 goal,
        string calldata uri
    ) external returns (uint256);

    function collectFunds(uint256 projectId) external;

    //----------------------------------------------------- funder functions

    function fundProject(uint256 projectId) external payable;

    function cancelFunding(uint256 projectId, uint256 amount) external;

    //----------------------------------------------------- owner functions

    function withdrawFees(address to) external;

    function updateCreatorRating(address creator, uint8 rating) external;

    function updateMaxFundingPeriod(uint64 newMaxFundingPeriod) external;

    function updatePlatformFee(uint16 newPlatformFee) external;

    //----------------------------------------------------- accessor functions

    function feeBalance() external view returns (uint256);

    function creatorRating(address creator) external view returns (uint8);

    function projectCounter() external view returns (uint256);

    function projectInfo(uint256 projectId) external view returns (ProjectInfo memory);

    function projectURI(uint256 projectId) external view returns (string memory);

    function funding(address funder, uint256 projectId) external view returns (uint256);

    function maxFundingPeriod() external view returns (uint64);

    function platformFee() external view returns (uint16);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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