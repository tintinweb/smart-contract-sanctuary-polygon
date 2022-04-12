/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/interfaces/Planet-Universe-Interface-Training.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfaceTraining {
function addAlienToTrainAsFarmer(address account, uint16 tokenId) external;
function addAlienToTrainAsResearch(address account, uint16 tokenId) external;
function addAlienToTrainAsCarbon(address account, uint16 tokenId) external;
function addAlienToTrainAsEnergy(address account, uint16 tokenId) external;
function addAlienToTrainAsWater(address account, uint16 tokenId) external;
}
// File: contracts/interfaces/Planet-Universe-Interface-PWATER.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfacePWATER {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function balanceOf(address account) external returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
// File: contracts/interfaces/Planet-Universe-Interface-PFOOD.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfacePFOOD {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function balanceOf(address account) external returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
// File: contracts/interfaces/Planet-Universe-Interface-PDUST.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfacePDUST {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function balanceOf(address account) external returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
   
}
// File: contracts/interfaces/Planet-Universe-Interface-PFOODHarvest.sol



pragma solidity ^0.8.0;

interface PlanetUniverseInterfacePFOODHarvest {
function addAlienToHarvestAndEarn(address account, uint16[] calldata tokenIds) external;
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

// File: contracts/interfaces/Planet-Universe-Interface-GAMEPASS.sol



pragma solidity ^0.8.0;


interface PlanetUniverseInterfaceGAMEPASS is IERC721Enumerable {
// Struct for gamedata
  struct PlanetUniverseGamepass {
        uint16 tokenId;
        uint8 rarity;
        uint256 buildingTime;
        bool isGamepassRegistered;
        address gamepassOwner;
  }

    struct RegisteredGamepass {
        uint16 tokenId;
        address gamepassOwner;
  }

// struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string svg;
  }

    function mint(uint256 _mintAmount) external payable;
    function getMaxSupplyTotal() external view returns (uint256);
    function getTotalMinted() external view returns (uint256);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function registerNewGamepass(uint16 tokenId) external returns (PlanetUniverseGamepass memory p);
    function unregisterGamepass(uint16 tokenId) external returns (PlanetUniverseGamepass memory p);
    function checkGamePass (address owner) external view returns (bool checkgamepass);
    function whatIsTheRegisteredBuildingTime(address gamepassOwner) external view returns (uint256);
}
// File: contracts/interfaces/Planet-Universe-Interface-Gen2Alien.sol



pragma solidity ^0.8.0;


interface PlanetUniverseInterfaceGen2Alien is IERC721Enumerable {

  struct AlienGen2 {
        uint8[17] traitarray;
        uint8 generation;
        uint8 farmerWorkSpeed;
        uint8 carbonWorkSpeed;
        uint8 energyWorkSpeed;
        uint8 researchWorkSpeed;
        uint8 waterWorkSpeed;
        uint8 builderWorkSpeed;
    }

