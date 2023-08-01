/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// File: contracts/Admin/data/guild/GuildStruct.sol


pragma solidity ^0.8.18;

    struct UserPaymentInfo {
        uint256 price;
        bool paymentState;
    }
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: contracts/Admin/LuxOnAdmin.sol


pragma solidity ^0.8.16;


contract LuxOnAdmin is Ownable {

    mapping(string => mapping(address => bool)) private _superOperators;

    event SuperOperator(string operator, address superOperator, bool enabled);

    function setSuperOperator(string memory operator, address[] memory _operatorAddress, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < _operatorAddress.length; i++) {
            _superOperators[operator][_operatorAddress[i]] = enabled;
            emit SuperOperator(operator, _operatorAddress[i], enabled);
        }
    }

    function isSuperOperator(string memory operator, address who) public view returns (bool) {
        return _superOperators[operator][who];
    }
}
// File: contracts/LUXON/utils/LuxOnSuperOperators.sol


pragma solidity ^0.8.16;



contract LuxOnSuperOperators is Ownable {

    event SetLuxOnAdmin(address indexed luxOnAdminAddress);
    event SetOperator(string indexed operator);

    address private luxOnAdminAddress;
    string private operator;

    constructor(
        string memory _operator,
        address _luxOnAdminAddress
    ) {
        operator = _operator;
        luxOnAdminAddress = _luxOnAdminAddress;
    }

    modifier onlySuperOperator() {
        require(LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, msg.sender), "LuxOnSuperOperators: not super operator");
        _;
    }

    function getLuxOnAdmin() public view returns (address) {
        return luxOnAdminAddress;
    }

    function getOperator() public view returns (string memory) {
        return operator;
    }

    function setLuxOnAdmin(address _luxOnAdminAddress) external onlyOwner {
        luxOnAdminAddress = _luxOnAdminAddress;
        emit SetLuxOnAdmin(_luxOnAdminAddress);
    }

    function setOperator(string memory _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    function isSuperOperator(address spender) public view returns (bool) {
        return LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, spender);
    }
}
// File: contracts/LUXON/guild/GuildStorage.sol


pragma solidity ^0.8.18;




contract GuildStorage is LuxOnSuperOperators {
    event SetPaymentState(address indexed userAddress, uint256 indexed price);
    event ResetPaymentState(address indexed userAddress, uint256 indexed price, string indexed reason);

    using SafeMath for uint256;

    mapping(address => UserPaymentInfo) public userPaymentState;

    constructor(
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {}

    function getPaymentState(address _address) public view returns (bool) {
        return userPaymentState[_address].paymentState;
    }

    function getPaymentPrice(address _address) public view returns (uint256) {
        return userPaymentState[_address].price;
    }

    function getPaymentInfo(address _address) public view returns (bool, uint256) {
        return (
        getPaymentState(_address),
        getPaymentPrice(_address)
        );
    }

    function setPaymentState(address _address, uint256 price) external onlySuperOperator {
        userPaymentState[_address].price = price;
        userPaymentState[_address].paymentState = true;
        emit SetPaymentState(_address, price);
    }

    function resetPaymentState(address _address, string memory reason) external onlySuperOperator {
        uint256 price = userPaymentState[_address].price;
        userPaymentState[_address].price = 0;
        userPaymentState[_address].paymentState = false;
        emit ResetPaymentState(_address, price, reason);
    }
    // 환불했을 때, 성공했을 때 reset
}

// File: contracts/Admin/LuxOnAuthority.sol


pragma solidity ^0.8.16;


contract LuxOnAuthority is Ownable {
    mapping (address => bool) blacklist;

    event Blacklist(address userAddress, uint256 timestamp, bool live);

    function isBlacklist(address user) public view returns (bool){
        return blacklist[user];
    }

    function setBlacklist(address[] memory userAddresses, bool _isBlacklist) external onlyOwner {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            blacklist[userAddresses[i]] = _isBlacklist;
            emit Blacklist(userAddresses[i], block.timestamp, _isBlacklist);
        }
    }
}


// File: contracts/LUXON/utils/LuxOnBlacklist.sol


pragma solidity ^0.8.16;




contract LuxOnBlacklist is Ownable {
    address private luxOnAuthority;

    event SetLuxOnAuthority (address indexed luxOnAuthority);

    constructor(
        address _luxOnAuthority
    ){
        luxOnAuthority = _luxOnAuthority;
    }

    function getLuxOnAuthority() external view returns(address) {
        return luxOnAuthority;
    }

    function setLuxOnAuthority(address _luxOnAuthority) external onlyOwner{
        luxOnAuthority = _luxOnAuthority;
    }

    function getIsInBlacklist(address _userAddress) external view returns(bool) {
        return LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress);
    }

    modifier isBlacklist(address _userAddress) {
        // blacklist에 등록된 유저 => true / 등록되지 않은 유저 => false ---> !를 붙여서 반대 값으로 에러 발생 (true면 에러 발생)
        require(LuxOnAuthority(luxOnAuthority).isBlacklist(_userAddress) == false, "LuxOnBlacklist: This user is on the blacklist");
        _;
    }

}


// File: contracts/Admin/LuxOnService.sol


pragma solidity ^0.8.15;


