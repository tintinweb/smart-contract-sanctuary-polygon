/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: contracts/SWCT_ICO.sol


pragma solidity ^0.8.7;




contract SWCT_ICO is Ownable {
    using Address for address;

    IERC20 public SWCT_TOKEN = IERC20(0x86ff422Ff39f87A219265b204c0F1598440B72Ca);
    address private COMPANY_WALLET = address(0xA1c485DDa5606E3E0e323D2B85B5144CAf874F15);

    uint256 public MAX_CONTRIBUTE_PRIVATE = 10000 ether; // 10000 MATIC
    uint256 public MAX_CONTRIBUTE_PRESALE = 10000 ether; // 10000if MATIC
    uint256 public MAX_CONTRIBUTE_PUBLIC = 10000 ether; // 500 MATIC

    uint256 public SWCT_PRICE_PRIVATE = 0.1 ether / 10**8; // 0.1 MATIC / SWCT
    uint256 public SWCT_PRICE_PRESALE = 0.1 ether / 10**8; // 0.1 MATIC / SWCT
    uint256 public SWCT_PRICE_PUBLIC = 0.1 ether / 10**8; // 0.1 MATIC / SWCT

    uint256 public START_DATETIME_PRIVATE = 1670263200; // December 5, 2022 18:00:00 PM GMT
    uint256 public END_DATETIME_PRIVATE = 1672531140; // December 31, 2022 4:59:00 PM GMT
    uint256 public START_DATETIME_PRESALE = 1641020400; // January 01, 2023 12:00:00 AM GMT
    uint256 public END_DATETIME_PRESALE = 1646092740; // February 28, 2023 4:59:00 PM GMT 
    uint256 public START_DATETIME_PUBLIC = 1646118000; // March 1, 2023 12:00:00 AM GMT
    uint256 public END_DATETIME_PUBLIC = 1651363140; // April 30, 2023 4:59:00 PM GMT

    mapping(address=>uint256) public MAP_DEPOSIT_PRIVATE;
    mapping(address=>uint256) public MAP_DEPOSIT_PRESALE;
    mapping(address=>uint256) public MAP_DEPOSIT_PUBLIC;

    mapping(address=>uint256) public MAP_CLAIM_PRIVATE;
    mapping(address=>uint256) public MAP_CLAIM_PRESALE;
    mapping(address=>uint256) public MAP_CLAIM_PUBLIC;

    uint256 public TOTAL_DEPOSIT_PRIVATE;
    uint256 public TOTAL_DEPOSIT_PRESALE;
    uint256 public TOTAL_DEPOSIT_PUBLIC;

    uint256 public HARDCAP_PRIVATE = 1440000 ether ;
    uint256 public HARDCAP_PRESALE = 1440000 ether;
    uint256 public HARDCAP_PUBLIC = 1920000 ether;

    mapping(address=>bool) public MAP_PRIVATE_LIST;

    bool public IDO_ENDED = false;

    constructor() {}

    function setSWCTToken(address _address) external onlyOwner {
        SWCT_TOKEN = IERC20(_address);
    }

    function setCompanyWallet(address _address) external onlyOwner {
        COMPANY_WALLET = _address;
    }

    function setPrivateList(address[] memory privateAddrs, bool bEnable) external onlyOwner {
        for (uint256 i = 0; i < privateAddrs.length; i++) {
            MAP_PRIVATE_LIST[privateAddrs[i]] = bEnable;
        }
    }

    function contributeForPrivate() external payable {
        require(block.timestamp >= START_DATETIME_PRIVATE && block.timestamp <= END_DATETIME_PRIVATE, "IDO is not activated");

        require(MAP_PRIVATE_LIST[msg.sender], "Invalid proof");
        
        require((MAP_DEPOSIT_PRIVATE[msg.sender] + msg.value) <= MAX_CONTRIBUTE_PRIVATE, "Exceeds Max Contribute Amount");

        require(TOTAL_DEPOSIT_PRIVATE + msg.value <= HARDCAP_PRIVATE, "Exceeds HardCap");

        payable(COMPANY_WALLET).transfer(msg.value);

        MAP_DEPOSIT_PRIVATE[msg.sender] += msg.value;

        TOTAL_DEPOSIT_PRIVATE += msg.value;
    }
    function contributeForPresale() external payable {
        require(block.timestamp >= START_DATETIME_PRESALE && block.timestamp <= END_DATETIME_PRESALE, "IDO is not activated");
        
        require((MAP_DEPOSIT_PRESALE[msg.sender] + msg.value) <= MAX_CONTRIBUTE_PRESALE, "Exceeds Max Contribute Amount");

        require(TOTAL_DEPOSIT_PRESALE + msg.value <= HARDCAP_PRESALE, "Exceeds HardCap");

        payable(COMPANY_WALLET).transfer(msg.value);

        MAP_DEPOSIT_PRESALE[msg.sender] += msg.value;

        TOTAL_DEPOSIT_PRESALE += msg.value;
    }
    function contributeForPublic() external payable {
        require(block.timestamp >= START_DATETIME_PUBLIC && block.timestamp <= END_DATETIME_PUBLIC, "IDO is not activated");

        require((MAP_DEPOSIT_PUBLIC[msg.sender] + msg.value) <= MAX_CONTRIBUTE_PUBLIC, "Exceeds Max Contribute Amount");

        require(TOTAL_DEPOSIT_PUBLIC + msg.value <= HARDCAP_PUBLIC, "Exceeds HardCap");

        payable(COMPANY_WALLET).transfer(msg.value);

        MAP_DEPOSIT_PUBLIC[msg.sender] += msg.value;

        TOTAL_DEPOSIT_PUBLIC += msg.value;
    }

    function reservedAmountPrivate(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PRIVATE[_address] / SWCT_PRICE_PRIVATE;
    }
    function reservedAmountPresale(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PRESALE[_address] / SWCT_PRICE_PRESALE;
    }
    function reservedAmountPublic(address _address) public view returns (uint256) {
        return MAP_DEPOSIT_PUBLIC[_address] / SWCT_PRICE_PUBLIC;
    }

    function claimForPrivate() public {
        require(IDO_ENDED , "IDO is not finished");
        
        uint256 remainedAmount = reservedAmountPrivate(msg.sender) - MAP_CLAIM_PRIVATE[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        SWCT_TOKEN.transfer(msg.sender, remainedAmount);

        MAP_CLAIM_PRIVATE[msg.sender] += remainedAmount;
    }
    function claimForPresale() public {
        require(IDO_ENDED , "IDO is not finished");
        
        uint256 remainedAmount = reservedAmountPresale(msg.sender) - MAP_CLAIM_PRESALE[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        SWCT_TOKEN.transfer(msg.sender, remainedAmount);

        MAP_CLAIM_PRESALE[msg.sender] += remainedAmount;
    }
    function claimForPublic() public {
        require(IDO_ENDED , "IDO is not finished");
        
        uint256 remainedAmount = reservedAmountPublic(msg.sender) - MAP_CLAIM_PUBLIC[msg.sender];
        
        require(remainedAmount > 0 , "Claimed all amount already");

        SWCT_TOKEN.transfer(msg.sender, remainedAmount);

        MAP_CLAIM_PUBLIC[msg.sender] += remainedAmount;
    }

    function airdrop(address[] memory _airdropAddresses, uint256 _airdropAmount) external onlyOwner {
        for (uint256 i = 0; i < _airdropAddresses.length; i++) {
            address to = _airdropAddresses[i];
            SWCT_TOKEN.transfer(to, _airdropAmount);
        }
    }

    function setPricePrivate(uint256 _newPrice) external onlyOwner {
        SWCT_PRICE_PRIVATE = _newPrice;
    }
    function setPricePresale(uint256 _newPrice) external onlyOwner {
        SWCT_PRICE_PRESALE = _newPrice;
    }
    function setPricePublic(uint256 _newPrice) external onlyOwner {
        SWCT_PRICE_PUBLIC = _newPrice;
    }

    function setMaxContributePrivate(uint256 _contribute) external onlyOwner {
        MAX_CONTRIBUTE_PRIVATE = _contribute;
    }
    function setMaxContributePresale(uint256 _contribute) external onlyOwner {
        MAX_CONTRIBUTE_PRESALE = _contribute;
    }
    function setMaxContributePublic(uint256 _contribute) external onlyOwner {
        MAX_CONTRIBUTE_PUBLIC = _contribute;
    }

    function setHardCapPrivate(uint256 _hardCap) external onlyOwner {
        HARDCAP_PRIVATE = _hardCap;
    }
    function setHardCapPresale(uint256 _hardCap) external onlyOwner {
        HARDCAP_PRESALE = _hardCap;
    }
    function setHardCapPublic(uint256 _hardCap) external onlyOwner {
        HARDCAP_PUBLIC = _hardCap;
    }

    function setSalePeriodPrivate(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        START_DATETIME_PRIVATE = _startTimestamp;
        END_DATETIME_PRIVATE = _endTimestamp;
    }
    function setMaxContributePresale(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        START_DATETIME_PRESALE = _startTimestamp;
        END_DATETIME_PRESALE = _endTimestamp;
    }
    function setMaxContributePublic(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwner {
        START_DATETIME_PUBLIC = _startTimestamp;
        END_DATETIME_PUBLIC = _endTimestamp;
    }


    function finishIDO(bool bEnded) external onlyOwner {
        IDO_ENDED = !bEnded;
    }

    function withdrawMATIC() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawSWCT() external onlyOwner {
        SWCT_TOKEN.transfer(msg.sender, SWCT_TOKEN.balanceOf(address(this)));
    }
}