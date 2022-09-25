/*
🇧​​​​​ 🇮​​​​​ 🇱​​​​​ 🇪​​​​​ 🇹​​​​​ 🇸​​​​​

🇨​​​​​ 🇱​​​​​ 🇺​​​​​ 🇧​​​​​

Go to https://bilets.club to see more.

████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
█████████████''.....................................''█████████████
█████████████''...........██████████████............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██████████████............''█████████████
█████████████''..............█████████..............''█████████████
█████████████''............█████████████............''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''.....................................''█████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BiletsClubLevel.sol";

/** 
@title Bilets Club NFT Contract
@dev BiletsClub ERC721 Non-Fungible Token
@author Bilets
**/

contract BiletsClub is
    ERC721A,
    Ownable,
    ERC721AQueryable,
    ERC721ABurnable,
    ReentrancyGuard
{
    uint256 public maxSupply = 10000;
    uint256 public constant maxMintsPerWallet = 10;
    uint256 public mintRate = 0.000 ether;
    bool public alreadyMintedByBilet = false;
    bool public pause = false;

    struct NFTSstatus {
        uint256 experience;
        uint256 health;
        uint256 mana;
        uint256 stamina;
    }

    mapping(uint256 => NFTSstatus) public NFTstatus;
    mapping(address => bool) public admins;

    string public contractURI =
        "https://bilets.club/api/opensea_contracts_meta/contractNftMeta";
    string public baseURI = "https://bilets.club/api/opensea_meta_club/";

    modifier onlyAdmins() {
        require(admins[msg.sender] == true, "Caller is not a admin.");
        _;
    }
    modifier isPaused() {
        require(pause == false, "The contract is paused.");
        _;
    }

    constructor() ERC721A("Bilets Club", "BLT-Club") {
        _safeMint(msg.sender, 10);
        admins[msg.sender] = true;
    }

    /******************** PUBLIC ********************/
    /** @notice Get Base URI. **/
    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

    /** @notice Get Token URI. **/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(currentBaseURI, Strings.toString(tokenId))
                )
                : "";
    }

    /** @notice Mint NFT (ERC721). **/
    function mint(uint256 quantity) external payable nonReentrant isPaused {
        require(msg.sender == tx.origin, "Not allowed.");
        require(
            quantity + _numberMinted(msg.sender) <= maxMintsPerWallet,
            "Mint limit amount per wallet exceeded."
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Not enough tokens left."
        );
        require(msg.value >= (mintRate * quantity), "Not enough ether.");
        _safeMint(msg.sender, quantity);
    }

    /** @notice Get NFT Experience. **/
    function Get_NFT_Experience(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].experience;
    }

    /** @notice Get NFT Health. **/
    function Get_NFT_Health(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].health;
    }

    /** @notice Get NFT Mana. **/
    function Get_NFT_Mana(uint256 tokenID) public view returns (uint256) {
        return NFTstatus[tokenID].mana;
    }

    /** @notice Get NFT Stamina Used. **/
    function Get_NFT_StaminaUsed(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        return Get_NFT_Stamina(tokenID) - block.timestamp;
    }

    /** @notice Get NFT Stamina Timestamp. **/
    function Get_NFT_Stamina(uint256 tokenID) internal view returns (uint256) {
        if (NFTstatus[tokenID].stamina <= block.timestamp) {
            return block.timestamp;
        } else {
            return NFTstatus[tokenID].stamina;
        }
    }

    /******************** ADMINS ********************/
    /** @notice Others Contracts can mint for Allowlist. **/
    function ADM_MintAllowlist(address account, uint256 quantity)
        external
        payable
        onlyAdmins
        nonReentrant
        isPaused
    {
        require(
            quantity + _numberMinted(account) <= maxMintsPerWallet,
            "Mint limit amount per wallet exceeded."
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "Not enough tokens left."
        );
        _safeMint(account, quantity);
    }

    /** @notice Others Contracts can change NFT Status. **/
    function ADM_ChangeStatus(
        bool earn,
        uint256 tokenID,
        uint256 amountExp,
        uint256 amountHp,
        uint256 amountMana,
        uint256 amountStamina
    ) external payable onlyAdmins nonReentrant isPaused {
        if (earn)
            NFTstatus[tokenID] = NFTSstatus(
                Get_NFT_Experience(tokenID) + amountExp,
                Get_NFT_Health(tokenID) + amountHp,
                Get_NFT_Mana(tokenID) + amountMana,
                Get_NFT_Stamina(tokenID) + amountStamina
            );
        else {
            NFTstatus[tokenID] = NFTSstatus(
                Get_NFT_Experience(tokenID) - amountExp,
                Get_NFT_Health(tokenID) - amountHp,
                Get_NFT_Mana(tokenID) - amountMana,
                Get_NFT_Stamina(tokenID) - amountStamina
            );
        }
    }

    /******************** OWNER ********************/
    /** @notice Owner can mint 500, only one time. **/
    function OWNER_mint500ForBilet() external onlyOwner {
        require(totalSupply() + 500 <= maxSupply, "Not enough tokens left.");
        require(!alreadyMintedByBilet, "Already been mint by the team.");
        alreadyMintedByBilet = true;
        _safeMint(_msgSender(), 500);
    }

    /** @notice Owner can choose others contracts an admin. **/
    function OWNER_FlipAdmin(address _admin) public onlyOwner {
        admins[_admin] = !admins[_admin];
    }

    /** @notice Owner can pause or unpause. **/
    function OWNER_FlipPause() public onlyOwner {
        pause = !pause;
    }

    /** @notice Owner can change Base URI. **/
    function OWNER_SetBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /** @notice Owner can change Contract URI. **/
    function OWNER_SetContractURI(string memory _newContractURI)
        public
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /** @notice Owner can change Mint Rate. **/
    function OWNER_SetMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    /** @notice Owner can change MaxSupply, maximum 10000. **/
    function OWNER_SetMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply <= 10000, "Max supply must be lower than 10000.");
        maxSupply = _maxSupply;
    }

    /** @notice Owner can withdraws balance from contract. **/
    function OWNER_Withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
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

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
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
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
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
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../ERC721A.sol';

