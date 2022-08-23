/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File: contracts\interfaces\ICapneoRegistry.sol
interface IRegistryStructs {
    struct CapneoNFT {
        address beacon;
        uint48 index;
        address deployer;
        uint48 deployedTimestamp;
        string snapshotSpace;
/*         string[] documents;
 */    }
}
interface IRegistryFunctions {
    // mutating functions:
    function setOpenseaFactory(address newFactory, bytes4 magicValue) external;
    function proposeUpgradeForBeacon(
        address beacon, 
        address proposedImplementation
    ) external;
    function upgradeBeacon(
        address beacon, 
        address newImplementation,
        bytes4 magicValue
    ) external;
    // view only functions :
    function getNFTAddressByIndex(uint256 index) external view returns(address);
    function getIndexByNFTAddress(address nftContract) external view returns(uint256);
    function getBeaconByNFTAddress(address nftContract) external view returns(address);
    function getUpgraderByNFTAddress(address nftContract) external view returns(address);
    function isNFTRegistered(address nftContract) external view returns(bool);
    function getNumberOfNfts() external view returns(uint256);
    function getAllNFTAddresses() external view returns(address[] memory);
    function getCapneoNFTByAddress(address nftAddress) external view returns(IRegistryStructs.CapneoNFT memory);
    function getCapneoNFTByIndex(uint256 index) external view returns(IRegistryStructs.CapneoNFT memory);
    function getMultipleCapneoNFTsByIndex(uint256[] calldata indices) external view returns(IRegistryStructs.CapneoNFT[] memory);
    function getOpenseaFactory() external view returns(address);
    function getProtocolFeeRecipient() external view returns(address);
    function getURIConstructor() external view returns(address);
    function isValidKYC(address account, bytes calldata signature) external view returns(bool);
}
interface IRegistryEvents {
    event NewCapneoNFT(address proxy, IRegistryStructs.CapneoNFT proxyData);
    event OpenseaFactoryChanged(address old, address current);
    event ProtocolFeeRecipientChanged(address old, address current);
    event NewURIConstructor(address uriConstructor);
}
interface IRegistryErrors {
    error IndexOutOfRange(uint256 have, uint256 maximum);
    error NFTNotRegistered(address nft);
    error ZeroParameter(string paramName);
}
// File: contracts\interfaces\ICapneoNFTImp.sol
interface ICapneoNFTImp {
    enum State {
        CLOSED,
        MINT_SEED,
        MINT_TOKEN,
        MINT_PUBLIC,
        MINT_SAFE_PAUSE,
        OFFCHAIN_INTERLUDE,
        OFFCHAIN_DISMISSED,
        ONGOING_ONGOING,
        ONGOING_SAFE_PAUSE,
        FINISHED
    }
    event StateChanged(address owner, State stateBefore, State stateAfter);
    event Deposit(address owner, uint256 amount);
    event NewContractURI(string uri);
    event NewNFTImage(string image);
    event Claim(address recipient, uint256 tokenId, uint256 amount);
    event MintInitial(address recipient, uint256 tokenId);
    event MintTransform(address recipient, uint256 tokenId, uint256 claimedAmount);
    event BurnTransform(uint256 tokenId);
    event BurnFinal(uint256 tokenId);
    error NotAuthorized(address caller, address want);
    error NotAllowedInState(State currentState);
    error AreaChanged(uint256 areaBefore, uint256 areaAfter);
    error TotalAreaExceeded(uint256 value, uint256 maximalArea);
    error AreaTooSmall(uint256 value, uint256 minimumValue);
    error MintNotAllowed(address minter, State currentState);
    error KycRequiredButInvalid(address who, bytes signature);
    error InsufficientFunds(uint256 have, uint256 need);
    error ZeroParameter(string parameter);
    function initialize(
        address admin,
        uint56 totalArea,
        uint56 minimumArea,
        uint56 pricePerArea,
        uint56 tokenAccessThresholdNoDecimals,
        uint16 dismissedPaybackRate,
        uint16 protocolFee,
        bool kycRequired
    ) external;
    function openseaFactoryMint(address to, uint256[] calldata tokenIds) external;
}
// File: @openzeppelin\contracts\utils\introspection\IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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
// File: @openzeppelin\contracts\token\ERC721\IERC721.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)
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
// File: @openzeppelin\contracts\token\ERC721\extensions\IERC721Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
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
// File: contracts\interfaces\IOpenseaFactory.sol
interface IOpenseaFactory {
    function numOptions() external view returns (uint256);
    function canMint(uint256 _optionId) external view returns (bool);
    function supportsFactoryInterface() external view returns (bool);
    function mint(uint256 _optionId, address _toAddress) external;
}
// File: @openzeppelin\contracts\utils\Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// File: @openzeppelin\contracts\access\Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
// File: contracts\utils\LibMintOptions.sol
library LibMintOptions {
    error tokenIdTooBig(uint256 tokenId, uint256 MAXIMUM);
    error nftIdTooBig(uint256 nftId, uint256 MAXIMUM);
    error tooManyTokens(uint256 amountOfTokens, uint256 MAXIMUM);
    error AmountIsZero();
    error flagTooBig(uint256 flag, uint256 MAXIMUM);
    /// 1111 1111
    uint256 private constant BITMASK_FLAG = type(uint8).max;
    /// 1111 1111 1111 1111 0000 0000 
    uint256 private constant BITMASK_NFT_ID = BITMASK_FLAG ^ type(uint24).max;
    /// 1111 1111 0000 0000 0000 0000 0000 0000
    uint256 private constant BITMASK_AMOUNT = type(uint32).max ^ type(uint24).max;
    uint256 private constant FLAG_OFFSET = 0;
    uint256 private constant NFT_ID_OFFSET = 8;    
    uint256 private constant AMOUNT_OFFSET = 24;
    uint256 private constant FIRST_TOKENID_OFFSET = 32;
    uint256 public constant MAXIMUM_AMOUNT = 7;
    uint256 public constant MAXIMUM_TOKEN_ID = type(uint32).max;
    uint256 public constant MAXIMUM_NFT_ID = type(uint16).max;
    uint256 public constant MAXIMUM_FLAG = type(uint8).max;
    function deconstructOption(uint256 _option) 
        internal
        pure
        returns(
            uint256 nftId,
            uint256[] memory,
            uint256 flag       
        ) 
    {
        nftId = (_option & BITMASK_NFT_ID) >> NFT_ID_OFFSET;
        uint256 amount = (_option & BITMASK_AMOUNT) >> AMOUNT_OFFSET;
        flag = (_option & BITMASK_FLAG);
        if(amount > MAXIMUM_AMOUNT) revert tooManyTokens(amount, MAXIMUM_AMOUNT);
        uint256[] memory tokenIds = new uint256[](amount);
        for(uint256 i = 0; i < amount; i++){
            _option >>= FIRST_TOKENID_OFFSET;
            tokenIds[i] = _option & MAXIMUM_TOKEN_ID;
        }
        return (nftId, tokenIds, flag);
    }
    function constructOption(
        uint256 nftId,
        uint256[] memory tokenIds,
        uint256 flag
    ) internal pure returns(uint256 _option) {
        uint256 amount = tokenIds.length;
        _checkParameters(nftId, flag, amount);
        _option = ((amount << AMOUNT_OFFSET) + (nftId << NFT_ID_OFFSET) + flag);
        for(uint256 i = 0; i < amount; i++) {
            if(tokenIds[i] > MAXIMUM_TOKEN_ID) revert tokenIdTooBig(tokenIds[i], MAXIMUM_TOKEN_ID);
            _option += (tokenIds[i] << ((i + 1) * FIRST_TOKENID_OFFSET));
        }
    }
    function _checkParameters(uint256 nftId, uint256 flag, uint256 amount) internal pure {
        if(amount == 0) revert AmountIsZero();
        if(nftId > MAXIMUM_NFT_ID) revert nftIdTooBig(nftId, MAXIMUM_NFT_ID);
        if(amount > MAXIMUM_AMOUNT) revert tooManyTokens(amount, MAXIMUM_AMOUNT);
        if(flag > MAXIMUM_FLAG) revert flagTooBig(flag, MAXIMUM_FLAG);
    }
}
// File: contracts\OpenseaFactory.sol
contract OpenseaFactory is IERC721Metadata, IOpenseaFactory, Ownable {
    using LibMintOptions for uint256;
    IRegistryFunctions public immutable REGISTRY;
//0x58807baD0B376efc12F5AD86aAc70E78ed67deaE polygon 
//0x1E0049783F008A0085193E00003D00cd54003c71 rinkeby
    address public conduit;
    constructor(IRegistryFunctions _registry, address _conduit) { 
        REGISTRY = _registry;
        conduit = _conduit;
    }
    function setConduit(address _conduit) public onlyOwner {
        conduit = _conduit;
    }
    function transferFrom(address, address to, uint256 _optionId) public override {
        mint(_optionId, to);
    }
    function emitEvents(uint256[] calldata enabled) public {
        uint256 length = enabled.length;
        do {
            emit Transfer(address(0), owner(), enabled[length - 1]);
            length--;
        } while(length > 0);
    }
    function name() public view override(IERC721Metadata) returns (string memory) {
        return "factory";
    }
    function symbol() public view override(IERC721Metadata) returns (string memory) {
        return "fctry";
    }
    function numOptions() external view override returns(uint256) {
        return type(uint256).max;
    }
    function canMint(uint256 _optionId) external view override returns (bool) {
        return true;
    }
    function supportsFactoryInterface() external view override returns (bool) {
        return true;
    }
    function mint(uint256 _optionId, address _toAddress) public override {        
        require(msg.sender == conduit || msg.sender == owner(), 
            string(
                abi.encodePacked(
                    "caller ", msg.sender, " is not the conduit")
            )
        );
        (uint256 nftId, uint256[] memory tokenIds, uint256 flag) = _optionId.deconstructOption();
        ICapneoNFTImp(
            REGISTRY.getNFTAddressByIndex(nftId)
        ).openseaFactoryMint(
            _toAddress, 
            tokenIds
        );
    }
    function getOption(address nft, uint256[] memory tokenIds, uint256 flag) external view returns(uint256 _option) {
        _option = REGISTRY.getIndexByNFTAddress(nft).constructOption(tokenIds, flag);
    }
    function tokenURI(uint256 tokenId) public view override(IERC721Metadata) returns(string memory) {
        return string(
            abi.encodePacked(
                string(
                    ""
                )
            )
        );
    }
    // register the IERC721 interface, so Opensea displays this contract like an NFT collection
    function supportsInterface(bytes4 interfaceId) public view override returns(bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }
    // pseudo ERC721 functions to not confuse opensea at any point
    function isApprovedForAll(address _owner, address _operator)
        public
        view override
        returns (bool)
    {
        if (
            (
                owner() == _owner 
                && 
                owner() == _operator
            ) 
                ||
            (
                owner() == _owner 
                &&
                conduit == _operator
            )
        ) return true;       
        return false;
    }
    function getApproved(uint256) public view override returns(address) {
        return address(conduit);
    }
    function ownerOf(uint256) public view override returns (address) {
        return owner();
    }
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) 
        external override { transferFrom(from, to, tokenId); }
    function safeTransferFrom(address from,address to,uint256 tokenId) 
        external override { transferFrom(from, to, tokenId); }
    function approve(address,uint256)public override {return;}
    function setApprovalForAll(address,bool) public override {return;}
    function balanceOf(address)public view override returns(uint256) { return 1; }
    function totalSupply() public view returns(uint256) { return 100; }
}