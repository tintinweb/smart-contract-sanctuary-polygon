/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: Copy_birb_seedz_discord_income.sol


pragma solidity ^0.8.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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

    function geUnlockTime() public view returns (uint256) {
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

contract EligibleUser {

    bytes32 emptyString = keccak256(abi.encodePacked(""));

    constructor(address _address, string memory _discordName){

        getAddress = _address;

        if(keccak256(abi.encodePacked(_discordName)) != emptyString){
        discordName = _discordName;
        }
    }

    address public getAddress;
    string public discordName = "null";

    //uint public claimableTokens;
    uint public claimedTime = block.timestamp;

    function resetClaimedTime() public {
        claimedTime = block.timestamp;
    }

// Blacklisting
    bool public isBlacklisted;
    function setBlacklisted() public{
        isBlacklisted = true;
    }

    function removeBlacklisted() public {
        isBlacklisted = false;
    }
    }


contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract BirbSeedzDiscordDistribution is Ownable, ReEntrancyGuard {

    constructor(){
        
    }
    // Eligible users
    mapping(address => EligibleUser) public eligibleUsers;
    mapping(address => uint) public userAddressesToIndexMap;
    mapping(string => address) public discordNameToAddressMap;
    mapping(string => bool) public discordNameIsIndexed;

    uint public claimLockPeriod = 1 days;
    function setClaimLockPeriod(uint _newPeriod) public onlyOwner{
        claimLockPeriod = _newPeriod;
    }

    // Indexing
    EligibleUser[10000] indexedEligibleUsers;

    function getIndexedDiscordNameAt(uint index) public view returns (string memory){
        return indexedEligibleUsers[index].discordName();
    }

    function getIndexedAddressAt(uint index) public view returns (address){
        return indexedEligibleUsers[index].getAddress();
    }
    
    // Get per user
    function getEligibleUserDiscordName(address addr) public view returns(string memory){
        return eligibleUsers[addr].discordName();
    }

    function getEligibleUserLastClaimTime(address addr) public view returns(uint){
        return eligibleUsers[addr].claimedTime();
    }

    function getEligibleUserCanClaim(address addr) public view returns(bool){
        bool res = false;
        if(block.timestamp > eligibleUsers[addr].claimedTime() + claimLockPeriod){
            res = true;
        }
        return res;
    }

    // can claim is true if claimLockPeriod has passed since claimedTime
    //function canClaim() public view returns (bool){
    //    bool res = false;
    //    if(block.timestamp > claimedTime + claimLockPeriod){
    //        res = true;
    //   }
    //
    //    return res;
    //}

    function getEligibleUserNextClaimTime(address addr) public view returns(uint){
        return eligibleUsers[addr].claimedTime() + claimLockPeriod;
    }

    function setNotBlacklisted(address _addr) public onlyOwner {
        eligibleUsers[_addr].removeBlacklisted();
    }

    uint minClaimAmountPerDay = 67 * 10**9;
    uint maxClaimAmountPerDay = 167 * 10**9;

    function getClaimableTokenAmount(address addr) public view returns (uint){
        return (block.timestamp - eligibleUsers[addr].claimedTime()) * (getTokensPerDayLerped(addr) / 1 days); // 1440 minutes in day / 86400 seconds
    }

    // lerp tokens per day based on index a + (b - a ) * (1 - (normalize)t);
    function getTokensPerDayLerped(address addr) public view returns(uint){
        return minClaimAmountPerDay + (maxClaimAmountPerDay - minClaimAmountPerDay) * ((10000 - userAddressesToIndexMap[addr]))/10000;
    }

    function getTokensPerDayLerpedForIndex(uint index) public view returns (uint){
        return minClaimAmountPerDay + (maxClaimAmountPerDay - minClaimAmountPerDay) * ((10000 - index))/10000;
    }

    function getEligibleUserIsBlacklisted(address addr) public view returns(bool){
        return eligibleUsers[addr].isBlacklisted();
    }

    function eligibleUserExists(address addr) public view returns(bool){
        bool res = false;
        if(address(eligibleUsers[addr]) != address(0)){
            res = true;
        }
        return res;
    }

    bytes32 _nullDiscordName = keccak256(abi.encodePacked("null"));

    uint public claimCost = 50000000000000000; //0.05 matic
    function setClaimCost(uint _newCost) public onlyOwner{
        claimCost = _newCost;
    }

    function claimTokens() public payable noReentrant {
        require(msg.value >= claimCost, "Claim tax too low");
        require(eligibleUsers[msg.sender].isBlacklisted() == false, "You are blacklisted");
        require(keccak256(abi.encodePacked(eligibleUsers[msg.sender].discordName)) != _nullDiscordName, "Not eligible to claim, discord name is null");
        uint _claimableTokens = getClaimableTokenAmount(msg.sender);
        internalTransferERC20(birbzTokenAddress, msg.sender, _claimableTokens);
        eligibleUsers[msg.sender].resetClaimedTime();
    }

// Add remove users
    function userSelfAdd(string memory _discordName) public {
        require(eligibleUserExists(msg.sender) == false, "User already exists");
        EligibleUser newUser = new EligibleUser(msg.sender, _discordName);
        eligibleUsers[msg.sender] = newUser;
        // index the new user, update mappings
        indexedEligibleUsers[currentUserIndex] = newUser;
        userAddressesToIndexMap[msg.sender] = currentUserIndex;
        discordNameToAddressMap[_discordName] = msg.sender;
        discordNameIsIndexed[_discordName] = true;
        // move index with 1
        currentUserIndex += 1;
    }

// Can overwrite users
    function addUserByOwner(address _userAddr, string memory _discordName) public onlyOwner{
        EligibleUser newUser = new EligibleUser(_userAddr, _discordName);
        eligibleUsers[_userAddr] = newUser;
        // index the new user
        indexedEligibleUsers[currentUserIndex] = newUser;
        userAddressesToIndexMap[_userAddr] = currentUserIndex;
        discordNameToAddressMap[_discordName] = _userAddr;
        discordNameIsIndexed[_discordName] = true;
        // move index with 1
        currentUserIndex += 1;
    }

    function removeUserByOwner(address _userAddr) public onlyOwner{
        eligibleUsers[_userAddr] = new EligibleUser(_userAddr, "null");
    }

    function removeMultipleByDiscordUsername(string[] memory _usernames) public onlyOwner{
        // for each username to be removed
        for(uint i = 0; i < _usernames.length; i++){
            // get the index from the mappings
            address addr = discordNameToAddressMap[_usernames[i]];
            uint index = userAddressesToIndexMap[addr];
            // invalidate the eligibleuser entry by setting blacklisted to true
            indexedEligibleUsers[index].setBlacklisted();
            discordNameIsIndexed[_usernames[i]] = false;
            // Remove the index and move all of the rest down
            reorderEligibleUserIndexes(index);
        }
    }

    mapping(string => bool) userStillValid;
    string[] removeUsersList;

    function removeAllButTheseByDiscordUsername(string[] memory _usernames) public onlyOwner{

        // reset the mapping
        for(uint i = 0; i < currentUserIndex; i++){
            userStillValid[indexedEligibleUsers[i].discordName()] = false;
        }

        // populate with the current valid users
        for(uint i = 0; i < _usernames.length; i++){
            userStillValid[_usernames[i]] = true;
        }

        // clear the removeUsersList so we can populate it
        delete removeUsersList;
        
        for(uint i = 0; i < currentUserIndex; i++){
            string memory usr = indexedEligibleUsers[i].discordName();
            if(userStillValid[usr] == false){
                removeUsersList.push(usr);
            }
        }

        // if there's any entries to remove, go ahead and remove them
        if(removeUsersList.length > 0){
            removeMultipleByDiscordUsername(removeUsersList);
        }
    }

    uint public currentUserIndex = 0;

    // Reorder the array of eligible users by pushing each other entry down from removedIndex+
    // using currentUserIndex as it's a better indicator of the actual elements length in the array
    // because the array is initialized to 10000
    function reorderEligibleUserIndexes(uint _removedIndex) private {
        delete indexedEligibleUsers[_removedIndex];
        for(uint i = _removedIndex; i < currentUserIndex - 1; i++){
            // move mapping values 1 down for the newly assigned indexed user
            userAddressesToIndexMap[indexedEligibleUsers[i + 1].getAddress()] = i;
            indexedEligibleUsers[i] = indexedEligibleUsers[i + 1];
        }

        // move currentUserIndex 1 down as this is called every time we remove a user
        currentUserIndex -= 1;
    }

    // Token accumulation - obsolete
    uint public tokenAccumulationSpeed =  4 * 10**9; // 4 SDZ per day in wei

    function setTokenAccumulationSpeed(uint _newTAS) public onlyOwner{
        tokenAccumulationSpeed = _newTAS;
    }

  
    
    // Interface specific
    mapping(address => mapping(address => uint)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    mapping(address => uint) public balances;
    uint transferTimestamp;
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'Balance too low');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from,address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'Balance too low');
        require(allowance[from][msg.sender] >= value, 'Allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }

  
    // Custom Token ERC20 Specific
    //0xFb398Fb7Ff4FF7b532905f77dB07401FeC5FdDF8 - SDZ token Matic Mainnet
    //0x374Eb0DB241d9ce7Dba8598acbd9F9B1821ee929 - SDZ token Mumbai Testnet
    IERC20 public birbzTokenAddress = IERC20(0xFb398Fb7Ff4FF7b532905f77dB07401FeC5FdDF8);

    function setBirbzTokenAddress(IERC20 _newTokenAddress) public onlyOwner{
        birbzTokenAddress = _newTokenAddress;
    } 

    // only for owner
    function transferERC20(IERC20 token, address to, uint amount) public onlyOwner {
        uint erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Balance too low, can't transfer");
        token.transfer(to, amount);
    }

    // same as transferERC20 but only for internal use
    function internalTransferERC20(IERC20 token, address to, uint amount) private {
        uint erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Balance too low, can't transfer");
        token.transfer(to, amount);
    }

    function balanceOfERC20(IERC20 token) public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function withdraw() public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}