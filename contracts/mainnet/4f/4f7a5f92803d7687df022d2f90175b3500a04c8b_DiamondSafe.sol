/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// File: IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.7.4;

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
// File: IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.7.4;


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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// File: Context.sol


pragma solidity ^0.7.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
// File: Ownable.sol


pragma solidity ^0.7.4;

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

 
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
// File: IPancakeRouter01.sol


pragma solidity ^0.7.4;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: IERC20.sol


pragma solidity ^0.7.4;

interface IERC20 
{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// File: SafeERC20.sol


pragma solidity ^0.7.4;

/* ROOTKIT:
Modified to remove some junk
Also modified to remove silly restrictions (traps!) within safeApprove
*/




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {        
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: SafeMath.sol


pragma solidity ^0.7.4;

library SafeMath 
{
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }
}
// File: Address.sol


pragma solidity ^0.7.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
// File: DiamondVault.sol


pragma solidity 0.7.4;








contract DiamondSafe is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // Import the BEP20 token interface
    IERC20 public stakingToken;
    IERC20 public buybackToken; // The token being bought back...
    IERC20 public wbnb;
    IERC721 public jpegTest;

    IPancakeRouter01 public uniswapV2Router;
    IPancakeRouter01 public tokenUniswapV2Router;

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$$CONFIGURABLES AND VARIABLES$$$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    uint256 public requiredBalance;

    // Store the token address and the reserve address
    address public tokenAddress;
    address payable public bnbReceiver;
    address[] public jpeg;
    // Store the number of unique users and total Tx's
    uint public users;
    uint public totalTxs;

    // Store the starting time & block number and the last payout time
    uint public lastPayout; // What time was the last payout (timestamp)?

    // Store the details of total deposits & claims
    uint public totalClaims;
    uint public totalDeposits;

    // Store the total drip pool balance and rate
    uint public dripPoolBalance;
    uint8 public dripRate;

    // 10% fee on deposit and withdrawal
    uint8 internal constant divsFee = 10;
    uint256 internal constant magnitude = 2 ** 64;

    // How many portions of the fees does each receiver get?
    uint public forPool;
    uint public forDivs;

    // Rebase and payout frequency
    uint256 public constant rebaseFrequency = 6 hours;
    uint256 public constant payoutFrequency = 2 seconds;

    // Timestamp of last rebase
    uint256 public lastRebaseTime;

    // Current total tokens staked, and profit per share
    uint256 private currentTotalStaked;
    uint256 private profitPerShare_;

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ MODIFIERS                    $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    // Only holders - Caller must have funds in the vault
    modifier onlyHolders() {
        require(myTokens() > 0);
        _;
    }

