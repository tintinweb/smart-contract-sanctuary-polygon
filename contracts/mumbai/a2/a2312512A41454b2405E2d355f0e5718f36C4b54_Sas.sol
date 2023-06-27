/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

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

contract Sas {
    struct UnlockInfo {
        uint256 unlockDate;
        uint256 percent;
    }

    struct VestingInfo {
        uint256 totalAmount;
        uint256 withdrawn;
        UnlockInfo[] unlockInfos; 
    }

    mapping(address => VestingInfo) public vestings;
    IERC20 public token;

    constructor(
        IERC20 _token,
        address[] memory _addresses,
        uint256[] memory _amounts,
        uint256[] memory _unlockDates, // single array of unlock dates
        uint256[] memory _unlockPercents // single array of unlock percentages
    ) {
        require(
            _addresses.length == _amounts.length &&
                _unlockDates.length == _unlockPercents.length,
            'Input arrays length mismatch'
        );

        token = _token;

        for (uint256 i = 0; i < _unlockDates.length; i++) {
            UnlockInfo memory newUnlockInfo = UnlockInfo({
                unlockDate: _unlockDates[i],
                percent: _unlockPercents[i]
            });

            for (uint256 j = 0; j < _addresses.length; j++) {
                VestingInfo storage vesting = vestings[_addresses[j]];
                vesting.totalAmount = _amounts[j];
                vesting.withdrawn = 0;
                vesting.unlockInfos.push(newUnlockInfo);
            }
        }
    }

    function withdraw() public {
        VestingInfo storage vesting = vestings[msg.sender];

        uint256 totalPercent = 0;
        for (uint256 i = 0; i < vesting.unlockInfos.length; i++) {
            if (block.timestamp >= vesting.unlockInfos[i].unlockDate) {
                totalPercent += vesting.unlockInfos[i].percent;
                vesting.unlockInfos[i].percent = 0;
            }
        }

        require(totalPercent > 0, 'No tokens to withdraw');

        uint256 withdrawable = (vesting.totalAmount * totalPercent) / 100;
        require(
            vesting.withdrawn + withdrawable <= vesting.totalAmount,
            'Cannot withdraw more than total amount'
        );
        vesting.withdrawn += withdrawable;

        token.transfer(msg.sender, withdrawable);
    }
}