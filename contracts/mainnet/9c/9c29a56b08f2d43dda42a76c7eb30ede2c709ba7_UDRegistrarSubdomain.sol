/**
 *Submitted for verification at polygonscan.com on 2022-12-16
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/subdomain-ud.sol



pragma solidity >= 0.8.0;



interface IUDNft {
    function exists(uint256 _tokenId) external view returns (bool);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface IUDManager {
    function issueWithRecords(address _to, string[] calldata _labels, string[] calldata _keys, string[] calldata _values) external;
}

contract UDRegistrarSubdomain is Ownable {
    IUDNft public udNft;
    IUDManager public udManager;
    string[] public parents;
    uint public price;
    uint256 public parentId;

    constructor(
        IUDNft _udNft,
        IUDManager _udManager,
        string[] memory _parents,
        uint _price
    ) {
        udNft = _udNft;
        udManager = _udManager;
        parents = _parents;
        price = _price;
        parentId = _namehash(_parents);
    }

    function getNamehash(string calldata _name) external view returns (uint256) {
        string[] memory path;
        path = new string[](parents.length+1);
        path[0] = _name;
        for (uint i=0; i<parents.length; i++) {
            path[i+1] = parents[i];
        }

        return _namehash(path);
    }

    function _namehash(string[] memory labels) internal pure returns (uint256) {
        uint256 node = 0x0;
        for (uint256 i = labels.length; i > 0; i--) {
            node = _namehash(node, labels[i - 1]);
        }
        return node;
    }

    function _namehash(uint256 tokenId, string memory label) internal pure returns (uint256) {
        require(bytes(label).length != 0, 'Registry: LABEL_EMPTY');
        return uint256(keccak256(abi.encodePacked(tokenId, keccak256(abi.encodePacked(label)))));
    }

    function setParent(string[] memory _labels) external onlyOwner {
        parents = _labels;
        parentId = _namehash(_labels);
    }

    function buySubDomain(string memory _name) payable external {
        string[] memory path;
        path = new string[](parents.length+1);
        path[0] = _name;
        for (uint i=0; i<parents.length; i++) {
            path[i+1] = parents[i];
        }
        // path[1] = parents[0];
        // path[2] = parents[1];
        uint256 _labels = _namehash(path);
        require(!udNft.exists(_labels), "Domain already taken"); // check subdomain

        require(msg.value == price, "Buying Price not match");

        string[] memory keys;
        keys = new string[](1);
        keys[0] = "crypto.ETH.address";

        string[] memory value;
        value = new string[](1);
        value[0] = Strings.toHexString(msg.sender);
        
        udManager.issueWithRecords(msg.sender, path, keys, value);
    }

    function changePrice(uint _price) external onlyOwner {
        price = _price;
    }

    function checkAvailable(string calldata _name) external view returns (bool) {
        string[] memory path;
        path = new string[](parents.length+1);
        path[0] = _name;
        for (uint i=0; i<parents.length; i++) {
            path[i+1] = parents[i];
        }

        return !udNft.exists(_namehash(path));
    }

    function migrateCollateral() external onlyOwner {
        udNft.safeTransferFrom(address(this), owner(), parentId);
    }

    function withdrawETH() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
    fallback() external payable {}
}