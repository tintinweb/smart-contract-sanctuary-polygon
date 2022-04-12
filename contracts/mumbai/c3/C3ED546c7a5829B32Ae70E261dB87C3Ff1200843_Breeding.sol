/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/interfaces/Planet-Universe-Interface-PDUST.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfacePDUST {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function balanceOf(address account) external returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
}
// File: contracts/interfaces/Planet-Universe-Interface-Breeding.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfaceBreeding {
function addLoveCoupleToBreed(address account, uint16 momTokenId, uint16 dadTokenId ) external;
function getMaximumggs() external returns (uint256);
}
// File: contracts/interfaces/Planet-UniverseGame-Interface.sol



pragma solidity ^0.8.0;

interface PlanetUniverseGameInterface {

}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/interfaces/Planet-Universe-Interface-Gen2Egg.sol



pragma solidity ^0.8.0;


interface PlanetUniverseInterfaceGen2Egg is IERC721Enumerable {

// struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string svg;
  }

    function mint(uint256 _mintAmount, address recipient) external;
    function getTotalMinted() external view returns (uint256);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function burn(uint256 tokenId) external;
}
// File: contracts/interfaces/Planet-Universe-Interface.sol



pragma solidity ^0.8.0;


interface PlanetUniverseInterface is IERC721Enumerable {

  struct PlanetAlien {
        bool isPlanet;
        uint8[17] traitarray;
        uint8 rankIndex;
        uint8 breedingAmount;
        uint8 generation;
        uint8 buildingPlots;
    }

    function mint(address recipient, uint256 seed) external;
    function totalMinted() external returns (uint16);
    function getMaxSupplyTotal() external view returns (uint256);
    function getMaxPlanetSupplyGen0() external view returns (uint256);
    function getMaxPlanetSupplyPresaleGen0() external view returns (uint256);
    function getMaxPlanetSupplyEarlyAdopterSaleGen0() external view returns (uint256);
    function getMaxPreSaleMintAmount() external view returns (uint256);
    function getMaxEarlyAdopterSaleMintAmount() external view returns (uint256);
    function getTotalPresaleMints() external view returns (uint256);
    function getTotalEarlyAdopterSaleMints() external view returns (uint256);
    function getTotalSaleMints() external view returns (uint256);
    function getTotalMinted() external view returns (uint256);
    function getContractPresale() external view returns (bool);
    function getContractEarlyAdopterSale() external view returns (bool);
    function getContractSale() external view returns (bool);
    function getAddressMintedPreSaleBalance(address _key) external view returns (uint256);
    function getAddressMintedEarlyAdopterSaleBalance(address _key) external view returns (uint256);
    function getAddressMintedSaleBalance(address _key) external view returns (uint256);
    function setAddressMintedPreSaleBalance(address recipient) external;
    function setAddressMintedEarlyAdopterSaleBalance(address recipient) external;
    function setAddressMintedSaleBalance(address recipient) external;
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function setTotalPresaleMints() external;
    function setTotalEarlyAdopterSaleMints() external;
    function setTotalSaleMints() external;
    function setCounterGen0MintedTotal() external;
    function setCounterGen1MintedTotal() external;
    function isWhitelisted(address _user) external view returns (bool);
    function isEarlyAdopter(address _user) external view returns (bool);
    function getTokenTraits(uint256 tokenId) external view returns (PlanetAlien memory);
    function isPlanet(uint256 tokenId) external view returns(bool);
    function isAlien(uint256 tokenId) external view returns(bool);
    function lowerBreedingAmount(uint256 tokenId) external;
    function whatisBreedingAmount(uint256 tokenId) external view returns(uint8);
    function isAlienToken(uint256 tokenId) external view returns (bool istokenalien);
}



// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Planet-Universe-Breeding.sol


// Breeding contracty depends on pdust nft and game contract
// Breed contract done! What is working:
// Breeding
// Checking the parents
// Counter on the number of breeds
// Saving the parents by breed id on the address but also by a breed id so that we can check em later
// Saving when claiming the cooldown on the token of the parent so that they cant breed more until cooldown is done.
// After breeding parents get returned to the original owner
// Deleting the breed struct on the blockchain when egg is claimed
// TODO: MAKE MINT Contract Gen2 Egg
// TODO: MAKE the claim egg actually claim the mint in the above contract
// TODO:: After all of this start testing ! :)

pragma solidity ^0.8.0;










contract Breeding is PlanetUniverseInterfaceBreeding, Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
    
// Building block to store a Breed, which contains [tokenId, value, owner]
struct Breed {
  uint256 breedId;
  uint16 momTokenId;
  uint16 dadTokenId;
  uint80 breedStarted;
  address owner;
}

struct Resting{
  uint256 tokenId;
  address owner;
  uint80 cooldown;
}

struct LastWrite {
  uint64 time;
  uint64 blockNum;
}

