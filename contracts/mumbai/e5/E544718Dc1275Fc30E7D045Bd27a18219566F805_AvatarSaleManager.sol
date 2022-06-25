// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/StringUtils.sol";
import "./interface/ERC721A.sol";
import "./interface/AvatarBasic.sol";
import "hardhat/console.sol";
/**************************************************
 * Avatar NFT
 *
 * Created for Pyre by: Patrick Kishi
 * Audited by: Jill
 * Special thanks goes to: Jill
 ***************************************************
 */

contract Avatar is ERC721A, AvatarBasic, Ownable, ReentrancyGuard {
    using Strings for uint256;
    struct AvatarDataType {
        bool isKeeper;
        string name;
        uint[7] ability;
    }
    
    //sum of initial states
    uint public initialSum = 35;
    uint8 public constant MIN_LEVEL = 1;
    uint8 public constant MAX_LEVEL = 10;
    
    // Minters
    mapping(address => bool) private minters;
    // Updaters
    mapping(address => bool) private updaters;

    mapping(uint => AvatarDataType) internal avatarInfo;
    
    // NFT Token Uris
    mapping(uint => string) internal _tokenUris;
    
    modifier onlyMinter() {
        require(minters[msg.sender], "Caller should be minter.");
        _;
    }
    modifier onlyUpdater() {
        require(updaters[msg.sender], "Caller should be updater.");
        _;
    }
    modifier onlyOperator() {
        require(minters[msg.sender] || updaters[msg.sender], "Caller should be either minter or updater.");
        _;
    }
   
    /**
        @param maxBatchSize_ Max size for ERC721A batch mint.
        @param collectionSize_ NFT collection size
    */
    constructor(
        uint16 maxBatchSize_,
        uint16 collectionSize_
    ) ERC721A("Pyre-Avatar", "Avatar", maxBatchSize_, collectionSize_) AvatarBasic() {
    }

    function mintNFT(
        address to,
        uint8 quantity,
        uint8[][] memory values,
        string[] memory metadataUris,
        string[] memory names
    )
        external
        nonReentrant
        onlyMinter
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        require(values.length == quantity, "No match array size.");
        require(names.length == quantity, "No match names size.");

        uint originalSupply = totalSupply();
        _safeMint(to, quantity);
        
        for (uint i = 0; i < quantity ; i ++) {
            require(getSum(values[i]) == initialSum, "Invalid state values.");
            setAvatarState(originalSupply + i, values[i]);
        }

        for (uint i = 0; i < quantity; i ++) {
            _tokenUris[originalSupply + i] = metadataUris[i];
        }

        for (uint i = 0; i < quantity; i ++) {
            updateName(originalSupply + i, names[i]);
        }
    }

    function getSum(uint8[] memory value) internal pure returns(uint sum) {
        sum = 0;
        for (uint i = 0; i < value.length; i ++) {
            sum += value[i];
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenUris[tokenId];
    }

    function isKeeper(uint tokenId) public view returns(bool) {
         require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        AvatarDataType memory data = avatarInfo[tokenId];

        return data.isKeeper;
    }

    function getKeepers(address sender) external view returns(uint[] memory) {
        console.log('keepers: ');
        uint balance = balanceOf(sender);
        uint[] memory _keepers = new uint[](balance);
        uint index = 0;
        for (uint i = 0; i < balance; i ++) {
            uint tokenId = tokenOfOwnerByIndex(sender, i);
            if (isKeeper(tokenId)) {
                _keepers[index] = tokenId;
                index ++;
            }
        }

        return _keepers;
    }

    // Advance human to keeper
    function upgradeToKeeper(uint tokenId) public onlyUpdater {
        require(!isKeeper(tokenId), "Already upgraded to Keeper.");

        AvatarDataType storage data = avatarInfo[tokenId];
        data.isKeeper = true;
    }

    function setAvatarState(uint _tokenId, uint8[] memory value) public onlyOperator {
        require(_exists(_tokenId), "Not exist NFT.");

        AvatarDataType storage data = avatarInfo[_tokenId];
        for (uint i = 0; i < value.length ; i ++) {
            require(value[i] >= MIN_LEVEL && value[i] <= MAX_LEVEL, "Invalid stat value");
            data.ability[i] = value[i];
        }
    }

    function setSingleAvatarState(uint _tokenId, Stat key, uint value) public onlyUpdater {
        require(_exists(_tokenId), "Not exist NFT.");
        require(value >= MIN_LEVEL && value <= MAX_LEVEL, "Invalid value.");

        AvatarDataType storage data = avatarInfo[_tokenId];
        uint[7] storage ability = data.ability;

        ability[uint(key)] = value;
    }

    function upgradeState(uint _tokenId, Stat key, uint delta ) public onlyUpdater {
        require(_exists(_tokenId), "Not exist NFT.");

        AvatarDataType storage data = avatarInfo[_tokenId];
        uint[7] storage ability = data.ability;

        uint value = ability[uint(key)] + delta;
        require(value >= MIN_LEVEL && value <= MAX_LEVEL, "Invalid value.");

        ability[uint(key)] = value;
        
    }

    function updateName(uint _tokenId, string memory name) public onlyOperator {
        require(_exists(_tokenId), "Not exists token");
        AvatarDataType storage data = avatarInfo[_tokenId];
        data.name = name;
    }

    function getAvatar(uint _tokenId) public view returns (AvatarDataType memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return avatarInfo[_tokenId];
    }

    function getSingleState(uint _tokenId, Stat key) external view returns(uint) {
        require(_exists(_tokenId), "Not exist NFT.");
        AvatarDataType memory data = avatarInfo[_tokenId];

        return data.ability[uint(key)];
    }

    function setTokenUri(uint tokenId, string memory uri) external onlyUpdater {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        _tokenUris[tokenId] = uri;
    }

    // Admin actions
    function addMinter(address _address) external onlyOwner {
        require(!minters[_address], "Already minter.");
        minters[_address] = true;
    }

    function addUpdater(address _address) external onlyOwner {
        require(!updaters[_address], "Already updater.");
        updaters[_address] = true;
    }
    function removeMinter (address _address) external onlyOwner {
        require(minters[_address], "Already removed.");
        minters[_address] = false;
    }
    function removeupdater(address _address) external onlyOwner {
        require(updaters[_address], "Already removed.");
        updaters[_address] = false;
    }

    // utility functions
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
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

pragma solidity ^0.8.0;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) public pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) public pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

pragma solidity ^0.8.0;