    // Only earners - Caller must have some earnings
    modifier onlyEarners() {
        require(myEarnings() > 0);
        _;
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
     $$ ACCOUNT STRUCT                 $$
     $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    struct Account {
        uint deposited;
        uint withdrawn;
        uint compounded;
        uint rewarded;
        uint contributed;
        uint transferredShares;
        uint receivedShares;
        uint xInvested;
        uint xCompounded;
        uint xRewarded;
        uint xContributed;
        uint xWithdrawn;
        uint xTransferredShares;
        uint xReceivedShares;
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ MAPPINGS                       $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    mapping(address => int256) payoutsOf_;
    mapping(address => uint256) balanceOf_;
    mapping(address => Account) accountOf_;

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ EVENTS                         $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    event onDeposit(
        address indexed _user,
        uint256 _deposited,
        uint256 tokensMinted,
        uint timestamp
    );
    event onWithdraw(
        address indexed _user,
        uint256 _liquidated,
        uint256 tokensEarned,
        uint timestamp
    );
    event onCompound(
        address indexed _user,
        uint256 _compounded,
        uint256 tokensMinted,
        uint timestamp
    );
    event onWithdraw(address indexed _user, uint256 _withdrawn, uint timestamp);
    event onTransfer(
        address indexed from,
        address indexed to,
        uint256 tokens,
        uint timestamp
    );
    event onUpdate(
        address indexed _user,
        uint256 invested,
        uint256 tokens,
        uint256 soldTokens,
        uint timestamp
    );

    event onRebase(uint256 balance, uint256 timestamp);

    event onDonate(address indexed from, uint256 amount, uint timestamp);
    event onDonateBNB(address indexed from, uint256 amount, uint timestamp);

    event onSetFeeSplit(uint _pool, uint _divs, uint256 timestamp);
    event onSetImmunityToken(
        address indexed _caller,
        address []oldOne,
        address []newOne,
        uint256 timestamp
    );

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ CONSTRUCTOR                    $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    constructor(address _tokenAddress, uint8 _dripRate) Ownable() {
        require(
            _tokenAddress != address(0) && Address.isContract(_tokenAddress),
            "INVALID_ADDRESS"
        );

        tokenAddress = _tokenAddress;
        stakingToken = IERC20(_tokenAddress);

        bnbReceiver = msg.sender;

        // Set Drip Rate and last payout date (first time around)...
        dripRate = _dripRate;
        lastPayout = (block.timestamp);

        // Fee portions
        forPool = 8;
        forDivs = 2;

        requiredBalance = 1;
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ FALLBACK                       $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    receive() external payable {
        Address.sendValue(bnbReceiver, msg.value);
        emit onDonateBNB(msg.sender, msg.value, block.timestamp);
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ WRITE FUNCTIONS                $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    // Donate
    function donate(uint _amount) public returns (uint256) {
        // Move the tokens from the caller's wallet to this contract.
        require(stakingToken.transferFrom(msg.sender, address(this), _amount));

        // Add the tokens to the drip pool balance
        dripPoolBalance += _amount;

        // Tell the network, successful function - how much in the pool now?
        emit onDonate(msg.sender, _amount, block.timestamp);
        return dripPoolBalance;
    }

    // Deposit
    function deposit(uint _amount) public returns (uint256) {
        return depositTo(msg.sender, _amount);
    }

    // DepositTo
    function depositTo(address _user, uint _amount) public returns (uint256) {
        // Move the tokens from the caller's wallet to this contract.
        require(stakingToken.transferFrom(msg.sender, address(this), _amount));

        // Add the deposit to the totalDeposits...
        totalDeposits += _amount;

        // Then actually call the deposit method...
        uint amount = _depositTokens(_user, _amount);

        // Update the leaderboard...
        emit onUpdate(
            _user,
            accountOf_[_user].deposited,
            balanceOf_[_user],
            accountOf_[_user].withdrawn,
            block.timestamp
        );

        // Then trigger a distribution for everyone, kind soul!
        distribute();

        // Successful function - how many 'shares' (tokens) are the result?
        return amount;
    }

    // Compound
    function compound() public onlyEarners {
        _compoundTokens();
    }

    // Harvest
    function harvest() public onlyEarners {
        address _user = msg.sender;
        uint256 _dividends = myEarnings();

        // Calculate the payout, add it to the user's total paid out accounting...
        payoutsOf_[_user] += (int256)(_dividends * magnitude);

        // Pay the user their tokens to their wallet
        stakingToken.transfer(_user, _dividends);

        // Update accounting for user/total withdrawal stats...
        accountOf_[_user].withdrawn = SafeMath.add(
            accountOf_[_user].withdrawn,
            _dividends
        );
        accountOf_[_user].xWithdrawn += 1;

        // Update total Tx's and claims stats
        totalTxs += 1;
        totalClaims += _dividends;

        // Tell the network...
        emit onWithdraw(_user, _dividends, block.timestamp);

        // Trigger a distribution for everyone, kind soul!
        distribute();
    }

    // Withdraw
    function withdraw(uint256 _amount) public onlyHolders {
        address _user = msg.sender;
        require(_amount <= balanceOf_[_user]);
         uint256 _undividedDividends = SafeMath.mul(_amount, divsFee) / 100;
        // Calculate dividends and 'shares' (tokens)
        
        bool isImmune = checkImmunity(msg.sender);
        
        if (isImmune) {
           _undividedDividends = 0;         

        } 
          uint256  _taxedTokens = SafeMath.sub(_amount, _undividedDividends);
           currentTotalStaked = SafeMath.sub(currentTotalStaked, _amount);
        balanceOf_[_user] = SafeMath.sub(balanceOf_[_user], _amount);

        // Update the payment ratios for the user and everyone else...
        int256 _updatedPayouts = (int256)(
            profitPerShare_ * _amount + (_taxedTokens * magnitude)
        );
        payoutsOf_[_user] -= _updatedPayouts;

        // Serve dividends between the drip and instant divs (4:1)...
        allocateFees(_undividedDividends);

        // Tell the network, and trigger a distribution
        emit onWithdraw(_user, _amount, _taxedTokens, block.timestamp);

        // Update the leaderboard...
        emit onUpdate(
            _user,
            accountOf_[_user].deposited,
            balanceOf_[_user],
            accountOf_[_user].withdrawn,
            block.timestamp
        );
        // Trigger a distribution for everyone, kind soul!
        distribute();

        }
       
     

        
    
    

    // Transfer
    function transfer(
        address _to,
        uint256 _amount
    ) external onlyHolders returns (bool) {
        return _transferTokens(_to, _amount);
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$VIEW FUNCTIONS                 $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    // User is immune to stakeing fees when holding an item
    function checkImmunity(address _user) public view returns (bool isImmune) {
        uint256 x = 0;
        IERC721 jpegTest1;
        for(uint i =0; i < jpeg.length; i++){
            jpegTest1 = IERC721(jpeg[i]);
             x += jpegTest1.balanceOf(_user);
        }
       if (x >= requiredBalance) {
            return true;
        }
        return false;
    }

    function myTokens() public view returns (uint256) {
        return balanceOf(msg.sender);
    }

    function myEarnings() public view returns (uint256) {
        return dividendsOf(msg.sender);
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balanceOf_[_user];
    }

    function tokenBalance(address _user) public view returns (uint256) {
        return _user.balance;
    }

    function totalBalance() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return currentTotalStaked;
    }

    function dividendsOf(address _user) public view returns (uint256) {
        return
            (uint256)(
                (int256)(profitPerShare_ * balanceOf_[_user]) -
                    payoutsOf_[_user]
            ) / magnitude;
    }

    function sellPrice() public pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _taxedTokens = SafeMath.sub(_tokens, _dividends);
        return _taxedTokens;
    }

    function buyPrice() public pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _taxedTokens = SafeMath.add(_tokens, _dividends);
        return _taxedTokens;
    }

    function calculateSharesReceived(
        uint256 _amount
    ) public pure returns (uint256) {
        uint256 _divies = SafeMath.div(SafeMath.mul(_amount, divsFee), 100);
        uint256 _remains = SafeMath.sub(_amount, _divies);
        uint256 _result = _remains;
        return _result;
    }

    function calculateTokensReceived(
        uint256 _amount
    ) public view returns (uint256) {
        require(_amount <= currentTotalStaked);
        uint256 _tokens = _amount;
        uint256 _divies = SafeMath.div(SafeMath.mul(_tokens, divsFee), 100);
        uint256 _remains = SafeMath.sub(_tokens, _divies);
        return _remains;
    }

    function accountOf(address _user) public view returns (uint256[14] memory) {
        Account memory a = accountOf_[_user];
        uint256[14] memory accountArray = [
            a.deposited,
            a.withdrawn,
            a.rewarded,
            a.compounded,
            a.contributed,
            a.transferredShares,
            a.receivedShares,
            a.xInvested,
            a.xRewarded,
            a.xContributed,
            a.xWithdrawn,
            a.xTransferredShares,
            a.xReceivedShares,
            a.xCompounded
        ];
        return accountArray;
    }

    function dailyEstimate(address _user) public view returns (uint256) {
        uint256 share = dripPoolBalance.mul(dripRate).div(100);
        return
            (currentTotalStaked > 0)
                ? share.mul(balanceOf_[_user]).div(currentTotalStaked)
                : 0;
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ PUBLIC OWNER-ONLY FUNCTIONS $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/
    function setFeeSplit(
        uint256 _pool,
        uint256 _divs
    ) public onlyOwner returns (bool _success) {
        require(_pool.add(_divs) == 10, "TEN_PORTIONS_REQUIRE_DIVISION");

        // Set the new values...
        forPool = _pool;
        forDivs = _divs;

        // Tell the network, successful function!
        emit onSetFeeSplit(_pool, _divs, block.timestamp);
        return true;
    }

   
    function setImmunityToken(
        address[] memory _contract
    ) public onlyOwner returns (bool _success) {
   
    

        address[] memory oldContract = jpeg;
        jpeg = _contract;

        emit onSetImmunityToken(
            msg.sender,
            oldContract,
            _contract,
            block.timestamp
        );
        return true;
    }

    /*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $$ PRIVATE / INTERNAL FUNCTIONS   $$
    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$*/

    // Allocate fees (private method)
    function allocateFees(uint fee) private {
        uint256 _onePiece = fee.div(10);

        uint256 _forPool = (_onePiece.mul(forPool)); // for the Drip Pool
        uint256 _forDivs = (_onePiece.mul(forDivs)); // for Instant Divs

        dripPoolBalance = dripPoolBalance.add(_forPool);

        // If there's more than 0 tokens staked in the vault...
        if (currentTotalStaked > 0) {
            // Distribute those instant divs...
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (_forDivs * magnitude) / currentTotalStaked
            );
        } else {
            // Otherwise add the divs portion to the drip pool balance.
            dripPoolBalance += _forDivs;
        }
    }

    // Distribute (private method)
    function distribute() private {
        uint _currentTimestamp = (block.timestamp);

        // Log a rebase, if it's time to do so...
        if (_currentTimestamp.safeSub(lastRebaseTime) > rebaseFrequency) {
            // Tell the network...
            emit onRebase(totalBalance(), _currentTimestamp);

            // Update the time this was last updated...
            lastRebaseTime = _currentTimestamp;
        }

        // If there's any time difference...
        if (
            SafeMath.safeSub(_currentTimestamp, lastPayout) > payoutFrequency &&
            currentTotalStaked > 0
        ) {
            // Calculate shares and profits...
            uint256 share = dripPoolBalance.mul(dripRate).div(100).div(
                24 hours
            );
            uint256 profit = share * _currentTimestamp.safeSub(lastPayout);

            // Subtract from drip pool balance and add to all user earnings
            dripPoolBalance = dripPoolBalance.safeSub(profit);
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                (profit * magnitude) / currentTotalStaked
            );

            // Update the last payout timestamp
            lastPayout = _currentTimestamp;
        }
    }

    // Deposit Tokens (internal method)
    function _depositTokens(
        address _recipient,
        uint256 _amount
    ) internal returns (uint256) {
        // If the recipient has zero activity, they're new - COUNT THEM!!!
        if (
            accountOf_[_recipient].deposited == 0 &&
            accountOf_[_recipient].receivedShares == 0
        ) {
            users += 1;
        }

        // Count this tx...
        totalTxs += 1;     
         uint256 _undividedDividends = SafeMath.mul(_amount, divsFee) / 100;
          uint256   _tokens = SafeMath.sub(_amount, _undividedDividends);

       
        // Tell the network...
        emit onDeposit(_recipient, _amount, _tokens, block.timestamp);

        // There needs to be something being added in this call...
        require(
            _tokens > 0 &&
                SafeMath.add(_tokens, currentTotalStaked) > currentTotalStaked
        );
        if (currentTotalStaked > 0) {
            currentTotalStaked += _tokens;
        } else {
            currentTotalStaked = _tokens;
        }

        // Allocate fees, and balance to the recipient
        allocateFees(_undividedDividends);
        balanceOf_[_recipient] = SafeMath.add(balanceOf_[_recipient], _tokens);

        // Updated payouts...
        int256 _updatedPayouts = (int256)(profitPerShare_ * _tokens);

        // Update stats...
        payoutsOf_[_recipient] += _updatedPayouts;
        accountOf_[_recipient].deposited += _amount;
        accountOf_[_recipient].xInvested += 1;

        // Successful function - how many "shares" generated?
        return _tokens;
    }

    // Compound (internal method)
    function _compoundTokens() internal returns (uint256) {
        address _user = msg.sender;

        // Quickly roll the caller's earnings into their payouts
        uint256 _dividends = dividendsOf(_user);
        payoutsOf_[_user] += (int256)(_dividends * magnitude);

        // Then actually trigger the deposit method
        // (NOTE: No tokens required here, earnings are tokens already within the contract)
        uint256 _tokens = _depositTokens(msg.sender, _dividends);

        // Tell the network...
        emit onCompound(_user, _dividends, _tokens, block.timestamp);

        // Then update the stats...
        accountOf_[_user].compounded = SafeMath.add(
            accountOf_[_user].compounded,
            _dividends
        );
        accountOf_[_user].xCompounded += 1;

        // Update the leaderboard...
        emit onUpdate(
            _user,
            accountOf_[_user].deposited,
            balanceOf_[_user],
            accountOf_[_user].withdrawn,
            block.timestamp
        );

        // Then trigger a distribution for everyone, you kind soul!
        distribute();

        // Successful function!
        return _tokens;
    }

    // Transfer Tokens (internal method)
    function _transferTokens(
        address _recipient,
        uint256 _amount
    ) internal returns (bool _success) {
        address _sender = msg.sender;
        require(_amount <= balanceOf_[_sender]);

        // Harvest any earnings before transferring, to help with cleaner accounting
        if (myEarnings() > 0) {
            harvest();
        }

        // "Move" the tokens...
        balanceOf_[_sender] = SafeMath.sub(balanceOf_[_sender], _amount);
        balanceOf_[_recipient] = SafeMath.add(balanceOf_[_recipient], _amount);

        // Adjust payout ratios to match the new balances...
        payoutsOf_[_sender] -= (int256)(profitPerShare_ * _amount);
        payoutsOf_[_recipient] += (int256)(profitPerShare_ * _amount);

        // If the recipient has zero activity, they're new - COUNT THEM!!!
        if (
            accountOf_[_recipient].deposited == 0 &&
            accountOf_[_recipient].receivedShares == 0
        ) {
            users += 1;
        }

        // Update stats...
        accountOf_[_sender].xTransferredShares += 1;
        accountOf_[_sender].transferredShares += _amount;
        accountOf_[_recipient].receivedShares += _amount;
        accountOf_[_recipient].xReceivedShares += 1;

        // Add this to the Tx counter...
        totalTxs += 1;

        // Tell the network, successful function!
        emit onTransfer(_sender, _recipient, _amount, block.timestamp);

        // Update the leaderboard for sender...
        emit onUpdate(
            _sender,
            accountOf_[_sender].deposited,
            balanceOf_[_sender],
            accountOf_[_sender].withdrawn,
            block.timestamp
        );

        // Update the leaderboard for recipient...
        emit onUpdate(
            _recipient,
            accountOf_[_recipient].deposited,
            balanceOf_[_recipient],
            accountOf_[_recipient].withdrawn,
            block.timestamp
        );

        return true;
    }
}