// Constants for this contract
  uint256 public constant MINIMUM_TO_EXIT = 5 minutes; // Aliens must spend 1 day breeding
  uint256 public constant LABORCOOLDOWN = 3 days; // Aliens must spend 3 days resting before they can breed again after claiming of egg;
  uint256 public constant MAXIMUM_GEN2EGGS = 21312; // maximum amount of eggs available

// Public counter
  uint256 public numberofbreeds;

// Calculators
  uint256 public totalBreedingCost;

// Events
  event BreedingStarted(address indexed owner, uint256 indexed momTokendId, uint256 indexed dadTokendId, uint256 breedStarted);
  event EggGen2Claimed(uint256 indexed tokenId);

  constructor() {
  }

// Reference to Planet Universe NFT collection part of the CORE CONFIG immutables
PlanetUniverseInterface public PlanetUniverseNFT;
// Reference to Planet Dust Interface part of the CORE CONFIG immutables
PlanetUniverseInterfacePDUST public pdust;
// Reference to Planet Universe Gen2 Eggs
PlanetUniverseInterfaceGen2Egg public gen2egg;

// Mappings
  mapping(address => Breed) private loveshack; //Mapping an adress to breed
  mapping(uint256 => Breed) private breedinfo; //Mapping an breedid to breed
  mapping(uint256 => Resting) private laborcooldown; //Mapping a long string to plan the cooldown

// Some public variables for views/trackers
  uint256 public totalEggsGen2Created; // The amount of Eggs created by breeding

// Contract checking modifier to protect routes and to make them only run when the contracts have been set
  modifier requireContractsSet() {
      require(address(PlanetUniverseNFT) != address(0) && address(pdust) != address(0) 
        , "Ratigan checks all the contracts...The contracts not set sir!");
      _;
  }

// Set the contracts so we can link these 
  function setContracts(address _nft, address _pdust, address _gen2egg) external onlyOwner {
    PlanetUniverseNFT = PlanetUniverseInterface(_nft);
    pdust = PlanetUniverseInterfacePDUST(_pdust);
    gen2egg = PlanetUniverseInterfaceGen2Egg(_gen2egg);
  }

// Cost to breed
  function costToBreed() public view returns (uint256 price) { 
    if (numberofbreeds >= 0) return 10000 ether;
    if (numberofbreeds >= 4445) return 20000 ether;
    if (numberofbreeds >= 8889) return 24000 ether;
    if (numberofbreeds >= 13333) return 36000 ether;
    if (numberofbreeds >= 17777) return 60000 ether; 
  }

// Adds aliens *@param [account] the address of the staker * @param [tokenIds] the IDs of the Planet to stake
  function addLoveCoupleToBreed(address account, uint16 momTokenId, uint16 dadTokenId ) external override nonReentrant {
    require(tx.origin == msg.sender, "Ratigan says that only the game contract or the origin sender can call this to protect cheese"); //Might be able to clean game here??
    require(PlanetUniverseNFT.ownerOf(momTokenId) == msg.sender, "Ratigan checks your pocket, sir/madam you don't own this token");
    require(PlanetUniverseNFT.ownerOf(dadTokenId) == msg.sender, "Ratigan checks your pocket, sir/madam you don't own this token");
    require(momTokenId != dadTokenId, "Sorry mom and dad cannot be the same tokenId");
    bool isMomAnAlien = PlanetUniverseNFT.isAlien(momTokenId);
    require(isMomAnAlien = true, "Sorry mom is not an alien you can only breed aliens!");
    bool isDadAnAlien = PlanetUniverseNFT.isAlien(dadTokenId);
    require(isDadAnAlien = true, "Sorry dad is not an alien you can only breed aliens!");
    uint8 breedingAmountMom = PlanetUniverseNFT.whatisBreedingAmount(momTokenId);
    uint8 breedingAmountDad = PlanetUniverseNFT.whatisBreedingAmount(dadTokenId);
    require(breedingAmountMom & breedingAmountDad >= 1, "Sorry it seems like you are out of breeding spots on one of the 2 tokens" ); // Only breed when there is 1 or more breeding amounts left
    require(account == tx.origin, "account to sender mismatch");
    require(onCooldown(momTokenId) == false, "Mom cant breed because he is on cooldown");
    require(onCooldown(dadTokenId) == false, "Dad cant breed because he is on cooldown");
    uint256 seed = random(momTokenId);
    totalBreedingCost = costToBreed();
    require(pdust.balanceOf(msg.sender) > totalBreedingCost, "Ratigan checks your wallet of $PDUST, you dont have enuff Chee$e sir/madam!" ); //Check balance to stop the vermin!
    PlanetUniverseNFT.transferFrom(msg.sender, address(this), momTokenId); //Transfer the token to the loveshack :)
    PlanetUniverseNFT.transferFrom(msg.sender, address(this), dadTokenId); //Transfer the token to the loveshack :)
    _addBreedingPairToLoveshack(account, momTokenId, dadTokenId, seed); // Create the Struct on the blockchain to store the breeding information
    PlanetUniverseNFT.lowerBreedingAmount(momTokenId); // Lower the breeding amount of the mom by -1 since we started breeding
    PlanetUniverseNFT.lowerBreedingAmount(dadTokenId); // Lower the breeding amount of the dad by -1 since we started breeding
    pdust.burn(msg.sender , totalBreedingCost);
  }

