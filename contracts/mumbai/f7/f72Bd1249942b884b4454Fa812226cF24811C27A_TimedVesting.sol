/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// File: IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: TimedVesting.sol

// ERRORS:
// TV0 : Already initialized
// TV1 : Incorrect length of arrays
// TV2 : Transfer of tokens failed
// TV3 : Total percentage doesnt add up to 10000 (100%)
// TV4 : vestings already added for this account. Use the addExtraVestings method to add more vestings
// TV5 : vestings still not created for this account. Use the addVestingSchedule method

/// @title TimedVesting of tokens
/// @notice timed vesting of tokens
/// @author @realdiganta
contract TimedVesting is ReentrancyGuard {
    event VestingScheduleAdded(
        address from,
        address to,
        uint64[] maturityPeriods,
        uint256[] amounts
    );

    event TokensWithdrawn(
        address vester,
        address to,
        uint256 amount,
        uint256 maturityPeriod
    );

    struct VesterData {
        uint64[] maturityPeriods;
        uint256[] amounts;
    }

    IERC20 private token;
    mapping(address => VesterData) private vestersData;
    uint256 private constant MAX_BPS = 10_000;

    function initialize(address _token) external {
        require(address(token) == address(0x0), "Error : TV0");
        token = IERC20(_token);
    }

    function addVestingSchedule(
        address _for,
        uint64[] calldata _maturityPeriods,
        uint256[] calldata _percents,
        uint256 _totalAmount
    ) external {
        require(vestersData[_for].amounts.length == 0, "Error : TV4");

        uint256 n = _percents.length;
        require(_maturityPeriods.length == n, "Error : TV1");

        uint256 totalPercent;
        uint256[] memory amounts = new uint256[](n);

        for (uint256 i = 0; i < n; ++i) {
            totalPercent += _percents[i];
            amounts[i] = (_totalAmount * _percents[i]) / MAX_BPS;
        }

        require(totalPercent == MAX_BPS, "Error : TV3");

        require(
            token.transferFrom(msg.sender, address(this), _totalAmount),
            "Error : TV2"
        );

        vestersData[_for] = VesterData({
            maturityPeriods: _maturityPeriods,
            amounts: amounts
        });

        emit VestingScheduleAdded(msg.sender, _for, _maturityPeriods, amounts);
    }

    function addExtraVestings(
        address _for,
        uint64[] calldata _maturityPeriods,
        uint256[] calldata _amounts
    ) external {
        VesterData storage data = vestersData[_for];
        require(data.amounts.length != 0, "Error : TV5");

        uint256 n = _maturityPeriods.length;

        require(n == _amounts.length, "Error : TV1");

        uint256 totalAmount;
        for (uint256 i = 0; i < n; ++i) {
            data.maturityPeriods.push(_maturityPeriods[i]);
            data.amounts.push(_amounts[i]);
            totalAmount += _amounts[i];
        }

        require(
            token.transferFrom(msg.sender, address(this), totalAmount),
            "Error : TV2"
        );

        emit VestingScheduleAdded(msg.sender, _for, _maturityPeriods, _amounts);
    }

    function withdraw(address _to) external nonReentrant {
        VesterData memory data = vestersData[msg.sender];
        uint256 n = data.maturityPeriods.length;

        for (uint256 i = 0; i < n; ++i) {
            if (data.amounts[i] != 0) {
                if (_isUnlocked(data.maturityPeriods[i])) {
                    require(
                        token.transfer(_to, data.amounts[i]),
                        "Error : TV2"
                    );

                    emit TokensWithdrawn(
                        msg.sender,
                        _to,
                        data.amounts[i],
                        data.maturityPeriods[i]
                    );

                    data.amounts[i] = 0; // sets the amount to zero so that the user cannot withdraw the same amount again
                }
            }
        }

        vestersData[msg.sender] = data;
    }

    /// @notice just a view method to get the vestings for an account
    function showVestings(address _for)
        external
        view
        returns (uint64[] memory maturityPeriods, uint256[] memory amounts)
    {
        VesterData memory data = vestersData[_for];

        maturityPeriods = data.maturityPeriods;
        amounts = data.amounts;
    }

    // *************************************** INTERNAL METHODS ********************************************************

    function _isUnlocked(uint64 _maturityPeriod) internal view returns (bool) {
        return block.timestamp > _maturityPeriod;
    }
}