contract LuxOnService is Ownable {
    mapping(address => bool) isInspection;

    event Inspection(address contractAddress, uint256 timestamp, bool live);

    function isLive(address contractAddress) public view returns (bool) {
        return !isInspection[contractAddress];
    }

    function setInspection(address[] memory contractAddresses, bool _isInspection) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            isInspection[contractAddresses[i]] = _isInspection;
            emit Inspection(contractAddresses[i], block.timestamp, _isInspection);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnLive.sol


pragma solidity ^0.8.16;



contract LuxOnLive is Ownable {
    address private luxOnService;

    event SetLuxOnService(address indexed luxOnService);

    constructor(
        address _luxOnService
    ) {
        luxOnService = _luxOnService;
    }

    function getLuxOnService() public view returns (address) {
        return luxOnService;
    }

    function setLuxOnService(address _luxOnService) external onlyOwner {
        luxOnService = _luxOnService;
        emit SetLuxOnService(_luxOnService);
    }

    modifier isLive() {
        require(LuxOnService(luxOnService).isLive(address(this)), "LuxOnLive: not live");
        _;
    }
}
// File: contracts/Admin/data/DataAddress.sol


pragma solidity ^0.8.16;


contract DspDataAddress is Ownable {

    event SetDataAddress(string indexed name, address indexed dataAddress, bool indexed isValid);

    struct DataAddressInfo {
        string name;
        address dataAddress;
        bool isValid;
    }

    mapping(string => DataAddressInfo) private dataAddresses;

    function getDataAddress(string memory _name) public view returns (address) {
        require(dataAddresses[_name].isValid, "this data address is not valid");
        return dataAddresses[_name].dataAddress;
    }

    function setDataAddress(DataAddressInfo memory _dataAddressInfo) external onlyOwner {
        dataAddresses[_dataAddressInfo.name] = _dataAddressInfo;
        emit SetDataAddress(_dataAddressInfo.name, _dataAddressInfo.dataAddress, _dataAddressInfo.isValid);
    }

    function setDataAddresses(DataAddressInfo[] memory _dataAddressInfos) external onlyOwner {
        for (uint256 i = 0; i < _dataAddressInfos.length; i++) {
            dataAddresses[_dataAddressInfos[i].name] = _dataAddressInfos[i];
            emit SetDataAddress(_dataAddressInfos[i].name, _dataAddressInfos[i].dataAddress, _dataAddressInfos[i].isValid);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnData.sol


pragma solidity ^0.8.16;



contract LuxOnData is Ownable {
    address private luxonData;
    event SetLuxonData(address indexed luxonData);

    constructor(
        address _luxonData
    ) {
        luxonData = _luxonData;
    }

    function getLuxOnData() public view returns (address) {
        return luxonData;
    }

    function setLuxOnData(address _luxonData) external onlyOwner {
        luxonData = _luxonData;
        emit SetLuxonData(_luxonData);
    }

    function getDataAddress(string memory _name) public view returns (address) {
        return DspDataAddress(luxonData).getDataAddress(_name);
    }
}
// File: contracts/LUXON/utils/IERC20LUXON.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.16;

interface IERC20LUXON {
    function paybackFrom() external view returns (address);

    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) external returns (bool success);
    function approveFor(address owner, address spender, uint256 amount) external returns (bool success);

    function paybackByMint(address to, uint256 amount) external;
    function paybackByTransfer(address to, uint256 amount) external;
    function burnFor(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/LUXON/utils/IERC1155LUXON.sol


pragma solidity ^0.8.16;

interface IERC1155LUXON {
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function getValueChipType() external view returns(uint32);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: contracts/LUXON/guild/Guild.sol


pragma solidity ^0.8.18;










contract Guild is ReentrancyGuard, LuxOnLive, LuxOnBlacklist {
    event PayGuildCost(address indexed user, uint256 indexed price);
    event RefundGuildCost(address indexed user, uint256 indexed price);

    GuildStorage public guildStorage;
    uint256 public price;

    constructor(
        address luxonService,
        address _guildStorage,
        address luxonAuthority
    ) LuxOnLive(luxonService) LuxOnBlacklist(luxonAuthority){
        guildStorage = GuildStorage(_guildStorage);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function getPrice() external onlyOwner view returns (uint256) {
        return price;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function payGuildCost() external payable nonReentrant isBlacklist(msg.sender){
        bool userPaymentState = guildStorage.getPaymentState(msg.sender);
        require(!userPaymentState, "guild cost already payment");

        require(0 != price, "price is default value");
        require(msg.value == price, "price and pay amount is different");

        guildStorage.setPaymentState(msg.sender, price);
        emit PayGuildCost(msg.sender, msg.value);
    }

    function refundGuildCost() public nonReentrant isBlacklist(msg.sender){
        bool success;

        address payable recipient = payable(msg.sender);

        //        uint256 refundPrice = price;
        (bool userPaymentState, uint256 refundPrice) = guildStorage.getPaymentInfo(msg.sender);
        require(userPaymentState, "guild cost not payment");
        require(0 != refundPrice, "refund price invalid");

        assembly {
            success := call(gas(), recipient, refundPrice, 0, 0, 0, 0)
        }

        require(success, "Transfer failed.");

        guildStorage.resetPaymentState(msg.sender, "refund");
        emit RefundGuildCost(msg.sender, refundPrice);
    }
}