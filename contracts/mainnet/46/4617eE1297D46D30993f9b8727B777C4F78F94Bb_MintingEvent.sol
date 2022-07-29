// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title VenlyERC1155Interface
 * @dev Venly Smart Contract interface
 */
contract VenlyERC1155Interface {
  function usedIds(uint256) public returns (bool) {}
  function maxSupplyForType(uint256) public returns (uint256) {}
  function noTokensForType(uint256) public returns (uint256) {}
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) public {}
  function mintNonFungible(uint256 typeId, uint256 id, address account) public {}
}


/**
 * @title MintingEvent
 */
contract MintingEvent is Ownable, ERC1155Holder {

    address public venlyContract;
    uint256 public mintingPrice = 0.06 ether;
    uint256 public maxMintPerAccount = 1;
    uint256 public lastMintedTokenIdx = 0;
    uint256 public lastMintedTokenIdUsed = 1;

    TokenType[] public tokenTypes;

    bool public paused = true;

    mapping(address => uint256) private minterBalance;

    VenlyERC1155Interface venlySc;

    struct TokenType {
        uint256 id;
        uint256 maxSupply;
        uint256 supply;
    }

    event MintedToken(uint256 tokenTypeId, uint256 mintId, address to);
    event Withdrawal(uint amount);
    event Transfer(uint amount, address to);

    function setBaseContractAddress(address addr) external onlyOwner {
        venlyContract = addr;
        venlySc = VenlyERC1155Interface(addr);
    }

    function setTokenTypeIds(uint256[] memory ids, uint32[] memory maxSupplies, uint32[] memory supplies) external onlyOwner {
        require(ids.length > 0, "Ids must have a least one item");
        require(ids.length == maxSupplies.length && maxSupplies.length == supplies.length, "Must have same length between input arrays");
        for (uint i = 0; i < ids.length; i = unsafe_inc(i)) {
            TokenType memory tokenType = TokenType(ids[i], maxSupplies[i], supplies[i]);
            tokenTypes.push(tokenType);
        }
        if (lastMintedTokenIdx != 0) {
            lastMintedTokenIdx = 0;
        }
    }

    function setPaused(bool state) external onlyOwner {
        paused = state;
    }

    function setMintingPrice(uint256 price) external onlyOwner {
        require(price > 0, "Minting price must be > 0");
        mintingPrice = price;
    }

    function setMaxMintPerAccount(uint256 amount) external onlyOwner {
        require(amount > 0, "Max mint per account must be > 0");
        maxMintPerAccount = amount;
    }

    // optimize gaz cost with unchecked mechanism
    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked { return x + 1; }
    }

    function mintToken() external payable {
        require(paused == false, "Minting event is paused");
        require(msg.value >= mintingPrice, "Ether received must be > to minting price");
        require(minterBalance[msg.sender] < maxMintPerAccount, "Max amount of mint has been reached for this account");
        // optimize gaz cost with memory variables for read/write
        uint _lastMintedTokenIdx = lastMintedTokenIdx;
        uint _lastMintedTokenIdUsed = lastMintedTokenIdUsed;
        for (uint i = _lastMintedTokenIdx; i < tokenTypes.length; i = unsafe_inc(i)) {
            // sync with current supply
            tokenTypes[i].supply = venlySc.noTokensForType(tokenTypes[i].id);
            if (tokenTypes[i].supply < tokenTypes[i].maxSupply) {
                _lastMintedTokenIdx = i;
                 // search for available mint id
                while (venlySc.usedIds(_lastMintedTokenIdUsed)) {
                    _lastMintedTokenIdUsed = unsafe_inc(_lastMintedTokenIdUsed);
                }

                venlySc.mintNonFungible(tokenTypes[_lastMintedTokenIdx].id, _lastMintedTokenIdUsed, msg.sender);

                minterBalance[msg.sender] = unsafe_inc(minterBalance[msg.sender]);
                tokenTypes[_lastMintedTokenIdx].supply = tokenTypes[_lastMintedTokenIdx].supply + 1;
                lastMintedTokenIdUsed = _lastMintedTokenIdUsed;

                emit MintedToken(tokenTypes[_lastMintedTokenIdx].id, _lastMintedTokenIdUsed, msg.sender);
                return;
            }
        }
        revert("No more available tokens to mint");
    }

    function sendTokenToUser(uint tokenId, address to) external onlyOwner {
        venlySc.safeTransferFrom(address(this), to, tokenId, 1, "0x6c00000000000000000000000000000000000000000000000000000000000000");
    }

    
    function totalTokenTypes() public view returns (uint)  {
        return tokenTypes.length;
    }
    
    function availableMints() external view returns (uint256) {
        uint _lastMintedTokenIdx = lastMintedTokenIdx;
        uint _availableToMint = 0;
        for (uint i = _lastMintedTokenIdx; i < tokenTypes.length; i = unsafe_inc(i)) {
            _availableToMint = _availableToMint + tokenTypes[i].maxSupply - tokenTypes[i].supply;
        }
        return _availableToMint;
    }

    // Function to withdraw all Ether from this contract.
    function withdraw() external onlyOwner {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
        emit Withdrawal(amount);
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) external onlyOwner {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
        emit Transfer(_amount, _to);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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