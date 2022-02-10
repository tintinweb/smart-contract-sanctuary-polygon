// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./BurnerMinterERC20.sol";
import "./MadApeRarityChecker.sol";

contract MadApeStaking is Ownable {
    using Address for address;

    BurnerMinterERC20 private _rewardToken;
    IERC721 private _stakeToken;
    MadApeRarityChecker private _rarityChecker;

    mapping(address => bool) internal operators;
    mapping(uint256 => bool) internal _isTokenStakedMapping;
    mapping(uint256 => address) internal _tokenStakedByMapping;
    mapping(address => mapping(uint256 => uint256)) internal _ownerStakedTokenTimeSinceLastRewardMapping;

    bool internal _isActive;
    uint256 internal _deactivationTime;
    uint256 internal _baseReward;
    uint256 internal _rewardInterval;

    /**
     * @dev Emitted when the reward token has changed.
     */
    event RewardTokenChanged(address previousToken, address newToken);

    /**
     * @dev Emitted when the rarity checker has changed.
     */
    event RarityCheckerChanged(address previousChecker, address newChecker);

    /**
     * @dev Emitted when the base reward has changed.
     */
    event BaseRewardChanged(uint256 previousBaseReward, uint256 newBaseReward);

    /**
     * @dev Emitted when the reward interval has changed.
     */
    event RewardIntervalChanged(uint256 previousRewardInterval, uint256 newRewardInterval);

    /**
    * @dev Emitted when the stake token has changed.
    */
    event StakeTokenChanged(address previousToken, address newToken);

    /**
    * @dev Emitted when the isActive has changed.
    */
    event IsActiveChanged(bool previousState, bool newState);

    /**
    * @dev Emitted when the token has been staked.
    */
    event TokenIdStaked(address owner, uint256 tokenId);

    /**
    * @dev Emitted when the token has been unstaked.
    */
    event TokenIdUnstaked(address owner, uint256 tokenId);

    /**
    * @dev Emitted when the owner of the token has changed.
    */
    event UnstakedByOperator(address oldOwner, address newOwner, uint256 tokenId, uint256 timestamp);

    /**
    * @dev Emitted when the rewards have been claimed.
    */
    event RewardClaimed(uint256 tokenId, uint256 rewards);

    /**
     * @dev Emitted when operator is added.
     */
    event OperatorAdded(address operator);

    /**
     * @dev Emitted when operator is removed.
     */
    event OperatorRemoved(address operator);

    constructor(address _rewardTokenAddress, address _stakeTokenAddress, address _rarityCheckerAddress){
        changeRewardToken(_rewardTokenAddress);
        changeStakeToken(_stakeTokenAddress);
        changeRarityChecker(_rarityCheckerAddress);
        changeBaseReward(1 ether);
        changeRewardInterval(86400);
        changeIsActive(true);
    }

    // =========== MODIFIERS METHODS ==========
    /**
     * @dev Throws if called by any account other than an operator.
     */
    modifier onlyOperator() {
        require(operators[_msgSender()], "MadApeStaking: caller is not an operator");
        _;
    }
    // =========== MODIFIERS METHODS ==========

    // =========== APE METHODS ================
    function apeStake(uint256 tokenId) public returns (bool){
        require(getIsActive(), "MadApeStaking: Staking is currently not active");
        require(_stakeToken.ownerOf(tokenId) == _msgSender(), "MadApeStaking: Message sender not currently the owner of this token");
        require(!_isTokenStakedMapping[tokenId], "MadApeStaking: Token already staked");

        _isTokenStakedMapping[tokenId] = true;
        _tokenStakedByMapping[tokenId] = _msgSender();
        _ownerStakedTokenTimeSinceLastRewardMapping[_msgSender()][tokenId] = block.timestamp;

        emit TokenIdStaked(_msgSender(), tokenId);
        return true;
    }

    function apeUnstake(uint256 tokenId) public returns (bool){
        require(_stakeToken.ownerOf(tokenId) == _msgSender(), "MadApeStaking: Message sender not currently the owner of this token");
        return _unstake(_msgSender(), tokenId);
    }

    function apeClaim(uint256 tokenId) public returns (uint256) {
        require(_stakeToken.ownerOf(tokenId) == _msgSender(), "MadApeStaking: Message sender not currently the owner of this token");
        return _claimReward(_msgSender(), tokenId);
    }
    // =========== APE METHODS ================

    // =========== OPERATOR METHODS ===========
    function operatorUnstake(address oldOwner, address newOwner, uint256 tokenId) public onlyOperator {
        _unstake(oldOwner, tokenId);
        emit UnstakedByOperator(oldOwner, newOwner, tokenId, block.timestamp);
    }
    // =========== OPERATOR METHODS ===========

    // =========== PUBLIC METHODS =============
    /**
     * @dev Returns boolean if given tokenId has been staked.
     */
    function isTokenStaked(uint256 tokenId) public view returns (bool){
        return _isTokenStakedMapping[tokenId];
    }

    /**
     * @dev Returns address of staker.
     */
    function getStakerAddress(uint256 tokenId) public view returns (address){
        return _tokenStakedByMapping[tokenId];
    }

    /**
     * @dev Returns accrued rewards so far.
     */
    function getAccruedRewards(address owner, uint256 tokenId) public view returns (uint256 rewardTokens){
        return _calculateReward(owner, tokenId);
    }

    /**
     * @dev Returns boolean if given address is an operator.
     */
    function isOperator(address operator) public view returns (bool){
        return operators[operator];
    }
    // =========== PUBLIC METHODS =============

    // =========== INTERNAL METHODS ===========
    function _unstake(address owner, uint256 tokenId) internal returns (bool){
        require(_isTokenStakedMapping[tokenId], "MadApeStaking: Token not currently staked");

        _isTokenStakedMapping[tokenId] = false;
        _tokenStakedByMapping[tokenId] = address(0);

        _claimReward(owner, tokenId);

        emit TokenIdUnstaked(owner, tokenId);
        return true;
    }

    function _claimReward(address owner, uint256 tokenId) internal returns (uint256 reward){
        reward = _calculateReward(owner, tokenId);
        _ownerStakedTokenTimeSinceLastRewardMapping[owner][tokenId] = block.timestamp;
        _rewardToken.transfer(owner, reward);
        emit RewardClaimed(tokenId, reward);
    }

    function _calculateReward(address owner, uint256 tokenId) internal view returns (uint256 rewardTokens){
        uint256 timeStakingSinceLastRewardInSeconds;
        if (!getIsActive()) {
            timeStakingSinceLastRewardInSeconds = SafeMath.sub(_deactivationTime, _ownerStakedTokenTimeSinceLastRewardMapping[owner][tokenId]);
        } else {
            timeStakingSinceLastRewardInSeconds = SafeMath.sub(block.timestamp, _ownerStakedTokenTimeSinceLastRewardMapping[owner][tokenId]);
        }
        uint256 daysStaking = SafeMath.div(timeStakingSinceLastRewardInSeconds, getRewardInterval());
        if (daysStaking == 0) return 0;
        //Multiplier returns as a multiple of 100; 1.25 multiplier would be represented as 125.
        uint256 rarityMultiplier = _rarityChecker.getMultiplierForTokenId(tokenId);
        uint256 baseReward = getBaseReward();
        uint256 baseRewardMultipliedByDays = SafeMath.mul(baseReward, daysStaking);
        uint256 rewardMultipliedByRarity = SafeMath.mul(baseRewardMultipliedByDays, rarityMultiplier);
        uint256 normalisedReward = SafeMath.div(rewardMultipliedByRarity, 100);
        return normalisedReward;
    }
    // =========== INTERNAL METHODS ===========

    // =========== GETTERS/SETTERS ============
    /**
         * @dev Changes the rarity checker.
     *
     * Emits an {RarityCheckerChanged} event.
     */
    function changeRarityChecker(address newRarityChecker) public onlyOwner {
        emit RarityCheckerChanged(getRarityChecker(), newRarityChecker);
        setRarityChecker(newRarityChecker);
    }

    /**
    * @dev Stores a new address for rarity checker.
    */
    function setRarityChecker(address newRarityChecker) internal {
        _rarityChecker = MadApeRarityChecker(newRarityChecker);
    }

    /**
    * @dev Returns current rarity checker.
    */
    function getRarityChecker() public view returns (address) {
        return address(_rarityChecker);
    }

    /**
     * @dev Changes the base reward.
     *
     * Emits an {BaseRewardChanged} event.
     */
    function changeBaseReward(uint256 newBaseReward) public onlyOwner {
        emit BaseRewardChanged(getBaseReward(), newBaseReward);
        setBaseReward(newBaseReward);
    }

    /**
    * @dev Stores a new value for base reward.
    */
    function setBaseReward(uint256 newBaseReward) internal {
        _baseReward = newBaseReward;
    }

    /**
    * @dev Returns current base reward.
    */
    function getBaseReward() public view returns (uint256) {
        return _baseReward;
    }

    /**
     * @dev Changes the reward interval.
     *
     * Emits an {RewardIntervalChanged} event.
     */
    function changeRewardInterval(uint256 newRewardInterval) public onlyOwner {
        emit RewardIntervalChanged(getRewardInterval(), newRewardInterval);
        setRewardInterval(newRewardInterval);
    }

    /**
    * @dev Stores a new value for reward interval.
    */
    function setRewardInterval(uint256 newRewardInterval) internal {
        _rewardInterval = newRewardInterval;
    }

    /**
    * @dev Returns current reward interval.
    */
    function getRewardInterval() public view returns (uint256) {
        return _rewardInterval;
    }

    /**
     * @dev Changes the reward token.
     *
     * Emits an {RewardTokenChanged} event.
     */
    function changeRewardToken(address newRewardToken) public onlyOwner {
        emit RewardTokenChanged(getRewardToken(), newRewardToken);
        setRewardToken(newRewardToken);
    }

    /**
    * @dev Stores a new address for reward token.
    */
    function setRewardToken(address newRewardToken) internal {
        _rewardToken = BurnerMinterERC20(newRewardToken);
    }

    /**
    * @dev Returns current reward token.
    */
    function getRewardToken() public view returns (address) {
        return address(_rewardToken);
    }

    /**
     * @dev Changes the stake token.
     *
     * Emits an {StakeTokenChanged} event.
     */
    function changeStakeToken(address newStakeToken) public onlyOwner {
        emit StakeTokenChanged(getStakeToken(), newStakeToken);
        setStakeToken(newStakeToken);
    }

    /**
    * @dev Stores a new address for stake token.
    */
    function setStakeToken(address newStakeToken) internal {
        _stakeToken = IERC721(newStakeToken);
    }

    /**
    * @dev Returns current stake token.
    */
    function getStakeToken() public view returns (address) {
        return address(_stakeToken);
    }

    /**
     * @dev Changes isActive state.
     *
     * Emits an {ActiveStateChanged} event.
     */
    function changeIsActive(bool isActive) public onlyOwner {
        emit IsActiveChanged(getIsActive(), isActive);
        setIsActive(isActive);
    }

    /**
    * @dev Sets isActive.
    */
    function setIsActive(bool isActive) internal {
        _isActive = isActive;
        if (!isActive) {
            _deactivationTime = block.timestamp;
        }
    }

    /**
    * @dev Returns isActive.
    */
    function getIsActive() public view returns (bool) {
        return _isActive;
    }
    // =========== GETTERS/SETTERS ============

    // =========== ADMIN METHODS ==============
    /**
     * @dev Add address as operator.
     * Can only be called by the current owner.
     */
    function addOperator(address operator) public onlyOwner {
        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    /**
     * @dev Remove operator.
     * Can only be called by the current owner.
     */
    function removeOperator(address operator) public onlyOwner {
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    /**
      * @dev Method to withdraw all native currency. Only callable by owner.
      */
    function withdraw() public onlyOwner {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
        require(success);
    }

    /**
      * @dev Method to withdraw all tokens complying to ERC20 interface. Only callable by owner.
      */
    function withdrawERC20(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, "SafeERC20: Balance already 0");

        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, address(this), owner(), token.balanceOf(address(this)));
        bytes memory return_data = address(_token).functionCall(data, "SafeERC20: low-level call failed");
        if (return_data.length > 0) {
            // Return data is optional to support crappy tokens like BNB and others not complying to ERC20 interface
            require(abi.decode(return_data, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    // =========== ADMIN METHODS ==============
}