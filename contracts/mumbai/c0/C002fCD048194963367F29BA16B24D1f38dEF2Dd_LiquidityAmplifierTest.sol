// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {ILiquidityAmplifier} from "../interfaces/ILiquidityAmplifier.sol";
import {IStake} from "../interfaces/IStake.sol";
import {IMaxxFinance} from "../interfaces/IMaxxFinance.sol";
import {IMAXXBoost} from "../interfaces/IMAXXBoost.sol";

/// @title Maxx Finance Liquidity Amplifier
/// @author Alta Web3 Labs - SonOfMosiah
contract LiquidityAmplifierTest is ILiquidityAmplifier, Ownable {
    using ERC165Checker for address;

    uint16 private constant _TEST_TIME_FACTOR = 336; // Test contract runs 336x faster (1 hour = 2 weeks)

    uint256[] private _maxxDailyAllocation = new uint256[](AMPLIFIER_PERIOD);
    uint256[] private _effectiveMaticDailyDeposits =
        new uint256[](AMPLIFIER_PERIOD);
    uint256[] private _maticDailyDeposits = new uint256[](AMPLIFIER_PERIOD);

    /// @notice Maxx Finance Vault address
    address public maxxVault;

    /// @notice maxxGenesis NFT
    address public maxxGenesis;

    /// @notice Array of addresses that have participated in the liquidity amplifier
    address[] public participants;

    /// @notice Array of address that participated in the liquidity amplifier for each day
    mapping(uint256 => address[]) public participantsByDay;

    /// @notice Liquidity amplifier start date
    uint256 public launchDate;

    /// @notice Address of the Maxx Finance staking contract
    IStake public stake;

    /// @notice Maxx Finance token
    address public maxx;

    bool private _allocationInitialized;
    bool public initialized;

    uint16 public constant MAX_LATE_DAYS = 100;
    uint16 public constant CLAIM_PERIOD = 60;
    uint16 public constant AMPLIFIER_PERIOD = 60;
    uint256 public constant MIN_GENESIS_AMOUNT = 5e19; // 50 matic

    /// @notice maps address to day (indexed at 0) to amount of tokens deposited
    mapping(address => uint256[60]) public userDailyDeposits;
    /// @notice maps address to day (indexed at 0) to amount of effective tokens deposited adjusted for referral and nft bonuses
    mapping(address => uint256[60]) public effectiveUserDailyDeposits;
    /// @notice maps address to day (indexed at 0) to amount of effective tokens gained by referring users
    mapping(address => uint256[60]) public effectiveUserReferrals;
    /// @notice tracks if address has participated in the amplifier
    mapping(address => bool) public participated;
    /// @notice tracks if address has claimed for a given day
    mapping(address => mapping(uint256 => bool)) public participatedByDay;
    mapping(address => mapping(uint256 => bool)) public dayClaimed;
    mapping(address => uint256) public claimedReferralAmount;

    mapping(address => uint256[]) public userAmpReferral;

    /// @notice
    uint256[60] public dailyDepositors;

    constructor() {
        _transferOwnership(tx.origin);
    }

    /// @notice Initialize maxxVault, launchDate and MAXX token address
    /// @dev Function can only be called once
    /// @param _maxxVault The address of the Maxx Finance Vault
    /// @param _launchDate The launch date of the liquidity amplifier
    /// @param _maxx The address of the MAXX token
    function init(
        address _maxxVault,
        uint256 _launchDate,
        address _maxx
    ) external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        maxxVault = _maxxVault;
        launchDate = _launchDate;
        maxx = _maxx;
        initialized = true;
    }

    /// @dev Function to deposit matic to the contract
    function deposit() external payable {
        if (
            block.timestamp >=
            launchDate + ((AMPLIFIER_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            revert AmplifierComplete();
        }

        uint256 amount = msg.value;
        uint256 day = getDay();

        if (!participated[msg.sender]) {
            participated[msg.sender] = true;
            participants.push(msg.sender);
        }

        if (!participatedByDay[msg.sender][day]) {
            participatedByDay[msg.sender][day] = true;
            participantsByDay[day].push(msg.sender);
        }

        userDailyDeposits[msg.sender][day] += amount;
        effectiveUserDailyDeposits[msg.sender][day] += amount;
        _maticDailyDeposits[day] += amount;
        _effectiveMaticDailyDeposits[day] += amount;

        dailyDepositors[day] += 1;
        emit Deposit(msg.sender, amount, address(0));
    }

    /// @dev Function to deposit matic to the contract
    function deposit(address _referrer) external payable {
        if (_referrer == address(0) || _referrer == msg.sender) {
            revert InvalidReferrer(_referrer);
        }
        if (
            block.timestamp >=
            launchDate + ((AMPLIFIER_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            revert AmplifierComplete();
        }
        uint256 amount = msg.value;
        uint256 originalAmount = amount;
        uint256 referralBonus = amount / 10; // +10% referral bonus
        amount += referralBonus;
        uint256 referrerAmount = msg.value / 20; // 5% bonus for referrer
        uint256 effectiveDeposit = amount + referrerAmount;
        uint256 day = getDay();

        if (!participated[msg.sender]) {
            participated[msg.sender] = true;
            participants.push(msg.sender);
        }

        if (!participatedByDay[msg.sender][day]) {
            participatedByDay[msg.sender][day] = true;
            participantsByDay[day].push(msg.sender);
        }

        userDailyDeposits[msg.sender][day] += amount;
        effectiveUserDailyDeposits[msg.sender][day] += amount;
        effectiveUserReferrals[_referrer][day] += referrerAmount;
        _maticDailyDeposits[day] += amount;
        _effectiveMaticDailyDeposits[day] += effectiveDeposit;
        dailyDepositors[day] += 1;

        userAmpReferral[_referrer].push(block.timestamp);
        userAmpReferral[_referrer].push(amount);
        userAmpReferral[_referrer].push(referrerAmount);

        emit Referral(msg.sender, _referrer, originalAmount);
        emit Deposit(msg.sender, originalAmount, _referrer);
    }

    /// @dev Function to deposit matic to the contract
    function deposit(string memory _code) external payable {
        if (
            block.timestamp >=
            launchDate + ((AMPLIFIER_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            revert AmplifierComplete();
        }

        uint256 amount = msg.value;
        if (amount >= MIN_GENESIS_AMOUNT) {
            _mintMaxxGenesis(_code);
        }

        uint256 day = getDay();

        if (!participated[msg.sender]) {
            participated[msg.sender] = true;
            participants.push(msg.sender);
        }

        if (!participatedByDay[msg.sender][day]) {
            participatedByDay[msg.sender][day] = true;
            participantsByDay[day].push(msg.sender);
        }

        userDailyDeposits[msg.sender][day] += amount;
        effectiveUserDailyDeposits[msg.sender][day] += amount;
        _maticDailyDeposits[day] += amount;
        _effectiveMaticDailyDeposits[day] += amount;

        dailyDepositors[day] += 1;
        emit Deposit(msg.sender, amount, address(0));
    }

    /// @dev Function to deposit matic to the contract
    function deposit(string memory _code, address _referrer) external payable {
        if (_referrer == address(0) || _referrer == msg.sender) {
            revert InvalidReferrer(_referrer);
        }

        if (
            block.timestamp >=
            launchDate + ((AMPLIFIER_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            revert AmplifierComplete();
        }

        uint256 amount = msg.value;
        uint256 originalAmount = amount;
        if (amount >= MIN_GENESIS_AMOUNT) {
            _mintMaxxGenesis(_code);
        }

        uint256 referralBonus = amount / 10; // +10% referral bonus
        amount += referralBonus;
        uint256 referrerAmount = msg.value / 20; // 5% bonus for referrer
        uint256 effectiveDeposit = amount + referrerAmount;
        uint256 day = getDay();

        if (!participated[msg.sender]) {
            participated[msg.sender] = true;
            participants.push(msg.sender);
        }

        if (!participatedByDay[msg.sender][day]) {
            participatedByDay[msg.sender][day] = true;
            participantsByDay[day].push(msg.sender);
        }

        userDailyDeposits[msg.sender][day] += amount;
        effectiveUserDailyDeposits[msg.sender][day] += amount;
        effectiveUserReferrals[_referrer][day] += referrerAmount;
        _maticDailyDeposits[day] += amount;
        _effectiveMaticDailyDeposits[day] += effectiveDeposit;
        dailyDepositors[day] += 1;

        userAmpReferral[_referrer].push(block.timestamp);
        userAmpReferral[_referrer].push(amount);
        userAmpReferral[_referrer].push(referrerAmount);

        emit Referral(msg.sender, _referrer, originalAmount);
        emit Deposit(msg.sender, originalAmount, _referrer);
    }

    /// @notice Function to claim MAXX directly to user wallet
    /// @param _day The day to claim MAXX for
    function claim(uint256 _day) external {
        _checkDayRange(_day);
        if (
            address(stake) == address(0) || block.timestamp < stake.launchDate()
        ) {
            revert StakingNotInitialized();
        }

        uint256 amount = _getClaimAmount(_day);

        if (
            block.timestamp >
            stake.launchDate() + ((CLAIM_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            // assess late penalty
            uint256 daysLate = ((block.timestamp -
                (stake.launchDate() +
                    ((CLAIM_PERIOD * 1 days) / _TEST_TIME_FACTOR))) *
                _TEST_TIME_FACTOR) / 1 days;
            if (daysLate >= MAX_LATE_DAYS) {
                revert ClaimExpired();
            } else {
                uint256 penaltyAmount = (amount * daysLate) / MAX_LATE_DAYS;
                amount -= penaltyAmount;
            }
        }

        bool success = IMaxxFinance(maxx).transfer(msg.sender, amount);
        if (!success) {
            revert MaxxTransferFailed();
        }

        emit Claim(msg.sender, _day, amount);
    }

    /// @notice Function to claim MAXX and directly stake
    /// @param _day The day to claim MAXX for
    /// @param _daysToStake The number of days to stake
    function claimToStake(uint256 _day, uint16 _daysToStake) external {
        _checkDayRange(_day);

        if (
            address(stake) == address(0) || block.timestamp < stake.launchDate()
        ) {
            revert StakingNotInitialized();
        }

        uint256 amount = _getClaimAmount(_day);

        if (
            block.timestamp >
            stake.launchDate() + ((CLAIM_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            // assess late penalty
            uint256 daysLate = (block.timestamp -
                (stake.launchDate() + CLAIM_PERIOD * 1 days)) / 1 days;
            if (daysLate >= MAX_LATE_DAYS) {
                revert ClaimExpired();
            } else {
                uint256 penaltyAmount = (amount * daysLate) / MAX_LATE_DAYS;
                amount -= penaltyAmount;
            }
        }

        IMaxxFinance(maxx).approve(address(stake), amount);
        stake.amplifierStake(msg.sender, _daysToStake, amount);
        emit Claim(msg.sender, _day, amount);
    }

    /// @notice Function to claim referral amount as liquid MAXX tokens
    function claimReferrals() external {
        if (
            address(stake) == address(0) || block.timestamp < stake.launchDate()
        ) {
            revert StakingNotInitialized();
        }
        uint256 amount = _getReferralAmountAndTransfer();
        emit ClaimReferral(msg.sender, amount);
    }

    /// @notice Function to set the Maxx Finance staking contract address
    /// @param _stake Address of the Maxx Finance staking contract
    function setStakeAddress(address _stake) external onlyOwner {
        stake = IStake(_stake);
        emit StakeAddressSet(_stake);
    }

    /// @notice Function to set the Maxx Genesis NFT contract address
    /// @param _maxxGenesis Address of the Maxx Genesis NFT contract
    function setMaxxGenesis(address _maxxGenesis) external onlyOwner {
        maxxGenesis = _maxxGenesis;
        emit MaxxGenesisSet(_maxxGenesis);
    }

    /// @notice Function to initialize the daily allocations
    /// @dev Function can only be called once
    /// @param _dailyAllocation Array of daily MAXX token allocations for 60 days
    function setDailyAllocations(uint256[60] memory _dailyAllocation)
        external
        onlyOwner
    {
        if (_allocationInitialized) {
            revert AlreadyInitialized();
        }
        _maxxDailyAllocation = _dailyAllocation;
        _allocationInitialized = true;
    }

    /// @notice Function to change the daily maxx allocation
    /// @dev Cannot change the daily allocation after the day has passed
    /// @param _day Day of the amplifier to change the allocation for
    /// @param _maxxAmount Amount of MAXX tokens to allocate for the day
    function changeDailyAllocation(uint256 _day, uint256 _maxxAmount)
        external
        onlyOwner
    {
        if (block.timestamp >= launchDate + (_day * 1 days)) {
            revert InvalidDay(_day);
        }
        _maxxDailyAllocation[_day] = _maxxAmount; // indexed at 0
    }

    /// @notice Function to change the start date
    /// @dev Cannot change the start date after the day has passed
    /// @param _launchDate New start date for the liquidity amplifier
    function changeLaunchDate(uint256 _launchDate) external onlyOwner {
        if (block.timestamp >= launchDate || block.timestamp >= _launchDate) {
            revert LaunchDatePassed();
        }
        launchDate = _launchDate;
        emit LaunchDateUpdated(_launchDate);
    }

    /// @notice Function to transfer Matic from this contract to address from input
    /// @param _to address of transfer recipient
    /// @param _amount amount of Matic to be transferred
    function withdraw(address payable _to, uint256 _amount) external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }

    /// @notice Function to reclaim any unallocated MAXX back to the vault
    function withdrawMaxx() external onlyOwner {
        if (address(stake) == address(0)) {
            revert StakingNotInitialized();
        }
        if (
            block.timestamp <=
            stake.launchDate() +
                (CLAIM_PERIOD * 1 days) +
                (MAX_LATE_DAYS * 1 days)
        ) {
            revert AmplifierNotComplete();
        }
        uint256 extraMaxx = IMaxxFinance(maxx).balanceOf(address(this));
        bool success = IMaxxFinance(maxx).transfer(maxxVault, extraMaxx);
        if (!success) {
            revert MaxxTransferFailed();
        }
    }

    /// @notice Get how many days have passed since `launchDate`
    /// @return day How many days have passed since `launchDate`
    function getDay() public view returns (uint256 day) {
        if (block.timestamp < launchDate) {
            revert AmplifierNotStarted();
        }
        day = ((block.timestamp - launchDate) * _TEST_TIME_FACTOR) / 1 days;
        return day;
    }

    /// @notice This function will return all liquidity amplifier participants
    /// @return participants Array of addresses that have participated in the Liquidity Amplifier
    function getParticipants() external view returns (address[] memory) {
        return participants;
    }

    /// @notice This function will return all liquidity amplifier participants for `day` day
    /// @param day The day for which to return the participants
    /// @return participants Array of addresses that have participated in the Liquidity Amplifier
    function getParticipantsByDay(uint256 day)
        external
        view
        returns (address[] memory)
    {
        return participantsByDay[day];
    }

    /// @notice This function will return a slice of the participants array
    /// @dev This function is used to paginate the participants array
    /// @param start The starting index of the slice
    /// @param length The amount of participants to return
    /// @return participantsSlice Array slice of addresses that have participated in the Liquidity Amplifier
    /// @return newStart The new starting index for the next slice
    function getParticipantsSlice(uint256 start, uint256 length)
        external
        view
        returns (address[] memory participantsSlice, uint256 newStart)
    {
        for (uint256 i = 0; i < length; i++) {
            participantsSlice[i] = (participants[i + start]);
        }
        return (participantsSlice, start + length);
    }

    /// @notice This function will return the maxx allocated for day `day`
    /// @dev This function will revert until after the day `day` has ended
    /// @param _day The day of the liquidity amplifier period 0-59
    /// @return The maxx allocated for day `day`
    function getMaxxDailyAllocation(uint256 _day)
        external
        view
        returns (uint256)
    {
        uint256 currentDay = getDay();

        // changed: does not revert on current day
        if (_day >= AMPLIFIER_PERIOD || _day > currentDay) {
            revert InvalidDay(_day);
        }

        return _maxxDailyAllocation[_day];
    }

    /// @notice This function will return the matic deposited for day `day`
    /// @dev This function will revert until after the day `day` has ended
    /// @param _day The day of the liquidity amplifier period 0-59
    /// @return The matic deposited for day `day`
    function getMaticDailyDeposit(uint256 _day)
        external
        view
        returns (uint256)
    {
        uint256 currentDay = getDay();

        // changed: does not revert on current day
        if (_day >= AMPLIFIER_PERIOD || _day > currentDay) {
            revert InvalidDay(_day);
        }

        return _maticDailyDeposits[_day];
    }

    /// @notice This function will return the effective matic deposited for day `day`
    /// @dev This function will revert until after the day `day` has ended
    /// @param _day The day of the liquidity amplifier period 0-59
    /// @return The effective matic deposited for day `day`
    function getEffectiveMaticDailyDeposit(uint256 _day)
        external
        view
        returns (uint256)
    {
        uint256 currentDay = getDay();
        if (_day >= AMPLIFIER_PERIOD || _day > currentDay) {
            revert InvalidDay(_day);
        }
        return _effectiveMaticDailyDeposits[_day];
    }

    function getUserAmpReferrals(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userAmpReferral[_user];
    }

    function _mintMaxxGenesis(string memory code) internal {
        if (maxxGenesis == address(0)) {
            revert MaxxGenesisNotSet();
        }

        bool success = IMAXXBoost(maxxGenesis).mint(code, msg.sender);
        if (!success) {
            revert MaxxGenesisMintFailed();
        }
        emit MaxxGenesisMinted(msg.sender, code);
    }

    /// @return amount The amount of MAXX tokens to be claimed
    function _getClaimAmount(uint256 _day) internal returns (uint256) {
        if (dayClaimed[msg.sender][_day]) {
            revert AlreadyClaimed(_day);
        }
        dayClaimed[msg.sender][_day] = true;
        uint256 amount = (_maxxDailyAllocation[_day] *
            effectiveUserDailyDeposits[msg.sender][_day]) /
            _effectiveMaticDailyDeposits[_day];
        return amount;
    }

    /// @return amount The amount of MAXX tokens to be claimed
    function _getReferralAmountAndTransfer() internal returns (uint256) {
        uint256 amount;
        for (uint256 i = 0; i < AMPLIFIER_PERIOD; i++) {
            if (_effectiveMaticDailyDeposits[i] > 0) {
                amount +=
                    (_maxxDailyAllocation[i] *
                        effectiveUserReferrals[msg.sender][i]) /
                    _effectiveMaticDailyDeposits[i];
            }
        }
        amount -= claimedReferralAmount[msg.sender];
        claimedReferralAmount[msg.sender] += amount;
        IMaxxFinance(maxx).transfer(msg.sender, amount);
        return amount;
    }

    function _checkDayRange(uint256 _day) internal view {
        if (_day >= AMPLIFIER_PERIOD) {
            revert InvalidDay(_day);
        }
        if (
            block.timestamp <=
            launchDate + ((CLAIM_PERIOD * 1 days) / _TEST_TIME_FACTOR)
        ) {
            revert AmplifierNotComplete();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title The interface for the Maxx Finance liquidity amplifier contract
interface ILiquidityAmplifier {
    /// Invalid referrer address `referrer`
    /// @param referrer The address of the referrer
    error InvalidReferrer(address referrer);
    /// Liquidity Amplifier has not yet started
    error AmplifierNotStarted();
    ///Liquidity Amplifier is already complete
    error AmplifierComplete();
    /// Liquidity Amplifier is not complete
    error AmplifierNotComplete();
    /// Claim period has ended
    error ClaimExpired();
    /// Invalid input day
    /// @param day The amplifier day 1-60
    error InvalidDay(uint256 day);
    /// User has already claimed for this day
    /// @param day The amplifier day 1-60
    error AlreadyClaimed(uint256 day);
    /// User has already claimed referral rewards
    error AlreadyClaimedReferrals();
    /// The Maxx allocation has already been initialized
    error AlreadyInitialized();
    /// The Maxx Finance Staking contract hasn't been initialized
    error StakingNotInitialized();
    /// Current or proposed launch date has already passed
    error LaunchDatePassed();
    /// Unable to withdraw Matic
    error WithdrawFailed();
    /// MaxxGenesis address not set
    error MaxxGenesisNotSet();
    /// MaxxGenesis NFT not minted
    error MaxxGenesisMintFailed();
    /// Maxx transfer failed
    error MaxxTransferFailed();

    /// @notice Emitted when matic is 'deposited'
    /// @param user The user depositing matic into the liquidity amplifier
    /// @param amount The amount of matic depositied
    /// @param referrer The address of the referrer (0x0 if none)
    event Deposit(
        address indexed user,
        uint256 indexed amount,
        address indexed referrer
    );

    /// @notice Emitted when MAXX is claimed from a deposit
    /// @param user The user claiming MAXX
    /// @param day The day of the amplifier claimed
    /// @param amount The amount of MAXX claimed
    event Claim(
        address indexed user,
        uint256 indexed day,
        uint256 indexed amount
    );

    /// @notice Emitted when MAXX is claimed from a referral
    /// @param user The user claiming MAXX
    /// @param amount The amount of MAXX claimed
    event ClaimReferral(address indexed user, uint256 amount);

    /// @notice Emitted when a deposit is made with a referral
    event Referral(
        address indexed user,
        address indexed referrer,
        uint256 amount
    );
    /// @notice Emitted when the Maxx Stake contract address is set
    event StakeAddressSet(address indexed stake);
    /// @notice Emitted when the Maxx Genesis NFT contract address is set
    event MaxxGenesisSet(address indexed maxxGenesis);
    /// @notice Emitted when the launch date is updated
    event LaunchDateUpdated(uint256 newLaunchDate);
    /// @notice Emitted when a Maxx Genesis NFT is minted
    event MaxxGenesisMinted(address indexed user, string code);

    /// @notice Liquidity amplifier start date
    function launchDate() external view returns (uint256);

    /// @notice This function will return all liquidity amplifier participants
    /// @return participants Array of addresses that have participated in the Liquidity Amplifier
    function getParticipants() external view returns (address[] memory);

    /// @notice This function will return all liquidity amplifier participants for `day` day
    /// @param day The day for which to return the participants
    /// @return participants Array of addresses that have participated in the Liquidity Amplifier
    function getParticipantsByDay(uint256 day)
        external
        view
        returns (address[] memory);

    /// @notice This function will return a slice of the participants array
    /// @dev This function is used to paginate the participants array
    /// @param start The starting index of the slice
    /// @param length The amount of participants to return
    /// @return participantsSlice Array slice of addresses that have participated in the Liquidity Amplifier
    /// @return newStart The new starting index for the next slice
    function getParticipantsSlice(uint256 start, uint256 length)
        external
        view
        returns (address[] memory participantsSlice, uint256 newStart);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title The interface for the Maxx Finance staking contract
interface IStake is IERC721 {
    /// Not authorized to control the stake
    error NotAuthorized();

    /// Cannot stake less than {MIN_STAKE_DAYS} days
    error StakeTooShort();

    /// Cannot stake more than {MAX_STAKE_DAYS} days
    error StakeTooLong();

    /// Cannot stake less than 50_000 MAXX
    error InvalidAmount();

    /// Address does not own enough MAXX tokens
    error InsufficientMaxx();

    /// Stake has not yet completed
    error StakeNotComplete();

    /// Stake has already been claimed
    error StakeAlreadyWithdrawn();

    /// User does not own the NFT
    error IncorrectOwner();

    /// NFT boost has already been used
    error UsedNFT();

    /// NFT collection is not accepted
    error NftNotAccepted();

    /// Token transfer returned false (failed)
    error TransferFailed();

    /// Tokens already staked for maximum duration
    error AlreadyMaxDuration();

    /// Unstaked Free Claims have already been migrated
    error FreeClaimsAlreadyMigrated();

    /// Current or proposed launch date has already passed
    error LaunchDatePassed();

    /// `_nft` does not support the IERC721 interface
    /// @param _nft the address of the NFT contract
    error InterfaceNotSupported(address _nft);

    /// @notice Emitted when MAXX is staked
    /// @param stakeId The ID of the stake
    /// @param user The user staking MAXX
    /// @param numDays The number of days staked
    /// @param amount The amount of MAXX staked
    event Stake(
        uint256 indexed stakeId,
        address indexed user,
        uint16 numDays,
        uint256 amount
    );

    /// @notice Emitted when MAXX is unstaked
    /// @param user The user unstaking MAXX
    /// @param amount The amount of MAXX unstaked
    event Unstake(
        uint256 indexed stakeId,
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when the name of a stake is changed
    /// @param stakeId The id of the stake
    /// @param name The new name of the stake
    event StakeNameChange(uint256 stakeId, string name);

    /// @notice Emitted when the launch date is updated
    event LaunchDateUpdated(uint256 newLaunchDate);
    /// @notice Emitted when the liquidityAmplifier address is updated
    event LiquidityAmplifierSet(address liquidityAmplifier);
    /// @notice Emitted when the freeClaim address is updated
    event FreeClaimSet(address freeClaim);
    event NftBonusSet(address nft, uint256 bonus);
    event BaseURISet(string baseUri);
    event AcceptedNftAdded(address nft);
    event AcceptedNftRemoved(address nft);

    struct StakeData {
        string name;
        address owner;
        uint256 amount;
        uint256 shares;
        uint256 duration;
        uint256 startDate;
        bool withdrawn;
    }

    enum MaxxNFT {
        MaxxGenesis,
        MaxxBoost
    }

    function stakes(uint256)
        external
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        );

    function launchDate() external view returns (uint256);

    function freeClaimStake(
        address owner,
        uint16 numDays,
        uint256 amount
    ) external returns (uint256 stakeId, uint256 shares);

    function amplifierStake(
        address owner,
        uint16 numDays,
        uint256 amount
    ) external returns (uint256 stakeId, uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title The interface for the Maxx Finance token contract
interface IMaxxFinance is IERC20, IAccessControl {
    /// @notice Increases the token balance of `to` by `amount`
    /// @param to The address to mint to
    /// @param amount The amount to mint
    /// Emits a {Transfer} event.
    function mint(address to, uint256 amount) external;

    /// @dev Decreases the token balance of `msg.sender` by `amount`
    /// @param amount The amount to burn
    /// Emits a {Transfer} event with `to` set to the zero address.
    function burn(uint256 amount) external;

    /// @dev Decreases the token balance of `from` by `amount`
    /// @param from The address to burn from
    /// @param amount The amount to burn
    /// Emits a {Transfer} event with `to` set to the zero address.
    function burnFrom(address from, uint256 amount) external;

    // solhint-disable-next-line func-name-mixedcase
    function MINTER_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title The interface for the Maxx Finance MAXXBoost NFT contract
interface IMAXXBoost is IERC721 {
    function setUsed(uint256 _tokenId) external;

    function getUsedState(uint256 _tokenId) external view returns (bool);

    function mint(string memory _code, address _user) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}