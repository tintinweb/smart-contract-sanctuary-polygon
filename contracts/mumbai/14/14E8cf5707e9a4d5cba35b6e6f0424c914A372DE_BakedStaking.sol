/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
    }
    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    
    return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    
    return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    
    return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    
    return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
    }
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// /**
// * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
// * the optional functions; to access them see {ERC20Detailed}.
// */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8);
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);
    
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);
    
    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);
    
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
    function allowance(address _owner, address spender) external view returns (uint256);
    
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
    function transferFrom(
    address sender,
    address recipient,
    uint256 amount
    ) external returns (bool);
    
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


contract Context {
    constructor()  {}
    
    function _msgSender_() internal view returns (address payable) {
    return payable(msg.sender);
    }
    
    function _msgData_() internal view returns (bytes memory) {
    this;
    return msg.data;
    }
}

contract Ownable is Context{
    address private _owner;
    
    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
    );
    
    constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
    return _owner;
    }
    
    modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
    }
    
    function isOwner() public view returns (bool) {
    return msg.sender == _owner;
    }
    
    function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
    require(
    newOwner != address(0),
    "Ownable: new owner is the zero address"
    );
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    }
}


contract TokenWrapper is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public BAKED; // BAKED Token address

    uint256 public _totalSupply;

    mapping(address => uint256) public _balances;
    
    function stakeTransfer(address _address,uint256 amount) internal virtual {
        require(BAKED.balanceOf(_address)>= amount,"Error: User Token Balance is insufficient");
        BAKED.safeTransferFrom(_address, address(this), amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[_address] = _balances[_address].add(amount);
    }
    
    function stakeWithdraw(address _address,uint256 amount) internal virtual{
        _totalSupply = _totalSupply.sub(amount);
        _balances[_address] = _balances[_address].sub(amount);
        BAKED.safeTransfer(_address, amount);
    }
    
}

contract BakedStaking is TokenWrapper {
    
    using SafeMath for uint256;

    bool public isStackPoolLive = true;     //stackpool status
    uint256 public duration = 30 days;      //unstake to release time duration  
    uint256 public minTokenValue= 25000000000000000000000;      //minimum token value
    uint256 stakeCounter = 0;   

     struct Stakepool {
        uint256 stakeId;
        uint256 amount;
        address userAddress;
        uint256 ticketCount;
        bool isStakeLive;
        uint256 stakeStartTime;
        uint256 stakeEndTime;
    }

    mapping (uint256 => Stakepool) public Stakemap; 
    mapping (address => uint256[]) private UserStakeList;
    mapping(address => uint256) private Totalticket;
    
    event Stake(uint256 stakeid,address user,uint256 amount);
    event Unstake(uint256 stakeid,address user);
    event Release(uint256 stakeid,address user);

    //to chnage minimum token values
    function adminSetMinTokenAmount(uint256 _minTokenAmount) external onlyOwner {
        minTokenValue = _minTokenAmount;
    }
    function setTokenContract(address _tokencontract) external onlyOwner{
        BAKED = IERC20(_tokencontract);
    }
    
    //to set unstake time duration for releasing tokens
    function adminSetDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    //to change the stake status of pool(live or not) 
    function changeStakePoolStatus(bool _status) external onlyOwner{
        isStackPoolLive = _status;
    }
    
    //stake function which set a new stake structure
    function stake(uint256 amount) external {
        require(isStackPoolLive,"stack pool is not live");
        require(amount >= minTokenValue, "Error : Canot stake, need minimum Baked tokens");
        stakeTransfer(msg.sender,amount);
        Stakemap[stakeCounter].stakeId = stakeCounter;
        Stakemap[stakeCounter].amount = amount;
        Stakemap[stakeCounter].userAddress = msg.sender;
        Stakemap[stakeCounter].stakeStartTime = block.timestamp;
        Stakemap[stakeCounter].ticketCount = amount.div(minTokenValue);
        Stakemap[stakeCounter].isStakeLive = true;
        UserStakeList[msg.sender].push(stakeCounter);
        emit Stake(stakeCounter,msg.sender,amount);
        stakeCounter++;
    }

    //unstake function which sets the stake for release the token    
    function unStake(uint256 _stkId) external{
        require(isStackPoolLive,"stack pool is not live");
        require(msg.sender==Stakemap[_stkId].userAddress,"you are not the owner of this stake");
        require(Stakemap[_stkId].stakeEndTime == 0,"stake is already unstaked");
        Stakemap[_stkId].stakeEndTime = block.timestamp + duration;
        emit Unstake(_stkId,msg.sender);
    }
    
    //Release function which withdraw the amount to user and set stake status off
    function release(uint256 _stkId) external{
        require(isStackPoolLive,"stack pool is not live");
        require(msg.sender==Stakemap[_stkId].userAddress,"you are not the owner of this stake");
        require(Stakemap[_stkId].stakeEndTime != 0,"this stake is not unstake yet");
        require(block.timestamp > Stakemap[_stkId].stakeEndTime,"User not Completed the Lock duration");
        stakeWithdraw(msg.sender,Stakemap[_stkId].amount);
        Stakemap[_stkId].isStakeLive = false;
        emit Release(_stkId,msg.sender);
    }

    //to set users and their tickets
    function batchUserTicketUpdates(address[] memory _addresses,uint256[] memory _tickets) external onlyOwner {
        require(_addresses.length == _tickets.length,"users and ticket count error");
        uint i;
        for(i=0;i<_addresses.length;i++){
            Totalticket[_addresses[i]] = _tickets[i];
        }
    }

    //to fetch totalticket count of user
    function totalTicket(address _address) external view returns (uint256) {
        uint256 i;
        uint256 ticket=0;
        if(UserStakeList[_address].length >=1){
            for(i=0;i<UserStakeList[_address].length;i++){
                if(Stakemap[UserStakeList[_address][i]].isStakeLive){
                    if((Stakemap[UserStakeList[_address][i]].stakeEndTime > block.timestamp) 
                        || (Stakemap[UserStakeList[_address][i]].stakeEndTime == 0)){
                        
                        ticket += Stakemap[UserStakeList[_address][i]].ticketCount;
                    }
                }
            }
        }
        ticket += Totalticket[_address];
        return ticket;
    }

    function getAllStakes(address _address) external view returns(uint256[] memory){
        return UserStakeList[_address];
    }
}