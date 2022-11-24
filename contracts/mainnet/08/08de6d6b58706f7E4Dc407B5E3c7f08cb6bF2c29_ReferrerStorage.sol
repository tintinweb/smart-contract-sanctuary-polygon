// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Managable.sol";

contract ReferrerStorage is Managable, Pausable, ReentrancyGuard {

    /// MUST be saved in the % * 100 form, e.g. 2.755% = 275
    uint256 public defaultRoyalty;
    uint32 public automaticApprovalWaitTime;

    /// @notice Referee (who was invited by a referrer) -> Referrer (who gets referral comission)
    mapping(address => address) public referrers;

    /// @notice Referrer (who gets referral comission) => Referee (who was invited by a referrer) => Royalty (will be saved in the % * 100 form, e.g. 2.75% = 275) 
    mapping(address => mapping(address => uint256)) public referrerRoyalty;

    /// @notice Referrer (who gets referral comission) => Token => Earned Reward 
    mapping(address => mapping(address => uint256)) public earnedReward;

    /// @notice Referrer (who gets referral comission) => Default withdrawal approval status
    mapping(address => bool) public defaultReferrerApproval;

    /// @notice ERC20 Address -> Bool
    mapping(address => bool) public allowedToken;

    /// @notice WithdrawRequest owner -> approval status 
    mapping(address => withdrawRequestStatus) private withdrawRequestApproves;

    address[] private withdrawRequests;

    struct withdrawRequestStatus {
        uint32 automaticApproveTime;
        bool approvalStatus;
        bool forbidden;
    }

    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    event DefaultRoyaltySet(uint256 _referrerRoyalty);
    event AutomaticApprovalWaitTimeSet(uint32 _automaticApprovalWaitTime);
    event ReferrerSet(address indexed _referrer, address _referree, uint256 _referrerRoyalty);
    event DefaultReferrerApprovalSet(address indexed _referrer, bool _defaultApproval);
    event TokenAdded(address _token);
    event TokenRemoved(address _token);
    event RewardAdded(address indexed _referrer, address _token, uint _amount);
    event RewardWithdrawn(address indexed _referrer, address _token, uint _amount);
    event RewardAsked(address indexed _referrer, uint32 automaticApprovalTime);
    event WithdrawalAllowed(address indexed _referrer);
    event WithdrawalDeclined(address indexed _referrer);
    event DeclinedForever(address indexed _referrer);
    event EmergencyWithdrawToken(address _to, address _token, uint quantity);

    /// @param _defaultRoyalty MUST be saved in the % * 100 form, e.g. 2.75% = 275
    constructor(uint _defaultRoyalty, uint32 _automaticApprovalWaitTime, address[] memory _allowedTokens) {

        defaultRoyalty = _defaultRoyalty;
        automaticApprovalWaitTime = _automaticApprovalWaitTime;
        _addManager(msg.sender);

        for(uint i = 0; i < _allowedTokens.length; i++){
            _addAllowedToken(_allowedTokens[i]);
        }
    }
 
    /// @notice Method for rewarding referrer
    /// @param _referrer Referrer address (who gets comissions)
    /// @param _token token address, ZERO_ADDRESS if MATIC
    /// @param _amount token amount
    function rewardReferrer(address _referrer, address _token, uint _amount) external payable onlyManager nonReentrant{        
        require(allowedToken[_token], "token not allowed");
        
        if(_token == ZERO_ADDRESS){
            require(msg.value == _amount, "incorrect amount");
        } else {
            require(IERC20(_token).transferFrom(msg.sender, address(this), _amount));
        }
        earnedReward[_referrer][_token] += _amount;
        emit RewardAdded(_referrer, _token, _amount);
    }

    function askForWithdrawal(address[] calldata _tokens) external {
        withdrawRequestStatus memory _status = withdrawRequestApproves[msg.sender];
        require(_status.automaticApproveTime == 0 && _status.approvalStatus == false, "already asked");

        for(uint i = 0; i < _tokens.length; i++){
            require(allowedToken[_tokens[i]], "token not allowed");

            uint _amount = earnedReward[msg.sender][_tokens[i]];
            require(_amount > 0, "zero token amount");
        }

        withdrawRequests.push(msg.sender);

        withdrawRequestStatus memory _newRequest;

        _newRequest.automaticApproveTime = uint32(block.timestamp) + automaticApprovalWaitTime;
        
        withdrawRequestApproves[msg.sender] = _newRequest;

        emit RewardAsked(msg.sender, _newRequest.automaticApproveTime);
    }

    function allowWithdrawal(address _referrer) external onlyManager {
        _allowWithdrawal(_referrer);
    }

    function multipleAllowWithdrawal(address[] calldata _referrers) external onlyManager {
        for (uint i = 0; i < _referrers.length; i++){
            _allowWithdrawal(_referrers[i]);
        }
    }

    function declineWithdrawal(address _referrer) external onlyManager {
        _declineWithdrawal(_referrer);
    }

    function multipleDeclineWithdrawal(address[] calldata _referrers) external onlyManager {
        for (uint i = 0; i < _referrers.length; i++){
            _declineWithdrawal(_referrers[i]);
        }
    }

    function declineWithdrawalForever(address _referrer) external onlyManager {
        _deleteFromWithdrawRequests(_referrer);
        withdrawRequestApproves[_referrer].forbidden = true;
        emit DeclinedForever(_referrer);
    }

    function _allowWithdrawal(address _referrer) internal {
        require(withdrawRequestApproves[_referrer].automaticApproveTime != 0, "no withdrawal request");
        withdrawRequestApproves[_referrer].approvalStatus = true;
        emit WithdrawalAllowed(_referrer);
    }

    function _declineWithdrawal(address _referrer) internal {
        _deleteFromWithdrawRequests(_referrer);
        emit WithdrawalDeclined(_referrer);
    }

    function withdrawRewards(address[] calldata _tokens) external nonReentrant {
        withdrawRequestStatus memory _status = withdrawRequestApproves[msg.sender];

        require(_status.forbidden == false, "forbidden");

        if(_status.approvalStatus == false){
            if(defaultReferrerApproval[msg.sender] == false){
                require(_status.automaticApproveTime != 0, "did not find request");
                require(block.timestamp >= _status.automaticApproveTime, "not approved");
            }
        }

        for(uint i = 0; i < _tokens.length; i++){
            require(allowedToken[_tokens[i]], "token not allowed");

            uint _amount = earnedReward[msg.sender][_tokens[i]];
            require(_amount > 0, "zero token amount");

            earnedReward[msg.sender][_tokens[i]] = 0;
            
            if(_tokens[i] == ZERO_ADDRESS){
                (bool success,) = payable(msg.sender).call{value: _amount, gas: 50000}("");
                require(success, "native call fail");
            } else {
                require(IERC20(_tokens[i]).transfer(msg.sender, _amount));
            }
            
            emit RewardWithdrawn(msg.sender, _tokens[i], _amount);
        }
        _deleteFromWithdrawRequests(msg.sender);
    }

    /// @notice Method for getting royalty of the referrer for referree
    /// @param _referrer Referrer address (who gets comissions)
    /// @param _referree Referree address (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    function getReferrerRoyalty(address _referrer, address _referree) external view returns(uint256 _royaltyPercMulByHundreed){
        return referrerRoyalty[_referrer][_referree];
    }

    /// @notice Method for getting royalty of the referrer for referree
    /// @param _referree Referree address (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    function getReferreeComission(address _referree) external view returns(address _referrer, uint256 _royaltyPercMulByHundreed){
         _referrer = referrers[_referree];
        return (_referrer, referrerRoyalty[_referrer][_referree]);
    }

    function getReferrerEarnedRewards(address _referrer, address[] calldata _tokens) external view returns(uint[] memory) {
        uint[] memory _amount = new uint[](_tokens.length);

        for(uint i = 0; i < _tokens.length; i++){
            _amount[i] = earnedReward[_referrer][_tokens[i]];
        }

        return _amount;
    }

    function getWithdrawRequests() external onlyManager view returns(address[] memory _withdrawRequests) {
        return withdrawRequests;
    }

    function getWithdrawRequestApprovalStatus(address _owner) external view returns(bool _approvalStatus) {
        return withdrawRequestApproves[_owner].approvalStatus;
    }

    function getForbiddenStatus(address _owner) external view returns(bool _forbiddenStatus) {
        return withdrawRequestApproves[_owner].forbidden;
    }

    function getWithdrawRequestAutomaticApprovalTime(address _owner) external view returns(uint32 _automaticApproveTime) {
        return withdrawRequestApproves[_owner].automaticApproveTime;
    }

    /// @notice Method for setting royalty for referrer
    /// @param _referrer Referrer address (who gets comissions)
    /// @param _referree Referree address (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    function setReferrer(address _referrer, address _referree, uint256 _royaltyPercMulByHundreed) external onlyManager {
        _setReferrer(_referrer, _referree, _royaltyPercMulByHundreed);
    }

    /// @notice Method for setting referree and royalty for multiple referrers
    /// @param _referrer Referrer address (who gets comissions),
    /// @param _referree Referree addresses (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    /// @param _royaltyPercMulByHundreed !!! Must be of the same order referree
    function setMultipleReferees(
        address[] calldata _referrer,
        address[] calldata _referree,
        uint256[] calldata _royaltyPercMulByHundreed
    ) external onlyManager {
        require(_referree.length == _royaltyPercMulByHundreed.length && _referree.length == _referrer.length, "invalid length");
        require(_referree.length <= 100, "too big length");

        for (uint i = 0;i < _referrer.length; i++){
            _setReferrer(_referrer[i], _referree[i], _royaltyPercMulByHundreed[i]);
        }
    }

    /// @notice Method for setting multiple referree/royalty for one referrer
    /// @param _referrer Referrer address (who gets comissions),
    /// @param _referree Referree addresses (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    /// @param _royaltyPercMulByHundreed !!! Must be of the same order referree
    function setMultipleRefereesForOneReferrer(
        address _referrer,
        address[] calldata _referree,
        uint256[] calldata _royaltyPercMulByHundreed
    ) external onlyManager {
        require(_referree.length == _royaltyPercMulByHundreed.length, "invalid length");
        require(_referree.length <= 100, "too big length");

        for (uint i = 0;i < _referree.length; i++){
            _setReferrer(_referrer, _referree[i], _royaltyPercMulByHundreed[i]);
        }
    }

    /// @notice Method for setting default withdrawal approval for a referrer
    /// @param _referrer Referrer address (who gets comissions)
    function setDefaultReferrerApproval(address _referrer, bool _defaultApproval) external onlyManager {
        _setDefaultReferrerApproval(_referrer, _defaultApproval);
    }

    /// @notice Method for setting default withdrawal approval for a referrer
    /// @param _referrer Referrer address (who gets comissions)
    function setMultipleDefaultReferrerApproval(address[] calldata _referrer, bool[] calldata _defaultApproval) external onlyManager {
        require(_referrer.length == _defaultApproval.length, "invalid length");
        require(_referrer.length <= 200, "too big length");

        for (uint i = 0;i < _referrer.length; i++){
            _setDefaultReferrerApproval(_referrer[i], _defaultApproval[i]);
        }
    }

    /// @notice Method for setting default royalty for all referrers
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275)
    function setDefaultRoyalty(uint256 _royaltyPercMulByHundreed) external onlyManager {
        require(_royaltyPercMulByHundreed <= 10000, "invalid royalty");
        defaultRoyalty = _royaltyPercMulByHundreed;
        emit DefaultRoyaltySet(_royaltyPercMulByHundreed);
    }

    /// @notice Method for setting wait time before withdrawal without approval
    function setAutomaticApprovalWaitTime(uint32 _automaticApprovalWaitTime) external onlyManager {
        automaticApprovalWaitTime = _automaticApprovalWaitTime;
        emit AutomaticApprovalWaitTimeSet(_automaticApprovalWaitTime);
    }

    function addAllowedToken(address _token) external onlyManager {
        _addAllowedToken(_token);
    }

    function removeAllowedToken(address _token) external onlyManager {
        require(allowedToken[_token], "token does not exist");
        allowedToken[_token] = false;
        emit TokenRemoved(_token);
    }

    /// @param _referrer Referrer address (who gets comissions)
    /// @param _referree Referree address (who was invited by a referrer)
    /// @param _royaltyPercMulByHundreed Royalty !!! (MUST be saved in the % * 100 form, e.g. 2.75% = 275) if 0 will be set to Default
    function _setReferrer(address _referrer, address _referree, uint256 _royaltyPercMulByHundreed) internal {
        require(_referree != ZERO_ADDRESS && _referrer != ZERO_ADDRESS, "invalid address");
        require(_referrer != _referree, "same address");
        require(_royaltyPercMulByHundreed <= 10000, "invalid royalty");

        referrers[_referree] = _referrer;

        if(_royaltyPercMulByHundreed == 0){
            referrerRoyalty[_referrer][_referree] = defaultRoyalty;
            emit ReferrerSet(_referrer, _referree,  defaultRoyalty);
        } else {
            referrerRoyalty[_referrer][_referree] = _royaltyPercMulByHundreed;
            emit ReferrerSet(_referrer, _referree,  _royaltyPercMulByHundreed);
        }
    }

    /// @param _referrer Referrer address (who gets comissions)
    function _setDefaultReferrerApproval(address _referrer, bool _defaultApproval) internal {
        defaultReferrerApproval[_referrer] = _defaultApproval;
        emit DefaultReferrerApprovalSet(_referrer, _defaultApproval);
    }

    function _addAllowedToken(address _token) internal {
        require(!allowedToken[_token], "token already added");
        allowedToken[_token] = true;
        emit TokenAdded(_token);
    }

    function _deleteFromWithdrawRequests(address _owner) internal {
        delete(withdrawRequestApproves[_owner]);

        uint _length = withdrawRequests.length;
        if(defaultReferrerApproval[msg.sender] == false){
            require(_length >= 1, "zero length");
        }

        bool _found = false;
        if(_length == 1){
            if(withdrawRequests[0] == _owner){
                _found = true;
                withdrawRequests.pop();
            }
        } else {
            for (uint i = 0; i < _length; i++){
                if(withdrawRequests[i] == _owner){
                    _found = true;
                    if(i != _length){
                        withdrawRequests[i] = withdrawRequests[_length-1];
                        withdrawRequests.pop();
                        break;
                    } else {
                        withdrawRequests.pop();
                        break;
                    }
                }
            }
        }
        if(defaultReferrerApproval[msg.sender] == false){
            require(_found, "did not find request");
        }
    }
    
    function emergencyTokenWithdraw (address _to, address _token) external onlyManager {

        uint _balance;
        if(_token == ZERO_ADDRESS){
            _balance = address(this).balance;
            (bool success,) = payable(msg.sender).call{value: _balance, gas: 50000}("");
            require(success, "native call fail");           
        } else {
            _balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_to, _balance);
        }

        emit EmergencyWithdrawToken(_to, _token, _balance);
    }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function transferManager(address _manager) external onlyManager {
        _removeManager(msg.sender);
        _addManager(_manager);
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

// SPDX-License-Identifier: MIT
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