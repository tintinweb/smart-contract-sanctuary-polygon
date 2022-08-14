//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

// Make it pausable!
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IMoonpageManager.sol";
import "../interfaces/IAuctionsManager.sol";

contract MoonpageFactory is Ownable, Pausable {
    uint256 public firstEditionMin = 5;
    uint256 public firstEditionMax = 1000;
    IMoonpageManager public moonpageManager;
    IAuctionsManager public auctionsManager;
    uint256 public projectsIndex = 1;
    event ProjectCreated(
        address owner,
        uint256 projectId,
        string title,
        string textIpfsHash,
        string originalLanguage,
        uint256 initialMintPrice,
        uint256 firstEditionAmount
    );

    constructor(address _mpManager, address _auctionsManager) {
        moonpageManager = IMoonpageManager(_mpManager);
        auctionsManager = IAuctionsManager(_auctionsManager);
    }

    function createProject(
        string calldata _title,
        string calldata _textIpfsHash,
        string calldata _originalLanguage,
        uint256 _initialMintPrice,
        uint256 _firstEditionAmount
    ) external whenNotPaused {
        require(
            _firstEditionAmount > firstEditionMin &&
                _firstEditionAmount < firstEditionMax,
            "Incorrect amount"
        );
        moonpageManager.setupDao(
            msg.sender,
            projectsIndex,
            _title,
            _textIpfsHash,
            _originalLanguage,
            _initialMintPrice,
            _firstEditionAmount
        );
        // this line causes problems when testing
        auctionsManager.setupAuctionSettings(projectsIndex, msg.sender);
        emit ProjectCreated(
            msg.sender,
            projectsIndex,
            _title,
            _textIpfsHash,
            _originalLanguage,
            _initialMintPrice,
            _firstEditionAmount
        );
        projectsIndex++;
    }

    // ------------------
    // Admin functions
    // -----------------

    function setContracts(address _mpManager, address _aManager)
        external
        onlyOwner
        whenNotPaused
    {
        moonpageManager = IMoonpageManager(_mpManager);
        auctionsManager = IAuctionsManager(_aManager);
    }

    function setGenesisAmountRange(uint256 _min, uint256 _max)
        external
        onlyOwner
        whenNotPaused
    {
        firstEditionMin = _min;
        firstEditionMax = _max;
    }

    function withdraw(address _to) external payable onlyOwner whenNotPaused {
        require(_to != address(0), "Cannot withdraw to the 0 address");
        payable(_to).transfer(address(this).balance);
    }

    receive() external payable {}

    // ------------------
    // Admin Functions
    // ------------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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

interface IAuctionsManager {
    function setContracts(
        address _manager,
        address _factory,
        address _collection
    ) external;

    function setupAuctionSettings(uint256 _projectId, address _creator)
        external;

    function getPrice(uint256 _projectId, uint256 _startPrice)
        external
        returns (uint256);

    function triggerNextAuction(uint256 _projectId) external;

    function startAuctions(
        uint256 _projectId,
        uint256 _amountForCreator,
        uint256 _discountRate
    ) external;

    function endAuctions(uint256 _projectId) external;

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
        );
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