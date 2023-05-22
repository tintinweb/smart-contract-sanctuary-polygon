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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A contract for interacting with the CraftingCard contract.
interface ICraftingCard {
    /// @notice Creates a new crafting card.
    /// @param tokenURI The URI of the crafting card.
    /// @return The new crafting card's token ID.
    function createCraftingCard(
        string memory tokenURI,
        address owner
    ) external returns (uint256);
}

/// @title A contract for interacting with the Category contract.
interface ICategory {
    /// @notice Creates a new category.
    /// @param tokenURI The URI of the category.
    /// @return The new category's token ID.
    function createCategory(string memory tokenURI,
        address owner) external returns (uint256);
}

/// @title A contract for interacting with the Year contract.
interface IYear {
    /// @notice Creates a new year.
    /// @param tokenURI The URI of the year.
    /// @return The new year's token ID.
    function createYear(string memory tokenURI,
        address owner) external returns (uint256);
}

/// @title A contract for interacting with the DayMonth contract.
interface IDayMonth {
    /// @notice Creates a new day and month.
    /// @param tokenURI The URI of the day and month.
    /// @return The new day and month's token ID.
    function createDayMonth(string memory tokenURI,
        address owner) external returns (uint256);
}

/// @title A contract for interacting with the CardPack contract.
interface ICardPack {
    /// @notice Creates a new card pack.
    /// @param tokenURI The URI of the card pack.
    /// @return The new card pack's token ID.
    function createCard(string memory tokenURI,
        address owner) external returns (uint256);

    /// @notice Changes the status of a card pack to "opened".
    /// @param tokenId The ID of the token to be opened.
    function changeToOpened(uint256 tokenId) external;

    /// @notice Fetches the owner of a particular card pack.
    /// @param tokenId The ID of the token whose owner is to be fetched.
    /// @return The address of the owner.
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Checks whether a card pack is opened or not.
    /// @param tokenId The ID of the token to be checked.
    /// @return A boolean indicating whether the card pack is opened or not.
    function isOpened(uint256 tokenId) external view returns (bool);
}

/// @title A contract to manage the opening of card packs.
/// @dev The contract is Ownable, and the owner has exclusive rights to perform certain actions.
contract PackOpener is Ownable {
    uint256 dayMonthAmount;
    uint256 yearAmount;
    uint256 categoryAmount;
    uint256 craftingCardAmount;
    ICardPack cardPackContract;
    IDayMonth dayMonthContract;
    IYear yearContract;
    ICategory categoryContract;
    ICraftingCard craftingCardContract;

    /// @notice Initializes the contract with specified parameters.
    /// @dev The contract takes the number of each type of card, and the addresses of the card contracts.
    /// @param _dayMonthAmount The number of DayMonth cards in a pack.
    /// @param _yearAmount The number of Year cards in a pack.
    /// @param _categoryAmount The number of Category cards in a pack.
    /// @param _craftingCardAmount The number of CraftingCard cards in a pack.
    /// @param _cardPackAddress The address of the CardPack contract.
    /// @param _dayMonthAddress The address of the DayMonth contract.
    /// @param _yearAddress The address of the Year contract.
    /// @param _categoryAddress The address of the Category contract.
    /// @param _craftingCardContract The address of the CraftingCard contract.
    constructor(
        uint256 _dayMonthAmount,
        uint256 _yearAmount,
        uint256 _categoryAmount,
        uint256 _craftingCardAmount,
        address _cardPackAddress,
        address _dayMonthAddress,
        address _yearAddress,
        address _categoryAddress,
        address _craftingCardContract
    ) {
        dayMonthAmount = _dayMonthAmount;
        yearAmount = _yearAmount;
        categoryAmount = _categoryAmount;
        craftingCardAmount = _craftingCardAmount;
        cardPackContract = ICardPack(_cardPackAddress);
        dayMonthContract = IDayMonth(_dayMonthAddress);
        yearContract = IYear(_yearAddress);
        categoryContract = ICategory(_categoryAddress);
        craftingCardContract = ICraftingCard(_craftingCardContract);
    }

    /// @notice Ensures that only the owner of a pack can call certain functions.
    /// @param _tokenId The ID of the pack that the owner wants to operate on.
    modifier onlyPackOwner(uint _tokenId) {
        require(
            msg.sender == cardPackContract.ownerOf(_tokenId),
            "Only the contract owner can call this function."
        );
        _;
    }

    /// @notice Ensures that only unopened packs can be operated on.
    /// @param _tokenId The ID of the pack that the owner wants to operate on.
    modifier onlyNonOpenedPacks(uint _tokenId) {
        require(
            false == cardPackContract.isOpened(_tokenId),
            "Pack already opened"
        );
        _;
    }

    /// @notice Allows the owner of a pack to open it.
    /// @dev When a pack is opened, new cards of each type are created.
    /// @param _tokenId The ID of the pack that the owner wants to open.
    /// @param _tokenDayMonth The URI for the DayMonth cards.
    /// @param _tokenYear The URI for the Year cards.
    /// @param _tokenCategory The URI for the Category cards.
    /// @param _tokenCraftingCard The URI for the CraftingCard cards.
    function openPack(
        uint _tokenId,
        string memory _tokenDayMonth,
        string memory _tokenYear,
        string memory _tokenCategory,
        string memory _tokenCraftingCard
    ) public onlyPackOwner(_tokenId) onlyNonOpenedPacks(_tokenId) {
        cardPackContract.changeToOpened(_tokenId);
        for (uint i = 0; i < dayMonthAmount; i++) {
            dayMonthContract.createDayMonth(_tokenDayMonth,msg.sender);
        }
        for (uint j = 0; j < yearAmount; j++) {
            yearContract.createYear(_tokenYear,msg.sender);
        }
        for (uint k = 0; k < categoryAmount; k++) {
            categoryContract.createCategory(_tokenCategory,msg.sender);
        }
        for (uint l = 0; l < craftingCardAmount; l++) {
            craftingCardContract.createCraftingCard(_tokenCraftingCard,msg.sender);
        }
    }
}