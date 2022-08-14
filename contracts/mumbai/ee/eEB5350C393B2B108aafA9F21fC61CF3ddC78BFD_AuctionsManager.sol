//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMoonpageManager.sol";
import "../interfaces/IMoonpageCollection.sol";
import "../interfaces/IMoonpageFactory.sol";

// should just be ownable???
contract AuctionsManager is Pausable, Ownable {
    uint256 public constant AUCTION_DURATION = 1 days;
    IMoonpageManager public moonpageManager;
    IMoonpageFactory public moonpageFactory;
    IMoonpageCollection public moonpageCollection;

    struct AuctionSettings {
        bool exists;
        address creator;
        uint256 discountRate;
        uint256 startAt;
        uint256 expiresAt;
        bool auctionsStarted;
        bool auctionsEnded;
    }
    mapping(uint256 => AuctionSettings) public auctions;

    event AuctionsStarted(
        uint256 projectId,
        uint256 premintedAmount,
        uint256 time
    );
    event AuctionsEnded(uint256 projectId, uint256 time);
    event ExpirationSet(uint256 projectId, uint256 expirationTime);

    modifier onlyCollection() {
        require(msg.sender == address(moonpageCollection), "Not authorized");
        _;
    }

    // ------------------
    // Gated external functions
    // -----------------

    // only called by owner
    function setContracts(
        address _manager,
        address _factory,
        address _collection
    ) external onlyOwner {
        moonpageManager = IMoonpageManager(_manager);
        moonpageFactory = IMoonpageFactory(_factory);
        moonpageCollection = IMoonpageCollection(_collection);
    }

    // only called by factory
    function setupAuctionSettings(uint256 _projectId, address _creatorAddress)
        external
        whenNotPaused
    {
        require(msg.sender == address(moonpageFactory), "Not authorized");
        require(!auctions[_projectId].exists, "Already added");

        auctions[_projectId].exists = true;
        auctions[_projectId].creator = _creatorAddress;
        auctions[_projectId].discountRate = 0;
        auctions[_projectId].startAt = 0;
        auctions[_projectId].expiresAt = 0;
        auctions[_projectId].auctionsStarted = false;
        auctions[_projectId].auctionsEnded = false;
    }

    // only called by collection
    function startAuctions(
        uint256 _projectId,
        uint256 _amountForCreator,
        uint256 _discountRate
    ) external whenNotPaused onlyCollection {
        require(
            !auctions[_projectId].auctionsStarted,
            "Auctions already started"
        );
        require(!auctions[_projectId].auctionsEnded, "Auctions already ended");

        auctions[_projectId].discountRate = _discountRate;
        auctions[_projectId].startAt = block.timestamp;
        auctions[_projectId].expiresAt = block.timestamp + AUCTION_DURATION;
        auctions[_projectId].auctionsStarted = true;
        emit ExpirationSet(_projectId, block.timestamp + AUCTION_DURATION);
        emit AuctionsStarted(_projectId, _amountForCreator, block.timestamp);
    }

    // only called by collection
    function triggerNextAuction(uint256 _projectId) external onlyCollection {
        auctions[_projectId].startAt = block.timestamp;
        auctions[_projectId].expiresAt = block.timestamp + AUCTION_DURATION;
        emit ExpirationSet(_projectId, block.timestamp + AUCTION_DURATION);
    }

    // only called by collection
    function endAuctions(uint256 _projectId) external onlyCollection {
        require(!auctions[_projectId].auctionsEnded, "Already ended");
        auctions[_projectId].auctionsEnded = true;
        emit AuctionsEnded(_projectId, block.timestamp);
    }

    // ------------------
    // Ungated external functions
    // -----------------

    function retriggerAuction(uint256 _projectId) external {
        require(
            auctions[_projectId].expiresAt < block.timestamp,
            "Triggering unnecessary. Auction running."
        );
        auctions[_projectId].startAt = block.timestamp;
        auctions[_projectId].expiresAt = block.timestamp + AUCTION_DURATION;
        emit ExpirationSet(_projectId, block.timestamp + AUCTION_DURATION);
    }

    // needed?
    receive() external payable {}

    // ------------------
    // View functions
    // -----------------

    function getPrice(uint256 _projectId, uint256 _startPrice)
        public
        view
        returns (uint256)
    {
        AuctionSettings memory auctionSetting = auctions[_projectId];
        if (auctionSetting.auctionsStarted && !auctionSetting.auctionsEnded) {
            uint256 timeElapsed = block.timestamp - auctionSetting.startAt;
            uint256 discount = auctionSetting.discountRate * timeElapsed;
            return _startPrice - discount;
        }
        return 0;
    }

    function readAuctionSettings(uint256 _projectId)
        external
        view
        returns (
            bool,
            address,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        AuctionSettings storage data = auctions[_projectId];

        return (
            data.exists,
            data.creator,
            data.discountRate,
            data.startAt,
            data.expiresAt,
            data.auctionsStarted,
            data.auctionsEnded
        );
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IMoonpageManager {
    function setupDao(
        address _caller,
        uint256 _projectId,
        string calldata _title,
        string calldata _textCID,
        string calldata _originalLanguage,
        uint256 _initialMintPrice,
        uint256 _firstEditionAmount
    ) external;

    function distributeShares(uint256 _projectId) external;

    function increaseBalance(uint256 _projectId, uint256 _amount) external;

    function increaseCurrentTokenId(uint256 _projectId) external;

    function setIsBaseDataFrozen(uint256 _projectId, bool _shouldBeFrozen)
        external;

    function setPremintedByCreator(
        uint256 _projectId,
        uint256 _premintedByCreator
    ) external;

    function projectIdOfToken(uint256 _projectId)
        external
        view
        returns (uint256);

    function exists(uint256 _projectId) external view returns (bool);

    function isFrozen(uint256 _projectId) external view returns (bool);

    function readProjectBalance(uint256 _projectId)
        external
        view
        returns (uint256);

    function readBaseData(uint256 _projectId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256
        );

    function readAuthorShare(uint256 _projectId)
        external
        view
        returns (uint256, uint256);

    function readEditionData(uint256 _projectId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function readContribution(uint256 _projectId, uint256 _index)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        );

    function readContributionIndex(uint256 _projectId)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IMoonpageCollection {
    function isBaseDataFrozen() external view returns (bool);

    function lastGenEd() external view returns (uint256);

    function paused() external view returns (bool);

    function withdraw(address _to, uint256 _amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IMoonpageFactory {
    function createProject(
        string calldata _title,
        string calldata _symbol,
        string calldata _textIpfsHash,
        uint256 _initialMintPrice,
        uint256 _firstEditionAmount
    ) external returns (address);

    function firstEditionMax() external view returns (uint256);

    function firstEditionMin() external view returns (uint256);

    function collections(uint256) external view returns (address);

    function setGenesisAmountRange(uint256 _min, uint256 _max) external;

    function withdraw(address _to) external payable;
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