error InvalidQueryRange();

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../ERC721A.sol';

/**
 * @title ERC721A Burnable Token
 * @dev ERC721A Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
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

/*
🇧​​​​​ 🇮​​​​​ 🇱​​​​​ 🇪​​​​​ 🇹​​​​​ 🇸​​​​​

🇨​​​​​ 🇱​​​​​ 🇺​​​​​ 🇧​​​​​

Go to https://bilets.club to see more.

████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
█████████████''.....................................''█████████████
█████████████''...........██████████████............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██....██....██............''█████████████
█████████████''...........██████████████............''█████████████
█████████████''..............█████████..............''█████████████
█████████████''............█████████████............''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''.....██████████████████████████......''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............█████████████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''............████.....████............''█████████████
█████████████''.....................................''█████████████
█████████████'''''''''''''''''''''''''''''''''''''''''█████████████
████████████████████████████Bilets-Club████████████████████████████
████████████████████████████Bilets-Club████████████████████████████
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** 
@title Bilets Club NFT Level
@author Bilets
**/

contract BiletsClubLevel {
    uint256[] public levelExperience = [
        0,
        100,
        200,
        400,
        800,
        1500,
        2600,
        4200,
        6400,
        9300,
        13000,
        17600,
        23200,
        29900,
        37800,
        47000,
        57600,
        69700,
        83400,
        98800,
        116000,
        135100,
        156200,
        179400,
        204800,
        232500,
        262600,
        295200,
        330400,
        368300,
        409000,
        452600,
        499200,
        548900,
        601800,
        658000,
        717600,
        780700,
        847400,
        917800,
        992000,
        1070100,
        1152200,
        1238400,
        1328800,
        1423500,
        1522600,
        1626200,
        1734400,
        1847300,
        1965000,
        2087600,
        2215200,
        2347900,
        2485800,
        2629000,
        2777600,
        2931700,
        3091400,
        3256800,
        3428000,
        3605100,
        3788200,
        3977400,
        4172800,
        4374500,
        4582600,
        4797200,
        5018400,
        5246300,
        5481000,
        5722600,
        5971200,
        6226900,
        6489800,
        6760000,
        7037600,
        7322700,
        7615400,
        7915800,
        8224000,
        8540100,
        8864200,
        9196400,
        9536800,
        9885500,
        10242600,
        10608200,
        10982400,
        11365300,
        11757000,
        12157600,
        12567200,
        12985900,
        13413800,
        13851000,
        14297600,
        14753700,
        15219400,
        15694800,
        16180000,
        16675100,
        17180200,
        17695400,
        18220800,
        18756500,
        19302600,
        19859200,
        20426400,
        21004300,
        21593000,
        22192600,
        22803200,
        23424900,
        24057800,
        24702000,
        25357600,
        26024700,
        26703400,
        27393800,
        28096000,
        28810100,
        29536200,
        30274400,
        31024800,
        31787500,
        32562600,
        33350200,
        34150400,
        34963300,
        35789000,
        36627600,
        37479200,
        38343900,
        39221800,
        40113000,
        41017600,
        41935700,
        42867400,
        43812800,
        44772000,
        45745100,
        46732200,
        47733400,
        48748800,
        49778500,
        50822600,
        51881200,
        52954400,
        54042300,
        55145000,
        56262600,
        57395200,
        58542900,
        59705800,
        60884000,
        62077600,
        63286700,
        64511400,
        65751800,
        67008000,
        68280100,
        69568200,
        70872400,
        72192800,
        73529500,
        74882600,
        76252200,
        77638400,
        79041300,
        80461000,
        81897600,
        83351200,
        84821900,
        86309800,
        87815000,
        89337600,
        90877700,
        92435400,
        94010800,
        95604000,
        97215100,
        98844200,
        100491400,
        102156800,
        103840500,
        105542600,
        107263200,
        109002400,
        110760300,
        112537000,
        114332600,
        116147200,
        117980900,
        119833800,
        121706000,
        123597600,
        125508700,
        127439400,
        129389800,
        131360000,
        133350100,
        135360200,
        137390400,
        139440800,
        141511500,
        143602600,
        145714200,
        147846400,
        149999300,
        152173000,
        154367600,
        156583200,
        158819900,
        161077800,
        163357000,
        165657600,
        167979700,
        170323400,
        172688800,
        175076000,
        177485100,
        179916200,
        182369400,
        184844800,
        187342500,
        189862600,
        192405200,
        194970400,
        197558300,
        200169000,
        202802600,
        205459200,
        208138900,
        210841800,
        213568000,
        216317600,
        219090700,
        221887400,
        224707800,
        227552000,
        230420100,
        233312200,
        236228400,
        239168800,
        242133500,
        245122600,
        248136200,
        251174400,
        254237300,
        257325000,
        260437600,
        263575200,
        266737900,
        269925800,
        273139000,
        276377600,
        279641700,
        282931400,
        286246800,
        289588000,
        292955100,
        296348200,
        299767400,
        303212800,
        306684500,
        310182600,
        313707200,
        317258400,
        320836300,
        324441000,
        328072600,
        331731200,
        335416900,
        339129800,
        342870000,
        346637600,
        350432700,
        354255400,
        358105800,
        361984000,
        365890100,
        369824200,
        373786400,
        377776800,
        381795500,
        385842600,
        389918200,
        394022400,
        398155300,
        402317000,
        406507600,
        410727200,
        414975900,
        419253800,
        423561000,
        427897600,
        432263700,
        436659400,
        441084800,
        445540000,
        450025100,
        454540200,
        459085400,
        463660800,
        468266500,
        472902600,
        477569200,
        482266400,
        486994300,
        491753000,
        496542600,
        501363200,
        506214900,
        511097800,
        516012000,
        520957600,
        525934700,
        530943400,
        535983800,
        541056000,
        546160100,
        551296200,
        556464400,
        561664800,
        566897500,
        572162600,
        577460200,
        582790400,
        588153300,
        593549000,
        598977600,
        604439200,
        609933900,
        615461800,
        621023000,
        626617600,
        632245700,
        637907400,
        643602800,
        649332000,
        655095100,
        660892200,
        666723400,
        672588800,
        678488500,
        684422600,
        690391200,
        696394400,
        702432300,
        708505000,
        714612600,
        720755200,
        726932900,
        733145800,
        739394000,
        745677600,
        751996700,
        758351400,
        764741800,
        771168000,
        777630100,
        784128200,
        790662400,
        797232800,
        803839500,
        810482600,
        817162200,
        823878400,
        830631300,
        837421000,
        844247600,
        851111200,
        858011900,
        864949800,
        871925000,
        878937600,
        885987700,
        893075400,
        900200800,
        907364000,
        914565100,
        921804200,
        929081400,
        936396800,
        943750500,
        951142600,
        958573200,
        966042400,
        973550300,
        981097000,
        988682600,
        996307200,
        1003970900,
        1011673800,
        1019416000,
        1027197600,
        1035018700,
        1042879400,
        1050779800,
        1058720000,
        1066700100,
        1074720200,
        1082780400,
        1090880800,
        1099021500,
        1107202600,
        1115424200,
        1123686400,
        1131989300,
        1140333000,
        1148717600,
        1157143200,
        1165609900,
        1174117800,
        1182667000,
        1191257600,
        1199889700,
        1208563400,
        1217278800,
        1226036000,
        1234835100,
        1243676200,
        1252559400,
        1261484800,
        1270452500,
        1279462600,
        1288515200,
        1297610400,
        1306748300,
        1315929000,
        1325152600,
        1334419200,
        1343728900,
        1353081800,
        1362478000,
        1371917600,
        1381400700,
        1390927400,
        1400497800,
        1410112000,
        1419770100,
        1429472200,
        1439218400,
        1449008800,
        1458843500,
        1468722600,
        1478646200,
        1488614400,
        1498627300,
        1508685000,
        1518787600,
        1528935200,
        1539127900,
        1549365800,
        1559649000,
        1569977600,
        1580351700,
        1590771400,
        1601236800,
        1611748000,
        1622305100,
        1632908200,
        1643557400,
        1654252800,
        1664994500,
        1675782600,
        1686617200,
        1697498400,
        1708426300,
        1719401000,
        1730422600,
        1741491200,
        1752606900,
        1763769800,
        1774980000,
        1786237600,
        1797542700,
        1808895400,
        1820295800,
        1831744000,
        1843240100,
        1854784200,
        1866376400,
        1878016800,
        1889705500,
        1901442600,
        1913228200,
        1925062400,
        1936945300,
        1948877000,
        1960857600,
        1972887200,
        1984965900,
        1997093800,
        2009271000,
        2021497600,
        2033773700,
        2046099400,
        2058474800,
        2070900000,
        2083375100,
        2095900200,
        2108475400,
        2121100800,
        2133776500,
        2146502600,
        2159279200,
        2172106400,
        2184984300,
        2197913000,
        2210892600,
        2223923200,
        2237004900,
        2250137800,
        2263322000,
        2276557600,
        2289844700,
        2303183400,
        2316573800,
        2330016000,
        2343510100,
        2357056200,
        2370654400,
        2384304800,
        2398007500,
        2411762600,
        2425570200,
        2439430400,
        2453343300,
        2467309000,
        2481327600,
        2495399200,
        2509523900,
        2523701800,
        2537933000,
        2552217600,
        2566555700,
        2580947400,
        2595392800,
        2609892000,
        2624445100,
        2639052200,
        2653713400,
        2668428800,
        2683198500,
        2698022600,
        2712901200,
        2727834400,
        2742822300,
        2757865000,
        2772962600,
        2788115200,
        2803322900,
        2818585800,
        2833904000,
        2849277600,
        2864706700,
        2880191400,
        2895731800,
        2911328000,
        2926980100,
        2942688200,
        2958452400,
        2974272800,
        2990149500,
        3006082600,
        3022072200,
        3038118400,
        3054221300,
        3070381000,
        3086597600,
        3102871200,
        3119201900,
        3135589800,
        3152035000,
        3168537600,
        3185097700,
        3201715400,
        3218390800,
        3235124000,
        3251915100,
        3268764200,
        3285671400,
        3302636800,
        3319660500,
        3336742600,
        3353883200,
        3371082400,
        3388340300,
        3405657000,
        3423032600,
        3440467200,
        3457960900,
        3475513800,
        3493126000,
        3510797600,
        3528528700,
        3546319400,
        3564169800,
        3582080000,
        3600050100,
        3618080200,
        3636170400,
        3654320800,
        3672531500,
        3690802600,
        3709134200,
        3727526400,
        3745979300,
        3764493000,
        3783067600,
        3801703200,
        3820399900,
        3839157800,
        3857977000,
        3876857600,
        3895799700,
        3914803400,
        3933868800,
        3952996000,
        3972185100,
        3991436200,
        4010749400,
        4030124800,
        4049562500,
        4069062600,
        4088625200,
        4108250400,
        4127938300,
        4147689000,
        4167502600,
        4187379200,
        4207318900,
        4227321800,
        4247388000,
        4267517600,
        4287710700,
        4307967400,
        4328287800,
        4348672000,
        4369120100,
        4389632200,
        4410208400,
        4430848800,
        4451553500,
        4472322600,
        4493156200,
        4514054400,
        4535017300,
        4556045000,
        4577137600,
        4598295200,
        4619517900,
        4640805800,
        4662159000,
        4683577600,
        4705061700,
        4726611400,
        4748226800,
        4769908000,
        4791655100,
        4813468200,
        4835347400,
        4857292800,
        4879304500,
        4901382600,
        4923527200,
        4945738400,
        4968016300,
        4990361000,
        5012772600,
        5035251200,
        5057796900,
        5080409800,
        5103090000,
        5125837600,
        5148652700,
        5171535400,
        5194485800,
        5217504000,
        5240590100,
        5263744200,
        5286966400,
        5310256800,
        5333615500,
        5357042600,
        5380538200,
        5404102400,
        5427735300,
        5451437000,
        5475207600,
        5499047200,
        5522955900,
        5546933800,
        5570981000,
        5595097600,
        5619283700,
        5643539400,
        5667864800,
        5692260000,
        5716725100,
        5741260200,
        5765865400,
        5790540800,
        5815286500,
        5840102600,
        5864989200,
        5889946400,
        5914974300,
        5940073000,
        5965242600,
        5990483200,
        6015794900,
        6041177800,
        6066632000,
        6092157600,
        6117754700,
        6143423400,
        6169163800,
        6194976000,
        6220860100,
        6246816200,
        6272844400,
        6298944800,
        6325117500,
        6351362600,
        6377680200,
        6404070400,
        6430533300,
        6457069000,
        6483677600,
        6510359200,
        6537113900,
        6563941800,
        6590843000,
        6617817600,
        6644865700,
        6671987400,
        6699182800,
        6726452000,
        6753795100,
        6781212200,
        6808703400,
        6836268800,
        6863908500,
        6891622600,
        6919411200,
        6947274400,
        6975212300,
        7003225000,
        7031312600,
        7059475200,
        7087712900,
        7116025800,
        7144414000,
        7172877600,
        7201416700,
        7230031400,
        7258721800,
        7287488000,
        7316330100,
        7345248200,
        7374242400,
        7403312800,
        7432459500,
        7461682600,
        7490982200,
        7520358400,
        7549811300,
        7579341000,
        7608947600,
        7638631200,
        7668391900,
        7698229800,
        7728145000,
        7758137600,
        7788207700,
        7818355400,
        7848580800,
        7878884000,
        7909265100,
        7939724200,
        7970261400,
        8000876800,
        8031570500,
        8062342600,
        8093193200,
        8124122400,
        8155130300,
        8186217000,
        8217382600,
        8248627200,
        8279950900,
        8311353800,
        8342836000,
        8374397600,
        8406038700,
        8437759400,
        8469559800,
        8501440000,
        8533400100,
        8565440200,
        8597560400,
        8629760800,
        8662041500,
        8694402600,
        8726844200,
        8759366400,
        8791969300,
        8824653000,
        8857417600,
        8890263200,
        8923189900,
        8956197800,
        8989287000,
        9022457600,
        9055709700,
        9089043400,
        9122458800,
        9155956000,
        9189535100,
        9223196200,
        9256939400,
        9290764800,
        9324672500,
        9358662600,
        9392735200,
        9426890400,
        9461128300,
        9495449000,
        9529852600,
        9564339200,
        9598908900,
        9633561800,
        9668298000,
        9703117600,
        9738020700,
        9773007400,
        9808077800,
        9843232000,
        9878470100,
        9913792200,
        9949198400,
        9984688800,
        10020263500,
        10055922600,
        10091666200,
        10127494400,
        10163407300,
        10199405000,
        10235487600,
        10271655200,
        10307907900,
        10344245800,
        10380669000,
        10417177600,
        10453771700,
        10490451400,
        10527216800,
        10564068000,
        10601005100,
        10638028200,
        10675137400,
        10712332800,
        10749614500,
        10786982600,
        10824437200,
        10861978400,
        10899606300,
        10937321000,
        10975122600,
        11013011200,
        11050986900,
        11089049800,
        11127200000,
        11165437600,
        11203762700,
        11242175400,
        11280675800,
        11319264000,
        11357940100,
        11396704200,
        11435556400,
        11474496800,
        11513525500,
        11552642600,
        11591848200,
        11631142400,
        11670525300,
        11709997000,
        11749557600,
        11789207200,
        11828945900,
        11868773800,
        11908691000,
        11948697600,
        11988793700,
        12028979400,
        12069254800,
        12109620000,
        12150075100,
        12190620200,
        12231255400,
        12271980800,
        12312796500,
        12353702600,
        12394699200,
        12435786400,
        12476964300,
        12518233000,
        12559592600,
        12601043200,
        12642584900,
        12684217800,
        12725942000,
        12767757600,
        12809664700,
        12851663400,
        12893753800,
        12935936000,
        12978210100,
        13020576200,
        13063034400,
        13105584800,
        13148227500,
        13190962600,
        13233790200,
        13276710400,
        13319723300,
        13362829000,
        13406027600,
        13449319200,
        13492703900,
        13536181800,
        13579753000,
        13623417600,
        13667175700,
        13711027400,
        13754972800,
        13799012000,
        13843145100,
        13887372200,
        13931693400,
        13976108800,
        14020618500,
        14065222600,
        14109921200,
        14154714400,
        14199602300,
        14244585000,
        14289662600,
        14334835200,
        14380102900,
        14425465800,
        14470924000,
        14516477600,
        14562126700,
        14607871400,
        14653711800,
        14699648000,
        14745680100,
        14791808200,
        14838032400,
        14884352800,
        14930769500,
        14977282600,
        15023892200,
        15070598400,
        15117401300,
        15164301000,
        15211297600,
        15258391200,
        15305581900,
        15352869800,
        15400255000,
        15447737600,
        15495317700,
        15542995400,
        15590770800,
        15638644000,
        15686615100,
        15734684200,
        15782851400,
        15831116800,
        15879480500,
        15927942600,
        15976503200,
        16025162400,
        16073920300,
        16122777000,
        16171732600,
        16220787200,
        16269940900,
        16319193800,
        16368546000,
        16417997600,
        16467548700,
        16517199400,
        16566949800
    ];
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