    function mint(address recipient, uint256 seed) external;
    function getTokenTraits(uint256 tokenId) external view returns (AlienGen2 memory);
    function makeFarmer(uint256 tokenId) external;
    function makeWater(uint256 tokenId) external;
    function makeCarbon(uint256 tokenId) external;
    function makeEnergy(uint256 tokenId) external;
    function makeResearch(uint256 tokenId) external;
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
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

// File: contracts/Planet-Universe-PFOODHarvest.sol


// PFOOD Harvesting contract
// Gen2 Aliens Can harvest
// Gen0/1 Aliens can tax by rank
// Pay 2 Food 2 Water cost per day, so also a per minute price that updates if you dont claim on 'whole' days
// Added the check that you need to have a gamepass registered and owned to stake :)
// TODO:: BUILDINGS :)

pragma solidity ^0.8.0;














contract FoodHarvest is PlanetUniverseInterfacePFOODHarvest, Ownable, ReentrancyGuard, Pausable, IERC721Receiver {
    
// Building block to store a Harvest, which contains [tokenId, value, owner]
  struct Harvest {
    uint16 tokenId;
    uint80 value;
    address owner;
    }

// Constants for this contract
  uint8 public constant MAX_RANK = 8; //RANK 5-8 for Aliens
  uint256 public constant WORKER_PERMINUTE_PFOOD_RATE = 0.0041667 ether; // Aliens Gen 2 Gather 0.0041667 PFOOD per minute
  uint256 public constant MINIMUM_TO_EXIT = 5 minutes; // Planets and Aliens must spend 1 days in the galaxy before they can be unstaked
  uint256 public constant MAXIMUM_GLOBAL_PFOOD = 600000000 ether; // The total of earnable $PFOOD earned through staking will be alot of chee$e
  uint256 public constant PDUSTCOSTTOSTAKE = 3 ether;
  uint256 public constant PFOODCOSTTOCLAIM = 0.001388 ether; //This is the cost per minute. 2 FOOD per day so 0.0013888
  uint256 public constant PWATERCOSTTOCLAIM = 0.001388 ether; //This is the cost per minute. 2 WATER per day so 0.0013888
  uint256 public constant ALIEN_CLAIM_TAX_PERCENTAGE = 20; // Aliens take a 20% tax on all $PFOOD claimed, divided by RANK 5-8 the Chee$e will be divided

// Private parts for this contract
  uint256 private totalRankStaked; // Total Rank of Aliens staked to show to the players how many aliens staked by rank
  uint256 private counterHarvestersStaked; // Total amount of Harvesters staked for the view for the website
  uint256 private lastClaimTimestamp; // The last timestamp $PDUST was claimed by anyone, also supplies us with protection against double claims, claims on top off claims etc
  uint256 private unaccountedRewards = 0; // Internal private for when the game launches there will be a small period when the claims (tax) wont be claimed because aliens are not staked yet
  uint256 private pfoodPerRank = 0; // amount of $PFOOD is put aside for each rank of alien staked, based on their rank

// Events
  event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
  event HarvesterClaimedPFOOD(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
  event AlienGen01ClaimedPFOOD(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);

  constructor()  {
  }

// Reference to Planet Universe NFT collection part of the CORE CONFIG immutables
PlanetUniverseInterface public PlanetUniverseNFT;
// Reference to Planet Dust Interface part of the CORE CONFIG immutables
PlanetUniverseInterfacePDUST public pdust;
// Reference to Planet Universe NFT collection part of the CORE CONFIG immutables
PlanetUniverseInterfaceGAMEPASS public gamepass;
// Reference to Planet PFOOD Interface part of the CORE CONFIG immutables
PlanetUniverseInterfacePFOOD public pfood;
// Reference to Planet PWATER Interface part of the CORE CONFIG immutables
PlanetUniverseInterfacePWATER public pwater;
// Reference to Planet Universe Gen2 Eggs
PlanetUniverseInterfaceGen2Alien public gen2alien;

// Mappings
  mapping(uint256 => Harvest) private harvest; //Mapping a long string Stake to harvest
  mapping(uint256 => Harvest[]) private alienharvest; // Maps rank of the aliens to their alienharvest so we know how much tax they claim
  mapping(uint256 => uint256) private ufoLocation; // Maps the location of the alien UFO to know where they are in the galaxy for staking/stealing
  
// Some public variables for views/trackers
  uint256 public totalPFOODEarned; // The amount of $PDUST earned so far is used for a counter on the website

// Contract checking modifier to protect routes and to make them only run when the contracts have been set
  modifier requireContractsSet() {
      require(address(PlanetUniverseNFT) != address(0) && address(pdust) != address(0) && address(gamepass) != address(0) && address(pfood) != address(0) && address(gen2alien) != address(0) && address(pwater) != address(0)   
        , "Ratigan checks all the contracts...The contracts not set sir!");
      _;
  }

// Set the contracts so we can link these 
  function setContracts(address _nft, address _pdust, address _gamepass, address _gen2alien, address _pfood, address _pwater) external onlyOwner {
    PlanetUniverseNFT = PlanetUniverseInterface(_nft);
    pdust = PlanetUniverseInterfacePDUST(_pdust);
    gamepass = PlanetUniverseInterfaceGAMEPASS(_gamepass);
    pdust = PlanetUniverseInterfacePDUST(_pdust);
    gen2alien = PlanetUniverseInterfaceGen2Alien(_gen2alien);
    pfood = PlanetUniverseInterfacePFOOD(_pfood);
    pwater = PlanetUniverseInterfacePWATER(_pwater);
  }

// Adds Planets to the Galaxy*@param [account] the address of the staker * @param [tokenIds] the IDs of the Planet to stake
  function addAlienToHarvestAndEarn(address account, uint16[] calldata tokenIds) external override nonReentrant {
    require(tx.origin == msg.sender, "Ratigan says that only the game contract or the origin sender can call this to protect cheese"); //Might be able to clean game here??
    require(account == tx.origin, "account to sender mismatch");
    require(gamepass.checkGamePass(account) == true, "Ratigan checks you do not own a game pass or have not registered it!");
    require(pdust.balanceOf(msg.sender) > PDUSTCOSTTOSTAKE, "Ratigan checks your wallet of $PDUST, you dont have enuff Chee$e sir/madam!" ); //Check balance to stop the vermin!
    for (uint i = 0; i < tokenIds.length; i++) {
      if(PlanetUniverseNFT.isAlienToken(tokenIds[i])) {
        require(PlanetUniverseNFT.ownerOf(tokenIds[i]) == msg.sender || gen2alien.ownerOf(tokenIds[i]) == msg.sender, "Ratigan checks your pocket, sir/madam you don't own this token"); //Check if the holder either holds a gen0/1 alien or gen2 harvester 
        PlanetUniverseNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
      else {
        gen2alien.transferFrom(msg.sender, address(this), tokenIds[i]);
      }
        if (PlanetUniverseNFT.isAlienToken(tokenIds[i])){ 
          _addAlienGen01ToHarvest(account, tokenIds[i]);
          pdust.burn(msg.sender , PDUSTCOSTTOSTAKE); // Pay 3 PDUST to stake
        }
        else 
          _addGen2AlienToHarvest(account, tokenIds[i]);
          pdust.burn(msg.sender , PDUSTCOSTTOSTAKE); // Pay 3 PDUST to stake
  }
}
// Sends a single planet to the galaxy, @param [account] the wallet address of the staker, @param [tokenId] the ID of NFT to send to the galaxy
  function _addGen2AlienToHarvest(address account, uint256 tokenId) internal requireContractsSet _updateEarnings {
    harvest[tokenId] = Harvest({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    counterHarvestersStaked += 1;
    emit TokenStaked(account, tokenId, block.timestamp);
  }

// Adds a single Alien to the UFO * @param [account] the address of the staker @param [tokenId] the ID of the Alien to add to the FlighUFO
  function _addAlienGen01ToHarvest(address account, uint256 tokenId) internal {
    uint8 rank = _rankForAlien(tokenId);
    totalRankStaked += rank; // Portion of earnings ranges from 8 to 5
    ufoLocation[tokenId] = alienharvest[rank].length; // Store the location of the dragon in the Flight
    alienharvest[rank].push(Harvest({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(pfoodPerRank)
    })); // Add the dragon to the Flight
    emit TokenStaked(account, tokenId, pfoodPerRank);
  }

// Calculations

// Calculation view for website and to start the claim
  function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
    uint64 lastTokenWrite = PlanetUniverseNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin protection and vermin
    require(lastTokenWrite < block.number, "Ratigan suspects vermin trying to steal chee$e in the same block!");
    Harvest memory stake = harvest[tokenId];
    if(gen2alien.ownerOf(tokenId) == msg.sender) {
      if (totalPFOODEarned < MAXIMUM_GLOBAL_PFOOD) {
        owed = (block.timestamp - stake.value) * WORKER_PERMINUTE_PFOOD_RATE;
      } else if (stake.value > lastClaimTimestamp) {
        owed = 0; // $PFOOD production stopped already
      } else {
        owed = (lastClaimTimestamp - stake.value) * WORKER_PERMINUTE_PFOOD_RATE; // stop earning additional $PDUST if it's all been earned
      }
    }
    else {
      uint8 rank = _rankForAlien(tokenId);
      owed = (rank) * (pfoodPerRank - stake.value); // Calculate portion of tokens based on Rank of the Alien
    }
  }

// Starting the claim $PFOOD
  function claimFromHarvest(uint16[] calldata tokenId, bool unstake) external _updateEarnings nonReentrant {
    require(tx.origin == msg.sender, "Ratigan says that only the game contract or the origin sender can call this to protect cheese"); //Might be able to clean game here??
    for (uint i = 0; i < tokenId.length; i++){
    Harvest memory stake = getHarvest(tokenId[i]);
    require((block.timestamp - stake.value) > MINIMUM_TO_EXIT, "Sorry you cannot claim you need to be harvesting for a minimum of 1 day");
    require((pfood.balanceOf(msg.sender) > ((block.timestamp - stake.value) * PFOODCOSTTOCLAIM)), "Ratigan checks your wallet of $PFOOD, you dont have enuff Chee$e sir/madam!" ); //Check balance to stop the vermin!
    require((pwater.balanceOf(msg.sender) > ((block.timestamp - stake.value) * PWATERCOSTTOCLAIM)), "Ratigan checks your wallet of $PWATER, you dont have enuff Chee$e sir/madam!" ); //Check balance to stop the vermin!
    uint256 owed = 0;
    if (gen2alien.ownerOf(tokenId[i]) == msg.sender) {
        owed += _claimGen2Harvest(tokenId[i], unstake);
      }
      else {
        owed += _claimGen01FromHarvest(tokenId[i], unstake);
      }
    
    pfood.updateOriginAccess();
    if (owed == 0) {
      return;
    }
    pwater.burn(msg.sender, ((block.timestamp - stake.value) * PWATERCOSTTOCLAIM));
    pfood.mint(msg.sender, owed);
    pfood.burn(msg.sender, ((block.timestamp - stake.value) * PFOODCOSTTOCLAIM));
  }
}
// Claiming, calculating and unstaking
// Claim Planets by param [tokenId or id's] decide wether they want to unstake yes or no @param [unstake]
  function _claimGen2Harvest(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Harvest memory stake = harvest[tokenId];
    require(stake.owner == msg.sender, "Ratigan checks your pocket, sir/madam you don't own this token");
    uint256 startseed = 0;
    uint256 workerspeed = gen2alien.getTokenTraits(tokenId).farmerWorkSpeed;
    if (totalPFOODEarned < MAXIMUM_GLOBAL_PFOOD) {
      owed = ((block.timestamp - stake.value) / 100) * WORKER_PERMINUTE_PFOOD_RATE * workerspeed;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // $PFOOD has been distributed
    } else {
      owed = (lastClaimTimestamp - stake.value) * WORKER_PERMINUTE_PFOOD_RATE; // Stop earning additional $PFOOD if it's all been earned
    }
    if (unstake) {
      startseed = randomseed();
      if (random(startseed) & 1 == 1) { // 50% chance of all $PFOOD is stolen when unstaking, thats the risk sir!
        _payAlienTax(owed);
        owed = 0;
      }
      delete harvest[tokenId];
      counterHarvestersStaked -= 1;
  // Always transfer last to guard against reentrance
      gen2alien.safeTransferFrom(address(this), msg.sender, tokenId, "Ratigan says, here you are sir"); // Send back gen2 Alien to owner
    } else {
      _payAlienTax(owed * ALIEN_CLAIM_TAX_PERCENTAGE / 100); // % of PDUST to Aliens
      owed = owed * (100 - ALIEN_CLAIM_TAX_PERCENTAGE) / 100; // % remainder goes to Planet owner
      harvest[tokenId] = Harvest({
        owner: msg.sender,
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake to start at 0 since there was a claim
    }
    emit HarvesterClaimedPFOOD(tokenId, unstake, owed);
  }

// Claim Aliens by param [tokenId or id's] decide wether they want to unstake yes or no @param [unstake]
  function _claimGen01FromHarvest(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    require(PlanetUniverseNFT.ownerOf(tokenId) == address(this), "Ratigan checks your pocket, sir/madam you don't own this token");
    uint8 rank = _rankForAlien(tokenId);
    Harvest memory stake = alienharvest[rank][ufoLocation[tokenId]];
    require(stake.owner == msg.sender, "Ratigan checks your pocket, sir/madam you don't own this token");
    owed = (rank) * (pfoodPerRank - stake.value); // Calculate portion of tokens based on Rank
    if (unstake) {
      totalRankStaked -= rank; // Remove rank from total staked to start on position 1 in the UFO galaxy
      Harvest memory lastStake = alienharvest[rank][alienharvest[rank].length - 1];
      alienharvest[rank][ufoLocation[tokenId]] = lastStake; // Shuffle last Alien to current position
      ufoLocation[lastStake.tokenId] = ufoLocation[tokenId];
      alienharvest[rank].pop(); // Remove duplicate from the same population of UFO's in flight
      delete ufoLocation[tokenId]; // Delete old mapping of previous locations, Always remove last to guard against reentrance or from the claim. Protected 2 ways... one by the claim one by the UFO position-/delete
      PlanetUniverseNFT.safeTransferFrom(address(this), msg.sender, tokenId, "Ratigan says Here is your alien back, Sir"); // Send back Alien to its rightfull owner
    } else {
      alienharvest[rank][ufoLocation[tokenId]] = Harvest({
        owner: msg.sender,
        tokenId: uint16(tokenId),
        value: uint80(pfoodPerRank)
      }); // Reset the stake back to 0. 
    }
    emit AlienGen01ClaimedPFOOD(tokenId, unstake, owed);
  }

// Calculations
// * add $PDUST to claimable pot for the UFO taxers * @param [amount] $PDUST to add to the pot
  function _payAlienTax(uint256 amount) internal {
    if (totalRankStaked == 0) { // if there's no staked Aliens
      unaccountedRewards += amount; // keep track of $PDUST due for Aliens
      return;
    }
    // makes sure to include any unaccounted $PDUST for when the game is launched! <3 WnD
    pfoodPerRank += (amount + unaccountedRewards) / totalRankStaked;
    unaccountedRewards = 0;
  }

// Update the earnings actively
  modifier _updateEarnings() {
    if (totalPFOODEarned < MAXIMUM_GLOBAL_PFOOD) {
      totalPFOODEarned += 
        (block.timestamp - lastClaimTimestamp) * counterHarvestersStaked * WORKER_PERMINUTE_PFOOD_RATE; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

// Checking rank of an Alien * gets the rank score of an alien * @param [tokenId] the ID of the Alien to get the rank score for * @return the rank score of the Dragon (5-8) but its by index so 0-3
  function _rankForAlien(uint256 tokenId) internal view returns (uint8) {
    PlanetUniverseInterface.PlanetAlien memory s = PlanetUniverseNFT.getTokenTraits(tokenId);
    return MAX_RANK - s.rankIndex; // rank index is 0-3
  }

// Randomness. During testing we saw that it is best not to make a generic randomized option, in case of integrity of the chain. Also make them seperate for better security
// Could have programmed this into 1 Randomizer interface, but I felt it was stricter to use internal private views

// Randomness fuctionality 
// Random function to get a seed to create a nice number feed by [first generation seed]
  function random(uint256 seed) public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed
    )));
  }

// Get the values of a harvest
    function getHarvest(uint256 tokenId) internal view returns (Harvest memory) {
        return harvest[tokenId];
  }


// To generate a first iteration seed
  function randomseed() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
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