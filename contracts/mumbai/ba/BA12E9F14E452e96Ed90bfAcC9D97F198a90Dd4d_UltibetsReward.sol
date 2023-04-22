// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Utils/CustomAdmin.sol";
import "../Interface/IUltiBetsSign.sol";

interface IUltiBetsToken {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);
}

contract UltibetsReward is CustomAdmin {
    address public ultiBetsToken;
    address public ultiBetsTreasury;
    address public utbetsDailyBets;
    address public ultibetsSign;

    uint8 public totalTier;

    uint8 public referralRewardPercent = 10;
    uint256 public referralRewardThreshold = 100 ether;
    mapping(address => uint256) public referralBettingReward;
    mapping(address => bool) public isClaimReferralBettingReward;
    mapping(address => uint256) public totalRefereeNumber;
    mapping(address => uint256) public validRefereeNumber;
    mapping(address => uint256) public claimableReferralRewardAmount;
    mapping(address => uint256) public claimedReferralRewardAmount;

    mapping(address => uint256) public totalBetAmount;
    mapping(uint8 => uint256) public thresholdByTier;
    mapping(uint8 => uint256) public rewardByTier; //reward amount for each tier
    mapping(address => uint8) public currentTierOfBettor;
    mapping(address => mapping(uint8 => bool)) public claimedTier;

    mapping(uint8 => uint256) public freebetAmountForSBCRoundNFTPerk; // 0: winner nft 1 - 5: round nft
    event ReleaseReward(address bettor, uint8 tier);
    event UpgradeTier(address bettor);
    event BetUsingReferralCode(
        address bettor,
        address referrer,
        uint256 reward,
        bool isValid
    );
    event ClaimReferralReward(address referrer, uint256 amount);
    event ClaimReferralBettingReward(address bettor, uint256 amount);

    modifier onlyDailyBets() {
        _;
        require(
            msg.sender == utbetsDailyBets,
            "Only Ultibets contract can call this function."
        );
    }

    constructor(address _ultiBetsToken, address _ultiBetsTreasury) {
        ultiBetsToken = _ultiBetsToken;
        ultiBetsTreasury = _ultiBetsTreasury;
    }

    function initRewardTiers(
        uint256[] memory _thresholds,
        uint256[] memory _rewards
    ) external onlyAdmin {
        require(_thresholds.length == _rewards.length, "Invalid Params.");
        totalTier = uint8(_thresholds.length);
        for (uint8 i; i < _thresholds.length; i++) {
            rewardByTier[i + 1] = _rewards[i];
            thresholdByTier[i + 1] = _thresholds[i];
        }
    }

    function betUsingReferralCode(
        address _referrer,
        uint256 _amount
    ) external onlyDailyBets {
        uint256 reward = 0;
        if (_amount >= referralRewardThreshold) {
            reward = (_amount * referralRewardPercent) / 100;
            claimableReferralRewardAmount[_referrer] += reward;
            validRefereeNumber[_referrer]++;
            referralBettingReward[tx.origin] = reward;
        }
        totalRefereeNumber[_referrer]++;

        emit BetUsingReferralCode(
            tx.origin,
            _referrer,
            reward,
            _amount >= referralRewardThreshold
        );
    }

    function claimReferralBettingReward(
        uint256 _amount,
        bytes memory _signature
    ) external {
        require(
            IUltiBetsSign(ultibetsSign).verify(msg.sender, _amount, _signature),
            "Invalid Signature"
        );
        require(
            isClaimReferralBettingReward[msg.sender] == false,
            "Already Claimed!"
        );
        IUltiBetsToken(ultiBetsToken).transfer(msg.sender, _amount);
        isClaimReferralBettingReward[msg.sender] = true;
        IUltiBetsSign(ultibetsSign).increaseNonce(msg.sender);

        emit ClaimReferralBettingReward(msg.sender, _amount);
    }

    //just for fantom
    function claimReferralReward(
        uint256 _amount,
        bytes memory _signature
    ) external {
        require(
            IUltiBetsSign(ultibetsSign).verify(msg.sender, _amount, _signature),
            "Invalid signature!"
        );
        claimedReferralRewardAmount[msg.sender] += _amount;
        IUltiBetsToken(ultiBetsToken).transfer(msg.sender, _amount);

        IUltiBetsSign(ultibetsSign).increaseNonce(msg.sender);
        emit ClaimReferralReward(msg.sender, _amount);
    }

    function updateRewardTier(uint256 _amount) external onlyDailyBets {
        totalBetAmount[tx.origin] += _amount;
        uint8 currentTier = currentTierOfBettor[tx.origin];
        if (
            currentTier < totalTier &&
            totalBetAmount[tx.origin] >= thresholdByTier[currentTier]
        ) {
            currentTierOfBettor[tx.origin] += 1;
            emit UpgradeTier(tx.origin);
        }
    }

    function releaseRewardOfTier(uint8 _tier) external {
        require(
            IUltiBetsToken(ultiBetsToken).balanceOf(address(this)) >=
                rewardByTier[_tier],
            "Deposit UTBETS to this contract."
        );
        require(
            currentTierOfBettor[msg.sender] >= _tier &&
                !claimedTier[msg.sender][_tier],
            "Can't claim reward of the tier!"
        );
        uint256 rewardAmount;
        rewardAmount = rewardByTier[_tier];
        IUltiBetsToken(ultiBetsToken).transfer(msg.sender, rewardAmount);
        claimedTier[msg.sender][_tier] = true;

        emit ReleaseReward(msg.sender, _tier);
    }

    function withdrawUltibets() external onlyAdmin {
        IUltiBetsToken(ultiBetsToken).transfer(
            ultiBetsTreasury,
            IUltiBetsToken(ultiBetsToken).balanceOf(address(this))
        );
    }

    //function for free bet
    function setFreeBetAmountForEachPerk(
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(_amounts.length == 6, "Invalid Param.");
        for (uint8 i; i < _amounts.length; i++) {
            freebetAmountForSBCRoundNFTPerk[i] = _amounts[i];
        }
    }

    function payForPerk(uint8 _round) external onlyDailyBets {
        IUltiBetsToken(ultiBetsToken).transfer(
            utbetsDailyBets,
            freebetAmountForSBCRoundNFTPerk[_round]
        );
    }

    function setReferralRewardThreshold(
        uint256 _referralRewardThreshold
    ) external {
        referralRewardThreshold = _referralRewardThreshold;
    }

    function setReferralRewardPercent(
        uint8 _referralRewardPercent
    ) external onlyAdmin {
        referralRewardPercent = _referralRewardPercent;
    }

    function setUTBETSDailyBets(address _utbetsDailyBets) external onlyAdmin {
        utbetsDailyBets = _utbetsDailyBets;
    }

    function setUltibetsSign(address _ultibetsSign) external onlyAdmin {
        ultibetsSign = _ultibetsSign;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomAdmin is Ownable {
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isOracle;

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You are not admin.");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "You are not oracle.");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
        isOracle[msg.sender] = true;
    }

    function addOracle(address _oracle) external onlyAdmin {
        isOracle[_oracle] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        isAdmin[_admin] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUltiBetsSign {
    function verify(address, uint256, bytes memory) external view returns(bool);

    function increaseNonce(address) external;
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