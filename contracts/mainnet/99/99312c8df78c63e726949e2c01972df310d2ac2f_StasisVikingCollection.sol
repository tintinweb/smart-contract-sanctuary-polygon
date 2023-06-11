/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

contract Ownable {

    address public owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IStaking {
    function stake(address user, uint256 amount) external;
}

contract StasisVikingCollection is Context, ERC165, IERC721, IERC721Metadata, ReentrancyGuard, Ownable {
    using Address for address;
    using SafeMath for uint256;

    // total number of NFTs Minted
    uint256 private _totalSupply;
    uint256 public currentSupplyIndex;

    // max supply cap
    uint256 public constant MAX_SUPPLY = 700;

    // max mint
    uint256 public maxMint = 3;

    // Reward Distribution Criteria
    uint256 public lastRewardTime;
    uint256 public rewardWaitTime = 7 days;
    uint256 public decay_rate = 33;
    uint256 private constant FEE_DENOM = 10000;

    // cost for minting NFT
    uint256 public cost = 700 * 10**6;

    // Redeem Fee
    uint256 public redeemFee = 2000;

    // Current Reward Cycle Index
    uint256 public currentRewardCycle;

    // base URI
    string private baseURI = "temp/";
    string private ending = ".json";

    // Token name
    string private constant _name = "Stasis Viking Collection";

    // Token symbol
    string private constant _symbol = "SVC";

    // Reward Token (STS)
    address public rewardToken;

    // List of all holders
    address[] public allHolders;

    // Enable Trading
    bool public tradingEnabled = false;

    // Holder Structure
    struct Holder {
        uint256 index;
        bool autoStake;
    }

    // Locking the contract structure for reward distribution
    struct LockedForRewards {
        uint256 distributionPerNFT;
        uint256 holderIndex;
        bool active;
    }

    mapping ( address => Holder ) public holderInfo;

    // Has Permission To Claim Mapping
    mapping ( address => bool ) public canClaimRewards;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Maps a reward cycle to data pertaining to those rewards
    mapping ( uint256 => LockedForRewards ) public rewardCycles;

    // STS Staking Contract
    address public STS_Staking;

    // List of all burned token IDs
    uint256[] public allRedeemedTokens;

    address public immutable USDC;

    address public mintReceiver;

    // events
    event MaxMintSet(uint256 maxMint);
    event mintReceiverSet(address mintReceiver);
    event DecayRateSet(uint256 decayRate);
    event RewardWaitTimeSet(uint256 rewardWaitTime);
    event MintingEnabled();
    event MintingDisabled();
    event CostSet(uint256 cost);
    event BaseURISet(string baseURI);
    event URIExtentionSet(string extention);
    event CanClaimRewardsSet(address user, bool canClaim);
    event RedeemFeeSet(uint256 fee);
    event STSStakingSet(address staking);
    event RewardTokenSet(address rewardToken);
    

    constructor(address rewardToken_, address STS_Staking_, address USDC_, address mintReceiver_) {
        rewardToken = rewardToken_;
        STS_Staking = STS_Staking_;
        USDC = USDC_;
        mintReceiver = mintReceiver_;
    }

    ////////////////////////////////////////////////
    ///////////     OWNER FUNCTIONS      ///////////
    ////////////////////////////////////////////////

    function initRewards() external onlyOwner {
        require(lastRewardTime == 0, 'Already Initialized');
        lastRewardTime = block.timestamp;
    }

    function setMaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
        emit MaxMintSet(maxMint);
    }

    function setMintReceiver(address newReceiver) external onlyOwner {
        mintReceiver = newReceiver;
        emit mintReceiverSet(newReceiver);
    }

    function setDecayRate(uint256 newRate) external onlyOwner {
        require(
            newRate <= FEE_DENOM / 2,
            'Decay Rate Too High'
        );
        decay_rate = newRate;
        emit DecayRateSet(newRate);
    }

    function setRewardWaitTime(uint256 newWaitTime) external onlyOwner {
        require(
            newWaitTime <= 365 days,
            'Wait Time Too Long'
        );
        rewardWaitTime = newWaitTime;
        emit RewardWaitTimeSet(newWaitTime);
    }

    function enableMinting() external onlyOwner {
        tradingEnabled = true;
        emit MintingEnabled();
    }

    function disableMinting() external onlyOwner {
        tradingEnabled = false;
        emit MintingDisabled();
    }

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function withdrawToken(address token_) external onlyOwner {
        require(token_ != address(0), 'Zero Address');
        IERC20(token_).transfer(msg.sender, IERC20(token_).balanceOf(address(this)));
    }

    function setCost(uint256 newCost) external onlyOwner {
        cost = newCost;
        emit CostSet(newCost);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
        emit BaseURISet(newURI);
    }

    function setURIExtention(string calldata newExtention) external onlyOwner {
        ending = newExtention;
        emit URIExtentionSet(newExtention);
    }

    function ownerMint(address to, uint256 qty) external onlyOwner {
        for (uint256 i = 0; i < qty;) {
            _safeMint(to, currentSupplyIndex);
            unchecked { ++i; }
        }
    }

    function setCanClaimRewards(address user, bool canClaim) external onlyOwner {
        canClaimRewards[user] = canClaim;
        emit CanClaimRewardsSet(user, canClaim);
    }

    function setRedeemFee(uint256 newFee) external onlyOwner {
        require(newFee <= FEE_DENOM, 'Fee Too Large');
        redeemFee = newFee;
        emit RedeemFeeSet(newFee);
    }

    function setSTSStaking(address newStaking) external onlyOwner {
        STS_Staking = newStaking;
        emit STSStakingSet(newStaking);
    }

    function setRewardToken(address _newRewardToken) external onlyOwner {
        rewardToken = _newRewardToken;
        emit RewardTokenSet(_newRewardToken);
    }

    ////////////////////////////////////////////////
    ///////////     PUBLIC FUNCTIONS     ///////////
    ////////////////////////////////////////////////


    /** 
     * Mints `numberOfMints` NFTs To Caller
     */
    function mint(uint256 numberOfMints) external nonReentrant {
        require(
            tradingEnabled,
            'Trading Not Enabled'
        );
        require(
            numberOfMints > 0, 
            'Invalid Input'
        );
        // ensure max cap
        require(
            _balances[msg.sender] + numberOfMints <= maxMint,
            'Exceeds Max Mint'
        );

        uint256 amount = cost * numberOfMints;

        require(
            IERC20(USDC).allowance(msg.sender, address(this)) >= amount,
            "Must approve contract for USDC"
        );

       require(
        IERC20(USDC).transferFrom(msg.sender, mintReceiver, amount),
        "Can't pay!"
        );

        for (uint256 i = 0; i < numberOfMints;) {
            _safeMint(msg.sender, currentSupplyIndex);
            unchecked { ++i; }
        }
        
    }


    function claimRewards(uint256 iterations) external nonReentrant {
        require(
            canClaimRewards[msg.sender],
            'Not Allowed To Claim'
        );
        require(
            timeUntilNextRewardDistribution() == 0,
            'Not Time For Distribution'
        );
        require(
            iterations > 0,
            'Cannot Have Zero Iterations'
        );

        if (rewardCycles[currentRewardCycle].holderIndex == 0) {
            // first claim, set data
            rewardCycles[currentRewardCycle].active = true;
            rewardCycles[currentRewardCycle].distributionPerNFT = nextRewardDistributionPerNFT();
        }

        // get the claim amount per NFT
        uint256 claimPerNFT = rewardCycles[currentRewardCycle].distributionPerNFT;

        // determine the number of holders for gas savings
        uint256 numHolders = allHolders.length;
        uint256 startingIndex = rewardCycles[currentRewardCycle].holderIndex;
        
        // loop through list of holders, sending them their portion of rewards
        for (uint256 i = 0; i < iterations;) {
            if (startingIndex + i >= numHolders) {
                // claim is finished, clean up data and move to next cycle

                // reset reward time
                lastRewardTime = block.timestamp;

                // move to next cycle
                currentRewardCycle++;

                // break out of loop
                break;
            }

            // current holder being evaluated
            address holder = allHolders[startingIndex + i];

            if (holderInfo[holder].autoStake) {

                // approve and stake tokens for user
                IERC20(rewardToken).approve(STS_Staking, claimPerNFT * _balances[holder]);
                IStaking(STS_Staking).stake(holder, claimPerNFT * _balances[holder]);
            } else {

                // transfer tokens directly to user
                require(
                    IERC20(rewardToken).transfer(holder, claimPerNFT * _balances[holder]),
                    "Can't transfer tokens!");
            }

            unchecked { 
                ++i;
                ++rewardCycles[currentRewardCycle].holderIndex;
            }
        }
    }

    function burn(uint256 tokenID) external nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenID), 
            "caller not owner nor approved"
        );
        require(
            rewardCycles[currentRewardCycle].active == false,
            'Reward Cycle Is Active'
        );
        _burn(tokenID);
    }

    function redeem(uint256 tokenID) external nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenID), 
            "caller not owner nor approved"
        );
        require(
            rewardCycles[currentRewardCycle].active == false,
            'Reward Cycle Is Active'
        );

        // determine amount of STS they should get back from redemption
        uint256 amountToRedeem = redeemAmount();

        // burn the token, reducing total supply
        _burn(tokenID);

        // send STS to caller
        require(
            IERC20(rewardToken).transfer(msg.sender, amountToRedeem),
            "Can't transfer STS!");
    }

    function setAutoStake(bool shouldAutoStake) external {
        holderInfo[msg.sender].autoStake = shouldAutoStake;
    }

    receive() external payable {}

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address wpowner = ownerOf(tokenId);
        require(to != wpowner, "ERC721: approval to current owner");

        require(
            _msgSender() == wpowner || isApprovedForAll(wpowner, _msgSender()),
            "ERC721: not approved or owner"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), _operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
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
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }



    ////////////////////////////////////////////////
    ///////////    INTERNAL FUNCTIONS    ///////////
    ////////////////////////////////////////////////


    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
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
    function _mint(address to, uint256 tokenId) internal {
        require(!_exists(tokenId), "already minted");
        require(currentSupplyIndex < MAX_SUPPLY, 'All NFTs Have Been Minted');

        // add to holders list
        if (_balances[to] == 0) {
            holderInfo[to].index = allHolders.length;
            allHolders.push(to);
        }

        _owners[tokenId] = to;
        unchecked {
            _balances[to]++;
            currentSupplyIndex++;
            _totalSupply++;
        }

        emit Transfer(address(0), to, tokenId);
    }

    function _removeHolder(address from) internal {

        // set last element index to be removed index
        holderInfo[
            allHolders[allHolders.length - 1]
        ].index = holderInfo[from].index;

        // set removed element to be last element
        allHolders[
            holderInfo[from].index
        ] = allHolders[allHolders.length - 1];

        // pop off last element
        allHolders.pop();
        delete holderInfo[from].index;
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
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: non ERC721Receiver implementer");
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
    ) internal nonReentrant {
        require(ownerOf(tokenId) == from, "Incorrect owner");
        require(to != address(0), "zero");
        require(balanceOf(from) > 0, 'Zero Balance');
        require(
            rewardCycles[currentRewardCycle].active == false,
            'Reward Cycle Is Active'
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // add to holders list
        if (_balances[to] == 0) {
            holderInfo[to].index = allHolders.length;
            allHolders.push(to);
        }

        // Allocate balances
        _balances[from] = _balances[from].sub(1);
        _balances[to] += 1;
        _owners[tokenId] = to;

        if (_balances[from] == 0) {
            _removeHolder(from);
        }

        // emit transfer
        emit Transfer(from, to, tokenId);
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
    function _burn(uint256 tokenId) internal {
        require(_exists(tokenId), 'Token Does Not Exist');

        // owner of token
        address owner = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // decrement balance
        _balances[owner] -= 1;
        delete _owners[tokenId];

        // decrement total supply
        _totalSupply -= 1;

        // remove from owner array if out of tokens
        if (_balances[owner] == 0) {
            _removeHolder(owner);
        }

        // add to list of burned tokens
        allRedeemedTokens.push(tokenId);

        // emit transfer
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address wpowner,
        address _operator,
        bool approved
    ) internal {
        require(wpowner != _operator, "ERC721: approve to caller");
        _operatorApprovals[wpowner][_operator] = approved;
        emit ApprovalForAll(wpowner, _operator, approved);
    }



    ////////////////////////////////////////////////
    ///////////      READ FUNCTIONS      ///////////
    ////////////////////////////////////////////////

    function nextRewardTimestamp() public view returns (uint256) {
        return lastRewardTime + rewardWaitTime;
    }

    function timeUntilNextRewardDistribution() public view returns (uint256) {
        if (lastRewardTime == 0) {
            return ~uint256(0);
        }
        uint256 nextRewardTime = nextRewardTimestamp();
        return block.timestamp < nextRewardTime ? nextRewardTime - block.timestamp : 0;
    }

    function nextRewardDistributionTotal() public view returns (uint256) {
        return ( IERC20(rewardToken).balanceOf(address(this)) * decay_rate ) / FEE_DENOM;
    }

    function nextRewardDistributionPerNFT() public view returns (uint256) {
        return nextRewardDistributionTotal() / _totalSupply;
    }

    /**
        Pending STS Rewards For `account`
     */
    function pendingRewards(address account) public view returns (uint256) {
        return ( _balances[account] * nextRewardDistributionTotal() ) / _totalSupply;
    }

    function viewAllHolders() public view returns (address[] memory) {
        return allHolders;
    }

    function nHolders() public view returns (uint256) {
        return allHolders.length;
    }

    function redeemAmountWithoutFee() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this)) / _totalSupply;
    }

    function redeemAmount() public view returns (uint256) {
        uint256 amountNoFee = redeemAmountWithoutFee();
        return amountNoFee - ( ( amountNoFee * redeemFee ) / FEE_DENOM );
    }

    function getAllRedeemedTokenIDs() external view returns (uint256[] memory) {
        return allRedeemedTokens;
    }

    function allRedeemedTokenIDsLen() external view returns (uint256) {
        return allRedeemedTokens.length;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function getIDsByOwner(address owner) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](balanceOf(owner));
        if (balanceOf(owner) == 0) return ids;
        uint256 count = 0;
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (_owners[i] == owner) {
                ids[count] = i;
                count++;
            }
        }
        return ids;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address wpowner) public view override returns (uint256) {
        require(wpowner != address(0), "query for the zero address");
        return _balances[wpowner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address wpowner = _owners[tokenId];
        require(wpowner != address(0), "query for nonexistent token");
        return wpowner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory idstr = uint2str(tokenId);
        string memory fHalf = string.concat(baseURI, idstr);
        return string.concat(fHalf, ending);
    }

    /**
        Converts A Uint Into a String
    */
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address wpowner, address _operator) public view override returns (bool) {
        return _operatorApprovals[wpowner][_operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        address wpowner = ownerOf(tokenId);
        return (spender == wpowner || getApproved(tokenId) == spender || isApprovedForAll(wpowner, spender));
    }

    function onReceivedRetval() public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
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
                    revert("ERC721: non ERC721Receiver implementer");
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
}