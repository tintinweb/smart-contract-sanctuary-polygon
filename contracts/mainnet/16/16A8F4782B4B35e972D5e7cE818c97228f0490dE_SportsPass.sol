// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ERC721,
    ContextMixin,
    NativeMetaTransaction,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs.
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */
    Counters.Counter private _nextTokenId;
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public onlyOwner {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /**
     * @dev Mints count tokens to an address with a tokenURI
     * @param _to address of the future owner of the token
     */
    function mintBatch(address _to, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            mintTo(_to);
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param tokenId token to burn
     */
    function burn(uint256 tokenId) public onlyOwner {
        address owner_address = ERC721.ownerOf(tokenId);
        require(
            owner() == owner_address,
            "Contract Owner can only burn tokens owned by the owner"
        );
        _burn(tokenId);
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function baseTokenURI() public view virtual returns (string memory);

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions may not be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {EIP712Base} from './EIP712Base.sol';

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                'MetaTransaction(uint256 nonce,address from,bytes functionSignature)'
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            'Signer and signature do not match'
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, 'Function call not successful');

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), 'NativeMetaTransaction: INVALID_SIGNER');
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.6;

import {Initializable} from './Initializable.sol';

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = '1';

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                'EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)'
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * '\\x19' makes the encoding deterministic
     * '\\x01' is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked('\x19\x01', getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, 'already inited');
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import './ERC721Tradable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract SportsPass is ERC721Tradable, IERC2981 {
  address private _recipient;
  string public OPENSEA_STORE_METADATA = 'ipfs://bafkreigugk6gwcbwb25zvh7ekvunrduuiiuy2xle5ynmepfwcdja3lftbq';
  string public BASE_URI = 'ipfs://bafybeiao25n3euq4jekad6v5n5scjwt7lfgu2moawphvsoxgkivgbyosaa';

  constructor(address _proxyRegistryAddress, address recipient)
    ERC721Tradable('Sports Pass', 'SP', _proxyRegistryAddress)
  {
    _recipient = recipient;
  }

  function baseTokenURI() public view override returns (string memory) {
    return BASE_URI;
  }

  /**
   *  @dev Set metadata to make OpenSea happy
   */
  function setContractURI(string memory _contractMetadataURI) public onlyOwner {
    OPENSEA_STORE_METADATA = _contractMetadataURI;
  }

  /**
   *  @dev Get contract metadata to make OpenSea happy
   */
  function contractURI() public view returns (string memory) {
    return OPENSEA_STORE_METADATA;
  }

  /**
   *  @dev Set the IPFS baseURI, including ending `/` where JSON is located
   *  ipfs://QmRQ9mB8UDRd3adMndj5NGTD9ajbJYuSQkbdm5mVQFWVxN/
   */
  function setBaseURI(string memory baseURI) public onlyOwner {
    BASE_URI = baseURI;
  }

  // Maintain flexibility to modify royalties recipient (could also add basis points).
  function _setRoyalties(address newRecipient) internal {
    require(newRecipient != address(0), 'Royalties: new recipient is the zero address');
    _recipient = newRecipient;
  }

  function setRoyalties(address newRecipient) external onlyOwner {
    _setRoyalties(newRecipient);
  }

  // EIP2981 standard royalties return.
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    address _recipient_ = _tokenId <= 9 || (_tokenId >= 1001 && _tokenId <= 2000)
      ? address(0x7422E34b8Dfd6F62B092D357445faDe7e3f5196f)
      : _recipient;
    return (_recipient_, (_salePrice * 1000) / 10000);
  }

  // EIP2981 standard Interface return. Adds to ERC721 and ERC165 Interface returns.
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// openzeppelin version  4.3.3
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Destroyable.sol';

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, Pausable, Destroyable, Ownable {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) internal _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) internal _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  // Use a split bit implementation.
  // Store the type in the upper 128 bits..
  uint256 public constant MASK = type(uint128).max;

  uint256 public constant TYPE_MASK = uint256(MASK) << 128;

  // ..and the non-fungible index in the lower 128
  uint256 public constant NF_INDEX_MASK = uint128(MASK);

  // The top bit is a flag to tell if this is a NFI.
  uint256 public constant TYPE_NF_BIT = 1 << 255;

  mapping(uint256 => address) nfOwners;

  // onReceive function signatures
  bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;

  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  function isNonFungible(uint256 _id) public pure returns (bool) {
    return _id & TYPE_NF_BIT == TYPE_NF_BIT;
  }

  function isFungible(uint256 _id) public pure returns (bool) {
    return _id & TYPE_NF_BIT == 0;
  }

  function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
    return _id & NF_INDEX_MASK;
  }

  function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
    return _id & TYPE_MASK;
  }

  function isNonFungibleBaseType(uint256 _id) public pure returns (bool) {
    // A base type has the NF bit but does not have an index.
    return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
  }

  function isNonFungibleItem(uint256 _id) public pure returns (bool) {
    // A base type has the NF bit but does has an index.
    return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
  }

  function ownerOf(uint256 _id) public view virtual returns (address) {
    return nfOwners[_id];
  }

  /**
   * @dev See {_setURI}.
   */
  constructor(string memory uri_) {
    _setURI(uri_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    override
    whenNotDestroyed
    whenNotPaused
    returns (uint256)
  {
    require(account != address(0), 'ERC1155: balance query for the zero address');
    if (isNonFungibleItem(id)) return ownerOf(id) == account ? 1 : 0;
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    whenNotDestroyed
    whenNotPaused
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, 'ERC1155: accounts and ids length mismatch');

    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; ++i) {
      uint256 id = ids[i];
      if (isNonFungibleItem(id)) {
        batchBalances[i] = ownerOf(id) == accounts[i] ? 1 : 0;
      } else {
        batchBalances[i] = balanceOf(accounts[i], id);
      }
    }
    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override whenNotDestroyed whenNotPaused {
    require(_msgSender() != operator, 'ERC1155: setting approval status for self');

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override
    whenNotDestroyed
    whenNotPaused
    returns (bool)
  {
    if (operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
      return true;
    }
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), 'ERC1155: transfer to the zero address');
    address operator = _msgSender();
    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
    if (isNonFungible(id)) {
      require(nfOwners[id] == from, 'ERC1155: insufficient balance for transfer');
      nfOwners[id] = to;
    } else {
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] = _balances[id][to] + amount;
    }

    emit TransferSingle(operator, from, to, id, amount);
    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(to != address(0), 'ERC1155: transfer to the zero address');
    address operator = _msgSender();
    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), '');
    if (isNonFungible(id)) {
      require(nfOwners[id] == from, 'ERC1155: insufficient balance for transfer');
      nfOwners[id] = to;
    } else {
      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] = _balances[id][to] + amount;
    }

    emit TransferSingle(operator, from, to, id, amount);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');
    require(to != address(0), 'ERC1155: transfer to the zero address');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      if (isNonFungible(id)) {
        require(nfOwners[id] == from);
        nfOwners[id] = to;
      } else {
        uint256 fromBalance = _balances[id][from];
        uint256 toBalance = _balances[id][to];
        require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
        unchecked {
          _balances[id][from] = fromBalance - amount;
          _balances[id][to] = toBalance + amount;
        }
      }
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');
    require(to != address(0), 'ERC1155: transfer to the zero address');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, '');

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      if (isNonFungible(id)) {
        require(nfOwners[id] == from);
        nfOwners[id] = to;
      } else {
        uint256 fromBalance = _balances[id][from];
        uint256 toBalance = _balances[id][to];
        require(fromBalance >= amount, 'ERC1155: insufficient balance for transfer');
        unchecked {
          _balances[id][from] = fromBalance - amount;
          _balances[id][to] = toBalance + amount;
        }
      }
    }

    emit TransferBatch(operator, from, to, ids, amounts);
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * By this mechanism, any occurrence of the `\{id\}` substring in either the
   * URI or any of the amounts in the JSON file at said URI will be replaced by
   * clients with the token type ID.
   *
   * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
   * interpreted by clients as
   * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
   * for token type ID 0x4cce0.
   *
   * See {uri}.
   *
   * Because these URIs cannot be meaningfully represented by the {URI} event,
   * this function emits no events.
   */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(account != address(0), 'ERC1155: mint to the zero address');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    if (isNonFungibleItem(id)) {
      require(amount == 1, 'non fungible items can only have 1');
      nfOwners[id] = account;
    } else {
      _balances[id][account] = _balances[id][account] + amount;
    }

    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);

    emit TransferSingle(operator, address(0), account, id, amount);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), 'ERC1155: mint to the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 amount = amounts[i];
      uint256 id = ids[i];
      if (isNonFungibleItem(id)) {
        require(amount == 1, 'non fungible items can only have 1');
        nfOwners[id] = to;
      } else {
        _balances[id][to] = _balances[id][to] + amount;
      }
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `account`
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens of token type `id`.
   */
  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(account != address(0), 'ERC1155: burn from the zero address');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), '');
    if (isNonFungible(id)) {
      require(nfOwners[id] == account, 'ERC1155: burn amount exceeds balance');
      require(amount == 1, 'ERC1155: burn amount exceeds balance');
      delete nfOwners[id];
    } else {
      uint256 accountBalance = _balances[id][account];
      require(accountBalance >= amount, 'ERC1155: burn amount exceeds balance');
      unchecked {
        uint256 newBalance = accountBalance - amount;
        _balances[id][account] = newBalance;
      }
    }

    emit TransferSingle(operator, account, address(0), id, amount);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(account != address(0), 'ERC1155: burn from the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    address operator = _msgSender();

    _beforeTokenTransfer(operator, account, address(0), ids, amounts, '');

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      if (isNonFungible(id)) {
        require(nfOwners[id] == account, 'ERC1155: burn amount exceeds balance');
        require(amount == 1, 'ERC1155: burn amount exceeds balance');
        delete nfOwners[id];
      } else {
        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, 'ERC1155: burn amount exceeds balance');
        unchecked {
          uint256 newBalance = accountBalance - amount;
          _balances[id][account] = newBalance;
        }
      }
    }

    emit TransferBatch(operator, account, address(0), ids, amounts);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Destroyable is Context {
  /**
   * @dev Emitted when the destroyed is triggered by `account`.
   */
  event Destroyed(address account);

  bool private _destroyed;

  /**
   * @dev Initializes the contract in undestroyed state.
   */
  constructor() {
    _destroyed = false;
  }

  /**
   * @dev Returns true if the contract is destroyed, and false otherwise.
   */
  function destroyed() public view virtual returns (bool) {
    return _destroyed;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not destroyed.
   *
   * Requirements:
   *
   * - The contract must not be destroyed.
   */
  modifier whenNotDestroyed() {
    require(!destroyed(), 'Pausable: paused');
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be destroyed.
   */
  function _destroy() internal virtual whenNotDestroyed {
    _destroyed = true;
    emit Destroyed(_msgSender());
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import './ERC1155.sol';

import './MetaTransactions.sol';

abstract contract NFTOneofExtention is ERC1155, ContextMixin, NativeMetaTransaction, ReentrancyGuard {
  string public name;
  mapping(uint256 => string) internal _tokenURIs;
  mapping(uint256 => uint256) private _totalSupply;
  mapping(address => bool) private _creatorsApprovals;
  uint256 public nonce;
  uint256 public constant POWER_MINT_BIT = 1 << 254;
  mapping(uint256 => mapping(address => bool)) public minters;
  mapping(uint256 => PowerMintValue) public power_mints;
  event ApprovalForMinter(address indexed account, bool approved);
  event PowerMint(address account, uint256 _type, uint256 amount, string uri);

  struct PowerMintValue {
    address owner;
    string metadata;
    uint256 amount;
  }

  constructor(string memory name_) {
    name = name_;
    _initializeEIP712(name);
  }

  modifier mintersOnly(uint256 _id) {
    require(
      minters[_id][msg.sender] == true || (_msgSender() == owner() && minters[_id][address(0x0)] == true), // only approve owner if type exist
      'mintersOnly: caller is not an approved minter'
    );
    _;
  }

  modifier onlyCreator() {
    require(isCreator(_msgSender()) || _msgSender() == owner(), 'onlyCreator: caller is not an approved creator');
    _;
  }

  modifier nonFungibleItemOnly(uint256 _id) {
    require(
      isNonFungibleItem(_id), // only approve  NFT
      'nonFungibleItemOnly: id is not for Non fungible item'
    );
    _;
  }

  function _msgSender() internal view override returns (address sender) {
    return ContextMixin.msgSender();
  }

  function isPowerMinted(uint256 _id) public pure returns (bool) {
    return _id & POWER_MINT_BIT == POWER_MINT_BIT;
  }

  function totalSupply(uint256 id) public view virtual whenNotDestroyed whenNotPaused returns (uint256) {
    if (isNonFungibleItem(id)) {
      return ownerOf(id) != address(0) ? 1 : 0;
    }
    return _totalSupply[id];
  }

  /**
   * @dev Indicates weither any token exist with a given id, or not.
   */
  function exists(uint256 id) public view virtual whenNotDestroyed whenNotPaused returns (bool) {
    return totalSupply(id) > 0;
  }

  function typeExists(uint256 id) public view virtual whenNotDestroyed whenNotPaused returns (bool) {
    return minters[id][address(0x0)] == true;
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */

  function setCreator(address operator, bool approved) public virtual onlyOwner whenNotDestroyed whenNotPaused {
    _creatorsApprovals[operator] = approved;
  }

  function isCreator(address account) public view virtual whenNotDestroyed whenNotPaused returns (bool) {
    return _creatorsApprovals[account] || account == owner();
  }

  function setMinter(
    uint256 _type,
    address operator,
    bool approved
  ) public virtual onlyOwner mintersOnly(_type) whenNotDestroyed whenNotPaused {
    // no need to check if this is a nf type, creatorOnly() will only let a nf type pass through.
    minters[_type][operator] = approved;
  }

  function initPowerMintingEnabledType(uint256 amount, string memory _uri)
    public
    onlyCreator
    whenNotDestroyed
    whenNotPaused
    returns (uint256 _type)
  {
    // Store the type in the upper 128 bits
    _type = (++nonce << 128);

    // Set a flag if this is an NFI.
    _type = _type | TYPE_NF_BIT | POWER_MINT_BIT;

    // This will allow restricted access to creators.
    minters[_type][msg.sender] = true;
    // this will allow contract to check if the type exist at all
    minters[_type][address(0x0)] = true;

    // emit a Transfer event with Create semantic to help with discovery.
    emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);

    if (bytes(_uri).length > 0) {
      _setURI(_type, _uri);
    }

    PowerMintValue memory value = PowerMintValue(msg.sender, _uri, amount);
    power_mints[_type] = value;
    emit PowerMint(msg.sender, _type, amount, _uri);
  }

  // This function only creates the type.
  function createMixedFungibleType(string memory _uri, bool _isNF)
    public
    onlyCreator
    whenNotDestroyed
    whenNotPaused
    returns (uint256 _type)
  {
    // Store the type in the upper 128 bits
    _type = (++nonce << 128);

    // Set a flag if this is an NFI.
    if (_isNF) _type = _type | TYPE_NF_BIT;

    // This will allow restricted access to creators.
    minters[_type][msg.sender] = true;
    // this will allow contract to check if the type exist at all
    minters[_type][address(0x0)] = true;

    // emit a Transfer event with Create semantic to help with discovery.
    emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);

    if (bytes(_uri).length > 0) {
      _setURI(_type, _uri);
    }
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    if (isPowerMinted(id) && !exists(id) && bytes(NFTOneofExtention._tokenURIs[id]).length == 0) {
      uint256 _type = getNonFungibleBaseType(id);
      require(
        minters[_type][msg.sender] == true || _msgSender() == owner(),
        'ERC1155: caller is not owner nor approved'
      );
      require(amount == 1, 'ERC1155: insufficient balance for transfer');
      require(typeExists(_type), 'ERC1155: insufficient balance for transfer');
      PowerMintValue memory power_mint = power_mints[_type];
      require(getNonFungibleIndex(id) <= power_mint.amount, 'ERC1155: insufficient balance for transfer');
      require(
        !(power_mint.owner == address(0) && power_mint.amount == 0 && bytes(power_mint.metadata).length == 0),
        'ERC1155: insufficient balance for transfer'
      );

      _mint(to, id, 1, '');
      NFTOneofExtention._setURI(id, power_mint.metadata);
      return;
    }
    require(from == _msgSender() || isApprovedForAll(from, _msgSender()), 'ERC1155: caller is not owner nor approved');

    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];
      if (isPowerMinted(id) && !exists(id) && bytes(NFTOneofExtention._tokenURIs[id]).length == 0) {
        uint256 _type = getNonFungibleBaseType(id);
        require(
          minters[_type][msg.sender] == true || _msgSender() == owner(),
          'ERC1155: caller is not owner nor approved'
        );
        require(amount == 1, 'ERC1155: insufficient balance for transfer');
        require(typeExists(_type), 'ERC1155: insufficient balance for transfer');
        PowerMintValue memory power_mint = power_mints[_type];
        require(getNonFungibleIndex(id) <= power_mint.amount, 'ERC1155: insufficient balance for transfer');
        require(
          !(power_mint.owner == address(0) && power_mint.amount == 0 && bytes(power_mint.metadata).length == 0),
          'ERC1155: insufficient balance for transfer'
        );

        _mint(from, id, 1, '');
        NFTOneofExtention._setURI(id, power_mint.metadata);
      }
    }
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'ERC1155: transfer caller is not owner nor approved'
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function transferOwnership(address newOwner) public virtual override onlyOwner whenNotDestroyed whenNotPaused {
    super.transferOwnership(newOwner);
  }

  function renounceOwnership() public virtual override onlyOwner whenNotDestroyed whenNotPaused {
    super.renounceOwnership();
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */

  function ownerOf(uint256 _id)
    public
    view
    virtual
    override
    whenNotDestroyed
    whenNotPaused
    nonFungibleItemOnly(_id)
    returns (address)
  {
    address owner = super.ownerOf(_id);
    //  if a power minted token has not been selected before _tokenURIs[_id] will be empty
    if (owner == address(0) && isPowerMinted(_id) && bytes(_tokenURIs[_id]).length != 0) {
      uint256 _type = getNonFungibleBaseType(_id);
      PowerMintValue memory power_mint = power_mints[_type];

      if (
        !(power_mint.owner == address(0) &&
          power_mint.amount == 0 &&
          bytes(power_mint.metadata).length == 0 &&
          getNonFungibleIndex(_id) > power_mint.amount)
      ) {
        return power_mint.owner;
      }
    }
    return owner;
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual whenNotDestroyed whenNotPaused {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'ERC1155: caller is not owner nor approved'
    );

    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual whenNotDestroyed whenNotPaused {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      'ERC1155: caller is not owner nor approved'
    );

    _burnBatch(account, ids, values);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override whenNotDestroyed whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        if (isFungible(id)) {
          _totalSupply[id] += amounts[i];
        }
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        if (isFungible(id)) {
          _totalSupply[id] -= amounts[i];
        }
      }
    }
  }

  function _setURI(uint256 tokenId, string memory _tokenURI) internal virtual whenNotDestroyed whenNotPaused {
    _tokenURIs[tokenId] = _tokenURI;
    emit URI(_tokenURI, tokenId);
  }

  function uri(uint256 tokenId) public view virtual override whenNotDestroyed whenNotPaused returns (string memory) {
    string memory _tokenURI = _tokenURIs[tokenId];

    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }

    if (isNonFungibleItem(tokenId)) {
      uint256 _type = getNonFungibleBaseType(tokenId);

      string memory _typeURI = _tokenURIs[_type];
      if (bytes(_typeURI).length > 0) {
        return _typeURI;
      }
    }

    return super.uri(tokenId);
  }

  function pause(bool pause_) public virtual onlyOwner whenNotDestroyed {
    if (pause_) {
      _pause();
    } else {
      _unpause();
    }
  }

  function destroy() public virtual onlyOwner whenNotPaused {
    _destroy();
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

abstract contract ReentrancyGuard {
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
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

abstract contract ContextMixin {
  function msgSender() internal view returns (address payable sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = payable(msg.sender);
    }
    return sender;
  }
}

contract Initializable {
  bool inited = false;

  modifier initializer() {
    require(!inited, 'already inited');
    _;
    inited = true;
  }
}

// File: contracts/common/meta-transactions/EIP712Base.sol

contract EIP712Base is Initializable {
  struct EIP712Domain {
    string name;
    string version;
    address verifyingContract;
    bytes32 salt;
  }

  string public constant ERC712_VERSION = '1';

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(bytes('EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)'));
  bytes32 internal domainSeperator;

  // supposed to be called once while initializing.
  // one of the contracts that inherits this contract follows proxy pattern
  // so it is not possible to do this in a constructor
  function _initializeEIP712(string memory name) internal initializer {
    _setDomainSeperator(name);
  }

  function _setDomainSeperator(string memory name) internal {
    domainSeperator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(ERC712_VERSION)),
        address(this),
        bytes32(getChainId())
      )
    );
  }

  function getDomainSeperator() public view returns (bytes32) {
    return domainSeperator;
  }

  function getChainId() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
    return keccak256(abi.encodePacked('\x19\x01', getDomainSeperator(), messageHash));
  }
}

