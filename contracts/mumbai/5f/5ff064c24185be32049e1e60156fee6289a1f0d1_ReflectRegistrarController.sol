//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringToBytes32 {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // Ensure that the source string is not longer than 32 bytes
        require(tempEmptyStringTest.length <= 32, "Source string is too long.");

        assembly {
            result := mload(add(source, 32))
        }
    }
}

interface LaunchTld {
    /**
     * @dev Returns the price to register.
     * @param condition keccak256 multiple conditions, like payment token address, duration, length, etc.
     * @return The price of this registration.
     */
    function prices(bytes32 tld, bytes32 condition) external view returns(uint);

    /**
     * @dev Returns the payment token addresses according to a specific tld.
     * @param tld keccak256 tld.
     * @return The payment token addresses.
     */
    function getSupportedPayment(bytes32 tld) external view returns(address[] memory);

    /**
     * @dev Returns the permanent ownership status of subnode belonged to a tld.
     * @param tld keccak256 tld.
     * @return The permanent ownership status of subnode belonged to a tld
     */
    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool);

    function receivingAddress(bytes32 tld) external view returns(address);
}

interface Reflect {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    event SetPermanent(bytes32 indexed node, bool permanent);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl, bool permanent) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl, bool permanent) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) virtual public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) virtual public view returns (address owner);

    function approve(address to, uint256 tokenId) virtual public;
    function getApproved(uint256 tokenId) virtual public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) virtual public;
    function isApprovedForAll(address owner, address operator) virtual public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) virtual public;
    function safeTransferFrom(address from, address to, uint256 tokenId) virtual public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) virtual public;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract BaseRegistrar is IERC721, Ownable {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, bytes32 baseNode, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, bytes32 baseNode, address indexed owner, uint expires, bool permanent);
    event NameRenewed(uint256 indexed id, bytes32 baseNode, uint expires);

    // The Reflect registry
    Reflect public reflect;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) virtual external;

    // Revoke controller permission for an address.
    function removeController(address controller) virtual external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view virtual returns(uint, bool);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view virtual returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, bytes32 baseNode, address owner, uint duration, bool permanent) virtual external returns(uint, bool);

    function renew(uint256 id, bytes32 baseNode, uint duration) virtual external returns(uint);

    /**
     * @dev Reclaim ownership of a name in Reflect, if you own it in the registrar.
     */
    function reclaim(uint256 id, bytes32 baseNode, address owner) virtual external;
}

interface Resolver {
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function dnsrr(bytes32 node) external view returns (bytes memory);
    function name(bytes32 node) external view returns (string memory);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

contract ReflectRegistrarController is Ownable {
    using SafeMath for uint;
    using StringUtils for string;

    BaseRegistrar public base;
    LaunchTld public launchTld;
    uint public platformPercentage;
    address public platformWallet;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires, bool permanent);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewLaunchTld(address indexed launchTld);

    event PlatformFee(bytes32 indexed tld, uint platformFee, address payment);
    event TldOwnerFee(bytes32 indexed tld, uint tldOwnerFee, address payment);

    constructor(BaseRegistrar _base, LaunchTld _launchTld, uint _platformPercentage, address _platformWallet) public {
        base = _base;
        launchTld = _launchTld;
        require(_platformPercentage < 100, 'Invalid platform percentage');
        platformPercentage = _platformPercentage;
        platformWallet = _platformWallet;
    }

    function rentPrice(string memory name, bytes32 baseNode, uint duration, address payment) public returns(uint, bool) {
        uint nameLength = name.strlen();
        require(nameLength >= 3, 'name length should be at least 3');
        if(nameLength > 4) {
            nameLength = 5;
        }
        bool permanentEnabled = launchTld.permanentOwnershipOfSubnode(baseNode);
        bytes32 priceConditionHash = keccak256(abi.encodePacked(permanentEnabled, nameLength, payment));
        uint cost = launchTld.prices(baseNode, priceConditionHash);
        require(cost > 0, 'price not set');
        if (permanentEnabled) {
            return (cost.div(100), permanentEnabled);
        } else {
            return (cost.mul(duration).div(100), permanentEnabled);
        }
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 3;
    }

    function available(string memory name, string memory tld) public view returns(bool) {
        bytes32 baseNode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(tld))));
        address receivingAddress = launchTld.receivingAddress(baseNode);
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(keccak256(abi.encodePacked(baseNode, uint(label))));
        return valid(name) && receivingAddress != address(0) && base.available(uint256(tokenId)) ;
    }

    function register(string calldata name, string calldata tld, address owner, uint duration, address payment) external {
        registerWithConfig(name, tld, owner, duration, payment, address(0), address(0));
    }

    function registerWithConfig(string memory name, string memory tld, address owner, uint duration, address payment, address resolver, address addr) public {
        bytes32 baseNode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(tld))));
        address receivingAddress = launchTld.receivingAddress(baseNode);
        require(receivingAddress != address(0), 'tld does not exist');

        (uint cost, bool permanentEnabled) = rentPrice(name, baseNode, duration, payment);
        uint platformFee = cost.div(100).mul(platformPercentage);
        emit PlatformFee(StringToBytes32.stringToBytes32(tld), platformFee, payment);
        uint tldOwnerFee = cost.sub(platformFee);
        emit TldOwnerFee(StringToBytes32.stringToBytes32(tld), tldOwnerFee, payment);
        IERC20 paymentToken = IERC20(payment);
        require(paymentToken.transferFrom(msg.sender, platformWallet, platformFee), 'Send to platform wallet failed');
        require(paymentToken.transferFrom(msg.sender, receivingAddress, tldOwnerFee), 'Send to tld owner wallet failed');

        uint256 tokenId = uint256(keccak256(bytes(name)));

        uint expires;
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            (uint expires, bool permanet) = base.register(tokenId, baseNode, address(this), duration, permanentEnabled);

            // Set the resolver
            bytes32 subnode = keccak256(abi.encodePacked(baseNode, tokenId));
            base.reflect().setResolver(subnode, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(subnode, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, baseNode, owner);
            base.transferFrom(address(this), owner, uint256(subnode));
        } else {
            require(addr == address(0));
            (uint expires, bool permanent) = base.register(tokenId, baseNode, owner, duration, permanentEnabled);
        }
    }

    function renew(string calldata name, string calldata tld, uint duration, address payment) external {
        bytes32 baseNode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(tld))));
        (uint cost, bool permanent) = rentPrice(name, baseNode, duration, payment);
        uint platformFee = cost.div(100).mul(platformPercentage);
        uint tldOwnerFee = cost.sub(platformFee);

        IERC20 paymentToken = IERC20(payment);
        bytes32 tldHash = keccak256(bytes(tld));
        address receivingAddress = launchTld.receivingAddress(baseNode);
        require(receivingAddress != address(0), 'tld does not exist');
        require(paymentToken.transferFrom(msg.sender, platformWallet, platformFee), 'Send to platform wallet failed');
        require(paymentToken.transferFrom(msg.sender, receivingAddress, tldOwnerFee), 'Send to tld owner wallet failed');

        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), baseNode, duration);

        emit NameRenewed(name, label, cost, expires);
    }

    function setLaunchTld(LaunchTld _launchTld) public onlyOwner {
        launchTld = _launchTld;
        emit NewLaunchTld(address(_launchTld));
    }
}