contract AvatarBasic {
    
    enum Stat {
        Strength,
        Agility,
        Charisma,
        Knowledge,
        Intuition,
        Endurance,
        Magic
    }

    enum CustomizableTrait {
        Tops,
        Bottoms,
        Hairstyles,
        Tattoos,
        Shoes,
        Glasses
    }

    // Train types
    enum TrainType {
        Gym,
        Study,
        Obstacle,
        Socialise,
        MagicSchool
    }

    function indexToStat(uint index) internal pure returns(Stat) {
        require(index < 7, "Invalid stat index.");

        if (index == 0) {
            return Stat.Strength;
        } else if (index == 1) {
            return Stat.Agility;
        } else if (index == 2) {
            return Stat.Charisma;
        } else if (index == 3) {
            return Stat.Knowledge;
        } else if (index == 4) {
            return Stat.Intuition;
        } else if (index == 5) {
            return Stat.Endurance;
        } else {
            return Stat.Magic;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Dragon.sol";
import "./Avatar.sol";
import "hardhat/console.sol";

contract DragonSaleManager is Ownable {
    // sale signer
    address public signer;

    // Avatar NFT
    address public nftAddress;

    // nft price in ETH
    uint public priceInEth;

    // nft price in Token
    uint public priceInToken;

    // payment token
    IERC20 public paymentToken;

    // AvatarNFT address
    address public avatarNFTAddress;

    constructor(address _nftAddress, address _avatarAddress, IERC20 _token, address _signer) {
        nftAddress = _nftAddress;
        avatarNFTAddress = _avatarAddress;
        paymentToken = _token;
        signer = _signer;
    }

    // Mint NFT with ETH
    function mintNFT(
        uint8 quantity,
        bytes calldata signature,
        string[] memory names 
    ) external payable {
        require(verifySigner(signature, signer), "Invalid signature.");
        verifyIfHasKeeper(msg.sender);

        Dragon(nftAddress).mintNFT(msg.sender, quantity, names);
        refundIfOver(priceInEth * quantity);
    }

    // Mint NFT with Token
    function mintNFTWithToken(
        uint8 quantity,
        bytes calldata signature,
        string[] memory names
    ) external {
        require(verifySigner(signature, signer), "Invalid signature.");
        verifyIfHasKeeper(msg.sender);
        console.log('It has keeper');
        Dragon(nftAddress).mintNFT(msg.sender, quantity, names);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), quantity * priceInToken);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verifySigner(bytes calldata signature, address _signer) 
        public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }

    function verifyIfHasKeeper(address owner) internal view {
        uint[] memory keepers = Avatar(avatarNFTAddress).getKeepers(owner);
        require(keepers.length > 0, "You need to have keeper.");
    }

    // Admin action
    function setSigner (address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid signer.");
        signer = _signer;
    }

    function getSigner() external view returns(address) {
        return signer;
    }

    function setPaymentToken (IERC20 _token) external onlyOwner {
        paymentToken = _token;
    }

    function setPriceInEth(uint _priceInEth) external onlyOwner {
        priceInEth = _priceInEth;
    }

    function setPriceInToken (uint _priceInToken) external onlyOwner {
        priceInToken = _priceInToken;
    }

    function setNFTAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/ERC721A.sol";
import "./interface/DragonBasic.sol";
/**************************************************
 * Dragon NFT
 *
 * Created for Pyre by: Patrick Kishi
 * Audited by: Jill
 * Special thanks goes to: Jill
 ***************************************************
 */

contract Dragon is ERC721A, DragonBasic, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // Token URI. Token uri is different based on DragonType, Age and Gender
    string[2][3][5] private tokenUris;
    string[4] private eggUris;

    // Min & Max level
    uint8 public constant MIN_LEVEL = 1;
    uint8 public constant MAX_LEVEL = 10;

    // 
    uint public AdolescentAge = 2 days;
    uint public AdultAge = 5 days;

    // minters & updaters
    mapping(address => bool) private minters;
    mapping(address => bool) private updaters;

    // DragonData token ID => data
    mapping(uint => DragonData) private dragonInfo;

    modifier onlyMinter() {
        require(minters[msg.sender], "Caller is not minter.");
        _;
    }
    modifier onlyUpdater() {
        require(updaters[msg.sender], "Caller should be updater.");
        _;
    }
   
    /**
        @param maxBatchSize_ Max size for ERC721A batch mint.
        @param collectionSize_ NFT collection size
        @param _tokenUris Dragon metadata uris
        @param _eggUris egg metadata uris
    */
    constructor(
        uint16 maxBatchSize_,
        uint16 collectionSize_,
        string[2][3][5] memory _tokenUris,
        string[4] memory _eggUris,
        uint[2][7][4][5] memory _stateRanges
    ) ERC721A("Pyre-Dragon", "Dragon", maxBatchSize_, collectionSize_) DragonBasic(){
        tokenUris = _tokenUris;
        eggUris = _eggUris;
        stateRanges = _stateRanges;
    }

    function getSum(uint _tokenId) internal view returns(uint sum) {
        require(_exists(_tokenId), "Not exists token.");

        DragonData memory dragon = dragonInfo[_tokenId];
        sum = 0;
        for (uint i = 0 ; i < dragon.ability.length ; i ++) {
            sum += dragon.ability[i];
        }
    }

    function getAge(uint _tokenId) public view returns(Age) {
        require(_exists(_tokenId), "Not exist NFT.");
        DragonData memory dragon = dragonInfo[_tokenId];
        if (!dragon.isDragon) return Age.Egg;

        uint age = block.timestamp - dragon.birthday;
        if (age >= AdultAge) return Age.Adult;
        if (age >= AdolescentAge) return Age.Adolescent;
        return Age.Hatchling;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply())));
    }

    function setDragonIndividualAbility(uint _tokenId, Stat key, uint value) external onlyUpdater {
        require(_exists(_tokenId), "Not exist NFT.");

        Age age = getAge(_tokenId);

        require(value >= MIN_LEVEL && value <= ageLimitInfo[age], "Invalid value.");
        
        DragonData storage dragon = dragonInfo[_tokenId];
        uint[7] storage data = dragon.ability;
        data[uint(key)] = value;
    }

    function upgradeDragonStat(uint _tokenId, Stat key, uint delta) external onlyUpdater {
        require(_exists(_tokenId), "Not exist NFT.");
        require(isHatched(_tokenId), "Dragon should be hatched first.");

        DragonData storage data = dragonInfo[_tokenId];
        uint[7] storage ability = data.ability;

        uint value = ability[uint(key)] + delta;
        require(value >= MIN_LEVEL && value <= ageLimitInfo[getAge(_tokenId)], "Invalid value.");

        ability[uint(key)] = value;
    }

    function upgradeSpecialSkill(uint _tokenId) external onlyUpdater {
        require(_exists(_tokenId), "Not exists.");
        require(isHatched(_tokenId), "Dragon should be hatched first.");

        DragonData storage dragon = dragonInfo[_tokenId];
        require(dragon.rarity == RarityType.Rare || dragon.rarity == RarityType.Legendary, "Only Rare and Legendary can have special skill.");
        require(getAge(_tokenId) != Age.Adult, "Cannot upgrade special skill at Adult age.");
        require(dragon.specialPoint < 5, "You already reached to max.");
        dragon.specialPoint ++;
    }

    function hasSpecial(uint _tokenId) external view returns(bool) {
        require(_exists(_tokenId), "Not exists.");
        DragonData memory dragon = dragonInfo[_tokenId];
        return dragon.specialPoint == 5;
    }

    function generateRarity(uint randomNumber) internal pure returns(RarityType) {
        uint number = randomNumber % 100;
        if (number < 50) {
            return RarityType.Common;
        } else if (number >= 50 && number < 80) {
            return RarityType.Uncommon;
        } else if (number >= 80 && number < 95) {
            return RarityType.Rare;
        } else {
            return RarityType.Legendary;
        }
    }

    function generateDragonType(uint randomNumber) internal pure returns(DragonType) {
        uint number = randomNumber % 5;
        return indexToType(number);
    }

    function generateGender(uint randomNumber) internal pure returns(Gender) {
        return randomNumber % 1000 <= 995 ? Gender.MALE : Gender.FEMALE; 
    }

    function hatchEgg(uint tokenId) external onlyUpdater {
        require(!isHatched(tokenId), "Already hatched");

        DragonData storage dragon = dragonInfo[tokenId];
        
        dragon.isDragon = true;
        dragon.birthday = block.timestamp;
       
        for (uint i = 0; i < 7 ; i ++) {
            dragon.ability[i] = stateRanges[uint(dragon.species)][uint(dragon.rarity)][i][0];
        }
    }

    function isHatched(uint tokenId) public view returns(bool) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        DragonData memory dragon = dragonInfo[tokenId];
        return dragon.isDragon;
    }

    function getDragon(uint tokenId) public view returns(DragonData memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return dragonInfo[tokenId];
    }

    function getIndividualDragonState(uint _tokenId, Stat key) external view returns(uint) {
        require(_exists(_tokenId), "Not exist NFT.");

        DragonData memory dragon = dragonInfo[_tokenId];
        return dragon.ability[uint(key)];
    }

    function mintNFT(
        address to,
        uint8 quantity,
        string[] memory names
    )
        external
        nonReentrant
        onlyMinter
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        require(quantity == names.length, "Not match array size.");

        uint currentSupply = totalSupply();

        _safeMint(to, quantity);

        for (uint i = 0 ; i < quantity ; i ++) {
            uint randomNumber = random();

            DragonType dragonType = generateDragonType(randomNumber);
            Gender gender = generateGender(randomNumber); 
            RarityType rarity = generateRarity(randomNumber);

            DragonData storage dragon = dragonInfo[currentSupply + i];
            dragon.rarity = rarity;
            dragon.species = dragonType;
            dragon.gender = gender;
            dragon.name = names[i];
        }
    }

    function breeding(
        address to,
        uint fatherTokenId,
        uint motherTokenId
    )   
        external
        nonReentrant
        onlyMinter
    {
        require(_exists(fatherTokenId), "Not exists father.");
        require(_exists(motherTokenId), "Not exists mother.");

        uint rn = random();
        uint quantity = (rn % 100) == 99 ? 2 : 1; // 1% => 2, 99% => 1
        uint restAmount = collectionSize - totalSupply();
        require(restAmount > 0, "Exceeds Max Supply.");

        quantity = quantity > restAmount ? restAmount : quantity;
        uint currentSupply = totalSupply();

        _safeMint(to, quantity);

        DragonData memory father = dragonInfo[fatherTokenId];
        DragonData storage mother = dragonInfo[motherTokenId];

        for (uint i = 0 ; i < quantity ; i ++) {
            uint randomNumber = random();

            Gender gender = generateGender(randomNumber); 
            RarityType rarity = generateRarity(randomNumber);

            DragonData storage dragon = dragonInfo[currentSupply + i];
            dragon.rarity = rarity;
            dragon.species = randomNumber > 50 ? father.species : mother.species;
            dragon.gender = gender;
            dragon.father = fatherTokenId;
            dragon.mother = motherTokenId;
            dragon.name = "Breed";
        }
        mother.lastBreed = block.timestamp;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        DragonData memory dragon = dragonInfo[tokenId];

        if (!dragon.isDragon) {
            return eggUris[uint(dragon.rarity)];
        }

        return tokenUris[uint(dragon.species)][uint(getAge(tokenId))][uint(dragon.gender)];
    }
    function updateName(uint _tokenId, string memory name) external onlyUpdater {
        require(_exists(_tokenId), "Not exists token");
        DragonData storage dragon = dragonInfo[_tokenId];
        dragon.name = name;
    }

    // Admin actions
    function setTokenUris(string[2][3][5] memory _tokenUris) external onlyOwner {
        tokenUris = _tokenUris;
    }

    function setEggUris(string[4] memory _eggUris) external onlyOwner {
            eggUris = _eggUris;
    }
    
    function addMinter(address _address) external onlyOwner {
        require(!minters[_address], "Already minter.");
        minters[_address] = true;
    }
    function addUpdater(address _address) external onlyOwner {
        require(!updaters[_address], "Already updater.");
        updaters[_address] = true;
    }

    function removeMinter (address _address) external onlyOwner {
        require(minters[_address], "Already removed.");
        minters[_address] = false;
    }
    function removeupdater(address _address) external onlyOwner {
        require(updaters[_address], "Already removed.");
        updaters[_address] = false;
    }
    
    function setStatRange(DragonType dragonType, RarityType rarity, Stat stat, uint[2] memory value) external onlyOwner{
        require(value[1] <= MAX_LEVEL && value[0] >= MIN_LEVEL, "Invalid value");
        stateRanges[uint(dragonType)][uint(rarity)][uint(stat)] = value;
    }
    function setLimitStatForAge(Age age, uint value) external onlyOwner {
        require(value <= MAX_LEVEL, "Invalid value");
        ageLimitInfo[age] = value;
    }

    // utility functions
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function isExist(uint tokenId) external view returns(bool) {
        return _exists(tokenId);
    }
}

