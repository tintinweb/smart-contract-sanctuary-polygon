/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/* Library */

library Strings {

    // DATA

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    
    uint8 private constant _ADDRESS_LENGTH = 20;

    
    // FUNCTION

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }

}

library Math {

    // DATA

    enum Rounding {
        Down,
        Up,
        Zero
    }


    // FUNCTION

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0;
            uint256 prod1;
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            if (prod1 == 0) {
                return prod0 / denominator;
            }

            require(denominator > prod1, "Math: mulDiv overflow");

            uint256 remainder;
            assembly {
                remainder := mulmod(x, y, denominator)

                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            uint256 twos = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, twos)

                prod0 := div(prod0, twos)

                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            uint256 inverse = (3 * denominator) ^ 2;

            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
            return result;
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 result = 1 << (log2(a) >> 1);

        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }

}

library SignedMath {

    // FUNCTION

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function average(int256 a, int256 b) internal pure returns (int256) {
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

}

abstract contract Context {

    // FUNCTION

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

}

/* Interface */ 

interface IERC165 {

    // FUNCTION

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

interface IERC721Receiver {
    
    // FUNCTION

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);

}

interface IERC721 is IERC165 {
    
    // EVENT

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    // FUNCTION

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

}

interface IERC721Metadata is IERC721 {

    // FUNCTION

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

}

interface IERC20 {
    
    // EVENT 

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    
    // FUNCTION

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

interface IERC4906 is IERC165, IERC721 {

    // EVENT

    event MetadataUpdate(uint256 _tokenId);
    
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

}

/* ERC Standard */

abstract contract ERC165 is IERC165 {

    // FUNCTION

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    // LIBRARY

    using Strings for uint256;


    // DATA

    string private _name;
    string private _symbol;


    // MAPPING

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;


    // CONSTRUCTOR

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    // FUNCTION

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        owner = ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;

        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

}

abstract contract ERC721Burnable is Context, ERC721 {
    
    // FUNCTION

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

}

abstract contract ERC721URIStorage is IERC4906, ERC721 {

    // LIBRARY

    using Strings for uint256;


    // MAPPING

    mapping(uint256 => string) private _tokenURIs;


    // FUNCTION

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

}

abstract contract ReentrancyGuard {

    // DATA

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    
    // MODIFIER

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }


    // CONSTRUCTOR

    constructor() {
        _status = _NOT_ENTERED;
    }
}

/* Access */

abstract contract Ownable is Context {
    
    // DATA

    address private _owner;


    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier authorized() {
        require(isAuthorized(_msgSender()), "Ownable: caller is not an authorized account");
        _;
    }


    // MAPPING

    mapping(address => bool) internal authorizations;

    
    // CONSTRUCTOR

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
        authorizations[initialOwner] = true;
        authorizations[msg.sender] = true;
    }


    // EVENT

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address adr) public view returns (bool) {
        return adr == owner();
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

/* Security */

abstract contract Pausable is Context {

    // DATA
    
    bool private _paused;


    // MODIFIER

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    
    // CONSTRUCTOR

    constructor() {
        _paused = false;
    }


    // EVENT

    event Paused(address account);

    event Unpaused(address account);


    // FUNCTION

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

}

/* Bebuzee NFP */

contract BebuzeeNFP is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    
    // LIBRARY

    using Strings for uint256;


    // DATA

    struct Meta {
        uint8 postType;
        uint256 dateAdded;
        uint256 dateUpdated;
        string postContent;
        string postImage;
        string displayImage;
        string profileImage;
        string username;
        string name;
        string uriToken;
    }

    string public uri = "";
    
    uint256 public postMaxLength = 200;
    uint256 public tokenIdCounter = 0;
    uint256 public mintPrice = 0;

    address public feeReceiver;
    address public feeCurrency;

    bool public freeMint = false;


    // MAPPING
    
    mapping(uint256 => Meta) public idToMetadata;


    // MODIFIER

    modifier onlyOwnerOrFeeReceiver() {
        require(owner() == _msgSender() || feeReceiver == _msgSender(), "Caller is not the owner or fee receiver.");
        _;
    }


    // CONSTRUCTOR

    constructor() Ownable(_msgSender()) ERC721("BebuzeeNFP", "XBZNFP") {
        feeReceiver = _msgSender();
    }


    // EVENT

    event EtherTransfer(address beneficiary, uint256 amount);

    event UpdateFeeReceiver(address oldReceiver, address newReceiver, address caller, uint256 timestamp);

    event SetFreeMint(bool oldStatus, bool newStatus, uint256 timestamp);

    // FUNCTION

    /* General */

    receive() external payable {} 

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }
    
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function wTokens(address tokenAddress, uint256 amount) external {
        uint256 toTransfer = amount;
        if (tokenAddress == address(0)) {
            if (amount == 0) {
                toTransfer = address(this).balance;
            }
            payable(owner()).transfer(toTransfer);
        } else {
            if (amount == 0) {
                toTransfer = IERC20(tokenAddress).balanceOf(address(this));
            }
            require(
                IERC20(tokenAddress).transfer(
                    feeReceiver,
                    toTransfer
                ),
                "WithdrawTokens: Transfer transaction might fail."
            );
        }
    }

    /* Check */

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    /* Update */

    function updateFeeReceiver(address newReceiver) external onlyOwnerOrFeeReceiver {
        require(newReceiver != address(0), "Cannot set fee receiver as null address.");
        require(newReceiver != address(0xdead), "Cannot set fee receiver as dead address.");
        require(newReceiver != feeReceiver, "Cannot set fee receiver as current receiver address.");
        address oldReceiver = feeReceiver;
        feeReceiver = newReceiver;
        emit UpdateFeeReceiver(oldReceiver, newReceiver, _msgSender(), block.timestamp);
    }

    function setFreeMint(bool newStatus) external onlyOwner {
        require(freeMint != newStatus, "This is the current value for free mint.");
        bool oldStatus = freeMint;
        freeMint = newStatus;
        emit SetFreeMint(oldStatus, newStatus, block.timestamp);
    }

    /* Payment */

    function takePayment(address tokenAddress) internal {
        if (tokenAddress == address(0)) {
            payable(feeReceiver).transfer(mintPrice);
        } else {
            require(
                IERC20(tokenAddress).transferFrom(
                    _msgSender(),
                    feeReceiver,
                    mintPrice
                ),
                "WithdrawTokens: Transfer transaction might fail."
            );
        }
    }

    /* Bebuzee NFP */

    function safeMint(
        uint8 types,
        string memory content,
        string memory imagePost,
        string memory imageDisplay,
        string memory imageProfile,
        string memory usernameStr,
        string memory nameStr
    ) external {
        if (!freeMint) {
            takePayment(feeCurrency);
        }
        _safeMint(_msgSender(), types, content, imagePost, imageDisplay, imageProfile, usernameStr, nameStr);
    }

    function ownerOnlySafeMint(
        uint8 types,
        string memory content,
        string memory imagePost,
        string memory imageDisplay,
        string memory imageProfile,
        string memory usernameStr,
        string memory nameStr
    ) external onlyOwner {
        _safeMint(_msgSender(), types, content, imagePost, imageDisplay, imageProfile, usernameStr, nameStr);
    }

    function _safeMint(
        address to,
        uint8 types,
        string memory content,
        string memory imagePost,
        string memory imageDisplay,
        string memory imageProfile,
        string memory usernameStr,
        string memory nameStr
    ) internal {
        string memory tokenUri = string(abi.encodePacked(uri, tokenIdCounter.toString()));
        tokenIdCounter += 1;
        Meta memory metadata = Meta({
            postType: types,
            dateAdded: block.timestamp,
            dateUpdated: block.timestamp,
            postContent: content,
            postImage: imagePost,
            displayImage: imageDisplay,
            profileImage: imageProfile,
            username: usernameStr,
            name: nameStr,
            uriToken: tokenUri
        });
        idToMetadata[tokenIdCounter] = metadata;
        _safeMint(to, tokenIdCounter);
        _setTokenURI(tokenIdCounter, tokenUri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

/* Marketplace */

contract Marketplace is Ownable, Pausable, ReentrancyGuard {    
    
    // DATA

    uint256 public itemsID;
    uint256 public itemsSold;
    uint256 public itemsCanceled;
    
    address public constant ZERO = address(0);

    address public feeReceiver;

    uint256 public collectionNumberInMarket = 0;
    uint256 public saleTax = 250;
    uint256 public saleTaxDenominator = 10000;

    address[] public collectionInMarket;

    struct MarketItem {
        uint256 itemID;
        address contractNFT;
        uint256 tokenID;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
     
    
    // MAPPING

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(address => mapping(uint256 => uint256)) public getItemIDForSpecificNFT;
    mapping(address => uint256) public collectionAmountOnSale;
    mapping(address => uint256) public collectionInMarketID;
     
    
    // CONSTRUCTOR

    constructor(
        address receiver
    ) Ownable (_msgSender()) {
        feeReceiver = receiver;
    }


    // EVENT

    event MarketItemCreated (uint256 indexed _itemID, address indexed _contractNFT, uint256 indexed _tokenID, address _seller, address _owner, uint256 _price, bool _sold);
    event MarketItemSold (uint256 indexed _itemID, address _owner);
    event MarketItemCanceled (uint256 indexed _itemID, address _owner);
    event ChangeFeeReceiver (address _caller, address _prevFeeReceiver, address _newFeeReceiver);
    event SetSaleTax (address _caller, uint256 _prevSaleTax, uint256 _newSaleTax, uint256 _prevSaleTaxDenominator, uint256 _newSaleTaxDenominator);
    

    // FUNCTION

    /* General */

    receive() external payable {}

    function pause() external whenNotPaused authorized {
        _pause();
    }
    
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function wTokens(address tokenAddress, uint256 amount) external {
        uint256 toTransfer = amount;
        if (tokenAddress == address(0)) {
            if (amount == 0) {
                toTransfer = address(this).balance;
            }
            payable(owner()).transfer(toTransfer);
        } else {
            if (amount == 0) {
                toTransfer = IERC20(tokenAddress).balanceOf(address(this));
            }
            require(
                IERC20(tokenAddress).transfer(
                    feeReceiver,
                    toTransfer
                ),
                "WithdrawTokens: Transfer transaction might fail."
            );
        }
    }

    /* Update */
    
    function changeFeeReceiver(address newReceiver) external onlyOwner {
        require(feeReceiver != newReceiver, "This is the current fee receiver address!");
        address oldReceiver = feeReceiver;
        feeReceiver = newReceiver;
        emit ChangeFeeReceiver(_msgSender(), oldReceiver, newReceiver);
    }

    function setSaleTax(uint256 newTax, uint256 newTaxDenominator) external onlyOwner {
        require(saleTax != newTax, "This is the current sale tax!!");
        require(newTax <= newTaxDenominator / 5, "Sale tax cannot exceed 20%!!");
        uint256 oldTax = saleTax;
        uint256 oldTaxDenominator = saleTaxDenominator;
        saleTax = newTax;
        saleTaxDenominator = newTaxDenominator;
        emit SetSaleTax(_msgSender(), oldTax, saleTax, oldTaxDenominator, saleTaxDenominator);
    }
    
    /* Check */

    function getItemIDForNFT(address contractNFT, uint256 tokenID) public view returns (uint256) {
        return getItemIDForSpecificNFT[contractNFT][tokenID];
    }

    /* Check Market */
    
    function fetchUserMarketItems(address user, uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items;
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].seller == user) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return items;
                }
            }
        }

        return items;
    }
    
    function fetchUserMarketItemsUnsold(address user, uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items;
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].seller == user && idToMarketItem[i + 1].owner == ZERO) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return items;
                }
            }
        }

        return items;
    }
    
    function fetchUserMarketItemsSold(address user, uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items;
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].seller == user && idToMarketItem[i + 1].owner != ZERO && idToMarketItem[i + 1].owner != idToMarketItem[i + 1].seller) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return items;
                }
            }
        }

        return items;
    }
    
    function fetchUserMarketItemsCanceled(address user, uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items;
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].seller == user && idToMarketItem[i + 1].owner != ZERO && idToMarketItem[i + 1].owner == idToMarketItem[i + 1].seller) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return items;
                }
            }
        }

        return items;
    }
    
    function fetchMarketItems(uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory, uint256 totalUnsold) {
        
        uint256 _unsoldItemCount = itemsID - itemsSold - itemsCanceled;
        uint256 _currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](_unsoldItemCount);
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].owner == ZERO) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return (items, _unsoldItemCount);
                }
            }
        }

        return (items, _unsoldItemCount);
    }
    
    function fetchMarketItemsSold(uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory, uint256 totalSold) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemsSold);
        
        for (uint256 i = 0; i < itemsID; i++) {
            if (idToMarketItem[i + 1].owner != ZERO && idToMarketItem[i + 1].owner != idToMarketItem[i + 1].seller) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return (items, itemsCanceled);
                }
            }
        }

        return (items, itemsCanceled);
    }
    
    function fetchMarketItemsCancelled(uint256 startIndex, uint256 endIndex) public view returns (MarketItem[] memory, uint256 totalCancelled) {
        
        uint256 _currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemsCanceled);
        
        for (uint256 i = 0; i < itemsID; i++) {
            if ( idToMarketItem[i + 1].owner != ZERO && idToMarketItem[i + 1].owner == idToMarketItem[i + 1].seller) {
                if (startIndex <= _currentIndex) {
                    uint256 currentID = i + 1;
                    MarketItem storage currentItem = idToMarketItem[currentID];
                    items[_currentIndex] = currentItem;
                }
                _currentIndex += 1;
                if (endIndex < _currentIndex) {
                    return (items, itemsCanceled);
                }
            }
        }

        return (items, itemsCanceled);
    }

    /* Market Transaction */

    function createMarketItem(address contractNFT, uint256 tokenID, uint256 price) public payable whenNotPaused nonReentrant {
        require(price > 0, "Price must be greater than 0!");

        itemsID += 1;

        idToMarketItem[itemsID] =  MarketItem(itemsID, contractNFT, tokenID, payable(_msgSender()), payable(ZERO), price, false);
        getItemIDForSpecificNFT[contractNFT][tokenID] = itemsID;

        IERC721(contractNFT).transferFrom(_msgSender(), address(this), tokenID);

        if (collectionAmountOnSale[contractNFT] < 1) {
            collectionInMarketID[contractNFT] = collectionNumberInMarket + 1;
            collectionInMarket.push(contractNFT);
        }
        collectionAmountOnSale[contractNFT] += 1;

        emit MarketItemCreated(itemsID, contractNFT,  tokenID, _msgSender(), ZERO, price, false);
    }

    function createMarketSale(address contractNFT, uint256 itemID) public payable whenNotPaused nonReentrant {   
        uint256 _price = idToMarketItem[itemID].price;
        uint256 _tokenID = idToMarketItem[itemID].tokenID;
        bool _sold = idToMarketItem[itemID].sold;
            
        require(msg.value == _price, "Please submit the asking price in order to complete the purchase.");
        require(_sold == false, "This NFT has either been sold or the listing was canceled. Please make an offer to the current owner.");

        emit MarketItemSold(itemID, _msgSender());

        uint256 _tax = (_price * saleTax) / saleTaxDenominator;
        uint256 _soldFor = _price - _tax;

        payable(feeReceiver).transfer(_tax);
        idToMarketItem[itemID].seller.transfer(_soldFor);
        IERC721(contractNFT).transferFrom(address(this), _msgSender(), _tokenID);
            
        idToMarketItem[itemID].owner = payable(_msgSender());
        itemsSold += 1;
            
        idToMarketItem[itemID].sold = true;

        collectionAmountOnSale[contractNFT] -= 1;

        if (collectionAmountOnSale[contractNFT] < 1) {
            collectionInMarketID[contractNFT] = 0;
            collectionInMarket[collectionInMarketID[contractNFT] - 1] = collectionInMarket[collectionInMarket.length - 1];
            collectionInMarketID[collectionInMarket[collectionInMarket.length - 1]] = collectionInMarketID[contractNFT];
            collectionInMarket.pop();
        }
    }
    
    function cancelMarketSale(address contractNFT, uint256 itemID) public payable nonReentrant {
        uint256 _tokenID = idToMarketItem[itemID].tokenID;
        address _seller = idToMarketItem[itemID].seller;
        address _owner = idToMarketItem[itemID].owner;
        bool _sold = idToMarketItem[itemID].sold;

        require(_msgSender() == _seller, "You are not the seller for this item.");
        require(_sold == false && _owner == payable(ZERO), "This NFT has either been sold or the listing was already canceled");
        
        emit MarketItemCanceled(itemID, _msgSender());

        IERC721(contractNFT).transferFrom(address(this), _msgSender(), _tokenID);

        idToMarketItem[itemID].owner = payable(_msgSender());
        itemsCanceled += 1;

        idToMarketItem[itemID].sold = true;

        collectionAmountOnSale[contractNFT] -= 1;

        if (collectionAmountOnSale[contractNFT] < 1) {
            collectionInMarketID[contractNFT] = 0;
            collectionInMarket[collectionInMarketID[contractNFT] - 1] = collectionInMarket[collectionInMarket.length - 1];
            collectionInMarketID[collectionInMarket[collectionInMarket.length - 1]] = collectionInMarketID[contractNFT];
            collectionInMarket.pop();
        }
    }
    
}