contract NativeMetaTransaction is EIP712Base {
  bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(bytes('MetaTransaction(uint256 nonce,address from,bytes functionSignature)'));
  event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
  mapping(address => uint256) nonces;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) external payable returns (bytes memory) {
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(verify(userAddress, metaTx, sigR, sigS, sigV), 'Signer and signature do not match');

    // increase nonce for user (to avoid re-use)
    nonces[userAddress] += 1;

    emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

    // Append userAddress and relayer address at the end to extract it from calling context
    (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
    require(success, 'Function call not successful');

    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
    return
      keccak256(abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature)));
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address signer,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    require(signer != address(0), 'NativeMetaTransaction: INVALID_SIGNER');
    return signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import './NFTOneofExtention.sol';

contract NFTOneof is NFTOneofExtention {
  mapping(uint256 => uint256) maxIndex;

  struct Mint {
    bool isNft;
    uint256 amount;
    uint256 _type;
    string metadata;
  }

  struct Tx {
    address to_;
    uint256 token_id;
    uint256 amount;
  }

  struct Transfer {
    address from_;
    Tx[] txs;
  }

  struct PowerMintSelect {
    uint256 token_id;
    address recipient;
  }

  constructor(string memory _uri, string memory _name) ERC1155(_uri) NFTOneofExtention(_name) {}

  function mintBatch(
    address _to,
    Mint[] calldata requests,
    bytes calldata _data
  ) public onlyCreator whenNotDestroyed whenNotPaused nonReentrant {
    uint256 count = 0;
    for (uint256 i = 0; i < requests.length; i++) {
      Mint memory mint = requests[i];
      if (!mint.isNft) {
        ++count;
      } else {
        count = count + mint.amount;
      }
    }
    uint256[] memory ids = new uint256[](count);
    uint256[] memory amounts = new uint256[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < requests.length; i++) {
      Mint memory mint = requests[i];
      uint256 _type;
      if (mint._type == 0) {
        _type = createMixedFungibleType(mint.metadata, mint.isNft);
      } else {
        require(typeExists(mint._type), 'mintBatch: token type does not exist');
        require(
          !(isFungible(mint._type) && bytes(mint.metadata).length == 0),
          'mintBatch: cannot set metadata for an existing fungible token '
        );
        _type = mint._type;
      }

      if (isFungible(_type)) {
        ids[index] = _type;
        amounts[index] = mint.amount;
        ++index;
      } else {
        uint256[] memory mintIds = getNonFungibleItems(_type, mint.amount);
        for (uint256 j = 0; j < mintIds.length; j++) {
          ids[index] = mintIds[j];
          amounts[index] = 1;
          ++index;
          if ((mint._type != 0 || mintIds.length == 1) && bytes(mint.metadata).length > 0) {
            NFTOneofExtention._setURI(mintIds[j], mint.metadata);
          }
        }
      }
    }
    _mintBatch(_to, ids, amounts, _data);
  }

  function powerMint(uint256[] memory counts, string[] memory metadataURIs)
    public
    onlyCreator
    whenNotDestroyed
    whenNotPaused
    nonReentrant
    returns (uint256[] memory)
  {
    require(counts.length == metadataURIs.length, 'PowerMint: counts and metadataURIs length mismatch here');
    uint256[] memory _types = new uint256[](counts.length);
    for (uint256 i = 0; i < counts.length; i++) {
      uint256 _type = initPowerMintingEnabledType(counts[i], metadataURIs[i]);
      _types[i] = _type;
    }
    return _types;
  }

  function select(PowerMintSelect[] memory requests) public onlyCreator whenNotDestroyed whenNotPaused nonReentrant {
    for (uint256 i = 0; i < requests.length; i++) {
      PowerMintSelect memory request = requests[i];
      require(isNonFungibleItem(request.token_id), 'Select: token must be non fungible');
      require(isPowerMinted(request.token_id), 'Select: token must be a powerminted type');
      require(
        !exists(request.token_id) && bytes(NFTOneofExtention._tokenURIs[request.token_id]).length == 0,
        'Select: token already exist'
      );
      uint256 _type = getNonFungibleBaseType(request.token_id);
      require(typeExists(_type), 'Select: token type does not exist');
      PowerMintValue memory power_mint = power_mints[_type];
      require(getNonFungibleIndex(request.token_id) <= power_mint.amount, 'Select: Token is out of bounds');
      require(
        !(power_mint.owner == address(0) && power_mint.amount == 0 && bytes(power_mint.metadata).length == 0),
        'Select: token undefined'
      );
      require(
        minters[_type][msg.sender] == true || _msgSender() == owner(),
        'Select: caller is not an approved minter'
      );
      _mint(request.recipient, request.token_id, 1, '');
      NFTOneofExtention._setURI(request.token_id, power_mint.metadata);
    }
  }

  function transfer(Transfer[] memory requests) public whenNotDestroyed whenNotPaused {
    for (uint256 i = 0; i < requests.length; i++) {
      Transfer memory request = requests[i];
      Tx[] memory txs = request.txs;
      for (uint256 j = 0; j < txs.length; j++) {
        Tx memory tx_ = txs[j];
        safeTransferFrom(request.from_, tx_.to_, tx_.token_id, tx_.amount, '');
      }
    }
  }

  function getNonFungibleItems(uint256 _type, uint256 amount)
    internal
    mintersOnly(_type)
    returns (uint256[] memory mints)
  {
    // No need to check this is a nf type rather than an id since
    // creatorOnly() will only let a type pass through.
    require(isNonFungible(_type));

    // Index are 1-based.
    uint256 index = maxIndex[_type] + 1;
    maxIndex[_type] = amount + maxIndex[_type];
    mints = new uint256[](amount);

    for (uint256 i = 0; i < amount; ++i) {
      uint256 id = _type | (index + i);
      mints[i] = id;
      // You could use base-type id to store NF type balances if you wish.
      // balances[_type][dst] = quantity.add(balances[_type][dst]);
    }
    return mints;
  }
}