// Sends a breeding pair to the loveshack, @param [account] the wallet address of the staker, @param [momtokenId] [dadtokenId] the ID of NFT to send to the loveshack (mapping to the account owner)
  function _addBreedingPairToLoveshack(address account, uint16 momTokenId, uint16 dadTokenId, uint256 seed) internal requireContractsSet{
    loveshack[account] = Breed({
      breedId: seed,
      owner: account,
      momTokenId: momTokenId,
      dadTokenId: dadTokenId,
      breedStarted: uint80(block.timestamp)
    });
    breedinfo[seed] = Breed({
      breedId: seed,
      owner: account,
      momTokenId: momTokenId,
      dadTokenId: dadTokenId,
      breedStarted: uint80(block.timestamp)
    });
    addOneBreedToTotal();
    emit BreedingStarted(account, momTokenId, dadTokenId, loveshack[account].breedStarted);
  }

// Calculations
// Calculation view for website and to start the claim for a Gen2 Egg :) just for testing public 
  function calculateBreedingTimeLeft(uint256 breedId) public view returns (bool readytoclaimegg) {
    Breed memory breed = breedinfo[breedId];
    require((block.timestamp - breed.breedStarted) > MINIMUM_TO_EXIT, "Sorry you cannot claim your Gen2 egg yet minimum of 1 days inside the loveshack");
    if((block.timestamp - breed.breedStarted) > MINIMUM_TO_EXIT) // Iff the current block timestamp is 1 day larger then when the breed started it is ready to claim!
    {
      return true;
    }
    else
    {
      return false;
  }
}

// Starting the egg claim and placing a cooldown
  function claimEgg(uint256 breedId) public nonReentrant {
    require(tx.origin == msg.sender, "Ratigan says that only the game contract or the origin sender can call this to protect cheese"); 
    require(calculateBreedingTimeLeft(breedId) == true, "You need a little longer breeding time....!");
    address recipient = msg.sender;
    Breed memory p = getBreedInfoByBreedId(breedId);
      laborcooldown[p.momTokenId] = Resting({
      tokenId: p.momTokenId,
      owner: msg.sender,
      cooldown: uint80(block.timestamp)
    });
      laborcooldown[p.dadTokenId] = Resting({
      tokenId: p.dadTokenId,
      owner: msg.sender,
      cooldown: uint80(block.timestamp)
    });
    PlanetUniverseNFT.safeTransferFrom(address(this), msg.sender, p.momTokenId, "Ratigan says, here you are sir"); // Send back mom to the owner after breeding
    PlanetUniverseNFT.safeTransferFrom(address(this), msg.sender, p.dadTokenId, "Ratigan says, here you are sir"); // Send back dad to the owner after breeding
    delete breedinfo[breedId]; // Once done delete the breeding
    gen2egg.mint(1, recipient);
  }

// Adding a breed to the counter so that we can check if number of breeds = less than the MAXIMUM_GEN2EGGS
  function addOneBreedToTotal() internal {
    numberofbreeds++;
  }

// Temp Public
  function getBreedInfoByBreedId(uint256 breedId) public view returns (Breed memory) {
    return breedinfo[breedId];
  }

  function getBreedInfobyAccount(address account) public view returns (Breed memory) {
    return loveshack[account];
  }

// external
  function getMaximumggs() external pure override returns (uint256) {
    return MAXIMUM_GEN2EGGS;
  }

  function onCooldown(uint256 tokenId) internal view returns (bool) {
    Resting memory labor = laborcooldown[tokenId];
    if (block.timestamp - labor.cooldown > LABORCOOLDOWN){ //If the timestamp of blockchain is higher after subctracting when breed was started, then the LABORCOOLDOWN the alien can breed again!
    return false; // False means the tokenId (alien) can breed again!
    }
    else
    {
    return true; // True means the tokenId (alien) has to wait longer to breed again!
  }
}

  function isTokenOnCooldown(uint256 tokenId) public view returns (bool) {
    Resting memory labor = laborcooldown[tokenId];
    if ((block.timestamp - labor.cooldown) > LABORCOOLDOWN){ //If the timestamp of blockchain is higher after subctracting when breed was started, then the LABORCOOLDOWN the alien can breed again!
    return false; // False means the tokenId (alien) can breed again!
    }
    else
    {
    return true; // True means the tokenId (alien) has to wait longer to breed again!
  }
}
// Random Part 1
// To generate a first iteration seed
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send to Tower directly");
      return IERC721Receiver.onERC721Received.selector;
    }
}