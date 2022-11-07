/**
 *Submitted for verification at polygonscan.com on 2022-11-06
*/

// SPDX-License-Identifier: GPL-3.0
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: contract5.sol


pragma solidity >=0.8.15;




contract Rewards_V5 is Ownable, Pausable {
  
    address public rewardToken;
    address public addressFee;
    uint public deployedTS;
    uint public rewardsPerDay;
    uint public requiredTokensBalance;
    uint public limitOfVerificationTokens;
    uint public addressFeeAmount;

//Mappings & Arrays

    mapping(address => uint) public startTS;
    mapping(address => bool) public userBlockedFromRewards;
    address[] public verificationTokens;
    address[] public participants;

//Events

    event addVerificationTokensAddress(address _newAddress, address _user);
    event deleteVerificationTokensAddress(address _delaeteAddress, address _user);
    event changeLimitOfVerificationTokens(uint _lastLimitOfVerificationTokens, uint _newLimitOfVerificationTokens);
    event changeRequiredTokensBalance(uint _lastRequiredTokensBalance, uint _newRequiredTokensBalance);
    event changeAddressFee(address _lastAddressFee, address _newAddressFee);
    event changeAddressFeeAmount(uint _lastAddressFeeAmount, uint _newAddressFeeAmount);

//Modifier

    ///@dev Check if the user has enough balance in the allowed token list
    modifier checkAccountBalance() {
        bool _userHasBalance;
        for(uint i = 0; i < verificationTokens.length; i++){
            uint _userBalance = IERC20(verificationTokens[i]).balanceOf(msg.sender);

            if(_userBalance >= requiredTokensBalance && _userHasBalance == false){
                _userHasBalance = true;
            }
        }
        require(_userHasBalance, "Error: User has insufficient balance");
        _;
    }

    ///@dev Check if the user is blocked from receiving rewards
    modifier checkIfUserAreBlocked() {
        require(!userBlockedFromRewards[msg.sender], "Error: User blocked from rewards");
        _;
    }

//Constructor

    /**
        @param _verificationToken First token in the list that will be used to validate users
        @param _rewardToken Token that will be used to give rewards
        @param _addressFee Token address to charge fee
        @param _requiredTokensBalance Minimum amount of token that the user must meet to receive rewards
        @param _limitOfVerificationTokens Maximum limit of tokens that can be added to the list of validation tokens
        @param _addressFeeAmount Token amount to charge fee
    */
    constructor(
        address _verificationToken, 
        address _rewardToken, 
        address _addressFee,
        uint _requiredTokensBalance, 
        uint _limitOfVerificationTokens,
        uint _addressFeeAmount
    ) {

        rewardsPerDay = 50e18; // wei, 18 decimals

        rewardToken = _rewardToken;
        limitOfVerificationTokens = _limitOfVerificationTokens;
        addressFee = _addressFee;

        requiredTokensBalance = _requiredTokensBalance * 10**18;
        addressFeeAmount = _addressFeeAmount * 10**18;

        verificationTokens.push(_verificationToken);
        deployedTS = block.timestamp;
    }

//Public Functions

    ///@notice Register the user in the list of rewards
    function addMe() public whenNotPaused checkAccountBalance {
        require(startTS[msg.sender] == 0, "Error: This address is already registered");

        participants.push(msg.sender);
        startTS[msg.sender] = block.timestamp; 
    }

    ///@notice Claim the rewards
    function claimRewards() public whenNotPaused checkIfUserAreBlocked {
        require(startTS[msg.sender] != 0, "Error: No record of user account");

        uint rewardAmount = (block.timestamp - startTS[msg.sender]) * rewardsPerDay / 1 days / participants.length;
        startTS[msg.sender] = block.timestamp;
        IERC20(rewardToken).transfer(msg.sender, rewardAmount);
    }

    ///@dev Allowed users will be able to add tokens which will be used to validate users
    function addVerificationTokenAddress( address _newVerificationTokenAddress ) public whenNotPaused {
        require(verificationTokens.length < limitOfVerificationTokens, "Error: No more addresses allowed");

        require(
            IERC20(addressFee).transferFrom(msg.sender, address(this), addressFeeAmount),
            "Error: Insufficient balance"
        );

        for(uint i = 0; i < verificationTokens.length; i++){
            require(_newVerificationTokenAddress != verificationTokens[i], "Error: Address already registered");
        }

        verificationTokens.push(_newVerificationTokenAddress);

        emit addVerificationTokensAddress(_newVerificationTokenAddress, msg.sender);
    }

//View Functions

    ///@notice Reflects accumulated rewards
    function userEarnings(address _user) public view returns(uint256) {
        require(!userBlockedFromRewards[_user], "Error: User blocked from rewards");

        if (startTS[_user] == 0){
            return 0;
        } 

        uint rewardAmount = (block.timestamp - startTS[_user]) * rewardsPerDay / 1 days / participants.length;
        return rewardAmount;
    }

    ///@notice Returns the number of users registered in the contract
    function getNumberOfParticipants() public view returns(uint){
        return participants.length;
    }

//Update Contract Functions

    /**
        @notice Update the list of users who can claim rewards, all this by validating whether they meet the minimum 
        amount of token established in the token list.
    */
    function updateDataInContract() external whenNotPaused {
        for(uint i = 0; i < participants.length; i++){

            bool _userHasBalance;
            for(uint j = 0; j < verificationTokens.length; j++){
                uint _userBalance = IERC20(verificationTokens[j]).balanceOf(participants[i]);

                if(_userBalance >= requiredTokensBalance && _userHasBalance == false){
                    _userHasBalance = true;
                }
            }
            
            if(!_userHasBalance){
                userBlockedFromRewards[participants[i]] = true;
                startTS[participants[i]] = block.timestamp;
            }else{
                userBlockedFromRewards[participants[i]] = false;
            }
        }
    }

//Only Owner Functions

    ///@dev The owner can withdraw the funds from the contract
    function withdrawFunds(address _token) public onlyOwner {

        uint _contractBalance = IERC20(_token).balanceOf(address(this));

        if(_contractBalance > 0){
            bool _success = IERC20(_token).transfer(msg.sender, _contractBalance);
            require(_success, "Error: Funds could not be withdrawn");
        }

        if(address(this).balance > 0){
            (bool _success,) = payable(msg.sender).call{ value: address(this).balance }("");
            require(_success, "Error: Funds could not be withdrawn");
        }
    }

    /**
        @dev Will remove some token address from the list of validator tokens
        @param _index Position of the token address within the list
    */
    function deleteVerificationTokenAddress(uint _index) public onlyOwner{
        require(
            verificationTokens.length > 0 && _index < verificationTokens.length, 
            "Error: This address cannot be deleted"
        );

        address _deleteAddress = verificationTokens[_index];
        for(uint i = _index; i < verificationTokens.length-1; i++){
            verificationTokens[i] = verificationTokens[i+1];      
        }
        
        verificationTokens.pop();

        emit deleteVerificationTokensAddress(_deleteAddress, msg.sender);
    }

    ///@dev The owner can change the minimum amount of token that a user must have to receive a reward
    function setRequiredTokensBalance(uint _newRequiredTokensBalance) public onlyOwner{
        require(_newRequiredTokensBalance > 0, "Error: The number must be greater than zero");
        require(
            _newRequiredTokensBalance != requiredTokensBalance, 
            "Error: The number must be different from the previous number"
        );

        uint _lastRequiredTokensBalance = requiredTokensBalance;
        requiredTokensBalance = _newRequiredTokensBalance * 10**18;

        emit changeRequiredTokensBalance(_lastRequiredTokensBalance, requiredTokensBalance);
    }

    ///@dev The owner can modify the maximum token limit that the list of validation tokens can accept.
    function setLimitOfVerificationTokens(uint _newLimitOfVerificationTokens) public onlyOwner{
        require(_newLimitOfVerificationTokens > 0, "Error: The number must be greater than zero");
        require(
            _newLimitOfVerificationTokens != limitOfVerificationTokens, 
            "Error: The number must be different from the previous number"
        );

        uint _lastLimitOfVerificationTokens = limitOfVerificationTokens;
        limitOfVerificationTokens = _newLimitOfVerificationTokens;

        emit changeLimitOfVerificationTokens(_lastLimitOfVerificationTokens, limitOfVerificationTokens);
    }

    /**
        @dev The owner can change the token address to be used to charge fees for users to register token 
        addresses within the contract
    */
    function setAddressFee(address _newAddressFee) public onlyOwner {
        require(
            (_newAddressFee != address(0)) && (_newAddressFee != addressFee),
            "Error: Invalid address to address fee"
        );

        address _lastAddressFee = addressFee;
        addressFee = _newAddressFee;

        emit changeAddressFee(_lastAddressFee, addressFee);
    }

    /**
        @dev The owner can change the amount of the token to be used to charge a fee for users to register token 
        addresses within the contract
    */
    function setAddressFeeAmount(uint _newAddressFeeAmount) public onlyOwner {
        require(_newAddressFeeAmount > 0, "Error: The number must be greater than zero");

        uint _lastAddressFeeAmount = addressFeeAmount;
        addressFeeAmount = _newAddressFeeAmount * 10**18;

        emit changeAddressFeeAmount(_lastAddressFeeAmount, addressFeeAmount);
    }

    ///@dev The owner will pause the main functions of the contract
    function pauseContract() public onlyOwner{
        _pause();
    }

    ///@dev The owner will unpause the main functions of the contract
    function unpauseContract() public onlyOwner{
        _unpause();
    }
}