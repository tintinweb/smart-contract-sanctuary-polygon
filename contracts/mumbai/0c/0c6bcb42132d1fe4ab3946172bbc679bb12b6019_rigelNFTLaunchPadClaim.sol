/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin\contracts\math\SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

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

// File: node_modules\@openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// File: node_modules\@openzeppelin\contracts\introspection\ERC165.sol

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor ()  {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: node_modules\@openzeppelin\contracts\token\ERC1155\ERC1155Receiver.sol

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// File: @openzeppelin\contracts\token\ERC1155\ERC1155Holder.sol

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol


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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts\rigelNFTLaunchPadClaim.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;



interface launchPadRouterContract {
    function viewLaunchPadData(address swapFrom, address swapTo) external view returns (
        address swapTokenFrom, 
        address swapTokenTo, 
        address  specialPoolC,
        uint256  price,
        uint256  expectedLockFunds,
        uint256  lockedFunds,
        uint256  maxLock
    ); 
    function userBalance( address swapFrom, address swapTo,  address _user) external view returns(uint256 _amount);
    function getUserLockedFund( address swapFrom, address swapTo, address _user) external view  returns (uint256);
}

interface launchPadFactoryContract {
    function allPairs(uint256 _id) external view returns (address);
    function allPairsLength() external view returns (uint256);
}

interface IrigelProtocolLanchPadPool {
    
    function period(uint256 _idZero, uint256 _chkPeriod) external view returns (uint256, uint256);
    function viewData() external view returns (
        address swapTokenFrom, 
        address swapTokenTo, 
        address  specialPoolC,
        uint256  price,
        uint256  expectedLockFunds,
        uint256  lockedFunds,
        uint256  maxLock
    );

    function userFunds(address _user) external view returns (uint256);
    function isWhitelist(address _user) external view returns (bool);
    function getMinimum() external view returns (uint256);
    function checkPoolBalance(address _user) external view returns (bool);
    function lockFund(address staker, uint256 _amount) external;
    function getUser(address _user) external view returns (uint256);
    function getOutPutAmount(uint256 _amt) external view returns (uint256);
    function lengthOfPeriod() external view returns (uint256);
}


contract rigelNFTLaunchPadClaim is Ownable, ERC1155Holder {
 using SafeMath for uint256;

    struct cardDetails {
        address token1;
        address token2;
        address token3;
        uint256 token1Price;
        uint256 token2Price;
        uint256 token3Price;        
        uint256 numberOfProjectRequire;
    }
    
    struct PairTokens {
        address token1;
        address token2;
        address token3;
        address projectToken;
    }

    struct PairDetails {
        uint256 investmentOnPairOne;
        uint256 investmentOnPairTwo;
        uint256 investmentOnPairThree;
    }

  struct Claimed {    
    bool InvestedLaunchPad;
    bool NumberOfProjectInvest;
  }
  address[] tk;
  
  address payable public _owner;
  address public rigelToken;
  IERC1155 public rigelNFT;
  address public launchPadFactory;
  address public launchPadRouter;
  mapping (uint256 => PairTokens) public addressOfPairTokens;
  mapping (uint256 => cardDetails) public buyWithToken;
  mapping (uint256 => PairDetails) public pairDetails;
  mapping (address => mapping (uint256 => bool)) public claimForPair;
  mapping (address => mapping (uint256 => uint256)) public userCurrentStateOfClaim;
 
  
  event Purchase(address indexed recipient, uint price, uint id);
  event claims(address indexed recipient, uint256 tokenID, uint256 price);
  event access(address indexed user, uint256 id, uint256 _event);

 constructor(
     address _rgp,
     address _rigelNFT,
     address _factory,
     address _router
    ) {
        _owner = payable(_msgSender());
        rigelToken = _rgp;
        rigelNFT = IERC1155(_rigelNFT);           
        launchPadFactory = _factory;
        launchPadRouter = _router;
    }

    function updateCardDetails(
        uint256 tokenID, 
        address _buyWithOne, 
        address _buyWithTwo, 
        uint256 _rgpPrice,
        uint256 _token2Price,
        uint256 _token3Price,
        uint256 _numberOfProjInvestedIn) external onlyOwner {
        cardDetails storage _purch = buyWithToken[tokenID];
        _purch.token1 = rigelToken; 
        _purch.token2 = _buyWithOne;
        _purch.token3 = _buyWithTwo; 
        _purch.token1Price = _rgpPrice;
        _purch.token2Price = _token2Price;
        _purch.token3Price = _token3Price;
        _purch.numberOfProjectRequire = _numberOfProjInvestedIn;
    }

     function Pairs(
         uint256 _id,
         uint256 _expectedAmountOnPair1,
         uint256 _expectedAmountOnPair2,
         uint256 _expectedAmountOnPair3,
         address[] memory _addressOfPairContract,
         address _tokenProject
        ) external onlyOwner {
        
        PairTokens storage _token = addressOfPairTokens[_id];
        PairDetails storage __pairs = pairDetails[_id];
        _token.token1 = _addressOfPairContract[0];
        _token.token2 = _addressOfPairContract[1];
        _token.token3 = _addressOfPairContract[2];
        _token.projectToken = _tokenProject;
        __pairs.investmentOnPairOne = _expectedAmountOnPair1;
        __pairs.investmentOnPairTwo = _expectedAmountOnPair2;
        __pairs.investmentOnPairThree = _expectedAmountOnPair3;
    }

    function claimLaunchPad(uint256 _tokenId, uint256 _projectID) external {   
        PairDetails memory __pairs = pairDetails[_projectID];
        PairTokens memory _token = addressOfPairTokens[_projectID];
        // (uint256[] memory userAmt, address[] memory pair) = getLaunchPadData(_msgSender());
        (uint256[] memory userAmt) = getLaunchPadData(_msgSender());

        uint256 stAmt = userCurrentStateOfClaim[_msgSender()][_tokenId];    

        if (userAmt.length > 0) {
            for (uint256 i = 0; i <= userAmt.length; i++) {  

                if (userAmt[i] >= __pairs.investmentOnPairOne) {                                    
                    if (_tokenId == 1 && stAmt == 0) {
                        userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairOne;
                        claim(_tokenId);
                        break;
                    } else {
                        uint256 cAmt = userCurrentStateOfClaim[_msgSender()][_tokenId - 1];
                        uint256 currentAmount = userAmt[i] - cAmt;
                        if (currentAmount >= __pairs.investmentOnPairOne) {
                            userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairOne;
                            claim(_tokenId);
                        }
                        break;
                    }                    
                }
                // if (userAmt[i] >= __pairs.investmentOnPairTwo && pair[i] == _token.token2) {                                    
                //     if (_tokenId == 1 && stAmt == 0) {
                //         userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairTwo;
                //         claim(_tokenId);
                //         break;
                //     } else {
                //         uint256 cAmt = userCurrentStateOfClaim[_msgSender()][_tokenId - 1];
                //         uint256 currentAmount = userAmt[i] - cAmt;
                //         if (currentAmount >= __pairs.investmentOnPairTwo) {
                //             userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairTwo;
                //             claim(_tokenId);
                //         }
                //         break;
                //     }                    
                // }
                // if (userAmt[i] >= __pairs.investmentOnPairThree && pair[i] == _token.token3) {                                    
                //     if (_tokenId == 1 && stAmt == 0) {
                //         userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairThree;
                //         claim(_tokenId);
                //         break;
                //     } else {
                //         uint256 cAmt = userCurrentStateOfClaim[_msgSender()][_tokenId - 1];
                //         uint256 currentAmount = userAmt[i] - cAmt;
                //         if (currentAmount >= __pairs.investmentOnPairOne) {
                //             userCurrentStateOfClaim[_msgSender()][_tokenId] = __pairs.investmentOnPairThree;
                //             claim(_tokenId);
                //         }
                //         break;
                //     }                    
                // }
            }
        }
       
    }

    // function numberOfProjInvestedIn(uint256 _tokenId, address[] memory pair) external {
    //     cardDetails memory _purch = buyWithToken[_tokenId];
    //     uint256 numbOfProjRequire = _purch.numberOfProjectRequire;
    //     // uint256 num = getNumbersOfProjInvestedIn(_msgSender());

    //     uint256 tNumber;
    //     // uint256 allPair = launchPadFactoryContract(launchPadFactory).allPairsLength();     
    //     for (uint256 i = 0; i <= pair.length; i++) {
    //         // address pair = launchPadFactoryContract(launchPadFactory).allPairs(i);
    //         uint256 bal = IrigelProtocolLanchPadPool(pair[i]).getUser(_msgSender());
    //         if (bal > 0) {
    //             tNumber = tNumber + 1;
    //         }
    //     }
    //     // return tNumber; 

    //     if (tNumber >= numbOfProjRequire) {
    //         require(!(claimForPair[msg.sender][_tokenId]), "Can't Claim twice");
    //         claimForPair[msg.sender][_tokenId] = true;
    //         claim(_tokenId);
    //     }
    // }

    function claim(uint256 _tokenId) internal { 
        rigelNFT.safeTransferFrom(address(this), _msgSender(), _tokenId, 1, " "); //nft to user 
        emit claims(_msgSender(), _tokenId, 1);
    }

    function getLaunchPadData(address _user) public view returns(uint256[] memory _userAmount) {  
        uint256 allPair = launchPadFactoryContract(launchPadFactory).allPairsLength();  
        for (uint256 i = 0; i <= allPair; i++) {
            address p = launchPadFactoryContract(launchPadFactory).allPairs(i);
            uint256 lockedAmount = IrigelProtocolLanchPadPool(p).userFunds(_user);
            if (lockedAmount > 0) {
               _userAmount[i] = lockedAmount;
            //    pair[i] = p;
            }
        }
        return (_userAmount);    
        // returns([200,100,300], [0xC972e9F6dA0C31cD50957F3244a9F822551e0616,0xC972e9F6dA0C31cD50957F3244a9F822551e0616z])
    }


    function getNumbersOfProjInvestedIn(address _user, address[] memory pair) public view returns(uint256 _num) {        
        uint256 tNumber;
        // uint256 allPair = launchPadFactoryContract(launchPadFactory).allPairsLength();     
        for (uint256 i = 0; i <= 3; i++) {
            // address pair = launchPadFactoryContract(launchPadFactory).allPairs(i);
            uint256 bal = IrigelProtocolLanchPadPool(pair[i]).getUser(_user);
            if (bal > 0) {
                tNumber = tNumber + 1;
            }
        }
        return tNumber; 
    }

    function buy(uint256 tokenID, address buyWith) external {
        cardDetails memory _purch = buyWithToken[tokenID];
        require(buyWith == _purch.token1 || buyWith == _purch.token2 || buyWith == _purch.token3, "Rigel: Token address Not accepted");
        if(buyWith == _purch.token1) {
            require(IERC20(buyWith).transferFrom(_msgSender(), address(this), _purch.token1Price));    
            _trade(tokenID); //swap nft for eth
        }
        if(buyWith == _purch.token2) {
            require(IERC20(buyWith).transferFrom(_msgSender(), address(this), _purch.token2Price));    
            _trade(tokenID); //swap nft for eth
        }
        if(buyWith == _purch.token3) {
            require(IERC20(buyWith).transferFrom(_msgSender(), address(this), _purch.token3Price));    
            _trade(tokenID); //swap nft for eth
        }        
    }

    function _trade(uint _id) internal {
        rigelNFT.safeTransferFrom(address(this), msg.sender, _id, 1, " ");
        emit Purchase(_msgSender(), 1, _id);
    }

    function EmmergencyWithdraw(address _token, address recipient, uint256 _amt) external onlyOwner {
        IERC20(_token).transfer(recipient, _amt);
    }
}