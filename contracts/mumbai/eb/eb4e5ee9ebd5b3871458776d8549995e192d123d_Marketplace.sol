// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Pausable.sol";

struct ERC721Listing {
    bool active;
    uint256 price;
}

struct ERC1155Listing {
    bool active;
    address owner;
    uint256 id;
    uint256 amount;
    uint256 price;
}

struct HunterClaimable {
    uint256 lendingPrice;
    uint256 gameRewards;
}

/**
    @title Marketplace
    @notice List, buy, sell, lend and borrow game assets
    @author Hamza Karabag
 */
contract Marketplace is OwnerPausable {
    IERC20 public bgem;
    IERC20 public boom;
    IERC721 public hunters;
    IERC1155 public perks;
    IERC1155 public shards;
    IERC1155 public equipments;
    address private studio;

    // Base precision of 10**5 gives us 3 decimals to work with
    uint256 constant BASE_PRECISION = 100_000;

    // All initialized to 0
    uint256 perkCounter;
    uint256 shardCounter;
    uint256 equipmentCounter;
    uint256 studioBalance;
    uint256 royalty;

    // Hunter ID => Listing
    mapping(uint256 => ERC721Listing) public hunterListings;

    // Listing Hash => Listing
    mapping(uint256 => ERC1155Listing) public perkListings;
    mapping(uint256 => ERC1155Listing) public shardListings;
    mapping(uint256 => ERC1155Listing) public equipmentListings;
    // ERC1155 Address => ListedAmount
    mapping(IERC1155 => mapping(address => uint256)) public erc1155ListingAmts;

    // For functions that only studio can call
    modifier onlyStudio() { 
        require(msg.sender == studio, "Caller is not studio");
        _;
    }

    //	███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗
    //	██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
    //	█████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
    //	██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║
    //	███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║
    //	╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝

    event HunterListed(uint256 id);
    event HunterPriceChanced(uint256 id);
    event HunterDelisted(uint256 id);
    event HunterBought(uint256 id, uint256 price);

    event PerkListed(uint256 listingHash);
    event PerkPriceChanced(uint256 listingHash);
    event PerkDelisted(uint256 listingHash);
    event PerkBought(uint256 listingHash, uint256 price);

    event EquipmentListed(uint256 listingHash);
    event EquipmentPriceChanced(uint256 listingHash);
    event EquipmentDelisted(uint256 listingHash);
    event EquipmentBought(uint256 listingHash, uint256 price);

    event ShardListed(uint256 listingHash);
    event ShardPriceChanced(uint256 listingHash);
    event ShardDelisted(uint256 listingHash);
    event ShardBought(uint256 listingHash, uint256 price);

    //	 ██████╗███╗   ██╗███████╗████████╗ ██████╗ ██████╗
    //	██╔════╝████╗  ██║██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗
    //	██║     ██╔██╗ ██║███████╗   ██║   ██║   ██║██████╔╝
    //	██║     ██║╚██╗██║╚════██║   ██║   ██║   ██║██╔══██╗
    //	╚██████╗██║ ╚████║███████║   ██║   ╚██████╔╝██║  ██║
    //	 ╚═════╝╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    constructor(
        address initStudio,
        IERC20 initBgem,
        IERC20 initBoom,
        IERC721 initHunters,
        IERC1155 initPerks,
        IERC1155 initShards,
        IERC1155 initEquipments,
        uint256 initRoyalty
    ) {
        studio = initStudio;
        bgem = initBgem;
        boom = initBoom;
        hunters = initHunters;
        perks = initPerks;
        shards = initShards;
        equipments = initEquipments;
        royalty = initRoyalty;
    }

    //	███████╗███████╗████████╗████████╗███████╗██████╗ ███████╗
    //	██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗██╔════╝
    //	███████╗█████╗     ██║      ██║   █████╗  ██████╔╝███████╗
    //	╚════██║██╔══╝     ██║      ██║   ██╔══╝  ██╔══██╗╚════██║
    //	███████║███████╗   ██║      ██║   ███████╗██║  ██║███████║
    //	╚══════╝╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝

    function setStudio(address newStudio) external onlyOwner {
        studio = newStudio;
    }

    function setBgemAddr(IERC20 newAddr) external onlyOwner {
        bgem = newAddr;
    }

    function setBoomAddr(IERC20 newAddr) external onlyOwner {
        boom = newAddr;
    }

    function setHuntersAddr(IERC721 newAddr) external onlyOwner {
        hunters = newAddr;
    }

    function setPerksAddr(IERC1155 newAddr) external onlyOwner {
        perks = newAddr;
    }

    function setShardsAddr(IERC1155 newAddr) external onlyOwner {
        shards = newAddr;
    }

    function setEquipmentsAddr(IERC1155 newAddr) external onlyOwner {
        equipments = newAddr;
    }

    function setRoyalty(uint256 newRoyalty) external onlyOwner {
        royalty = newRoyalty;
    }

    //	██╗     ██╗███████╗████████╗
    //	██║     ██║██╔════╝╚══██╔══╝
    //	██║     ██║███████╗   ██║
    //	██║     ██║╚════██║   ██║
    //	███████╗██║███████║   ██║
    //	╚══════╝╚═╝╚══════╝   ╚═╝

    /// @notice Lists a hunter
    /// @param hunterId ID of the hunter
    /// @param price    Price of the listing
    function listHunter(uint256 hunterId, uint256 price) 
        external 
        onlyNotPaused {

        require(!hunterListings[hunterId].active, "Hunter is already on sale");
        require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the asset");

        hunterListings[hunterId] = ERC721Listing({active: true, price: price});

        emit HunterListed(hunterId);
    }

    /// @notice Lists a perk
    /// @param perkId ID of the perk
    /// @param amount Amount of perks
    /// @param price  Price of the listing
    function listPerk(
        uint256 perkId,
        uint256 amount,
        uint256 price
    ) external onlyNotPaused {

        uint256 availableBalance = perks.balanceOf(msg.sender, perkId) -
            erc1155ListingAmts[perks][msg.sender];
        
        require(availableBalance >= amount, "Not enough of asset");

        uint256 listingHash = uint256(
            keccak256(
                abi.encodePacked(perkId, amount, tx.origin, block.timestamp)
            )
        );
        require(!perkListings[listingHash].active, "Already on sale");

        perkListings[listingHash] = ERC1155Listing({
            active: true,
            id: perkId,
            owner: msg.sender,
            amount: amount,
            price: price
        });
        erc1155ListingAmts[perks][msg.sender] += amount;

        emit PerkListed(listingHash);
    }

    /// @notice Lists a equipment
    /// @param equipmentId ID of the equipment
    /// @param amount Amount of equipments
    /// @param price  Price of the listing
    function listEquipment(
        uint256 equipmentId,
        uint256 amount,
        uint256 price
    ) external onlyNotPaused {

        uint256 availableBalance = equipments.balanceOf(
            msg.sender,
            equipmentId
        ) - erc1155ListingAmts[equipments][msg.sender];
        require(availableBalance >= amount, "Not enough of asset");

        uint256 listingHash = uint256(
            keccak256(
                abi.encodePacked(
                    equipmentId,
                    amount,
                    tx.origin,
                    block.timestamp
                )
            )
        );
        require(!equipmentListings[listingHash].active, "Already on sale");

        equipmentListings[listingHash] = ERC1155Listing({
            active: true,
            id: equipmentId,
            owner: msg.sender,
            amount: amount,
            price: price
        });
        erc1155ListingAmts[equipments][msg.sender] += amount;

        emit EquipmentListed(listingHash);
    }

    /// @notice Lists a shard
    /// @param shardId ID of the shard
    /// @param amount Amount of shards
    /// @param price  Price of the listing
    function listShard(
        uint256 shardId,
        uint256 amount,
        uint256 price
    ) external onlyNotPaused {

        uint256 availableBalance = shards.balanceOf(msg.sender, shardId) -
            erc1155ListingAmts[shards][msg.sender];
        require(availableBalance >= amount, "Not enough of asset");

        uint256 listingHash = uint256(
            keccak256(
                abi.encodePacked(shardId, amount, tx.origin, block.timestamp)
            )
        );
        require(!shardListings[listingHash].active, "Already on sale");

        shardListings[listingHash] = ERC1155Listing({
            active: true,
            id: shardId,
            owner: msg.sender,
            amount: amount,
            price: price
        });
        erc1155ListingAmts[shards][msg.sender] += amount;

        emit ShardListed(listingHash);
    }

    //	███████╗██████╗ ██╗████████╗
    //	██╔════╝██╔══██╗██║╚══██╔══╝
    //	█████╗  ██║  ██║██║   ██║
    //	██╔══╝  ██║  ██║██║   ██║
    //	███████╗██████╔╝██║   ██║
    //	╚══════╝╚═════╝ ╚═╝   ╚═╝

    /// @notice Edits price of a hunter listing
    /// @param hunterId ID of the hunter
    /// @param newPrice New price for the listing
    function editHunter(uint256 hunterId, uint256 newPrice) 
        external onlyNotPaused {

        require(hunterListings[hunterId].active, "Not on sale");
        require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

        // Change price
        hunterListings[hunterId].price = newPrice;
        emit HunterPriceChanced(hunterId);
    }

    /// @notice Edits price of a perk listing
    /// @param listingHash  Hash of the listing
    /// @param newPrice     New price for the listing
    function editPerk(uint256 listingHash, uint256 newPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = perkListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Change price
        perkListings[listingHash].price = newPrice;
        emit PerkPriceChanced(listingHash);
    }

    /// @notice Edits price of an equipment listing
    /// @param listingHash  Hash of the listing
    /// @param newPrice     New price for the listing
    function editEquipment(uint256 listingHash, uint256 newPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = equipmentListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Change price
        equipmentListings[listingHash].price = newPrice;
        emit EquipmentPriceChanced(listingHash);
    }

    /// @notice Edits price of a shard listing
    /// @param listingHash  Hash of the listing
    /// @param newPrice     New price for the listing
    function editShard(uint256 listingHash, uint256 newPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = shardListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Change price
        shardListings[listingHash].price = newPrice;
        emit ShardPriceChanced(listingHash);
    }

    //	██████╗ ███████╗██╗     ██╗███████╗████████╗
    //	██╔══██╗██╔════╝██║     ██║██╔════╝╚══██╔══╝
    //	██║  ██║█████╗  ██║     ██║███████╗   ██║
    //	██║  ██║██╔══╝  ██║     ██║╚════██║   ██║
    //	██████╔╝███████╗███████╗██║███████║   ██║
    //	╚═════╝ ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝

    /// @notice Delists a hunter listing
    /// @param hunterId ID of the hunter
    function delistHunter(uint256 hunterId) external {

        require(hunterListings[hunterId].active, "Not on sale");
        require(hunters.ownerOf(hunterId) == msg.sender, "Not owner of the listing");

        // Delete listing
        delete hunterListings[hunterId];
        emit HunterDelisted(hunterId);
    }

    /// @notice Delists a perk listing
    /// @param listingHash Hash of the perk listing
    function delistPerk(uint256 listingHash) external {
        
        ERC1155Listing memory listing = perkListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Decrement listed amount
        erc1155ListingAmts[perks][msg.sender] -= listing.amount;

        // Delete listing
        delete perkListings[listingHash];
        emit PerkDelisted(listingHash);
    }

    /// @notice Delists a equipment listing
    /// @param listingHash Hash of the equipment listing
    function delistEquipment(uint256 listingHash) external {

        ERC1155Listing memory listing = equipmentListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Decrement listed amount
        erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

        // Delete listing
        delete equipmentListings[listingHash];
        emit EquipmentDelisted(listingHash);
    }

    /// @notice Delists a shard listing
    /// @param listingHash Hash of the shard listing
    function delistShard(uint256 listingHash) external {

        ERC1155Listing memory listing = shardListings[listingHash];

        require(listing.active, "Not on sale");
        require(listing.owner == msg.sender, "Not owner of the listing");

        // Decrement listed amount
        erc1155ListingAmts[shards][msg.sender] -= listing.amount;

        // Delete listing
        delete shardListings[listingHash];
        emit ShardDelisted(listingHash);
    }

    //	██████╗ ██╗   ██╗██╗   ██╗
    //	██╔══██╗██║   ██║╚██╗ ██╔╝
    //	██████╔╝██║   ██║ ╚████╔╝
    //	██╔══██╗██║   ██║  ╚██╔╝
    //	██████╔╝╚██████╔╝   ██║
    //	╚═════╝  ╚═════╝    ╚═╝

    /// @notice Buys a hunter listing
    /// @param hunterId         ID of the hunter
    /// @param expectedPrice    Price at the moment of purchase
    function buyHunter(uint256 hunterId, uint256 expectedPrice) 
        external onlyNotPaused {

        ERC721Listing memory listing = hunterListings[hunterId];
        address listingOwner = hunters.ownerOf(hunterId);

        require(listing.active, "Not on sale");
        require(msg.sender != listingOwner, "Owner of the listing");

        // This might be required as it would be possible to front-run buyHunter
        // and increase the price so if it was just "buy whatever the price is"
        // kind of function buyer could pay much more than the expected
        require(listing.price == expectedPrice, "Price mismatch");

        uint256 royaltyAmount = (expectedPrice * royalty) / BASE_PRECISION;
        studioBalance += royaltyAmount;        

        require(
            boom.transferFrom(
                msg.sender, 
                listingOwner, 
                expectedPrice-royaltyAmount
            ),
            "BOOM transfer failed"
        );
        hunters.safeTransferFrom(listingOwner, msg.sender, hunterId);

        // Delete listing
        delete hunterListings[hunterId];
        emit HunterBought(hunterId, expectedPrice);
    }

    /// @notice Buys a perk listing
    /// @param listingHash      Hash of the perk listing
    /// @param expectedPrice    Price at the moment of purchase
    function buyPerk(uint256 listingHash, uint256 expectedPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = perkListings[listingHash];

        require(listing.active, "Not on sale");
        require(msg.sender != listing.owner, "Owner of the listing");

        // see buyHunter about this
        require(listing.price == expectedPrice, "Price mismatch");

        uint256 royaltyAmount = (expectedPrice * royalty) / BASE_PRECISION;
        studioBalance += royaltyAmount;  

        require(
            boom.transferFrom(
                msg.sender, 
                listing.owner, 
                expectedPrice-royaltyAmount
            ),
            "BOOM transfer failed"
        );
        perks.safeTransferFrom(
            listing.owner,
            msg.sender,
            listing.id,
            listing.amount,
            ""
        );

        // Decrement listed amount
        erc1155ListingAmts[perks][msg.sender] -= listing.amount;

        // Delete listing
        delete perkListings[listingHash];
        emit PerkBought(listingHash, expectedPrice);
    }

    /// @notice Buys a equipment listing
    /// @param listingHash      Hash of the equipment listing
    /// @param expectedPrice    Price at the moment of purchase
    function buyEquipment(uint256 listingHash, uint256 expectedPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = equipmentListings[listingHash];

        require(listing.active, "Not on sale");
        require(msg.sender != listing.owner, "Owner of the listing");

        // see buyHunter about this
        require(listing.price == expectedPrice, "Price mismatch");

        uint256 royaltyAmount = (expectedPrice * royalty) / BASE_PRECISION;
        studioBalance += royaltyAmount;  

        require(
            boom.transferFrom(
                msg.sender, 
                listing.owner, 
                expectedPrice-royaltyAmount
            ),
            "BOOM transfer failed"
        );
        equipments.safeTransferFrom(
            listing.owner,
            msg.sender,
            listing.id,
            listing.amount,
            ""
        );

        // Decrement listed amount
        erc1155ListingAmts[equipments][msg.sender] -= listing.amount;

        // Delete listing
        delete equipmentListings[listingHash]; 
        emit EquipmentBought(listingHash, expectedPrice);
    }

    /// @notice Buys a shard listing
    /// @param listingHash      Hash of the shard listing
    /// @param expectedPrice    Price at the moment of purchase
    function buyShard(uint256 listingHash, uint256 expectedPrice) 
        external onlyNotPaused {

        ERC1155Listing memory listing = shardListings[listingHash];

        require(listing.active, "Not on sale");
        require(msg.sender != listing.owner, "Owner of the listing");

        // see buyHunter about this
        require(listing.price == expectedPrice, "Price mismatch");

        uint256 royaltyAmount = (expectedPrice * royalty) / BASE_PRECISION;
        studioBalance += royaltyAmount;  

        require(
            boom.transferFrom(
                msg.sender, 
                listing.owner, 
                expectedPrice-royaltyAmount
            ),
            "BOOM transfer failed"
        );
        shards.safeTransferFrom(
            listing.owner,
            msg.sender,
            listing.id,
            listing.amount,
            ""
        );

        // Decrement listed amount
        erc1155ListingAmts[shards][msg.sender] -= listing.amount;

        // Delete listing
        delete shardListings[listingHash];
        emit ShardBought(listingHash, expectedPrice);
    }

    function withdrawStudio() external onlyStudio {
        uint256 tmpBal = studioBalance;
        studioBalance = 0;
        boom.transfer(msg.sender, tmpBal);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Owner Pausable
/// @notice Handles logic to pause contracts as the owner
/// @author Hamza Karabag
abstract contract OwnerPausable is Ownable {
    bool internal paused;

    event ContractPause();
    event ContractResume();

    modifier onlyPaused() {
        require(paused, "Not paused");
        _;
    }

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPause();
    }

    function resumeContract() external onlyOwner {
        paused = false;
        emit ContractResume();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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