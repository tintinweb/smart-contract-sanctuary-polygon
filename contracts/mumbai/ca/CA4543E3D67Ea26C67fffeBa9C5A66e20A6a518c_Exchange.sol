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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Exchange {
    using Counters for Counters.Counter;
    Counters.Counter private _IdCounter; // for count id of request

    struct Withdrawals {
        mapping(address => uint) tokensToWithdraw;
        uint creationTime;
        address userAddress;
    }

    mapping(uint => Withdrawals) private withdrawId;

    mapping(address => mapping(address => uint)) private balances;

    IERC20 USDT;
    IERC20 MATIC;
    address public MATICAddress;
    address public USDTAddress;

    event MATICLoaded(address indexed from, uint MATICAmount); // emits when MATIC successfully loaded
    event USDTLoaded(address indexed from, uint USDTAmount); // emits when USDT successfully loaded
    event WithdrawRequest(
        uint indexed id,
        uint MATICToWithdraw,
        uint USDTToWithdraw,
        uint creationTime,
        address indexed from
    ); // emits when withdraw request created

    constructor(address _MATICAddress, address _USDTAddress) {
        MATICAddress = _MATICAddress; // set address for MATIC token
        USDTAddress = _USDTAddress; // set address for USDT token
        MATIC = IERC20(MATICAddress); // set interface for MATIC token
        USDT = IERC20(USDTAddress); // set interface for USDT token
    }

    /// @dev this functions takes amout for MATIC and USDT from user how many it want to load
    /// @dev user must load at least one asset
    /// @dev user must have enough to load on his balance
    /// @dev if this conditions are true this function transfer token from his balance to contract balance
    /// @dev if tokens successfully transfered to contract balance it store this data and emits event with this data

    function loadFunds(uint MATICToReceive, uint USDTToReceive) public {
        require(
            MATICToReceive > 0 || USDTToReceive > 0,
            "AT LEAST ONE OF ASSETS MUST BE GREATER THEN ZERO"
        ); // check that user want load at least one token
        require(MATIC.balanceOf(msg.sender) >= MATICToReceive, "NOT ENOUGH MATIC"); // check that user have enough MATIC to transfer or pass if user won't load MATIC
        require(USDT.balanceOf(msg.sender) >= USDTToReceive, "NOT ENOUGH USDT"); // check that user have enough USDT to transfer or pass if user won't load USDT
        require(
            MATIC.allowance(msg.sender, address(this)) >= MATICToReceive,
            "NOT ENOUGH MATIC ALLOWANCE"
        ); // because when user call "transfer()" of ERC20 token it doesn't change allowance and allowance can be more then user balance
        // (!) user can set allowance greater then current balance (!)
        require(
            USDT.allowance(msg.sender, address(this)) >= USDTToReceive,
            "NOT ENOUGH USDT ALLOWANCE"
        ); // because when user call "transfer()" of ERC20 token it doesn't change allowance and allowance can be more then user balance
        // (!) user can set allowance greater then current balance (!)

        // if user want load MATIC
        if (MATICToReceive > 0) {
            bool MATICTransferred = MATIC.transferFrom(msg.sender, address(this), MATICToReceive); // it makes transfer tokens from user's balance to contract balance and return bool of result
            if (MATICTransferred) {
                // if transfer return true (it success) contract add it to user balance
                balances[msg.sender][MATICAddress] += MATICToReceive;
                emit MATICLoaded(msg.sender, MATICToReceive); // emits event with user address and amount MATIC if transfer success
            }
        }
        // if user want load USDT
        // require contract to be approved by user to spend USDTToReceive
        if (USDTToReceive > 0) {
            bool USDTTransferred = USDT.transferFrom(msg.sender, address(this), USDTToReceive); // it makes transfer tokens from user's balance to contract balance and return bool of result
            if (USDTTransferred) {
                // if transfer return true (it success) contract add it to user balance
                balances[msg.sender][USDTAddress] += USDTToReceive;
                emit USDTLoaded(msg.sender, USDTToReceive); // emits event with user address and amount USDT if transfer success
            }
        }
    }

    /// @dev this function just store data with user's request to withdraw funds

    function withdrawFunds(uint MATICToWithdraw, uint USDTToWithdraw) public {
        uint id = _IdCounter.current(); // will use current id
        _IdCounter.increment(); // then increment id counter
        withdrawId[id].tokensToWithdraw[MATICAddress] = MATICToWithdraw; // store how many MATIC user want withdraw
        withdrawId[id].tokensToWithdraw[USDTAddress] = USDTToWithdraw; // store how many USDT user want withdraw
        withdrawId[id].creationTime = block.timestamp; // store time when user create withdraw request
        withdrawId[id].userAddress = msg.sender; // store user address that want withdraw
        emit WithdrawRequest(id, MATICToWithdraw, USDTToWithdraw, block.timestamp, msg.sender); // emits event with withdraw request data
    }

    // function confirmWithdraw(uint _withdrawId) public {
    //     require(block.timestamp > (withdrawId[_withdrawId].creationTime + 1 weeks));
    // }

    // function catchCheater()public{}
}