/**
 *Submitted for verification at polygonscan.com on 2022-03-31
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/RecipeHandler.sol


pragma solidity ^0.8.10;





/**
  @title Recipe Handler

  Handles batch transfers (recipes) specified by the owner.
  This way we can ensure each recipe happens atomatically (All or nothing)

  @author Hamza Karabag
*/
contract RecipeHandler is Ownable {
  IERC20    public bgem;
  IERC20    public boom;
  IERC721   public hunters;
  IERC1155  public perks;
  IERC1155  public shards;
  IERC1155  public equipments;
  address   private studio;

  event UpgradeSuccess(); 


//  ██████ ███    ██ ███████ ████████  ██████  ██████  
// ██      ████   ██ ██         ██    ██    ██ ██   ██ 
// ██      ██ ██  ██ ███████    ██    ██    ██ ██████  
// ██      ██  ██ ██      ██    ██    ██    ██ ██   ██ 
//  ██████ ██   ████ ███████    ██     ██████  ██   ██ 


  constructor(
    address   initStudio,
    IERC20    initBgem,
    IERC20    initBoom,
    IERC721   initHunters,
    IERC1155  initPerks,
    IERC1155  initShards,
    IERC1155  initEquipments
  ) {
    studio      = initStudio;
    bgem        = initBgem;
    boom        = initBoom;
    hunters     = initHunters;
    perks       = initPerks;
    shards      = initShards;
    equipments  = initEquipments; 
  }


// ███████ ███████ ████████ ████████ ███████ ██████  ███████ 
// ██      ██         ██       ██    ██      ██   ██ ██      
// ███████ █████      ██       ██    █████   ██████  ███████ 
//      ██ ██         ██       ██    ██      ██   ██      ██ 
// ███████ ███████    ██       ██    ███████ ██   ██ ███████ 
             
                                                          
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


// ██████  ███████  ██████ ██ ██████  ███████ ███████ 
// ██   ██ ██      ██      ██ ██   ██ ██      ██      
// ██████  █████   ██      ██ ██████  █████   ███████ 
// ██   ██ ██      ██      ██ ██      ██           ██ 
// ██   ██ ███████  ██████ ██ ██      ███████ ███████ 
                                                   
                                                                                  
  /**
    @notice Takes BGem from user and gives 1155 tokens to the user

    @param user       address
    @param inBgem     uint256     Amount of BGem user pays
    @param outBgem    uint256     Amount of BGem user will get
    @param outHunters uint256[ ]  List of Hunter IDs studio gives
    @param outSizes   uint256[3]  *
    @param outIds     uint256[ ]  *
    @param outAmts    uint256[ ]  *

    *: In order to make arbitrary transfers possible we had to pack ids and 
    amounts of the perks, shards and equipments to one array.

    For example if studio returns look like this:
    
            IDS:            AMOUNTS:
    PERKS:  [1, 3, 5]        [100, 200, 300]
    SHARDS: [2, 4, 5, 12]    [500, 600, 700, 800]
    EQPTS:  [1, 2]           [1, 2]

    We have to pack all ids and amount to separate arrays and specify sizes of
    each return type, resulting with

    outSizes: [3, 4, 2]
    outIds:   [1, 3, 5, 2, 4, 5, 12, 1, 2]
    outAmts:  [100, 200, 300, 500, 600, 700, 800, 1, 2]
  */
  function openChest(
    address user,
    uint256 inBgem,
    uint256 outBgem,
    uint256[ ] calldata outHunters,
    uint256[3] calldata outSizes,
    uint256[ ] calldata outIds,
    uint256[ ] calldata outAmts
  ) external onlyOwner {

    // IN  - BGems
    if(inBgem > outBgem) {
      bgem.transferFrom(user, studio, inBgem - outBgem);
    }
    else if (outBgem > inBgem) {
      bgem.transferFrom(user, studio, outBgem - inBgem);
    }

    // OUT - Hunters
    for (uint256 i = 0; i < outHunters.length; ++i) {
      hunters.transferFrom(studio, user, outHunters[i]);
    }

    // OUT - Perks, Shards & Equipments
    uint256 sizeCtr = 0;
    for (uint256 i = 0; i < 3; ++i) {
      
      uint256 nextSize = sizeCtr + outSizes[i];
      for (; sizeCtr < nextSize; ++sizeCtr) {
        if(i == 0) {
          perks.safeTransferFrom(
            studio,
            user,
            outIds[sizeCtr],
            outAmts[sizeCtr], "");
        }
        else if(i == 1) {
          shards.safeTransferFrom(
            studio,
            user,
            outIds[sizeCtr],
            outAmts[sizeCtr], "");
        }
        else {
          equipments.safeTransferFrom(
            studio,
            user,
            outIds[sizeCtr],
            outAmts[sizeCtr], "");
        }
      }
    }
  }

  /**
    @notice Takes Boom and Shards from user
    @dev Emits {UpgradeSuccess}

    @param user         address
    @param inBoom       uint256
    @param inShardIds   uint256[]
    @param inShardAmts  uint256[]
  
    For example if user has to pay 100 BOOMs and 5 of SHARDs with ID 3, we'd call:
    upgrade(user, 100, [3], [5])
  */
  function upgrade(
    address user,
    uint256 inBoom,
    uint256[] calldata inShardIds,
    uint256[] calldata inShardAmts
  ) external onlyOwner {

    // IN - Booms
    boom.transferFrom(user, studio, inBoom);

    // IN - Shards
    for (uint256 i = 0; i < inShardIds.length; ++i) {
      shards.safeTransferFrom(
        user, 
        studio, 
        inShardIds[i], 
        inShardAmts[i], "");
    }

    emit UpgradeSuccess();
  }

  /**
    @notice Takes Boom and Equipments from user and gives 721 Hunters
  
    @param user             address
    @param inBoom           uint256
    @param inEquipmentIds   uint256[]
    @param inEquipmentAmts  uint256[]
    @param outHunterIds     uint256[]

    For example, if user has to pay 100 BOOMs and 5 of SHARDs with ID 3 and 
    receives HUNTER with ID 12, we'd call:
    summon(user, 100, [3], [5], [12])
  */
  function summon(
    address user,
    uint256 inBoom,
    uint256[] calldata inEquipmentIds,
    uint256[] calldata inEquipmentAmts,
    uint256[] calldata outHunterIds
  ) external onlyOwner {

    // IN - Booms
    boom.transferFrom(user, studio, inBoom);

    // IN - Equipments
    for (uint256 i = 0; i < inEquipmentIds.length; ++i) {
      equipments.safeTransferFrom(
        user, 
        studio, 
        inEquipmentIds[i], 
        inEquipmentAmts[i], "");
    }

    // OUT - Hunters
    for (uint256 i = 0; i < outHunterIds.length; ++i) {
      hunters.transferFrom(studio, user, outHunterIds[i]);
    }
  }
}