pragma solidity ^0.8.0;

contract DragonBasic {
    // Rarity. Common 50%, Uncommon 30%, Rare 15%, Legendary 5%
    enum RarityType {
        Common,
        Uncommon,
        Rare,
        Legendary
    }

    // Dragon Type: The same percent
    enum DragonType {
        Attack,
        Healer,
        Stealth,
        Rescue,
        Supply
    }

    // Male: 99.5%, Female: 0.5%
    enum Gender {
        MALE,
        FEMALE
    }

    // Age
    enum Age {
        Egg,
        Hatchling,
        Adolescent,
        Adult
    }

    // Stats
    enum Stat {
        Strength,
        FireDamage,
        Healing,
        Agility,
        Flight,
        Magic,
        Defense
    }

    // TrainTypes 
    enum TrainType {
        Feed,
        CastSpell,
        SpecialSkill,

        Study,
        Spar,
        Obstacle,
        
        Fight,
        Hunt,
        Rescue,
        Race
    }

    struct DragonData {
        RarityType rarity;
        DragonType species;
        Gender gender;
        uint birthday;
        bool isDragon;
        uint lastBreed;
        uint father;
        uint mother;
        string name;
        uint[7] ability;
        uint specialPoint; // increase to max 5. Should be developed before Adult age. 
    }

    // states limit per age
    mapping(Age => uint) internal ageLimitInfo; 

    // mapping(DragonType => mapping(RarityType => mapping(Stat => StateRange))) internal stateRanges;
    uint[2][7][4][5] stateRanges;

    constructor() {
        ageLimitInfo[Age.Egg] = 0;
        ageLimitInfo[Age.Hatchling] = 3;
        ageLimitInfo[Age.Adolescent] = 5;
        ageLimitInfo[Age.Adult] = 10;
    }

    function indexToStat(uint index) internal pure returns(Stat) {
        require(index < 7, "Invalid stat index.");

        if (index == 0) {
            return Stat.Strength;
        } else if (index == 1) {
            return Stat.FireDamage;
        } else if (index == 2) {
            return Stat.Healing;
        } else if (index == 3) {
            return Stat.Agility;
        } else if (index == 4) {
            return Stat.Flight;
        } else if (index == 5) {
            return Stat.Magic;
        } else {
            return Stat.Defense;
        }
    }

    function indexToType(uint index) internal pure returns(DragonType) {
        require(index < 5, "Invalid type index.");

        if (index == 0) {
            return DragonType.Attack;
        } else if (index == 1) {
            return DragonType.Healer;
        } else if (index == 2) {
            return DragonType.Stealth;
        } else if (index == 3) {
            return DragonType.Rescue;
        } else {
            return DragonType.Supply;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Dragon.sol";

contract DragonUpdateManager is Ownable, DragonBasic {
    struct PendingToDragon {
        address owner;
        uint startAt;
        bool pending;
    }

    struct PendingToUpgradeSpecial {
        address owner;
        uint startAt;
        bool pending;
    }

    struct PendingToUpgradeState {
        address owner;
        Stat[] stats;
        uint startAt;
        bool pending;
        uint fee;
        uint duration;
    }

    // sale signer
    address public signer;

    // Avatar NFT address
    address public dragonNFTAddress;

    // Pending to upgrade states.
    mapping(uint => PendingToUpgradeState) public pendingToUpgradeInfo;
    // duration for upgrading states;
    uint[9] public pendingDurationForState = 
        [ 1 days, 1 days, 1 days, 1 days, 1 days, 1 days, 2 days, 3 days, 4 days]; // level is between 1 and 10, so need 9 of duration values.
    // fee for upgrading states;
    uint[9] public feeForUpgradeState = [
        0, 0, 0, 0, 0, 0, 5 ether, 10 ether, 15 ether
    ];
    // duration for upgrading special skill
    uint[5] public pendingDurationForSpecialSkill = [
        1 days, 1 days, 1 days, 1 days, 2 days
    ]; // level 0 ~ 5
    uint[5] public feeForUpgradeSpecial = [
        0, 0, 0, 10 ether, 20 ether
    ]; // level 0 ~ 5

    // Pending to Dragon
    mapping(uint => PendingToDragon) pendingToDragonInfo;
    uint public durationForHatch = 3 days;

    uint8 public constant MIN_LEVEL = 1;
    uint8 public constant MAX_LEVEL = 10;

    // pending to upgrade special skill
    mapping(uint => PendingToUpgradeSpecial) pendingToUpgradeSpecial;

    constructor(address _dragonNFTAddress, address _signer, uint[2][7][4][5] memory _stateRanges) DragonBasic() {
        dragonNFTAddress = _dragonNFTAddress;
        signer = _signer;
        stateRanges = _stateRanges;
    }

    // Request for Egg => Dragon, Lock NFT to this contract.
    function requestHatchEgg(uint tokenId) external {
        require(Dragon(dragonNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token.");
        require(!Dragon(dragonNFTAddress).isHatched(tokenId), "Already dragon.");

        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), tokenId);

        PendingToDragon storage data = pendingToDragonInfo[tokenId];
        data.owner = msg.sender;
        data.pending = true;
        data.startAt = block.timestamp;
    }

    // Finalize to upgrade to Dragon.
    function hatchEgg(uint tokenId, bytes calldata signature) external {
        require(verifySigner(signature, signer), "Invalid Signature.");

        PendingToDragon storage data = pendingToDragonInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "Should be pending first.");
        require(block.timestamp >= data.startAt + durationForHatch, "Not available now.");

        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        Dragon(dragonNFTAddress).hatchEgg(tokenId);

        data.pending = false;
    }

    // Cancel upgrade
    function cancelHatchEgg(uint tokenId) external {
        PendingToDragon storage data = pendingToDragonInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You didn't request.");

        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        data.owner = address(0);
        data.pending = false;
        data.startAt = 0;
    }

    // Request upgrade state
    function requestUpgradeState(uint tokenId, Stat[] memory keys) public {
        require(Dragon(dragonNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token.");
        require(Dragon(dragonNFTAddress).isHatched(tokenId), "Dragon should be hatched first.");

        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];
        require(!data.pending, "Already requested.");
        
        DragonData memory dragon = Dragon(dragonNFTAddress).getDragon(tokenId);

        bool upgradable = false;
        uint duration = 0;
        uint fee = 0;
        uint index = 0;

        Stat[] memory stats = new Stat[](keys.length);
        for (uint i = 0; i < keys.length; i ++) {
            uint currentValue = Dragon(dragonNFTAddress).getIndividualDragonState(tokenId, keys[i]);
            Age age = Dragon(dragonNFTAddress).getAge(tokenId);

            uint[2] memory stateRange =  stateRanges[uint(dragon.species)][uint(dragon.rarity)][uint(keys[i])];

            if (currentValue < ageLimitInfo[age] && currentValue < stateRange[1]) {
                upgradable = true;
                duration += pendingDurationForState[currentValue - 1];
                fee += feeForUpgradeState[currentValue - 1];
                stats[index] = keys[i];
                index ++;
            }
        }
        require(upgradable, "No stat can be upgradable.");

        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), tokenId);
    
        data.owner = msg.sender;
        data.pending = true;
        data.startAt = block.timestamp;
        data.stats = stats;
        data.fee = fee;
        data.duration = duration;
    }

    // Request upgrade state
    function upgradeState(
        uint tokenId,
        bytes calldata signature
    ) external payable {

        require(verifySigner(signature, signer), "Invalid Signature.");
        require(Dragon(dragonNFTAddress).isExist(tokenId), "Not exists Token.");

        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];

        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You need to request first.");


        refundIfOver(data.fee);

        require(block.timestamp >= data.startAt + data.duration, "Not available now.");

        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);

        for (uint i = 0; i < data.stats.length ; i ++ ) {
            Dragon(dragonNFTAddress).upgradeDragonStat(tokenId, data.stats[i], 1);
        }

        data.pending = false;
        data.startAt = 0;
        data.owner = address(0);
        data.duration = 0;
        data.fee = 0;
    }

    function requestUpgradeSpecial(
        uint tokenId,
        bytes calldata signature
    ) external {
        require(verifySigner(signature, msg.sender), "Invalid signature");
        require(!Dragon(dragonNFTAddress).hasSpecial(tokenId), "Already upgraded to special.");

        PendingToUpgradeSpecial storage pendingSpecial = pendingToUpgradeSpecial[tokenId];
        require(!pendingSpecial.pending, "Already pending");

        pendingSpecial.pending = true;
        pendingSpecial.owner = msg.sender;
        pendingSpecial.startAt = block.timestamp;

        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), tokenId);
    }

    function upgradeSpecialSkill (
        uint tokenId,
        bytes calldata signature
    ) external payable {
        require(verifySigner(signature, signer), "Invalid Signature.");
        PendingToUpgradeSpecial storage data = pendingToUpgradeSpecial[tokenId];

        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "Should be pending first.");

        DragonData memory dragon = Dragon(dragonNFTAddress).getDragon(tokenId);
        
        uint currentValue = dragon.specialPoint;
        uint pendingPeriod = pendingDurationForSpecialSkill[currentValue];
        uint fee = feeForUpgradeSpecial[currentValue];

        refundIfOver(fee);
        require(block.timestamp >= data.startAt + pendingPeriod, "Not available now.");

        data.pending = false;
        data.startAt = 0;
        data.owner = address(0);

        Dragon(dragonNFTAddress).upgradeSpecialSkill(tokenId);
        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    // Cancel upgrade
    function cancelUpgradeState(uint tokenId) external {
        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You didn't request.");

        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        data.owner = address(0);
        data.pending = false;
        data.startAt = 0;
    }

    // Cancel upgrade special
    function cancelUpgradeSpecial(uint tokenId) external {
        PendingToUpgradeSpecial storage data = pendingToUpgradeSpecial[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You didn't request.");

        Dragon(dragonNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        data.owner = address(0);
        data.pending = false;
        data.startAt = 0;
    }

    function setStatRange(DragonType species, RarityType rarity, Stat stat, uint[2] memory value) external onlyOwner{
        require(value[1] <= MAX_LEVEL && value[0] >= MIN_LEVEL, "Invalid value");
        stateRanges[uint(species)][uint(rarity)][uint(stat)] = value;
    }

    function setLimitStatForAge(Age age, uint value) external onlyOwner {
        require(value <= MAX_LEVEL, "Invalid value");
        ageLimitInfo[age] = value;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verifySigner(bytes calldata signature, address _signer) 
        public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }

    function updateDragonName(uint _tokenId, string memory name, bytes calldata signature ) external {
        require(verifySigner(signature, signer), "Invalid signature");
        Dragon(dragonNFTAddress).updateName(_tokenId, name);
    }

    // Admin action
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function getSigner() external view returns(address) {
        return signer;
    }

    function setNFTAddress(address _address) external onlyOwner {
        dragonNFTAddress = _address;
    }

    function setPendingDurationForState(uint[9] memory durations) external onlyOwner {
        pendingDurationForState = durations;
    }

    function setFeeForUpgradeState(uint[9] memory fees) external onlyOwner {
        feeForUpgradeState = fees;
    }

    function setPendingDurationForDragon (uint duration) external onlyOwner {
        durationForHatch = duration;
    }

    function setPendingDurationForSpecial(uint[5] memory durations) external onlyOwner {
        pendingDurationForSpecialSkill = durations;
    }

    function setFeeForUpgradeSpecial(uint[5] memory fees) external onlyOwner {
        feeForUpgradeSpecial = fees;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Dragon.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DragonBreedingManager is Ownable, DragonBasic, ReentrancyGuard {
    struct BreedLand {
        uint id;
        address owner;
        uint father;
        uint mother;
        address fatherOwner;
        address motherOwner;
        uint startAt;
        bool pending;
        bool isRent;
        uint rentOrder;
    }

    struct RentOrder {
        uint id;
        address owner;
        uint tokenId;
        uint fee;
        bool enable;
    }

    // Dragon NFT address
    address public dragonNFTAddress;

    // Duration for re breeding for female.
    uint durationRebreeding = 1 weeks;
    uint duration = 2 weeks;
    Age minAgeForBreeding = Age.Adult;

    // Breeding ground;
    BreedLand[] breedlands;

    // RentOrder list
    RentOrder[] rentOrders;

    // token id => rent id
    mapping(uint => uint) private rentIDs;

    // token id => breed id
    mapping(uint => uint) private breedIDs; 

    // Breeding ground counter;
    uint public breedCount;

    // Rent order count
    uint public rentCount;

    constructor(address _dragonNFTAddress) DragonBasic() {
        dragonNFTAddress = _dragonNFTAddress;
    }

    function requestBreeding(uint fatherTokenId, uint motherTokenId) external {
        require(Dragon(dragonNFTAddress).ownerOf(fatherTokenId) == msg.sender, "You are not owner of this token.");
        require(Dragon(dragonNFTAddress).ownerOf(motherTokenId) == msg.sender, "You are not owner of this token.");

        require(uint(Dragon(dragonNFTAddress).getAge(fatherTokenId)) >= uint(minAgeForBreeding), "This dragon is too young.");
        require(uint(Dragon(dragonNFTAddress).getAge(motherTokenId)) >= uint(minAgeForBreeding), "This dragon is too young.");

        DragonData memory father = Dragon(dragonNFTAddress).getDragon(fatherTokenId);
        DragonData memory mother = Dragon(dragonNFTAddress).getDragon(motherTokenId);


        require(father.gender != mother.gender, "Gender should be opposite.");

        uint _motherTokenId;
        uint _fatherTokenId;

        if (father.gender == Gender.MALE) {
            _motherTokenId = motherTokenId;
            _fatherTokenId = fatherTokenId;
        } else {
            _motherTokenId = fatherTokenId;
            _fatherTokenId = motherTokenId;
        }

        require(mother.lastBreed + durationRebreeding <= block.timestamp, "Not available rebreeding for female.");

        breedIDs[fatherTokenId] = breedCount;
        breedIDs[motherTokenId] = breedCount;

        breedlands[breedCount] = BreedLand({
            id: breedCount,
            owner: msg.sender,
            father: _fatherTokenId,
            mother: _motherTokenId,
            fatherOwner: msg.sender,
            motherOwner: msg.sender,
            startAt: block.timestamp,
            pending: true,
            isRent: false,
            rentOrder: 0
        });

        breedCount ++;
        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), fatherTokenId);
        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), motherTokenId);
    }

    function breeding (uint breedId) external {
        require(breedId < breedCount, "Invalid breed ID.");
        BreedLand storage breedLand = breedlands[breedId];
        
        require(
            breedLand.owner == msg.sender || msg.sender == breedLand.fatherOwner || msg.sender == breedLand.motherOwner, 
            "You are not the owner or parent of this breed."
        );

        require(breedLand.startAt + duration <= block.timestamp, "Still incubating.");
        require(breedLand.pending, "You need to request first.");

        Dragon(dragonNFTAddress).breeding(breedLand.owner, breedLand.father, breedLand.mother);

        if (breedLand.isRent) {
            RentOrder storage rentOrder = rentOrders[breedLand.rentOrder];
            uint rentTokenId = rentOrder.tokenId;
            rentOrder.enable = true;

            if (rentTokenId == breedLand.father) {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.motherOwner, breedLand.mother);
            } else {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.fatherOwner, breedLand.father);
            }
        } else {
            Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.fatherOwner, breedLand.father);
            Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.motherOwner, breedLand.mother);
        }

        breedLand.father = 0;
        breedLand.mother = 0;
        breedLand.owner = address(0);
        breedLand.pending = false;
        breedLand.startAt = 0;
        breedLand.fatherOwner = address(0);
        breedLand.motherOwner = address(0);
    }

    function cancelBreeding (uint breedId) external {
        require(breedId < breedCount, "Invalid breed ID.");
        
        BreedLand storage breedLand = breedlands[breedId];
        require(breedLand.owner == msg.sender, "You are not the owner of this breed.");
        
        if (breedLand.isRent) {
            RentOrder storage rentOrder = rentOrders[breedLand.rentOrder];
            rentOrder.enable = true;
            uint rentTokenId = rentOrder.tokenId;

            if (rentTokenId == breedLand.father) {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.motherOwner, breedLand.mother);
            } else {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.fatherOwner, breedLand.father);
            }
        } else {
            if (breedLand.fatherOwner != address(0)) {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.fatherOwner, breedLand.father);
            }
            if (breedLand.motherOwner != address(0)) {
                Dragon(dragonNFTAddress).transferFrom(address(this), breedLand.motherOwner, breedLand.mother);
            }
        }

        breedLand.father = 0;
        breedLand.mother = 0;
        breedLand.owner = address(0);
        breedLand.pending = false;
        breedLand.startAt = 0;
        breedLand.fatherOwner = address(0);
        breedLand.motherOwner = address(0);
    }

    function createNewBreedLandWithSingleDragon(uint tokenId) external {
        require(Dragon(dragonNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token.");
        require(uint(Dragon(dragonNFTAddress).getAge(tokenId)) >= uint(minAgeForBreeding), "This dragon is too young.");

        DragonData memory dragon = Dragon(dragonNFTAddress).getDragon(tokenId);

        if (dragon.gender == Gender.FEMALE) {
            require(dragon.lastBreed + durationRebreeding <= block.timestamp, "Not available rebreeding for female.");
        }
        breedIDs[tokenId] = breedCount;
        breedlands[breedCount] = BreedLand({
            id: breedCount,
            owner: msg.sender,
            father: dragon.gender == Gender.MALE ? tokenId : 0,
            mother: dragon.gender == Gender.FEMALE ? tokenId : 0,
            fatherOwner: dragon.gender == Gender.MALE ? msg.sender : address(0),
            motherOwner: dragon.gender == Gender.FEMALE ? msg.sender : address(0),
            startAt: 0,
            pending: false,
            isRent: false,
            rentOrder: 0
        });

        breedCount ++;
        Dragon(dragonNFTAddress).transferFrom(msg.sender, address(this), tokenId);
    }

    function borrowDragon(uint rentId, uint landId) external payable {
        require(rentId < rentCount, "Invalid rent id.");
        require(isRentOrderAvailable(rentId), "This rent order is not available now.");

        RentOrder storage rentOrder = rentOrders[rentId];
        require(Dragon(dragonNFTAddress).getApproved(rentOrder.tokenId) == address(this), "Not approved.");
        require(Dragon(dragonNFTAddress).ownerOf(rentOrder.tokenId) == rentOrder.owner, "Rent dragon's ownership has been changed.");
        require(uint(Dragon(dragonNFTAddress).getAge(rentOrder.tokenId)) >= uint(minAgeForBreeding), "This dragon is too young.");

        DragonData memory rentedDragon = Dragon(dragonNFTAddress).getDragon(rentOrder.tokenId);
        BreedLand storage breedLand = breedlands[landId];
        
        address fatherOwner = breedLand.fatherOwner;
        address motherOwner = breedLand.motherOwner;
        require(fatherOwner != address(0) || motherOwner != address(0), "This breed land is not available.");
        require(fatherOwner == address(0) || motherOwner == address(0), "This breed land is not available.");
        
        if (fatherOwner != address(0)) {
            require(rentedDragon.gender == Gender.FEMALE, "Dragons should have opposite gender.");
            breedLand.motherOwner = rentOrder.owner;
            breedLand.mother = rentOrder.tokenId;
        } else {
            require(rentedDragon.gender == Gender.MALE, "Dragons should have opposite gender.");
            breedLand.fatherOwner = rentOrder.owner;
            breedLand.father = rentOrder.tokenId;
        }

        refundIfOver(rentOrder.fee);

        if (rentOrder.fee > 0) {
            payable(rentOrder.owner).transfer(rentOrder.fee);
        }

        Dragon(dragonNFTAddress).transferFrom(rentOrder.owner, address(this), rentOrder.tokenId);

        breedIDs[rentOrder.tokenId] = breedLand.id;

        breedLand.startAt = block.timestamp;
        breedLand.pending = true;
        breedLand.isRent = true;
        breedLand.rentOrder = rentId;

        rentOrder.enable = false;
    }


    function createRentOrder(uint tokenId, uint fee) external {
        require(Dragon(dragonNFTAddress).getApproved(tokenId) == address(this), "Not approved.");
        require(isRentable(tokenId), "This dragon is not rentable now.");
        require(uint(Dragon(dragonNFTAddress).getAge(tokenId)) >= uint(minAgeForBreeding), "This dragon is too young.");

        rentIDs[tokenId] = rentCount;

        rentOrders[rentCount] = RentOrder({
            id: rentCount,
            owner: msg.sender,
            tokenId: tokenId,
            fee: fee,
            enable: true
        });
        rentCount ++;
    }

    function cancelRentOrder (uint rentId) external {
        require(rentId < rentCount, "Invalid rent id.");
        RentOrder storage rentOrder = rentOrders[rentId];
        BreedLand memory land = breedlands[breedIDs[rentOrder.tokenId]];

        require(!land.pending, "Dragon is in pending.");

        rentOrder.enable = false;
    }

    function isRentOrderAvailable(uint rentId) public view returns(bool) {
        require(rentId < rentCount, "Invalid Rent ID.");

        RentOrder memory rentOrder = rentOrders[rentId];
        return rentOrder.enable && isRentable(rentOrder.tokenId);
    }

    function isRentable(uint tokenId) public view returns(bool) {
        DragonData memory dragon = Dragon(dragonNFTAddress).getDragon(tokenId);
        if (dragon.gender == Gender.MALE) {
            return true;
        } else {
            return dragon.lastBreed + durationRebreeding <= block.timestamp;
        }
    }

    function getBreedLands(address owner) external view returns(BreedLand[] memory){
        BreedLand[] memory lands = new BreedLand[](breedCount);
        uint index = 0;
        for (uint i = 0; i < breedlands.length; i ++) {
            BreedLand memory land = breedlands[i];
            if (land.owner == owner && land.pending) {
                lands[index] = land;
                index ++;
            }
        }

        return lands;
    }

    function getRentOrders() external view returns(RentOrder[] memory) {
        RentOrder[] memory orders = new RentOrder[](rentCount);
        uint index = 0;
        for (uint i = 0; i < orders.length; i ++) {
            RentOrder memory order = orders[i];
            if (order.enable) {
                orders[index] = order;
                index ++;
            }
        }

        return orders;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./library/StringUtils.sol";
import "./interface/ERC721A.sol";
import "./interface/AvatarBasic.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**************************************************
 * Avatar NFT
 *
 * Created for Pyre by: Patrick Kishi
 * Audited by: Jill
 * Special thanks goes to: Jill
 ***************************************************
 */

contract AvatarAssets is ERC721A, AvatarBasic, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint => CustomizableTrait) private assetType;
    // prices
    mapping(CustomizableTrait => uint) private pricesInEth;
    mapping(CustomizableTrait => uint) private pricesInToken;
    // price in token
    string[] private baseUris;

    IERC20 public paymentToken;
    constructor(
        uint16 maxBatchSize_,
        uint16 collectionSize_,
        string[] memory _baseUris,
        address _paymentToken
    ) ERC721A("AvatarAsset", "AvatarAsset", maxBatchSize_, collectionSize_) AvatarBasic() {
        require(_baseUris.length == 6, "Invalid base uris length");
        baseUris = _baseUris;
        paymentToken = IERC20(_paymentToken);
    }

    function _mint(
        address to,
        uint8 quantity,
        CustomizableTrait _assetType
    ) internal {
        uint originalSupply = totalSupply();
        _safeMint(to, quantity);

        for (uint i = 0; i < quantity; i ++) {
            assetType[originalSupply + i] = _assetType;
        }
    }

    function mintNFT(
        uint8 quantity,
        CustomizableTrait _assetType
    )
        external
        nonReentrant
        payable
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        _mint(msg.sender, quantity, _assetType);
        refundIfOver(pricesInEth[_assetType] * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function mintNFTWithToken(
        uint8 quantity,
        CustomizableTrait _assetType
    )
    external
    nonReentrant
    {
         require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
         paymentToken.transferFrom(msg.sender, address(this), quantity * pricesInToken[_assetType]);
        _mint(msg.sender, quantity, _assetType);
    }

    // admin action
    function setPaymentToken (IERC20 _token) external onlyOwner {
        paymentToken = _token;
    }

    function setPriceInEth(uint _priceInEth, CustomizableTrait _assetType) external onlyOwner {
        pricesInEth[_assetType] = _priceInEth;
    }

    function setPriceInToken (uint _priceInToken, CustomizableTrait _assetType) external onlyOwner {
        pricesInToken[_assetType] = _priceInToken;
    }

    function adminMint(
        address to,
        uint8 quantity,
        CustomizableTrait _assetType
    ) external onlyOwner { 
         require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        _mint(to, quantity, _assetType);
    }

    function getTrait(uint tokenId) public view returns(CustomizableTrait) {
        require(_exists(tokenId), "Not exists NFT.");
        return assetType[tokenId];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Avatar.sol";
import "./AvatarAssets.sol";

contract AvatarUpdateManager is Ownable, AvatarBasic {
    struct PendingToKeeper {
        address owner;
        uint startAt;
        bool pending;
    }

    struct PendingToUpgradeState {
        address owner;
        Stat[] states;
        uint startAt;
        uint duration;
        uint fee;
        bool pending;
    }

    // sale signer
    address public signer;

    // Avatar NFT address
    address public avatarNFTAddress;

    // Avatar Asset NFT address
    address public avatarAssetNFTAddress;

    // Pending to upgrade states.
    mapping(uint => PendingToUpgradeState) public pendingToUpgradeInfo;
    // duration, fee for upgrading states;
    uint[9] public pendingDurationForState = 
        [ 1 days, 1 days, 1 days, 1 days, 1 days, 1 days, 2 days, 3 days, 4 days]; // level is between 1 and 10, so need 9 of duration values.
     // fee for upgrading states;
    uint[9] public feeForUpgradeState = [
        0, 0, 0, 0, 0, 0, 5 ether, 10 ether, 15 ether
    ];

    // Pending to keeper
    mapping(uint => PendingToKeeper) pendingToKeeperInfo;
    uint public pendingToKeeperLockDuration = 1 weeks;

    // storage for stroring component NFTs. traits
    mapping(address => mapping(CustomizableTrait => uint)) private reservedTraits;

    constructor(address _avatarNFTAddress, address _signer) AvatarBasic() {
        avatarNFTAddress = _avatarNFTAddress;
        signer = _signer;
    }

    // Request for Human => Keeper, Lock NFT to this contract.
    function requestUpgradeToKeeper(uint tokenId) external {
        require(Avatar(avatarNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token.");
        require(!Avatar(avatarNFTAddress).isKeeper(tokenId), "Already keeper.");

        Avatar(avatarNFTAddress).transferFrom(msg.sender, address(this), tokenId);

        PendingToKeeper storage data = pendingToKeeperInfo[tokenId];
        data.owner = msg.sender;
        data.pending = true;
        data.startAt = block.timestamp;
    }

    // Finalize to upgrade to Keeper.
    function upgradeToKeeper(uint tokenId, string memory metadataUri, bytes calldata signature) external {
        require(verifySigner(signature, signer), "Invalid Signature.");

        PendingToKeeper storage data = pendingToKeeperInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "Should be pending first.");
        require(block.timestamp >= data.startAt + pendingToKeeperLockDuration, "Not available now.");

        Avatar(avatarNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        Avatar(avatarNFTAddress).upgradeToKeeper(tokenId);
        Avatar(avatarNFTAddress).setTokenUri(tokenId, metadataUri);
        data.pending = false;
    }

    // Cancel upgrade
    function cancelToKeeper(uint tokenId) external {
        PendingToKeeper storage data = pendingToKeeperInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You didn't request.");

        Avatar(avatarNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        data.owner = address(0);
        data.pending = false;
        data.startAt = 0;
    }

    // Request upgrade state
    function requestUpgradeState(uint tokenId, Stat[] memory keys) external {
        require(Avatar(avatarNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this token.");
        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];
        require(!data.pending, "Already requested.");
        
        bool upgradable = false;
        uint duration = 0;
        uint fee = 0;
        uint index = 0;

        Stat[] memory stats = new Stat[](keys.length);
        for (uint i = 0; i < keys.length; i ++) {
            uint currentValue =  Avatar(avatarNFTAddress).getSingleState(tokenId, keys[i]);
            if (currentValue <= 9) {
                upgradable = true;
                duration += pendingDurationForState[currentValue - 1];
                fee += feeForUpgradeState[currentValue - 1];
                stats[index] = keys[i];
                index ++;
            }
        }
        require(upgradable, "No stat can be upgradable.");
        
        Avatar(avatarNFTAddress).transferFrom(msg.sender, address(this), tokenId);

    
        data.owner = msg.sender;
        data.pending = true;
        data.startAt = block.timestamp;
        data.states = stats;
        data.duration = duration;
        data.fee = fee;
    }

    // upgrade state
    function upgradeState(
        uint tokenId,
        bytes calldata signature
    ) external payable {

        require(verifySigner(signature, signer), "Invalid Signature.");

        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];

        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "Should be pending first.");

        refundIfOver(data.fee);
        require(block.timestamp >= data.startAt + data.duration, "Not available now.");

        for (uint i = 0; i < data.states.length ; i ++ ) {
            Avatar(avatarNFTAddress).upgradeState(tokenId, data.states[i], 1);
        }

        Avatar(avatarNFTAddress).transferFrom(address(this), msg.sender, tokenId);

        data.pending = false;
        data.owner = address(0);
        data.duration = 0;
        data.fee = 0;
    }

    // Cancel upgrade
    function cancelUpgradeState(uint tokenId) external {
        PendingToUpgradeState storage data = pendingToUpgradeInfo[tokenId];
        require(data.owner == msg.sender, "You are not NFT owner.");
        require(data.pending, "You didn't request.");

        Avatar(avatarNFTAddress).transferFrom(address(this), msg.sender, tokenId);
        data.owner = address(0);
        data.pending = false;
        data.startAt = 0;
    }

    function updateMetadata(uint tokenId, CustomizableTrait trait, uint assetTokenId, string memory uri, bytes calldata signature) external {
        require(verifySigner(signature, signer), "Invalid signature");
        require(Avatar(avatarNFTAddress).ownerOf(tokenId) == msg.sender, "You are not owner of this Avatar.");
        require(AvatarAssets(avatarAssetNFTAddress).ownerOf(assetTokenId) == msg.sender, "You are not owner of this asset.");
        require(AvatarAssets(avatarAssetNFTAddress).getTrait(assetTokenId) == trait, "Invalid asset token.");
        
        uint prevTokenId = reservedTraits[msg.sender][trait];
        if (prevTokenId != 0) {
            IERC721(avatarAssetNFTAddress).transferFrom(address(this), msg.sender, prevTokenId);
        }
        Avatar(avatarNFTAddress).setTokenUri(tokenId, uri);
        IERC721(avatarAssetNFTAddress).transferFrom(msg.sender, address(this), assetTokenId);
        reservedTraits[msg.sender][trait] = assetTokenId;
    }

    function updateAvatarName(uint _tokenId, string memory name, bytes calldata signature ) external {
        require(verifySigner(signature, signer), "Invalid signature");
        Avatar(avatarNFTAddress).updateName(_tokenId, name);
    }

    function setAssetNFTAddress(address nftAddress) external onlyOwner {
        avatarAssetNFTAddress = nftAddress;
    } 

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verifySigner(bytes calldata signature, address _signer) 
        public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }

    function getSigner() external view returns(address) {
        return signer;
    }
    
    // Admin action
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setAvatarNFTAddress(address _address) external onlyOwner {
        avatarNFTAddress = _address;
    }

    function setPendingDurationForState(uint[9] memory durations) external onlyOwner {
        pendingDurationForState = durations;
    }

    function setFeeForUpgradeState(uint[9] memory fees) external onlyOwner {
        feeForUpgradeState = fees;
    }

    function setPendingDurationForKeeper (uint duration) external onlyOwner {
        pendingToKeeperLockDuration = duration;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Avatar.sol";

contract AvatarSaleManager is Ownable {
    // sale signer
    address public signer;

    // Avatar NFT
    address public nftAddress;

    // nft price in ETH
    uint public priceInEth;

    // nft price in Token
    uint public priceInToken;

    // payment token
    IERC20 public paymentToken;

    constructor(address _nftAddress, IERC20 _token, address _signer) {
        nftAddress = _nftAddress;
        paymentToken = _token;
        signer = _signer;
    }

    function batchUpdateMetadata(uint from, uint to, string[] memory uris) internal {
        uint index = 0;
        for (uint i = from; i < to; i ++) {
            Avatar(nftAddress).setTokenUri(i, uris[index]);
            index ++;
        }
    }

    // Mint NFT with ETH
    function mintNFT(
        uint8 quantity,
        uint8[][] memory values,
        string[] memory metadataUris,
        bytes calldata signature ,
        string[] memory names
    ) external payable {
        require(verifySigner(signature, signer), "Invalid signature.");
        require(metadataUris.length == quantity, "Metadata length should be same as quantity.");

        Avatar(nftAddress).mintNFT(msg.sender, quantity, values, metadataUris, names);
        refundIfOver(priceInEth * quantity);
    }

    // Mint NFT with Token
    function mintNFTWithToken(
        uint8 quantity,
        uint8[][] memory values,
        string[] memory metadataUris,
        bytes calldata signature,
        string[] memory names
    ) external {
        require(verifySigner(signature, signer), "Invalid signature.");
        require(metadataUris.length == quantity, "Metadata");

        Avatar(nftAddress).mintNFT(msg.sender, quantity, values, metadataUris, names);
        IERC20(paymentToken).transferFrom(msg.sender, address(this), quantity * priceInToken);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verifySigner(bytes calldata signature, address _signer) 
        public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return (recoveredAddress != address(0) && recoveredAddress == _signer);
    }

    function getSigner() external view returns(address) {
        return signer;
    }
    
    // Admin action
    function setSigner (address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid signer.");
        signer = _signer;
    }

    function setPaymentToken (IERC20 _token) external onlyOwner {
        paymentToken = _token;
    }

    function setPriceInEth(uint _priceInEth) external onlyOwner {
        priceInEth = _priceInEth;
    }

    function setPriceInToken (uint _priceInToken) external onlyOwner {
        priceInToken = _priceInToken;
    }

    function setNFTAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

}