/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
    function renounceOwnership() external virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface ITokenVestingTLT {
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) external;
}

contract TokenPresaleTLT is Ownable, ReentrancyGuard {
    IERC20 public immutable tokenAddress;
    uint8 private constant _tokenDecimals = 18;
    uint256 public tokenPriceInWei;
    uint256 public referrerCommissionTokenAmount;
    uint256 public minimumBuyMaticValueForRefferal;

    ITokenVestingTLT public vestingContractAddress;
    uint256 private _vestingCliff1;
    uint256 private _vestingStart1;
    uint256 private _vestingDuration1;
    uint256 private _vestingSlicePeriodSeconds1;
    uint256 private _vestingCliff2;
    uint256 private _vestingStart2;
    uint256 private _vestingDuration2;
    uint256 private _vestingSlicePeriodSeconds2;

    event TokenSold(address, uint256);
    event TokenPriceChanged(uint256, uint256);
    event ReferrerCommissionSent(address, uint256);
    event VestingScheduleChanged(uint256, uint256, uint256, uint256);
    event VestingContractAddressChanged(address, address);
    event ReferrerCommissionTokenAmountChanged(uint256);
    event MinimumBuyMaticValueForRefferalChanged(uint256);

    constructor(address _tokenAddress, address _vestingContractAddress) {
        require(
            _tokenAddress != address(0x0),
            "TokenPresaleTLT: token contract address must not be null"
        );
        require(
            _vestingContractAddress != address(0x0),
            "TokenPresaleTLT: vesting contract address must not be null"
        );
        tokenAddress = IERC20(_tokenAddress);
        tokenPriceInWei = 87000000000000000; // 0.087 MATIC =~ 0.1USD at 1.14USD/MATIC
        referrerCommissionTokenAmount = 150 * 10 ** _tokenDecimals; // 150TLT = 15USD at 0.10USD/TLT
        minimumBuyMaticValueForRefferal = 44 * 10 ** _tokenDecimals; // 44MATIC = 50USD

        vestingContractAddress = ITokenVestingTLT(_vestingContractAddress);

        // VESTING SCHEDULE: in first 11 months 8% release per month, in 12th month 12% release
        _vestingCliff1 = 1;
        _vestingStart1 = 1698778800; // October 31, 2023 20:00 (German Time)
        _vestingDuration1 = 28927173; // 11 months
        _vestingSlicePeriodSeconds1 = 86400; // daily release

        _vestingCliff2 = 1;
        _vestingStart2 = 1698778800 + 28927173; // after 11 months: Monday, September 30, 2024 15:19  (German Time)
        _vestingDuration2 = 2629743; // 1 month
        _vestingSlicePeriodSeconds2 = 86400; // daily release
    }

    function changeTokenPrice(
        uint256 _tokenPriceInWei
    ) external onlyOwner returns (bool) {
        require(
            _tokenPriceInWei > 0,
            "TokenPresaleTLT: token price must be greater than 0 wei"
        );

        uint256 oldPrice = tokenPriceInWei;
        tokenPriceInWei = _tokenPriceInWei;

        emit TokenPriceChanged(oldPrice, tokenPriceInWei);
        return true;
    }

    function changeReferrerCommissionTokenAmount(
        uint256 _referrerCommissionTokenAmount
    ) external onlyOwner returns (bool) {
        referrerCommissionTokenAmount = _referrerCommissionTokenAmount;

        emit ReferrerCommissionTokenAmountChanged(
            referrerCommissionTokenAmount
        );
        return true;
    }

    function changeMinimumMaticValueForRefferal(
        uint256 _minimumBuyMaticValueForRefferal
    ) external onlyOwner returns (bool) {
        minimumBuyMaticValueForRefferal = _minimumBuyMaticValueForRefferal;

        emit MinimumBuyMaticValueForRefferalChanged(
            minimumBuyMaticValueForRefferal
        );
        return true;
    }

    function changeVestingContractAddress(
        address newContractAddress
    ) external onlyOwner returns (bool) {
        require(
            newContractAddress != address(0),
            "TokenPresaleTLT: new contract address is the zero address"
        );
        address oldContractAddress = address(vestingContractAddress);
        vestingContractAddress = ITokenVestingTLT(newContractAddress);

        emit VestingContractAddressChanged(
            oldContractAddress,
            address(vestingContractAddress)
        );
        return true;
    }

    function changeVestingSchedule1(
        uint256 vestingCliff1_,
        uint256 vestingStart1_,
        uint256 vestingDuration1_,
        uint256 vestingSlicePeriodSeconds1_
    ) external onlyOwner returns (bool) {
        _vestingCliff1 = vestingCliff1_;
        _vestingStart1 = vestingStart1_;
        _vestingDuration1 = vestingDuration1_;
        _vestingSlicePeriodSeconds1 = vestingSlicePeriodSeconds1_;

        emit VestingScheduleChanged(
            _vestingCliff1,
            _vestingStart1,
            _vestingDuration1,
            _vestingSlicePeriodSeconds1
        );
        return true;
    }

    function changeVestingSchedule2(
        uint256 vestingCliff2_,
        uint256 vestingStart2_,
        uint256 vestingDuration2_,
        uint256 vestingSlicePeriodSeconds2_
    ) external onlyOwner returns (bool) {
        _vestingCliff2 = vestingCliff2_;
        _vestingStart2 = vestingStart2_;
        _vestingDuration2 = vestingDuration2_;
        _vestingSlicePeriodSeconds2 = vestingSlicePeriodSeconds2_;

        emit VestingScheduleChanged(
            _vestingCliff2,
            _vestingStart2,
            _vestingDuration2,
            _vestingSlicePeriodSeconds2
        );
        return true;
    }

    function getvestingSchedule1()
        external
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (
            _vestingCliff1,
            _vestingStart1,
            _vestingDuration1,
            _vestingSlicePeriodSeconds1
        );
    }

    function getvestingSchedule2()
        external
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (
            _vestingCliff2,
            _vestingStart2,
            _vestingDuration2,
            _vestingSlicePeriodSeconds2
        );
    }

    function buyToken(
        address referrerAddress
    ) external payable nonReentrant returns (bool) {
        _buyToken(referrerAddress);

        return true;
    }

    function _buyToken(address referrerAddress) private {
        require(
            msg.value >= 1 wei,
            "TokenPresaleTLT: sent MATIC amount must be greater than 0 wei"
        );
        address buyer = _msgSender();
        uint256 contractTokenBalance = getContractTokenBalance();
        uint256 buyableTokens = _buyableTokens();

        if (
            referrerAddress != address(0) &&
            referrerAddress != buyer &&
            msg.value >= minimumBuyMaticValueForRefferal &&
            referrerCommissionTokenAmount > 0
        ) {
            require(
                (buyableTokens + referrerCommissionTokenAmount) <=
                    contractTokenBalance,
                "TokenPresaleTLT: buyable/commissioned token amount exceeds presale contract balance"
            );

            // VESTING SCHEDULE: in first 11 months 8% release per month, in 12th month 12% release
            _sendToVesting1(
                referrerAddress,
                (referrerCommissionTokenAmount * 88) / 100
            );
            _sendToVesting2(
                referrerAddress,
                (referrerCommissionTokenAmount * 12) / 100
            );
            emit ReferrerCommissionSent(
                referrerAddress,
                referrerCommissionTokenAmount
            );
        } else {
            require(
                buyableTokens <= contractTokenBalance,
                "TokenPresaleTLT: buyable token amount exceeds presale contract balance"
            );
        }

        // VESTING SCHEDULE: in first 11 months 8% release per month, in 12th month 12% release
        _sendToVesting1(buyer, (buyableTokens * 88) / 100);
        _sendToVesting2(buyer, (buyableTokens * 12) / 100);
        emit TokenSold(buyer, buyableTokens);
    }

    function _buyableTokens() private view returns (uint256) {
        uint256 buyableTokens = (msg.value * 10 ** _tokenDecimals) /
            tokenPriceInWei;

        return buyableTokens;
    }

    function _sendToVesting1(address beneficiary, uint256 amount) private {
        if (_vestingCliff1 == 1 && _vestingDuration1 == 1) {
            require(
                tokenAddress.transfer(beneficiary, amount),
                "TokenPresaleTLT: token TLT transfer to buyer/referrer not succeeded"
            );
        } else {
            require(
                tokenAddress.approve(address(vestingContractAddress), amount),
                "TokenPresaleTLT: token TLT approve to vesting contract not succeeded"
            );
            vestingContractAddress.createVestingSchedule(
                beneficiary,
                _vestingStart1,
                _vestingCliff1,
                _vestingDuration1,
                _vestingSlicePeriodSeconds1,
                amount
            );
        }
    }

    function _sendToVesting2(address beneficiary, uint256 amount) private {
        if (_vestingCliff2 == 1 && _vestingDuration2 == 1) {
            require(
                tokenAddress.transfer(beneficiary, amount),
                "TokenPresaleTLT: token TLT transfer to buyer/referrer not succeeded"
            );
        } else {
            require(
                tokenAddress.approve(address(vestingContractAddress), amount),
                "TokenPresaleTLT: token TLT approve to vesting contract not succeeded"
            );
            vestingContractAddress.createVestingSchedule(
                beneficiary,
                _vestingStart2,
                _vestingCliff2,
                _vestingDuration2,
                _vestingSlicePeriodSeconds2,
                amount
            );
        }
    }

    function getContractMaticBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMaticBalance() external onlyOwner returns (bool) {
        require(
            payable(owner()).send(address(this).balance),
            "TokenPresaleTLT: failed to send MATIC to the owner"
        );

        return true;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return tokenAddress.balanceOf(address(this));
    }

    function withdrawContractTokenBalance(
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(
            amount <= getContractTokenBalance(),
            "TokenVestingTLT: not enough withdrawable funds"
        );
        require(
            tokenAddress.transfer(owner(), amount),
            "TokenPresaleTLT: token TLT transfer to owner not succeeded"
        );

        return true;
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    fallback() external payable {
        _buyToken(address(0));
    }

    receive() external payable {
        _buyToken(address(0));
    }
}