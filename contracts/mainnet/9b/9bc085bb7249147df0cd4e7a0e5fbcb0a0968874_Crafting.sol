// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../ERC20/interface/IERC20Permit.sol";
import "../ERC1155/interface/ICraftable.sol";
import "../ERC1155/interface/IGameAsset.sol";

contract Crafting is Ownable, Pausable{

    event Deposited(address owner, uint256 tokenId);
    event Withdrawn(address owner, uint256 tokenId);
    event DepositedMutliple(address owner, uint256[] tokenIds, uint256[] amounts);
    event WithdrawnMutliple(address owner, uint256[] tokenIds, uint256[] amounts);

    bytes32 public constant CRAFT_TYPEHASH = keccak256("Craft(address owner,uint256 inToken,uint256 outToken,bool isVirtual,uint256 nonce,uint256 deadline)");
    bytes32 public constant DEPOSIT_TYPEHASH = keccak256("Deposit(address owner,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant MULTIPLE_DEPOSIT_TYPEHASH = keccak256("Deposit(address owner,uint256[] tokenIds,uint256[] amounts,uint256 nonce,uint256 deadline)");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(address owner,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant MULTIPLE_WITHDRAW_TYPEHASH = keccak256("Withdraw(address owner,uint256[] tokenIds,uint256[] amounts,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    uint256 internal constant _COLLECTION_MASK = uint256(type(uint32).max) << 224;

    mapping(address => uint256) public nonces;
    address public admin;
    address public payeeWallet;
    IERC20Permit public payoutToken;
    ICraftable public craftable;
    IGameAsset public gameasset;

    constructor(address _craftable, address _gameasset, address _payoutToken, address _payeeWallet){
        craftable = ICraftable(_craftable);
        gameasset = IGameAsset(_gameasset);
        payoutToken = IERC20Permit(_payoutToken);
        payeeWallet = _payeeWallet;

        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Crafting")),
                keccak256(bytes("2")),
                chainId,
                address(this)));
    }

    function craft(address from, uint256 inToken, uint256 outToken, uint256 value, bool isVirtual, uint256 deadline, uint8 v, bytes32 r, bytes32 s, uint8 v2, bytes32 r2, bytes32 s2) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        require(getCollectionId(inToken) == 0, "Crafting: invalid collection");
        
        uint256 nonce = nonces[from]++;
        bytes32 hashStruct = keccak256(abi.encode(CRAFT_TYPEHASH, from, inToken, outToken, isVirtual, nonce, deadline));
        
        require(verifySignature(admin, hashStruct, v2, r2, s2), "Crafting: wrong signature");
        payoutToken.permit(from, address(this), value, deadline, v, r, s);
        if(value > 0){
            payoutToken.transferFrom(from, payeeWallet, value);
        }

        craftable.craft(from, inToken, 1);

        if(isVirtual){
            emit Deposited(from, outToken);
        }else{
            gameasset.mint(from, outToken, 1, "0x00");
            emit Withdrawn(from, outToken);
        }
    }

    function deposit(address owner, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s, uint8 v2, bytes32 r2, bytes32 s2 ) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        
        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(DEPOSIT_TYPEHASH, owner, tokenId, nonce, deadline));

        require(verifySignature(admin, hashStruct, v2, r2, s2), "Crafting: wrong signature");

        gameasset.burnWithPermit(owner, tokenId, 1, deadline, v, r, s);
        emit Deposited(owner, tokenId);
    }

    function withdraw(address owner, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        
        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(WITHDRAW_TYPEHASH, owner, tokenId, nonce, deadline));

        require(verifySignature(admin, hashStruct, v, r, s), "Crafting: wrong signature");

        gameasset.mint(owner, tokenId, 1, "0x00");
        emit Withdrawn(owner, tokenId);
    }

    function depositBundle(address owner, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        require(getCollectionId(tokenId) == 1, "Crafting: invalid collection");

        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(DEPOSIT_TYPEHASH, owner, tokenId, nonce, deadline));

        require(verifySignature(admin, hashStruct, v, r, s), "Crafting: wrong signature");

        craftable.craft(owner, tokenId, 1);
        emit Deposited(owner, tokenId);
    }

     function depositMultipleBundles(address owner, uint256[] memory tokenIds, uint256[] memory amounts, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");

        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(MULTIPLE_DEPOSIT_TYPEHASH, owner, keccak256(abi.encodePacked(tokenIds)), keccak256(abi.encodePacked(amounts)), nonce, deadline));

        require(verifySignature(admin, hashStruct, v, r, s), "Crafting: wrong signature");

        for(uint256 i; i != tokenIds.length; i++){
            require(getCollectionId(tokenIds[i]) == 1, "Crafting: invalid collection");
            craftable.craft(owner, tokenIds[i], amounts[i]);
        }
        emit DepositedMutliple(owner, tokenIds, amounts);
    }

    function withdrawBundle(address owner, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        require(getCollectionId(tokenId) == 1, "Crafting: invalid collection");

        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(WITHDRAW_TYPEHASH, owner, tokenId, nonce, deadline));

        require(verifySignature(admin, hashStruct, v, r, s), "Crafting: wrong signature");

        craftable.mint(owner, tokenId, 1, "0x00");
        emit Withdrawn(owner, tokenId);
    }

    function withdrawMultipleBundles(address owner, uint256[] memory tokenIds, uint256[] memory amounts, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused{
        require(block.timestamp <= deadline, "Crafting: signature is expired");
        require(tokenIds.length == amounts.length, "Crafting: ids and amounts length mismatch");
        
        uint256 nonce = nonces[owner]++;
        bytes32 hashStruct = keccak256(abi.encode(MULTIPLE_WITHDRAW_TYPEHASH, owner, keccak256(abi.encodePacked(tokenIds)), keccak256(abi.encodePacked(amounts)), nonce, deadline));

        require(verifySignature(admin, hashStruct, v, r, s), "Crafting: wrong signature");

        for(uint256 i; i != tokenIds.length; i++){
            require(getCollectionId(tokenIds[i]) == 1, "Crafting: invalid collection");
        }
        craftable.mintBatch(owner, tokenIds, amounts, "0x00");
        emit WithdrawnMutliple(owner, tokenIds, amounts);
    }

    function verifySignature(address owner, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal view returns (bool){
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == owner);
    }

    function getCollectionId(uint256 id) public pure returns (uint256) {
        return (id & _COLLECTION_MASK) >> 224;
    }

    function setAdmin(address _admin) external onlyOwner{
        admin = _admin;
    }

    function setPayoutToken(address _payoutToken) external onlyOwner{
        payoutToken = IERC20Permit(_payoutToken);
    }

    function setPayeeWallet(address _payeeWallet) external onlyOwner{
        payeeWallet = _payeeWallet;
    }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Permit {
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

    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferWithPermit(
        address target, 
        address to, 
        uint256 value, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICraftable is IERC1155{
    function craft( address account, uint256 id, uint256 value) external;

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGameAsset{
    
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function burnWithPermit(address owner, uint256 id, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
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