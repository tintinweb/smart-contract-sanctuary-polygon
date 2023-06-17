/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
}

// File: contracts/LCTExchange.sol

pragma solidity ^0.8.3;

// Openzeppelin Imports


contract LCTExchange is Ownable {
    IERC20 public token;
    string public name;
    uint public exchangeStakedTokens;

    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public stakes;
    mapping(address => S_liquidity[]) public liqudityProviders;

    Stakeholder[] public stakeholders;

    struct Stake {
        uint256 amount;
        uint256 since;
        uint32 timeStaked;
        address user;
        bool claimable;
    }

    struct S_liquidity {
        uint256 amount;
        uint256 sinse;
    }

    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    event StakeWithdraw(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp
    );

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp
    );

    // END LIQUIDITY STATES

    // modifier handleWithdrawFundsModifier() {
    //     require(msg.sender == ownerWalletAddress);
    //     _;
    // }

    // constructor(IERC20Upgradeable _token, string memory _name) public {
    constructor(IERC20 _token, string memory _name) {
        token = _token;
        name = _name;
        stakeholders.push();
    }

    function exchangeBnbBalance() external view returns (uint) {
        return address(this).balance;
    }

    function userHistoryOfStake(
        address _user
    ) external view returns (Stakeholder memory) {
        uint256 index = stakes[_user];
        return stakeholders[index];
    }

    function exchangeHistoryOfStake()
        external
        view
        returns (Stakeholder[] memory)
    {
        return stakeholders;
    }

    function adminWithdraw(
        address payable recipient
    ) external payable onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function adminWithdrawToken() external payable onlyOwner {
        bool sent = token.transfer(
            owner(),
            (token.balanceOf(address(this)) - exchangeStakedTokens)
        );
        require(sent, "Failed to transfer tokens from vendor to Owner");
    }

    function _addStakeholder(address staker) internal returns (uint) {
        stakeholders.push();
        uint userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function stakeTokens(
        uint256 _amount,
        uint32 _timeStaked // timestaked will be in months Ex. 12,6,3,1,2
    ) public {
        // Check that the requested amount of tokens to sell is more than 0
        require(_amount > 100, "Cannot stake Belown then 100 wei");

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = token.balanceOf(msg.sender);
        require(
            userBalance >= _amount,
            "Your balance is lower than the amount of tokens you want to stake"
        );
        require(
            _timeStaked == 12 ||
                _timeStaked == 6 ||
                _timeStaked == 3 ||
                _timeStaked == 1 ||
                // this is for two minute test
                _timeStaked == 2,
            "Time Staked Should be 12, 6, 3, 1, 2"
        );

        if (_timeStaked == 2) {
            require(
                msg.sender == owner(),
                "Only Owner can test two minute Lock Token Function"
            );
        }

        uint256 index = stakes[msg.sender];
        if (index == 0) {
            index = _addStakeholder(msg.sender);
        }

        uint balanceBeforeTranfer = token.balanceOf(address(this));

        bool sent = token.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to transfer tokens from user to vendor");

        uint256 balanceAfterTranfer = token.balanceOf(address(this));
        uint256 actualAmount = balanceAfterTranfer - balanceBeforeTranfer;

        stakingBalance[msg.sender] += actualAmount;
        exchangeStakedTokens += actualAmount;

        stakeholders[index].address_stakes.push(
            Stake(actualAmount, block.timestamp, _timeStaked, msg.sender, true)
        );
        emit Staked(msg.sender, actualAmount, index, block.timestamp);
    }

    function _help_withdrawCheckTimePassedOrNot(
        uint256 _currentTimeStakedSince,
        uint32 stakedTimePeriod
    ) private view returns (bool) {
        //Example: 1677136837   >  (1674458437    +       (2629756 * 12))

        bool answer;
        if (
            block.timestamp >
            _currentTimeStakedSince + (2629756 * stakedTimePeriod)
        ) {
            answer = true;
        } else {
            answer = false;
        }
        return answer;
    }

    function userHaveStakes() public view returns (uint) {
        uint256 user_index = stakes[msg.sender];
        return user_index;
    }

    function withdrawStake(uint256 index) public {
        // require(index < stakes[msg.sender].address_stakes.length, "Invalid stake index.");

        uint256 user_index = stakes[msg.sender];
        require(user_index != 0, "You have no Stakes");

        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.claimable == true, "You already Withdrew");
        // If we not have to put 2 minutes testing
        // bool responseTimePassed = _help_withdrawCheckTimePassedOrNot(
        //     current_stake.since,
        //     current_stake.timeStaked
        // );
        // require(
        //     responseTimePassed == true,
        //     "You have to wait for the time, which selected in stake"
        // );

        bool responseTimePassed;
        // We also creted two minute stake test this two is two Minute stake test
        // if it is not two minute test then check the time is pass or not
        if (current_stake.timeStaked != 2) {
            responseTimePassed = _help_withdrawCheckTimePassedOrNot(
                current_stake.since,
                current_stake.timeStaked
            );
            require(
                responseTimePassed == true,
                "You have to wait for the time, which selected in stake"
            );
        }
        stakeholders[user_index].address_stakes[index].claimable = false;

        // uint256 timeDiffrence = block.timestamp - current_stake.since;
        // timeStaked ======= 12, 6, 3, 1, and 2 minute
        uint256 timeDiffrence;
        if (current_stake.timeStaked == 12) {
            timeDiffrence = 2629756 * 12;
        } else if (current_stake.timeStaked == 6) {
            timeDiffrence = 2629756 * 6;
        } else if (current_stake.timeStaked == 3) {
            timeDiffrence = 2629756 * 3;
        } else if (current_stake.timeStaked == 1) {
            timeDiffrence = 2629756 * 1;
        } else if (current_stake.timeStaked == 2) {
            timeDiffrence = 120;
        }

        uint256 unstakeAmount = current_stake.amount;

        uint256 incentiveAmount;
        uint256 countIntrest;

        uint32 LCTApyPercent12M = 30;
        uint32 LCTApyPercent06M = 20;
        uint32 LCTApyPercent03M = 15;
        // for 1 mounth formula is 12.5 but there is not . in solidity
        // second thing in finding intrust i write 4 weeks but there is 4.3 weeks in one month
        // if we see these two things then the formula is actually the same
        uint32 LCTApyPercent01M = 12;

        if (timeDiffrence >= 52 weeks) {
            countIntrest = (unstakeAmount / 100) * LCTApyPercent12M;
            incentiveAmount = countIntrest + unstakeAmount;
        } else if (timeDiffrence >= 26 weeks) {
            countIntrest = ((unstakeAmount / 100) * LCTApyPercent06M) / 2;
            incentiveAmount = countIntrest + unstakeAmount;
        } else if (timeDiffrence >= 13 weeks) {
            countIntrest = ((unstakeAmount / 100) * LCTApyPercent03M) / 4;
            incentiveAmount = countIntrest + unstakeAmount;
        } else if (timeDiffrence >= 4 weeks) {
            countIntrest = ((unstakeAmount / 100) * LCTApyPercent01M) / 12;
            incentiveAmount = countIntrest + unstakeAmount;
        } else if (timeDiffrence >= 2 minutes) {
            countIntrest = 1000000000000000000;
            incentiveAmount = countIntrest + unstakeAmount;
        } else {
            incentiveAmount = unstakeAmount;
        }
        require(
            token.transfer(msg.sender, incentiveAmount),
            "Transfer failed."
        );

        exchangeStakedTokens -= unstakeAmount;
        stakingBalance[msg.sender] -= current_stake.amount;

        emit StakeWithdraw(
            msg.sender,
            current_stake.amount,
            index,
            current_stake.since
        );
    }

    function handleInvestInvestor(uint _value, address _sender) internal {
        liqudityProviders[_sender].push(S_liquidity(_value, block.timestamp));
    }

    function get_Investor(
        address _sender
    ) public view returns (S_liquidity[] memory) {
        return liqudityProviders[_sender];
    }

    receive() external payable {
        handleInvestInvestor(msg.value, msg.sender);
    }

    fallback() external payable {
        handleInvestInvestor(msg.value, msg.sender);
    }
}