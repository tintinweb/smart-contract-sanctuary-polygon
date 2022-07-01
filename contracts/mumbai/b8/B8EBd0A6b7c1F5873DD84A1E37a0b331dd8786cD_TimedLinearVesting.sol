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

// File: TimedLinearVesting.sol

// ERRORS
// TLV1 : Incorrect length of arrays
// TLV2 : Token transfer failed
// TLV7 : Maturity time less than start time

/// @title Timed Linear Vesting
/// @notice Tokens are vesterd lineary at/till fixed timed periods
/// 20% vested linearly in 6 months, then next 30% vested linearly in 2 months
/// @author @realdiganta
contract TimedLinearVesting {
    event NewVestingScheduled(
        address from,
        address to,
        uint64 startTime,
        uint64 maturityTime,
        uint256 tokensAllocation
    );

    event TokensWithdrawn(address vester, address to, uint256 amount);

    struct VesterData {
        uint64 duration;
        uint64 startTime; // also is the time when the user last withdrawn
        uint64 maturityTime; // the timestamp when token vesting will end
        uint256 tokensAlloc; // total number of tokens that will ve vested in the given period
    }

    uint256 private constant MAX_BPS = 10_000;

    IERC20 token;
    mapping(address => bool) creators; // only creators are allowed to create vesting schedules
    mapping(address => uint256) public totalVestingSchedules; // vester => total number of vesting schedules created for the user
    mapping(address => mapping(uint256 => VesterData)) public vesterData; // vester => vestingId => VesterData

    modifier onlyCreator(address _account) {
        require(creators[_account], "Error : LV5");
        _;
    }

    function initialize(address _token, address[] memory _creators) public {
        require(address(token) == address(0), "Error : LV1");
        token = IERC20(_token);
        for (uint256 i = 0; i < _creators.length; ++i) {
            creators[_creators[i]] = true;
        }
    }

    /// @dev Hypothesis: This same method can be used to extra vestings for this user. Test it properly & come to your conclusion
    function addVestingSchedule(
        address _for,
        uint64 _startTime,
        uint64[] calldata _maturityTimes,
        uint256[] calldata _percents,
        uint256 _totalAmt
    ) external onlyCreator(msg.sender) {
        uint256 length = _percents.length;

        require(_maturityTimes.length == length, "Error : TLV1");
        uint256 amount;
        uint64 maturityTimeOfPrevVesting = _startTime;
        for (uint256 i = 0; i < length; ++i) {
            amount = (_percents[i] * _totalAmt) / MAX_BPS;
            _addVestingSchedule(
                _for,
                maturityTimeOfPrevVesting,
                _maturityTimes[i],
                amount
            );

            maturityTimeOfPrevVesting = _maturityTimes[i];
        }
    }

    /// @dev go through all the vesting ids & then withdraw the vestings for each id
    function withdraw(address _to) external {
        uint64 timeNow = uint64(block.timestamp);
        uint256 vestings = totalVestingSchedules[msg.sender];

        uint256 tokensVested;
        uint256 temp;
        for (uint256 i = 0; i < vestings; ++i) {
            temp = _tokensUnlocked(msg.sender, i);

            if (temp > 0) {
                tokensVested += temp;
                vesterData[msg.sender][i].startTime = timeNow;
            }
        }

        require(token.transfer(_to, tokensVested), "Error : TLV2");

        emit TokensWithdrawn(msg.sender, _to, tokensVested);
    }

    // ******************************************************** INTERNAL METHODS ********************************************************************************

    function _tokensUnlocked(address _for, uint256 _id)
        internal
        view
        returns (uint256 toBeVested)
    {
        VesterData memory data = vesterData[_for][_id];

        // if current time is greater than data.maturityTime then take current time as maturityTime so as to only give rewards till maturityTime
        uint256 rn = block.timestamp < data.maturityTime
            ? block.timestamp
            : data.maturityTime;

        // if rn < data.startTime then vesting has not started till now, so return zero
        if (rn > data.startTime) {
            uint256 timeGone = (rn - data.startTime);

            toBeVested = (timeGone * data.tokensAlloc) / data.duration;
        }
    }

    function _addVestingSchedule(
        address _for,
        uint64 _startTime,
        uint64 _maturityTime,
        uint256 _tokensAllocation
    ) internal {
        // sanity checks
        require(_startTime > block.timestamp, "TLV3");
        require(_maturityTime > _startTime, "TLV4");

        // first transfer tokens to contract
        require(
            token.transferFrom(msg.sender, address(this), _tokensAllocation),
            "LV2"
        );

        vesterData[_for][totalVestingSchedules[_for]] = VesterData({
            duration: _maturityTime - _startTime,
            startTime: _startTime,
            maturityTime: _maturityTime,
            tokensAlloc: _tokensAllocation
        });

        ++totalVestingSchedules[_for];

        emit NewVestingScheduled(
            msg.sender,
            _for,
            _startTime,
            _maturityTime,
            _tokensAllocation
        );
    }

    function _isUnlocked(uint64 _maturityPeriod) internal view returns (bool) {
        return block.timestamp > _maturityPeriod;
    }
}