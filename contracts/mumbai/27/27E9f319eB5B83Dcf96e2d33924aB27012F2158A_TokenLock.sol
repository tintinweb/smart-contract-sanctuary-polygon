// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLock {
    address public beneficiary;
    address public immutable tokenAddress;
    bool public immutable doVesting;
    uint public latestClaim = 0;
    struct Vesting {
        uint256 vestingTime;
        uint256 releaseValue;
    }
    Vesting[13] public vestings; // Array to store the Vesting
    uint256 public immutable totalTokens;
    uint256 public tokensReleased = 0;

    constructor(
        address _beneficiary,
        bool _doVesting,
        uint256[] memory _vestingTime,
        uint256[] memory _releaseValue,
        uint256 _totalTokens,
        address _tokenAddress
    ) {
        require(
            _vestingTime.length == _releaseValue.length,
            "require same length of array"
        );
        uint totalPercentage;
        for(uint256 i = 0; i < _releaseValue.length; i++){
            totalPercentage += _releaseValue[i];
        }
        require(totalPercentage == 10000, "total must 100%");

        for(uint256 i = 0; i < _vestingTime.length-1; i++){
            require(_vestingTime[i] < _vestingTime[i+1], "next vesting time must be higher than last vesting time!");
        }

        tokenAddress = _tokenAddress;
        beneficiary = _beneficiary;
        doVesting = _doVesting;
        totalTokens = _totalTokens;
        for (uint256 i = 0; i < _vestingTime.length; i++) {
            _releaseValue[i] = _releaseValue[i]*totalTokens/10000;
            // Create a new Vesting struct with the provided parameters
            Vesting memory vest = Vesting({
                vestingTime: _vestingTime[i],
                releaseValue: _releaseValue[i]
            });

            // Add the new pool to the vestings array
            vestings[i+1] = vest;
        }
    }

    modifier owner() {
        require(msg.sender == beneficiary, "only owner can Release Token!");
        _;
    }

    function releaseTokens() external owner{
        require(block.timestamp >= vestings[latestClaim+1].vestingTime, "cant claim token now!");
        require(vestings[latestClaim+1].releaseValue > 0, "All tokens have already been released");
        uint256 tokensToRelease = 0;
        for (uint256 i = latestClaim; i <= 12; i++) {
            if (block.timestamp >= vestings[i+1].vestingTime && vestings[i+1].vestingTime != 0) {
                tokensToRelease += vestings[i+1].releaseValue;
                vestings[i+1].releaseValue = 0;
                latestClaim = i+1;
            } else {
            break;
            }
        }
        tokensReleased += tokensToRelease;

        // Perform token transfer to the beneficiary
        require(IERC20(tokenAddress).transfer(beneficiary, tokensToRelease));
    }
}