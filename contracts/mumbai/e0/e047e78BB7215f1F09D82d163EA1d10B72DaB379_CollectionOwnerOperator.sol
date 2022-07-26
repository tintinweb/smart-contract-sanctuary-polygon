/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


/**
 * @dev Interface of an Lands ERC721 compliant contract.
 */
interface IERC721RentingContract {

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isTokenRented(uint256 tokenId) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IAccountManagers {
    function isManager(address account, address manager) external view returns (bool);
}

interface IRentingContract {

    event CollectionCreated(uint256 id);
    event CollectionUpdated(uint256 id);
    event CollectionPlayersUpdated(uint256 id);
    event CollectionBotsUpdated(uint256 id);
    event CollectionLandsUpdated(uint256 id);
    event CollectionDisband(uint256 id);

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        BUSD,
        USDT,
        DAI
    }

    enum RentingType {
        FIXED_PRICE,
        REVENUE_SHARE
    }

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }

    struct BattleSet {
        uint256 landId;
        uint256[] botsIds;
    }

    struct RentingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 price;
        address owner;
        address renter;
        uint256 rentingTs;
        uint256 renewTs;
        uint256 rentingEndTs;
        uint256 cancelTs;
        uint256 collectionId;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct Collection {
        uint256 id;
        address owner;
        uint256[] landIds;
        uint256[] botsIds;
        uint256[] rentedLandIds;
        uint256[] rentedBotsIds;
        uint256[] landsToRemove;
        uint256[] botsToRemove;
        address[] whitelist;
        RentingType rentingType;
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
        uint revenueShare;
    }
}


library Array256Lib {
    function contains(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }


    function remove(uint256[] memory array, uint256 value) internal pure returns (uint256[] memory){
        uint256[] memory newArray = new uint256[](array.length - 1);
        uint idx = 0;
        for (uint i = 0; i < array.length; i++) {
            if (array[i] != value) {
                newArray[idx++] = array[i];
            }
        }
        require(newArray.length == array.length - 1, "Failed to remove");
        return newArray;
    }
}


interface IXoiliumMarketplace {
    function anyListingsExist(uint8 nft, uint256[] memory tokenIds) external view returns (bool);

    function validListingExists(uint8 nft, uint256 tokenId) external view returns (bool);
}


interface IRentingContractStorage is IRentingContract {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external returns (uint256);

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external;

    function getCollection(uint256 id) external view returns (Collection memory);

    function removeListedLand(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external;

    function removeListedBot(uint id, uint256 botIdToRemove) external;

    function addPlayersToCollection(uint id, address[] memory players) external;

    function removePlayersFromCollection(uint id, address player) external;

    function disbandCollection(uint256 id) external returns (bool);

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external;
}


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract CollectionOwnerOperator is Context, IRentingContract, Ownable, Pausable {

    uint private constant MAX_LANDS_IN_COLLECTION = 300;
    uint private constant MAX_BOTS_IN_COLLECTION = 600;

    mapping(Coin => address) private paymentContracts;
    IRentingContractStorage private storageContract;
    IERC721RentingContract private landsContract;
    IERC721RentingContract private botsContract;
    IXoiliumMarketplace private xoiliumMarketplace;
    IAccountManagers private accountManagers;

    Coin[] private fixedPriceRentalsSupportedCoins = new Coin[](0);
    Coin[] private revShareRentalsSupportedCoins = [Coin.XOIL];

    constructor(address storageContractAddress,
        address xoiliumMarketplaceAddress,
        address accountManagersAddress,
        address landsContractAddress,
        address botsContractAddress,
        address xoilAddress,
        address rblsAddress,
        address wethAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        paymentContracts[Coin.WETH] = wethAddress;
        storageContract = IRentingContractStorage(storageContractAddress);
        landsContract = IERC721RentingContract(landsContractAddress);
        botsContract = IERC721RentingContract(botsContractAddress);
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
        accountManagers = IAccountManagers(accountManagersAddress);
    }

    function setMarketplaceAddress(address xoiliumMarketplaceAddress) onlyOwner external {
        xoiliumMarketplace = IXoiliumMarketplace(xoiliumMarketplaceAddress);
    }

    function setUpSupportedCoins(Coin[] memory fixedPriceCoins, Coin[] memory revShareCoins) onlyOwner external {
        fixedPriceRentalsSupportedCoins = fixedPriceCoins;
        revShareRentalsSupportedCoins = revShareCoins;
    }

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(rentingType == RentingType.FIXED_PRICE || (revenueShare != 0 && revenueShare < 100),
            "Revenue share should be between 0-100 with revenue share renting type");
        require(price >= 100, "Price should be greater than 100");
        require(paymentContracts[coin] != address(0), "Not supported payment coin");
        require(containsCoin(rentingType == RentingType.FIXED_PRICE ? fixedPriceRentalsSupportedCoins : revShareRentalsSupportedCoins, coin),
            "Not supported payment currency for selected renting type");

        storageContract.editCollection(id, coin, price, rentingType, perpetual, revenueShare);
        emit CollectionUpdated(id);
    }

