// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./SkyToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Calamity
/// @author rektt (https://twitter.com/rekttdoteth)

contract Calamity is Ownable{
    /* ========== STORAGE ========== */

    SkyToken public skyToken;
    bool public paused;
    
    uint256 public constant TARGET = 50000000 ether;
    address public constant INITIAL_ADDY = 0x37876b9828e3B8413cD8d736672dD1c27cDe8220;

    uint256 public totalBlessed;
    uint256 public userSize = 0;

    struct UserInfo {
        address wallet;
        uint256 blessedAmount;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => address) public _nextUser;

    /* ========== EVENTS ========== */

    //@dev Emitted when a user blessed $SKY.
    event Blessed(address from, uint256 amount);

    /* ========== ERRORS ========== */
    error CalamityPaused();
    error CalamityCapped();
    error ZeroBlessing();
    error ZeroWithdraw();

    /* ========== CONSTRUCTOR ========== */

    constructor(address skyERC20) {
        skyToken = SkyToken(skyERC20);
        _nextUser[INITIAL_ADDY] = INITIAL_ADDY;
    }

    /* ========== MODIFIERS ========== */

    modifier notPaused(){
        if(paused) revert CalamityPaused();
        _;
    }

    modifier notCapped(){
        if(totalBlessed >= TARGET) revert CalamityCapped();
        _;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function withdraw(uint256 amount) public onlyOwner {
        if(amount == 0) revert ZeroWithdraw();
        skyToken.transferFrom(address(this), owner(), amount);
    }

     /* ========== PUBLIC READ ========== */

    function getBlessers() public view returns (UserInfo[] memory) {
        UserInfo[] memory _userInfos;
        address currentAddy = _nextUser[INITIAL_ADDY];
        for(uint256 i = 0; currentAddy != INITIAL_ADDY; ++i){
            _userInfos[i] = userInfo[currentAddy];
            currentAddy = _nextUser[currentAddy];
        }   
        return _userInfos;
    }

    /* ========== PUBLIC MUTATIVE ========== */

    function bless(uint256 amount, address user, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public notPaused notCapped {
        if(amount == 0) revert ZeroBlessing();
        UserInfo storage _user = userInfo[user];

        if(_user.blessedAmount == 0) {
            _nextUser[user] = _nextUser[INITIAL_ADDY];
            _nextUser[INITIAL_ADDY] = user;
            userSize++;
            _user.wallet = user;
        }

        totalBlessed += amount;
        _user.blessedAmount += amount;
        skyToken.permit(user, msg.sender, amount, deadline, v, r, s);
        skyToken.transferFrom(user, address(this), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./FxBaseChildTunnel.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title SkyToken
/// @author aceplxx (https://twitter.com/aceplxx)

contract SkyToken is ERC20, FxBaseChildTunnel, Ownable {
    using ECDSA for bytes32;

    struct StakeRecord{
        uint256 tokenId;
        uint256 stakedOn;
        uint256 lastClaimed;
        uint256 bonusTierPercent;
    }

    struct UserInfo{
        uint256 stakedBalance;
        uint256[] stakedIds;
    }

    /* ========== EVENTS ========== */

    //@dev Emitted when message from root is processed.
    event ProcessedMessage(address from, uint256 tokenId, bool stake);

    /* ========== STORAGE ========== */

    //user address => tokenId => record mapping
    mapping(address => mapping(uint => StakeRecord)) private stakeRecord;

    mapping(address => UserInfo) private userInfo;
    mapping(uint256 => uint256) public tokenIndex;

    mapping(address => bool) public harvester;
    mapping(bytes32 => bool) public usedMessage;

    mapping(uint256 => uint256) public tokenRarity;
    mapping(uint256 => uint256) public rarityRate;

    // staking bonus percent based on days range staked threshold
    mapping(uint256 => uint256) public stakingBonus;

    uint256[] public thresholdRecord;

    bool public paused = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _fxChild)
        FxBaseChildTunnel(_fxChild)
        ERC20("Sky Token", "SKY", 18)
    {
        rarityRate[0] = 1000 ether;
        rarityRate[1] = 1500 ether;
        rarityRate[2] = 2000 ether;
        rarityRate[3] = 3000 ether;
    }

    /* ========== MODIFIERS ========== */

    modifier notPaused() {
        require(!paused, "Reward is paused");
        _;
    }

    modifier onlyHarvester() {
        require(harvester[msg.sender], "Only harvester allowed!");
        _;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function setBonus(uint256[] memory stakeDays, uint256[] memory multiplierPercent) external onlyOwner{
        require(stakeDays.length == multiplierPercent.length, "Input length missmatch");

        for(uint256 i = 0; i < stakeDays.length; i++){
            uint256 daysToDelta = stakeDays[i] * 1 days;
            stakingBonus[daysToDelta] = multiplierPercent[i];
            thresholdRecord.push(daysToDelta);
        }
    }

    function setRarities(uint256[] memory tokenIds, uint256[] memory rarities) external onlyOwner {
        require(tokenIds.length == rarities.length, "Input length missmatch");
        for(uint256 i = 0; i < tokenIds.length; i++){
            tokenRarity[tokenIds[i]] = rarities[i];
        }
    }

    function setRaritiesRate(uint256[] memory rarities, uint256[] memory rates) external onlyOwner{
        require(rarities.length == rates.length, "Input length missmatch");
        for(uint256 i = 0; i < rarities.length; i++){
            rarityRate[rarities[i]] = rates[i];
        }
    }

    function setHarvester(address[] memory harvesters, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < harvesters.length; i++) {
            harvester[harvesters[i]] = state;
        }
    }

    function updateFxRootRunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }

    function mint(uint256 amount, address receiver) external onlyOwner {
        _mint(receiver, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(address(this), amount);
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "address amounts missmatch"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 amount = amounts[i];
            _mint(addresses[i], amount);
        }
    }

    /* ========== PUBLIC READ ========== */

    function pendingRewards(address user) external view returns (uint256) {
        return _getPendingRewards(user);
    }

    function pendingRewardsByNFT(address user, uint256 tokenId) external view returns (uint256 boosted, uint256 nonboosted) {
        return (_getPendingRewardsByNFT(user, tokenId), _getPendingRewardsByNFTNonBoosted(user, tokenId));
    }

    function createMessage(address user, uint256 amount)
        external
        view
        returns (bytes32)
    {
        return _createMessage(user, amount);
    }

    function getStakeRecord(address user, uint256 tokenId) external view returns (StakeRecord memory){
        StakeRecord memory _record = stakeRecord[user][tokenId];
        uint256 deltaDifference = _record.stakedOn > 0 ? block.timestamp - _record.stakedOn : 0;
        _record.bonusTierPercent = _bonusThreshold(deltaDifference);

        return _record;
    }

    function getUserInfo(address user) external view returns (uint256 stakedBalance, uint256[] memory stakedIds){
        UserInfo memory _info = userInfo[user];

        return(
            _info.stakedBalance,
            _info.stakedIds
        );
    }

    /* ========== PUBLIC MUTATIVE ========== */

    function spend(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _harvestReward(owner);
        permit(owner, msg.sender, value, deadline, v, r, s);
        transferFrom(owner, address(this), value);
    }

    function totalBalance(address user) external view returns (uint256) {
        return balanceOf[user] + _getPendingRewards(user);
    }

    /// @notice Harvest $SKY reward.
    function harvestReward() external {
        _harvestReward(msg.sender);
    }

    /**
     * @notice Harvest $SKY on behalf.
     * @param user user address to harvest reward on behalf
     * @param amount amount to be harvested
     * @param signature bytes message of signatures
     */
    function gaslessHarvest(
        address user,
        uint256 amount,
        bytes memory signature
    ) external onlyHarvester {
        _useMessage(user, amount, signature);
        _harvestReward(user);
    }

    /**
     * @notice Harvest $SKY on behalf  by NFT.
     * @param user user address to harvest reward on behalf
     * @param amount amount to be harvested
     * @param tokenId tokenId to be harvested
     * @param signature bytes message of signatures
     */
    function gaslessHarvestByNFT(
        address user,
        uint256 amount,
        uint256 tokenId,
        bytes memory signature
    ) external onlyHarvester {
        _useMessage(user, amount, signature);
        _harvestRewardByNFT(user, tokenId);
    }

    /* ========== OVERRIDES ========== */

    /**
     * @notice Process message received from FxChild
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 tokenId, bool stake) = abi.decode(
            message,
            (address, uint256, bool)
        );

        UserInfo storage _userInfo = userInfo[from];

        if(stake){
            StakeRecord memory _record = StakeRecord(tokenId, block.timestamp,0,0);
            stakeRecord[from][tokenId] = _record;
            tokenIndex[tokenId] = _userInfo.stakedIds.length;
            _userInfo.stakedIds.push(tokenId);
            _userInfo.stakedBalance++;
        } else {
            _harvestRewardByNFT(from, tokenId);
            delete stakeRecord[from][tokenId];
            _userInfo.stakedBalance--;
            if(_userInfo.stakedIds.length > 1){
                uint256 lastTokenId = _userInfo.stakedIds[_userInfo.stakedIds.length - 1];
                uint256 lastTokenIndexNew = tokenIndex[tokenId];

                _userInfo.stakedIds[lastTokenIndexNew] = lastTokenId;
                _userInfo.stakedIds.pop();

                tokenIndex[lastTokenId] = lastTokenIndexNew;
            } else {
                _userInfo.stakedIds.pop();
            }
            delete tokenIndex[tokenId]; 
        }

        emit ProcessedMessage(from, tokenId, stake);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @notice Helper that creates the message for gaslessHarvest
    /// @param user user address
    /// @param amount the amount
    /// @return the message to sign
    function _createMessage(address user, uint256 amount)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(user, amount, address(this)));
    }

    /// @dev It ensures that signer signed a message containing (account, amount, address(this))
    ///      and that this message was not already used
    /// @param user the signer
    /// @param amount the amount associated to this allowance
    /// @param signature the signature by the allowance signer wallet
    /// @return the message to mark as used
    function _validateSignature(
        address user,
        uint256 amount,
        bytes memory signature
    ) internal view returns (bytes32) {
        bytes32 message = _createMessage(user, amount).toEthSignedMessageHash();

        // verifies that the sha3(account, amount, address(this)) has been signed by user
        require(message.recover(signature) == user, "!INVALID_SIGNATURE!");

        // verifies that the message was not already used
        require(usedMessage[message] == false, "!ALREADY_USED!");

        return message;
    }

    /// @notice internal function that verifies an allowance and marks it as used
    ///         this function throws if signature is wrong or this amount for this user has already been used
    /// @param user the account the allowance is associated to
    /// @param amount the amount
    /// @param signature the signature by the allowance wallet
    function _useMessage(
        address user,
        uint256 amount,
        bytes memory signature
    ) internal {
        bytes32 message = _validateSignature(user, amount, signature);
        usedMessage[message] = true;
    }

    function _harvestReward(address user) internal notPaused {
        uint256 pendingReward = 0;
        UserInfo storage _userInfo = userInfo[user];    

        for(uint256 i = 0; i < _userInfo.stakedIds.length; i++){
            pendingReward += _pendingByNFTAndMarkClaim(user, _userInfo.stakedIds[i]);
        }

        _mint(user, pendingReward);
    }

    function _harvestRewardByNFT(address user, uint256 tokenId) internal notPaused {
        uint256 pendingReward = _getPendingRewardsByNFT(user, tokenId);

        StakeRecord storage _record = stakeRecord[user][tokenId];
        _record.lastClaimed = block.timestamp;
        
        _mint(user, pendingReward);
    }   

    function _bonusThreshold(uint256 deltaDifference) internal view returns (uint256) {
        uint256 bonus = 0;

        for(uint256 i = 0; i < thresholdRecord.length; i++){
            if(deltaDifference >= thresholdRecord[i]){
                if(stakingBonus[thresholdRecord[i]] > bonus) bonus = stakingBonus[thresholdRecord[i]];
            }
        }

        return bonus;
    }

    function _pendingByNFTAndMarkClaim(address user, uint256 tokenId) internal returns (uint256){
        uint256 rewards = 0;
        uint256 rewardsBonus = 0;

        StakeRecord storage _record = stakeRecord[user][tokenId];
        uint256 deltaStakedDifference = _record.stakedOn > 0 ? block.timestamp - _record.stakedOn : 0;
        uint256 deltaClaimedDifference = _record.lastClaimed > 0 ? block.timestamp - _record.lastClaimed : deltaStakedDifference;
        
        uint256 bonusPercent = _bonusThreshold(deltaStakedDifference) * 10**16;
        uint256 rarityBasedRate = rarityRate[tokenRarity[_record.tokenId]];

        if(bonusPercent > 0) rewardsBonus = (rarityBasedRate * bonusPercent / 10**18);
        uint256 dayRate = (rarityBasedRate + rewardsBonus);
        
        if(dayRate > 0) rewards = ((dayRate * deltaClaimedDifference) / 86400);
        
        _record.lastClaimed = block.timestamp;
        return rewards;
    }

    function _getPendingRewardsByNFT(address user, uint256 tokenId) internal view returns (uint256){
        uint256 rewards = 0;
        uint256 rewardsBonus = 0;

        StakeRecord memory _record = stakeRecord[user][tokenId];
        uint256 deltaStakedDifference = _record.stakedOn > 0 ? block.timestamp - _record.stakedOn : 0;
        uint256 deltaClaimedDifference = _record.lastClaimed > 0 ? block.timestamp - _record.lastClaimed : deltaStakedDifference;
        
        uint256 bonusPercent = _bonusThreshold(deltaStakedDifference) * 10**16;
        uint256 rarityBasedRate = rarityRate[tokenRarity[_record.tokenId]];

        if(bonusPercent > 0) rewardsBonus = (rarityBasedRate * bonusPercent / 10**18);
        uint256 dayRate = (rarityBasedRate + rewardsBonus);
        
        if(dayRate > 0) rewards = ((dayRate * deltaClaimedDifference) / 86400);
        return rewards;
    }

    function _getPendingRewardsByNFTNonBoosted(address user, uint256 tokenId) internal view returns (uint256){
        uint256 rewards = 0;

        StakeRecord memory _record = stakeRecord[user][tokenId];
        uint256 deltaStakedDifference = _record.stakedOn > 0 ? block.timestamp - _record.stakedOn : 0;
        uint256 deltaClaimedDifference = _record.lastClaimed > 0 ? block.timestamp - _record.lastClaimed : deltaStakedDifference;

        uint256 rarityBasedRate = rarityRate[tokenRarity[_record.tokenId]];

        if(rarityBasedRate > 0) rewards = ((rarityBasedRate * deltaClaimedDifference) / 86400);
        return rewards;
    }

    function _getPendingRewards(address user) internal view returns (uint256) {
        UserInfo storage _userInfo = userInfo[user];

        uint256 rewards = 0;
        
        for(uint256 i = 0; i < _userInfo.stakedIds.length; i++){
            rewards += _getPendingRewardsByNFT(user, _userInfo.stakedIds[i]);
        }

        return rewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}