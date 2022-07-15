// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IWhitelist.sol";

/**
 * @title MintRequests
 * Mint Requests - This contract accepts NFT minting requests, 
 * for admin approval. Once a request is approved, it can be 
 created or minted from the equivelant NFT Factory or NFT contract
 */
contract MintRequests is Ownable {
    /// @dev Events of the contract
    event RequestSubmitted(
        uint256 requestId,
        bool isMultiToken,
        bool deployAndMint,
        address existingAddress,
        address owner,
        address recipient,
        string tokenUri1155,
        string name,
        string symbol,
        string tokenUri,
        uint256 supply,
        uint256 expirationDate
    );

    event RequestApproved(uint256 requestId);

    event RequestUpdated(
        uint256 requestId,
        address existingAddress,
        address owner,
        address recipient,
        string tokenUri1155,
        string name,
        string symbol,
        string tokenUri,
        uint256 supply
    );

    event RequestSetAsMinted(uint256 requestId);

    /// @notice Whitelist contract address
    IAddressRegistry public addressRegistry;
    /// @notice _currentRequestId keeps the latest request Id
    uint256 public _currentRequestId = 0;
    /// @notice Expired requests cannot be updated, minted or approved. Default value is 7 days after submission
    uint24 public expAfterDays = 7;

    /// @notice The Requests struct keeps all the requests
    struct Requests {
        bool isMultiToken;
        bool deployAndMint;
        address existingAddress;
        address owner;
        address recipient;
        string tokenUri1155;
        string name;
        string symbol;
        string tokenUri;
        uint256 supply;
        uint256 expirationDate;
        bool isApproved;
        bool isMinted;
    }

    // Map the id of the NFT to the struct
    mapping(uint256 => Requests) public requests;

    /// @notice Relying on the Whitelist contract's roles
    modifier onlyLazyOrFullOrAdmin() {
        bool hasLazy = IWhitelist(addressRegistry.whitelistContract()).hasRoleLazy(msg.sender);
        bool hasFull = IWhitelist(addressRegistry.whitelistContract()).hasRoleFull(msg.sender);
        bool hasAdmin = IWhitelist(addressRegistry.whitelistContract()).hasRoleAdmin(msg.sender);

        require(hasLazy || hasFull || hasAdmin, "not lazy or full minter role");
        _;
    }

    modifier onlyFactoryOrAdmin() {
        bool isFactory = IWhitelist(addressRegistry.whitelistContract()).hasRoleFactory(msg.sender);
        bool isAdmin = IWhitelist(addressRegistry.whitelistContract()).hasRoleAdmin(msg.sender);

        require(isFactory || isAdmin, "not factory or admin role");
        _;
    }

    modifier onlyAdmin() {
        require(IWhitelist(addressRegistry.whitelistContract()).hasRoleAdmin(msg.sender), "not an admin");
        _;
    }

    modifier notExpiredApprovedOrMinted(uint256 requestId) {
        Requests memory request = requests[requestId];
        require(block.timestamp <= request.expirationDate, "Request has expired");
        require(!request.isApproved, "Request already approved");
        require(!request.isMinted, "Request already minted");
        _;
    }

    /**
     @notice Constructor
     @param _addressRegistry is the address of the whitelist contract
     */
    constructor(address _addressRegistry) {
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    /**
    @notice Method for updating whitelist contract address
    @dev Only owner
    @param _addressRegistry address to the new whitelist contract
    */
    function updateAddressRegistryContract(address _addressRegistry) external onlyOwner {
        addressRegistry = IAddressRegistry(_addressRegistry);
    }

    /**
    @notice Method for updating the duration of requests
    @dev Only admin
    @param _expAfterDays the number of days that new requests will expire after
    */
    function updateRequestDuration(uint24 _expAfterDays) external onlyAdmin {
        expAfterDays = _expAfterDays;
    }

    /**
    @notice Method for submitting a mint request
    @dev Only Lazy minters, Full minters, or Admins (on behalf of minters)
    */
    function submitRequest(
        bool _isMultiToken,
        bool _deployAndMint,
        address _existingAddress,
        address _recipient,
        string memory _tokenUri1155,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        uint256 _supply
    ) external onlyLazyOrFullOrAdmin {
        uint24 duration = expAfterDays * 1 days;
        _currentRequestId++;

        //Add to struct
        Requests memory request;
        request.isMultiToken = _isMultiToken;
        request.deployAndMint = _deployAndMint;
        request.owner = msg.sender;
        request.recipient = _recipient;
        request.tokenUri = _tokenUri;
        request.expirationDate = block.timestamp + duration;
        request.isApproved = false;
        request.isMinted = false;

        //If ERC1155 spec, specify additional info
        if (_isMultiToken) {
            request.tokenUri1155 = _tokenUri1155;
            request.supply = _supply;
        }

        //If deploy and mint request, specify additional info
        if (_deployAndMint) {
            request.name = _name;
            request.symbol = _symbol;
            request.existingAddress = _existingAddress;
        }

        //Add to mapping
        requests[_currentRequestId] = request;

        //Emit RequestSubmitted event
        emit RequestSubmitted(
            _currentRequestId,
            request.isMultiToken,
            request.deployAndMint,
            request.existingAddress,
            request.owner,
            request.recipient,
            request.tokenUri1155,
            request.name,
            request.symbol,
            request.tokenUri,
            request.supply,
            request.expirationDate
        );
    }

    /**
    @notice Method to check if a request has expired, given its Id
    @param requestId the Id of the request
    */
    function isRequestActive(uint256 requestId) public view returns (bool) {
        Requests memory request = requests[requestId];
        return block.timestamp <= request.expirationDate;
    }

    /**
    @notice Method to approve an active request
    @dev Only admin
    @param requestId the Id of the request
    */
    function approveRequest(uint256 requestId) external onlyAdmin notExpiredApprovedOrMinted(requestId) {
        requests[requestId].isApproved = true;

        //Emit RequestApproved event
        emit RequestApproved(requestId);
    }

    /**
    @notice Method to update a non-approved, active request
    @dev Only admin
    @param requestId the Id of the request
    */
    function updateRequest(
        uint256 requestId,
        address _existingAddress,
        address _owner,
        address _recipient,
        string memory _tokenUri1555,
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        uint256 _supply
    ) external onlyAdmin {
        //Get item from the requests mapping
        Requests storage request = requests[requestId];
        require(block.timestamp <= request.expirationDate, "Request has expired");
        //Update struct
        request.existingAddress = _existingAddress;
        request.owner = _owner;
        request.recipient = _recipient;
        request.tokenUri1155 = _tokenUri1555;
        request.name = _name;
        request.symbol = _symbol;
        request.tokenUri = _tokenUri;
        request.supply = _supply;

        //Emit RequestUpdated event
        emit RequestUpdated(
            requestId,
            request.existingAddress,
            request.owner,
            request.recipient,
            request.tokenUri1155,
            request.name,
            request.symbol,
            request.tokenUri,
            request.supply
        );
    }

    /**
    @notice Method to check if a request can be minted (Is approved, not minted, and hasn't expired)
    @param requestId the Id of the request
    */
    function shouldBeMinted(uint256 requestId) external view returns (bool) {
        Requests memory request = requests[requestId];
        if ((block.timestamp <= request.expirationDate) && (request.isApproved) && (!request.isMinted)) {
            return true;
        }
        return false;
    }

    /**
    @notice Method to set a request as minted (called from the Factory or NFT contract)
    @dev Only Factory contract or Admin
    @param requestId the Id of the request
    */
    function setAsMinted(uint256 requestId) external onlyFactoryOrAdmin {
        Requests storage request = requests[requestId];
        require(request.isApproved, "Request already approved");
        require(!request.isMinted, "Request already minted");
        request.isMinted = true;
        //emit RequestSetAsMinted event
        emit RequestSetAsMinted(requestId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAddressRegistry {
  function MultiTokenFactory (  ) external view returns ( address );
  function NFT (  ) external view returns ( address );
  function auction (  ) external view returns ( address );
  function factory (  ) external view returns ( address );
  function marketplace (  ) external view returns ( address );
  function mintRequest (  ) external view returns ( address );
  function treasuryManagement (  ) external view returns ( address );
  function whitelistContract (  ) external view returns ( address );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWhitelist {
    function hasRoleUnlimited(address _account) external view returns (bool);
    function hasRoleAdmin(address _account) external view returns (bool);
    function hasRoleLazy(address _account) external view returns (bool);
    function hasRoleFull(address _account) external view returns (bool);
    function hasRoleFactory(address _account) external view returns (bool);
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