    function createCollectionFixedPrice(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 price, bool perpetual) whenNotPaused external returns (uint256) {
        require(containsCoin(fixedPriceRentalsSupportedCoins, coin), "Not supported payment currency");

        PaymentData memory pd = PaymentData({rentingType : RentingType.FIXED_PRICE, coin : coin, price : price, revenueShare : 0});
        return createCollection(landIds, botIds, players, perpetual, pd);
    }

    function createCollectionShareRental(uint256[] memory landIds, uint256[] memory botIds, address[] memory players,
        Coin coin, uint256 guaranteeAmount, bool perpetual, uint revenueShare) whenNotPaused external returns (uint256) {
        require(containsCoin(revShareRentalsSupportedCoins, coin), "Not supported payment currency");
        require(revenueShare != 0 && revenueShare < 100, "Revenue share should be between 0-100 with revenue share renting type");

        PaymentData memory pd = PaymentData({rentingType : RentingType.REVENUE_SHARE, coin : coin, price : guaranteeAmount, revenueShare : revenueShare});
        return createCollection(landIds, botIds, players, perpetual, pd);
    }

    function addLandsToCollection(uint id, uint256[] memory landIds) whenNotPaused external returns (bool) {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(0, landIds), "One of the land is listed for sale");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.landIds.length + landIds.length <= MAX_LANDS_IN_COLLECTION, "Lands number exceeds the limit");
        require(areLandsAvailable(landIds) && !landsAreRented(landIds), "One of the land is present in other battle set or in the collection");

        transferTokens(landIds, new uint256[](0), _msgSender(), address(storageContract));
        storageContract.addAssetsToCollection(id, landIds, new uint256[](0));

        emit CollectionLandsUpdated(id);

        return true;
    }

    function addBotsToCollection(uint id, uint256[] memory botIds) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds), "One of the bots listed for sale");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.botsIds.length + botIds.length <= MAX_BOTS_IN_COLLECTION, "Bots number exceeds the limit");
        require(areBotsAvailable(botIds) && !botsAreRented(botIds), "One of the bots is present in other battle set or in the collection");

        transferTokens(new uint256[](0), botIds, _msgSender(), address(storageContract));
        storageContract.addAssetsToCollection(id, new uint256[](0), botIds);

        emit CollectionBotsUpdated(id);
    }

    function removeLandFromCollection(uint id, uint256 landIdToRemove) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.landIds.length + collection.rentedLandIds.length - 1 >= 2, "The target size of lands in collection is below of minimum");

        TokenRentingStatus status = storageContract.getLandStatus(landIdToRemove);
        if (status == TokenRentingStatus.LISTED_COLLECTION) {
            storageContract.removeListedLand(id, landIdToRemove);

            landsContract.transferFrom(address(storageContract), collection.owner, landIdToRemove);
        } else if (status == TokenRentingStatus.RENTED) {
            RentingInfo memory ri = storageContract.getRentingInfo(landIdToRemove);
            require(ri.collectionId == id, "The land is not contained in specified collection");

            if (!Array256Lib.contains(collection.landsToRemove, landIdToRemove)) {
                storageContract.pushToBeRemovedLands(id, landIdToRemove);
            }
        }
        emit CollectionLandsUpdated(id);
    }

    function removeBotFromCollection(uint id, uint256 botIdToRemove) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        require(collection.botsIds.length + collection.rentedBotsIds.length - 1 >= 6, "The target size of bots in collection is below of minimum");

        if (Array256Lib.contains(collection.botsIds, botIdToRemove)) {//not rented
            storageContract.removeListedBot(id, botIdToRemove);

            botsContract.transferFrom(address(storageContract), collection.owner, botIdToRemove);
        } else if (Array256Lib.contains(collection.rentedBotsIds, botIdToRemove)) {
            storageContract.pushToBeRemovedBots(id, botIdToRemove);
        }
        emit CollectionBotsUpdated(id);
    }

    function addPlayersToCollection(uint id, address[] memory players) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(players.length >= 0, "Wrong number of players");
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        storageContract.addPlayersToCollection(id, players);
        emit CollectionPlayersUpdated(id);
    }

    function removePlayersFromCollection(uint id, address player) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");

        storageContract.removePlayersFromCollection(id, player);
        emit CollectionPlayersUpdated(id);
    }


    function disbandCollection(uint256 id) whenNotPaused external {
        Collection memory collection = storageContract.getCollection(id);
        require(isAuthorizedToEdit(collection.owner), "Not authorized");
        if (storageContract.disbandCollection(id)) {
            transferTokens(collection.landIds, collection.botsIds, address(storageContract), collection.owner);
            emit CollectionDisband(id);
        }
    }

    function isAuthorizedToEdit(address collectionOwner) private view returns (bool) {
        return collectionOwner == _msgSender() || accountManagers.isManager(collectionOwner, _msgSender());
    }

    function createCollection(uint256[] memory landIds, uint256[] memory botIds, address[] memory players, bool perpetual, PaymentData memory pd) private returns (uint256) {
        address assetsOwner = landsContract.ownerOf(landIds[0]);
        require(!xoiliumMarketplace.anyListingsExist(1, botIds) && !xoiliumMarketplace.anyListingsExist(0, landIds), "One of the assets listed for sale");
        require(isAuthorizedToEdit(_msgSender()), "Not authorized");
        require(landIds.length >= 2 && botIds.length >= 6 && landIds.length <= MAX_LANDS_IN_COLLECTION
            && botIds.length <= MAX_BOTS_IN_COLLECTION, "Collection should consist of 2 - 200 lands and 6 - 600 bots");
        require(pd.price >= 100, "Price should be greater than 100");
        require(areLandsAvailable(landIds) && areBotsAvailable(botIds), "One of the asset is present in other battle set or in the collection");
        require(!landsAreRented(landIds) && !botsAreRented(botIds), "One of the asset is rented");

        transferTokens(landIds, botIds, _msgSender(), address(storageContract));

        uint256 id = storageContract.createCollection(assetsOwner, landIds, botIds, perpetual, players, pd);

        emit CollectionCreated(id);

        return id;
    }

    function areLandsAvailable(uint256[] memory landIds) private view returns (bool) {
        for (uint i = 0; i < landIds.length; i++) {
            if (storageContract.getLandStatus(landIds[i]) != TokenRentingStatus.AVAILABLE) {
                return false;
            }
        }
        return true;
    }

    function areBotsAvailable(uint256[] memory botIds) private view returns (bool) {
        for (uint i = 0; i < botIds.length; i++) {
            if (storageContract.getBotStatus(botIds[i]) != TokenRentingStatus.AVAILABLE) {
                return false;
            }
        }
        return true;
    }

    function transferTokens(uint256[] memory landIds, uint256[] memory botIds, address from, address to) private {
        for (uint i = 0; i < landIds.length; i++) {
            landsContract.transferFrom(from, to, landIds[i]);
        }
        for (uint i = 0; i < botIds.length; i++) {
            botsContract.transferFrom(from, to, botIds[i]);
        }
    }

    function containsCoin(Coin[] memory array, Coin value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    function botsAreRented(uint256[] memory botIds) private view returns (bool) {
        for (uint i = 0; i < botIds.length; i++) {
            if (botsContract.isTokenRented(botIds[i])) {
                return true;
            }
        }
        return false;
    }

    function landsAreRented(uint256[] memory landIds) private view returns (bool) {
        for (uint i = 0; i < landIds.length; i++) {
            if (landsContract.isTokenRented(landIds[i])) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Pauses operations.
    */
    function setPaused(bool pause) public onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     *
     * @dev Allow owner to transfer ERC-20 token from contract
     *
     * @param tokenContract contract address of corresponding token
     * @param amount amount of token to be transferred
     *
     */
    function withdrawToken(address tokenContract, uint256 amount) external onlyOwner {
        IERC20(tokenContract).transfer(msg.sender, amount);
    }
}