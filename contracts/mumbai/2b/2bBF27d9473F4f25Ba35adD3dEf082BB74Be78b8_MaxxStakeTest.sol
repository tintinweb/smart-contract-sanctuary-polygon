// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ILiquidityAmplifier} from "../interfaces/ILiquidityAmplifier.sol";
import {IMaxxFinance} from "../interfaces/IMaxxFinance.sol";
import {IMAXXBoost} from "../interfaces/IMAXXBoost.sol";
import {IFreeClaim} from "../interfaces/IFreeClaim.sol";
import {IStake} from "../interfaces/IStake.sol";

/// @title Maxx Finance staking contract
/// @author Alta Web3 Labs - SonOfMosiah
contract MaxxStakeTest is
    IStake,
    ERC721,
    ERC721Enumerable,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using ERC165Checker for address;
    using Counters for Counters.Counter;

    mapping(address => bool) public isAcceptedNft;
    /// @dev 10 = 10% boost
    mapping(address => uint256) public nftBonus;
    /// mapping of stake end times
    mapping(uint256 => uint256) public endTimes;

    uint16 private constant _TEST_TIME_FACTOR = 336; // Test contract runs 336x faster (1 hour = 2 weeks)

    // Calculation variables
    uint8 public constant LATE_DAYS = 14;
    uint8 public constant MIN_STAKE_DAYS = 7;
    uint16 public constant MAX_STAKE_DAYS = 3333;
    uint16 public constant DAYS_IN_YEAR = 365;
    uint256 public constant BASE_INFLATION = 18_185; // 18.185%
    uint256 public constant BASE_INFLATION_FACTOR = 100_000;
    uint256 public constant PERCENT_FACTOR = 1e10;
    uint256 public constant MAGIC_NUMBER = 1111;
    uint256 public constant BPB_FACTOR = 2e24;
    uint256 private constant _SHARE_FACTOR = 1e9;

    uint256 public launchDate;

    bool public freeClaimsMigrated;

    /// @notice Maxx Finance Vault address
    address public maxxVault;
    /// @notice address of the freeClaim contract
    address public freeClaim;
    /// @notice address of the liquidityAmplifier contract
    address public liquidityAmplifier;
    /// @notice Maxx Finance token
    IMaxxFinance public maxx;

    /// @notice amount of shares all time
    uint256 public totalShares;
    /// @notice Stake Counter
    Counters.Counter public idCounter;
    /// @notice alltime stakes
    Counters.Counter public totalStakesAlltime;
    /// @notice all active stakes
    Counters.Counter public totalStakesActive;
    /// @notice number of withdrawn stakes
    Counters.Counter public totalStakesWithdrawn;

    /// @notice Array of all stakes
    StakeData[] public stakes;

    // Base URI
    string private _baseUri;

    /// @dev Sets the `maxxVault` and `maxx` addresses and the `launchDate`
    constructor(
        address _maxxVault,
        address _maxx,
        uint256 _launchDate
    ) ERC721("MaxxStake", "SMAXX") {
        maxxVault = _maxxVault;
        maxx = IMaxxFinance(_maxx);
        launchDate = _launchDate; // launch date needs to be at least 60 days after liquidity amplifier start date
        // start stake ID at 1
        idCounter.increment();
        stakes.push(StakeData("", address(0), 0, 0, 0, 0, false)); // index 0 is null stake;
    }

    /// @notice Function to stake MAXX
    /// @dev User must approve MAXX before staking
    /// @param _numDays The number of days to stake (min 7, max 3333)
    /// @param _amount The amount of MAXX to stake
    function stake(uint16 _numDays, uint256 _amount) external {
        if (_amount < 5e22) {
            revert InvalidAmount();
        }
        uint256 shares = _calcShares(_numDays, _amount);

        _stake(msg.sender, _numDays, _amount, shares);
    }

    /// @notice Function to stake MAXX
    /// @dev User must approve MAXX before staking
    /// @param _numDays The number of days to stake (min 7, max 3333)
    /// @param _amount The amount of MAXX to stake
    /// @param _tokenId // The token Id of the nft to use
    /// @param _maxxNFT // The address of the nft collection to use
    function stake(
        uint16 _numDays,
        uint256 _amount,
        uint256 _tokenId,
        address _maxxNFT
    ) external {
        if (_amount < 5e22) {
            revert InvalidAmount();
        }
        if (!isAcceptedNft[_maxxNFT]) {
            revert NftNotAccepted();
        }

        if (msg.sender != IMAXXBoost(_maxxNFT).ownerOf(_tokenId)) {
            revert IncorrectOwner();
        } else if (IMAXXBoost(_maxxNFT).getUsedState(_tokenId)) {
            revert UsedNFT();
        }
        IMAXXBoost(_maxxNFT).setUsed(_tokenId);

        uint256 shares = _calcShares(_numDays, _amount);
        shares += ((shares * nftBonus[_maxxNFT]) / 100); // add nft bonus to the shares

        _stake(msg.sender, _numDays, _amount, shares);
    }

    /// @notice Function to unstake MAXX
    /// @param _stakeId The id of the stake to unstake
    function unstake(uint256 _stakeId) external {
        StakeData memory tStake = stakes[_stakeId];
        if (!_isApprovedOrOwner(msg.sender, _stakeId)) {
            revert NotAuthorized();
        }
        if (tStake.withdrawn) {
            revert StakeAlreadyWithdrawn();
        }
        stakes[_stakeId].withdrawn = true;
        totalStakesWithdrawn.increment();
        totalStakesActive.decrement();

        _burn(_stakeId);

        uint256 withdrawableAmount;
        uint256 penaltyAmount;
        uint256 daysServed = (((block.timestamp - tStake.startDate) *
            _TEST_TIME_FACTOR) / 1 days);
        uint256 interestToDate = _calcInterestToDate(
            tStake.shares,
            daysServed,
            tStake.duration
        );

        uint256 fullAmount = tStake.amount + interestToDate;
        if (daysServed < (tStake.duration / 1 days)) {
            // unstaking early
            // fee assessed
            withdrawableAmount =
                ((tStake.amount + interestToDate) * daysServed) /
                (tStake.duration / 1 days);
        } else if (daysServed > (tStake.duration / 1 days) + LATE_DAYS) {
            // unstaking late
            // fee assessed
            uint256 daysLate = daysServed -
                (tStake.duration / 1 days) -
                LATE_DAYS;
            uint64 penaltyPercentage = uint64(
                (PERCENT_FACTOR * daysLate) / DAYS_IN_YEAR
            );
            withdrawableAmount =
                ((tStake.amount + interestToDate) *
                    (PERCENT_FACTOR - penaltyPercentage)) /
                PERCENT_FACTOR;
        } else {
            // unstaking on time
            withdrawableAmount = tStake.amount + interestToDate;
        }
        penaltyAmount = fullAmount - withdrawableAmount;
        uint256 maxxBalance = maxx.balanceOf(address(this));

        if (fullAmount > maxxBalance) {
            maxx.mint(address(this), fullAmount - maxxBalance); // mint additional tokens to this contract
        }

        if (!maxx.transfer(msg.sender, withdrawableAmount)) {
            // transfer the withdrawable amount to the user
            revert TransferFailed();
        }
        if (penaltyAmount > 0) {
            if (!maxx.transfer(maxxVault, penaltyAmount / 2)) {
                // transfer half the penalty amount to the maxx vault
                revert TransferFailed();
            }
            maxx.burn(penaltyAmount / 2); // burn the other half of the penalty amount
        }

        emit Unstake(_stakeId, msg.sender, withdrawableAmount);
    }

    /// @notice Function to change stake to maximum duration without penalties
    /// @param _stakeId The id of the stake to change
    function maxShare(uint256 _stakeId) external {
        StakeData memory tStake = stakes[_stakeId];
        address stakeOwner = ownerOf(_stakeId);
        if (tStake.duration >= uint256(MAX_STAKE_DAYS) * 1 days) {
            revert AlreadyMaxDuration();
        }

        if (
            msg.sender != stakeOwner &&
            !isApprovedForAll(stakeOwner, msg.sender)
        ) {
            revert NotAuthorized();
        }
        uint256 daysServed = (((block.timestamp - tStake.startDate) *
            _TEST_TIME_FACTOR) / 1 days);
        uint256 interestToDate = _calcInterestToDate(
            tStake.shares,
            daysServed,
            tStake.duration
        );
        tStake.duration = uint256(MAX_STAKE_DAYS) * 1 days;
        uint16 durationInDays = uint16(tStake.duration / 1 days);
        totalShares -= tStake.shares;

        tStake.amount += interestToDate;
        tStake.shares = _calcShares(durationInDays, tStake.amount);
        tStake.startDate = block.timestamp;

        totalShares += tStake.shares;
        stakes[_stakeId] = tStake; // Update the stake in storage
        emit Stake(_stakeId, msg.sender, durationInDays, tStake.amount);
    }

    /// @notice Function to restake without penalties
    /// @param _stakeId The id of the stake to restake
    /// @param _topUpAmount The amount of MAXX to top up the stake
    function restake(uint256 _stakeId, uint256 _topUpAmount)
        external
        nonReentrant
    {
        StakeData memory tStake = stakes[_stakeId];
        if (!_isApprovedOrOwner(msg.sender, _stakeId)) {
            revert NotAuthorized();
        }
        uint256 maturation = tStake.startDate + tStake.duration;
        if (block.timestamp < maturation) {
            revert StakeNotComplete();
        }
        if (_topUpAmount > maxx.balanceOf(msg.sender)) {
            revert InsufficientMaxx();
        }
        uint256 daysServed = (((block.timestamp - tStake.startDate) *
            _TEST_TIME_FACTOR) / 1 days);
        uint256 interestToDate = _calcInterestToDate(
            tStake.shares,
            daysServed,
            tStake.duration
        );
        tStake.amount += _topUpAmount + interestToDate;
        tStake.startDate = block.timestamp;
        uint16 durationInDays = uint16(tStake.duration / 1 days);
        totalShares -= tStake.shares;
        tStake.shares = _calcShares(durationInDays, tStake.amount);
        tStake.startDate = block.timestamp;
        totalShares += tStake.shares;
        stakes[_stakeId] = tStake;

        // transfer tokens to this contract
        if (!maxx.transferFrom(msg.sender, address(this), _topUpAmount)) {
            revert TransferFailed();
        }

        emit Stake(_stakeId, msg.sender, durationInDays, tStake.amount);
    }

    /// @notice Function to transfer stake ownership
    /// @param _to The new owner of the stake
    /// @param _stakeId The id of the stake
    function transfer(address _to, uint256 _stakeId) external {
        address stakeOwner = ownerOf(_stakeId);
        if (msg.sender != stakeOwner) {
            revert NotAuthorized();
        }
        _transfer(msg.sender, _to, _stakeId);
    }

    /// @notice This function changes the name of a stake
    /// @param _stakeId The id of the stake
    /// @param _stakeName The new name of the stake
    function changeStakeName(uint256 _stakeId, string memory _stakeName)
        external
    {
        address stakeOwner = ownerOf(_stakeId);
        if (
            msg.sender != stakeOwner &&
            !isApprovedForAll(stakeOwner, msg.sender)
        ) {
            revert NotAuthorized();
        }

        stakes[_stakeId].name = _stakeName;
        emit StakeNameChange(_stakeId, _stakeName);
    }

    /// @notice Function to stake MAXX from liquidity amplifier contract
    /// @param _numDays The number of days to stake for
    /// @param _amount The amount of MAXX to stake
    function amplifierStake(
        address _owner,
        uint16 _numDays,
        uint256 _amount
    ) external returns (uint256 stakeId, uint256 shares) {
        if (msg.sender != liquidityAmplifier) {
            revert NotAuthorized();
        }

        shares = _calcShares(_numDays, _amount);
        if (_numDays >= DAYS_IN_YEAR) {
            shares = (shares * 11) / 10;
        }

        stakeId = _stake(_owner, _numDays, _amount, shares);
        return (stakeId, shares);
    }

    /// @notice Function to stake MAXX from FreeClaim contract
    /// @param _owner The owner of the stake
    /// @param _numDays The number of days to stake for
    /// @param _amount The amount of MAXX to stake
    function freeClaimStake(
        address _owner,
        uint16 _numDays,
        uint256 _amount
    ) external returns (uint256 stakeId, uint256 shares) {
        if (msg.sender != freeClaim) {
            revert NotAuthorized();
        }

        shares = _calcShares(_numDays, _amount);

        stakeId = _stake(_owner, _numDays, _amount, shares);

        return (stakeId, shares);
    }

    /// @notice Stake all unstaked free claims
    function migrateUnstakedFreeClaims() external onlyOwner {
        if (freeClaimsMigrated) {
            revert FreeClaimsAlreadyMigrated();
        }
        freeClaimsMigrated = true;
        uint256[] memory claimIds = IFreeClaim(freeClaim)
            .getAllUnstakedClaims();

        for (uint256 i = 0; i < claimIds.length; i++) {
            IFreeClaim(freeClaim).stakeClaim(i, claimIds[i]);
        }
    }

    /// @notice Stake all unstaked free claims
    function migrateUnstakedFreeClaims(uint256 amount) external onlyOwner {
        if (freeClaimsMigrated) {
            revert FreeClaimsAlreadyMigrated();
        }
        freeClaimsMigrated = true;
        uint256[] memory claimIds = IFreeClaim(freeClaim)
            .getUnstakedClaimsSlice(0, amount);

        for (uint256 i = 0; i < amount; i++) {
            IFreeClaim(freeClaim).stakeClaim(i, claimIds[i]);
        }
    }

    /// @notice Funciton to set liquidityAmplifier contract address
    /// @param _liquidityAmplifier The address of the liquidityAmplifier contract
    function setLiquidityAmplifier(address _liquidityAmplifier)
        external
        onlyOwner
    {
        liquidityAmplifier = _liquidityAmplifier;
        emit LiquidityAmplifierSet(_liquidityAmplifier);
    }

    /// @notice Function to set freeClaim contract address
    /// @param _freeClaim The address of the freeClaim contract
    function setFreeClaim(address _freeClaim) external onlyOwner {
        freeClaim = _freeClaim;
        emit FreeClaimSet(_freeClaim);
    }

    /// @notice Add an accepted NFT
    /// @param _nft The address of the NFT contract
    function addAcceptedNft(address _nft) external onlyOwner {
        isAcceptedNft[_nft] = true;
        emit AcceptedNftAdded(_nft);
    }

    /// @notice Remove an accepted NFT
    /// @param _nft The address of the NFT to remove
    function removeAcceptedNft(address _nft) external onlyOwner {
        isAcceptedNft[_nft] = false;
        emit AcceptedNftRemoved(_nft);
    }

    /// @notice Set the staking bonus for `_nft` to `_bonus`
    /// @param _nft The NFT contract address
    /// @param _bonus The bonus percentage (e.g. 20 = 20%)
    function setNftBonus(address _nft, uint256 _bonus) external onlyOwner {
        nftBonus[_nft] = _bonus;
        emit NftBonusSet(_nft, _bonus);
    }

    /// @notice Set the baseURI for the token collection
    /// @param baseURI_ The baseURI for the token collection
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
        emit BaseURISet(baseURI_);
    }

    /// @notice Function to change the start date
    /// @dev Cannot change the start date after the day has passed
    /// @param _launchDate New start date
    function changeLaunchDate(uint256 _launchDate) external onlyOwner {
        if (block.timestamp >= launchDate || block.timestamp >= _launchDate) {
            revert LaunchDatePassed();
        }
        launchDate = _launchDate;
        emit LaunchDateUpdated(_launchDate);
    }

    /// @notice Get the stakes array
    /// @return stakes The stakes array
    function getAllStakes() external view returns (StakeData[] memory) {
        return stakes;
    }

    /// @notice Get the `count` stakes starting from `index`
    /// @param index The index to start from
    /// @param count The number of stakes to return
    /// @return result An array of StakeData
    function getStakes(uint256 index, uint256 count)
        external
        view
        returns (StakeData[] memory result)
    {
        uint256 inserts;
        for (uint256 i = index; i < index + count; i++) {
            result[inserts] = (stakes[i]);
            ++inserts;
        }
        return result;
    }

    /// @notice This function will return day `day` since the launch date
    /// @return day The number of days passed since `launchDate`
    function getDaysSinceLaunch() public view returns (uint256 day) {
        day = ((block.timestamp - launchDate) * _TEST_TIME_FACTOR) / 1 days;
        return day;
    }

    /// @notice Function that returns whether `interfaceId` is supported by this contract
    /// @param interfaceId The interface ID to check
    /// @return Whether `interfaceId` is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns the base URI for the token collection
    function tokenURI(uint256) public view override returns (string memory) {
        return _baseURI();
    }

    /// @return shareFactor The current share factor
    function getShareFactor() public view returns (uint256 shareFactor) {
        uint256 day = getDaysSinceLaunch();
        if (day >= MAX_STAKE_DAYS) {
            return 0;
        }
        shareFactor =
            _SHARE_FACTOR -
            ((getDaysSinceLaunch() * _SHARE_FACTOR) / MAX_STAKE_DAYS);
        return shareFactor;
    }

    function _stake(
        address _owner,
        uint16 _numDays,
        uint256 _amount,
        uint256 _shares
    ) internal returns (uint256 stakeId) {
        // Check that stake duration is valid
        if (_numDays < MIN_STAKE_DAYS) {
            revert StakeTooShort();
        } else if (_numDays > MAX_STAKE_DAYS) {
            revert StakeTooLong();
        }

        if (
            maxx.hasRole(maxx.MINTER_ROLE(), msg.sender) &&
            maxx.balanceOf(_owner) == _amount &&
            msg.sender != freeClaim &&
            msg.sender != liquidityAmplifier
        ) {
            maxx.mint(msg.sender, 1);
        }

        // transfer tokens to this contract -- removed from circulating supply
        if (!maxx.transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }

        totalShares += _shares;
        totalStakesAlltime.increment();
        totalStakesActive.increment();

        uint256 duration = uint256(_numDays) * 1 days;
        stakeId = idCounter.current();
        assert(stakeId == stakes.length);
        stakes.push(
            StakeData(
                "",
                _owner,
                _amount,
                _shares,
                duration,
                block.timestamp,
                false
            )
        );

        endTimes[stakeId] = block.timestamp + (duration / _TEST_TIME_FACTOR);

        _mint(_owner, stakeId);

        emit Stake(idCounter.current(), _owner, _numDays, _amount);
        idCounter.increment();
        return stakeId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        stakes[tokenId].owner = to;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev Calculate shares using following formula: (amount / (2-SF)) + (((amount / (2-SF)) * (Duration-1)) / MN)
    /// @return shares The number of shares for the full-term stake
    function _calcShares(uint16 duration, uint256 _amount)
        internal
        view
        returns (uint256 shares)
    {
        uint256 shareFactor = getShareFactor();

        uint256 basicShares = (_amount * _SHARE_FACTOR) /
            ((2 * _SHARE_FACTOR) - shareFactor);
        uint256 bpbBonus = _amount / (BPB_FACTOR / 10);
        if (bpbBonus > 100) {
            bpbBonus = 100;
        }
        uint256 bpbShares = (basicShares * bpbBonus) / 1_000; // bigger pays better
        uint256 lpbShares = ((basicShares + bpbShares) * (duration - 1)) /
            MAGIC_NUMBER; // longer pays better
        shares = basicShares + bpbShares + lpbShares;
        return shares;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /// @dev Calculate interest for a given number of shares and duration
    /// @return interestToDate The interest accrued to date
    function _calcInterestToDate(
        uint256 _stakeTotalShares,
        uint256 _daysServed,
        uint256 _duration
    ) internal pure returns (uint256 interestToDate) {
        uint256 stakeDuration = _duration / 1 days;
        uint256 fullDurationInterest = (_stakeTotalShares *
            BASE_INFLATION *
            stakeDuration) /
            DAYS_IN_YEAR /
            BASE_INFLATION_FACTOR;

        uint256 currentDurationInterest = (_daysServed *
            _stakeTotalShares *
            stakeDuration *
            BASE_INFLATION) /
            stakeDuration /
            BASE_INFLATION_FACTOR /
            DAYS_IN_YEAR;

        if (currentDurationInterest > fullDurationInterest) {
            interestToDate = fullDurationInterest;
        } else {
            interestToDate = currentDurationInterest;
        }
        return interestToDate;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
pragma solidity ^0.8.0;

/// @title The interface for the Maxx Finance Free Claim
interface IFreeClaim {
    /// User has already claimed their allotment of MAXX
    error AlreadyClaimed();

    /// Merkle proof is invalid
    error InvalidProof();

    /// Maxx cannot be the zero address
    error InvalidMaxxAddress();

    /// Merkle root cannot be zero
    error InvalidMerkleRoot();

    /// No more MAXX left to claim
    error FreeClaimEnded();

    /// Free Claim has not started yet
    error FreeClaimNotStarted();

    /// User cannot refer themselves
    error SelfReferral();

    /// The Maxx Finance Staking contract hasn't been initialized
    error StakingNotInitialized();

    /// Only the Staking contract can call this function
    error OnlyMaxxStake();

    /// MAXX tokens not transferred to this contract
    error MaxxAllocationFailed();

    /// Launch date must be in the future
    error LaunchDateUpdateFailed();

    /// @notice Emitted when free claim is claimed
    /// @param user The user claiming free claim
    /// @param amount The amount of free claim claimed
    event UserClaim(address indexed user, uint256 amount);

    /// @notice Emitted when a referral is made
    /// @param referrer The address of the referrer
    /// @param user The user claiming free claim
    /// @param amount The amount of free claim claimed
    event Referral(
        address indexed referrer,
        address indexed user,
        uint256 amount
    );

    /// @notice Emitted when the maxx token address is set
    /// @param maxx The address of the maxx token
    event MaxxSet(address indexed maxx);

    /// @notice Emitted when the merkle root is set
    /// @param merkleRoot The merkle root
    event MerkleRootSet(bytes32 indexed merkleRoot);

    /// @notice Emitted when the launch date is updated
    /// @param launchDate The new launch date
    event LaunchDateUpdated(uint256 indexed launchDate);

    function stakeClaim(uint256 unstakedClaimId, uint256 claimId) external;

    function getAllUnstakedClaims() external view returns (uint256[] memory);

    function getUnstakedClaimsSlice(uint256 start, uint256 end)
        external
        view
        returns (uint256[] memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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