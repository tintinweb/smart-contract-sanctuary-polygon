// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

    interface LPPrice {
        function getCurrentPrice(address _lppairaddress) external view returns(uint256);
        function getLatestPrice(address _lppairaddress) external view returns(uint256);
        function updatePriceFromLP(address _lppairaddress) external returns(uint256);
        function getDecVal() external view returns(uint256);
    }

    /**
    * @title Pausable
    * @dev Base contract which allows children to implement an emergency stop mechanism.
    */
    contract Pausable is Ownable {
        event Pause();
        event Unpause();

        bool public paused = false;


        /**
        * @dev Modifier to make a function callable only when the contract is not paused.
        */
        modifier whenNotPaused() {
            require(!paused);
            _;
        }

        /**
        * @dev Modifier to make a function callable only when the contract is paused.
        */
        modifier whenPaused() {
            require(paused);
            _;
        }

        /**
        * @dev called by the owner to pause, triggers stopped state
        */
        function pause() onlyOwner whenNotPaused public {
            paused = true;
            emit Pause();
        }

        /**
        * @dev called by the owner to unpause, returns to normal state
        */
        function unpause() onlyOwner whenPaused public {
            paused = false;
            emit Unpause();
        }
    }

    contract BOMICO is Pausable{
        using SafeMath for uint;
        using SafeMath for uint8;
        using SafeERC20 for IERC20;

        // Structure Per ICO Round
        struct WhitelistRound {
            uint roundId;
            uint startTime;
            uint duration;
            uint amountRaised;
            uint tokenPrice;

            uint amountSold;
            uint amountClaimed;
            uint turnId;
            uint turnSold;

            // Vesting Frequency = 1 month
            uint init_unlock_amount;    // Ex: 0 Tokens
            uint vesting_amount;    // Ex: 500,000 Tokens (amountRaised - initial_unlock_amount) / vesting_months
            uint cliff_months;      // Ex: 3 months

            mapping(address => uint[]) lock_time;
            mapping(address => uint[]) lock_amount;
        }

        WhitelistRound[] public _whiteListRounds;
        uint public _curRound = 0;
        LPPrice public lpinfo;
        address public lpaddress; // Address of Matic & USD LP
        uint public softCap;
        uint public hardCap;

        IERC20 public bom;
        IERC20 public matic;
        IERC20 public busd;
        IERC20 public usdt;
        IERC20 public usdc;
        
        address public masterWallet;
        uint8 public _decimals = 10;
        uint public constant MAX_UINT = 2**256 - 1;

        // Amount of tokens bought by the investor
        mapping(address => uint) public balances;
        // Amount of tokens distributed to the investor
        mapping(address => uint) public claimed;

        /** New presale is scheduled */
        event newPresaleRound(uint roundId, uint startTime, uint duration, uint amountRaised, uint tokenPrice, uint init_unlock_amount, uint vesting_amount, uint cliff_months);

        /** Presale Round is updated */
        event updatedPresaleRound(uint roundId, uint startTime, uint duration, uint amountRaised, uint tokenPrice, uint init_unlock_amount, uint vesting_amount, uint cliff_months);


        /** Somebody loaded their investment money */
        event Invested(address investor, uint weiAmount, uint tokenAmount);
        /** We distributed tokens to an investor */
        event Distributed(address investor, uint count);
        event LockedAmount(uint roundId, address investor, uint amount, uint locktime);

        constructor(IERC20 _bom, IERC20 _matic, IERC20 _busd, IERC20 _usdt, IERC20 _usdc, address _masterWallet) {
            require(address(_bom) != address(0), "BOM address should not be zero address");
            require(address(_matic) != address(0), "Matic address should not be zero address");
            require(address(_busd) != address(0), "BUSD address should not be zero address");
            require(address(_usdt) != address(0), "USDT address should not be zero address");
            require(address(_usdc) != address(0), "USDC address should not be zero address");

            require(_masterWallet != address(0), "master wallet address should not be zero address");
            bom = _bom;
            matic = _matic;
            busd = _busd;
            usdt = _usdt;
            usdc = _usdc;
            masterWallet = _masterWallet;

            // softCap = getDecVal()/100;
            softCap = 0;
            hardCap = MAX_UINT;
        }
        // Add New ICO Round
        function addNewRound(uint _startTime, 
                            uint _duration, 
                            uint _amountRaised, 
                            uint _tokenPrice, 
                            uint _init_unlock_amount,
                            uint _vesting_amount, 
                            uint _cliff_months 
                            ) onlyOwner public {
            
            require(_duration > 0, "Duration should be greater than 0");
            require(_amountRaised > 0, "Amount raised should be greater than 0");
            require(_tokenPrice > 0, "Token price should be greater than 0");

            uint _roundId = _whiteListRounds.length;
            WhitelistRound storage _wlRound = _whiteListRounds.push();
            _wlRound.roundId = _roundId;
            _wlRound.startTime = _startTime;
            _wlRound.duration = _duration;
            _wlRound.amountRaised = _amountRaised;
            _wlRound.tokenPrice = _tokenPrice;
            _wlRound.init_unlock_amount = _init_unlock_amount;
            _wlRound.vesting_amount = _vesting_amount;
            require(_vesting_amount >= 10**4 * 10 ** 10, "Vesting amount should be greater than 10K Tokens");
            _wlRound.cliff_months = _cliff_months;

            emit newPresaleRound(_roundId, _startTime, _duration, _amountRaised, _tokenPrice, _init_unlock_amount, _vesting_amount, _cliff_months);
        }

        function lockAmount(address investor, uint amount, uint locktime) internal {
            WhitelistRound storage wlRound = _whiteListRounds[_curRound];
            wlRound.lock_time[investor].push(locktime);
            wlRound.lock_amount[investor].push(amount);
            emit LockedAmount(_curRound, investor, amount, locktime);
        }

        function min(uint a, uint b) public pure returns(uint) {
            if (a <= b) return a;
            return b;
        }

        function calcLockTime(address investor, uint amount) internal {
            WhitelistRound storage wlRound = _whiteListRounds[_curRound];
            require(wlRound.amountSold + amount <= wlRound.amountRaised, "Raised Amount Overflow");

            uint target_amount = wlRound.amountSold + amount;
            if (wlRound.turnId == 0) {
                uint sell = min(wlRound.init_unlock_amount - wlRound.turnSold, amount);
                wlRound.amountSold += sell;
                wlRound.turnSold += sell;
                lockAmount(investor, sell, wlRound.startTime);
                if(wlRound.turnSold == wlRound.init_unlock_amount) {
                    wlRound.turnId = 1;
                    wlRound.turnSold = 0;
                }
            }
            while(wlRound.amountSold < target_amount) {
                uint sell = min(wlRound.vesting_amount - wlRound.turnSold, target_amount - wlRound.amountSold);
                wlRound.amountSold += sell;
                wlRound.turnSold += sell;
                lockAmount(investor, sell, wlRound.startTime + (wlRound.cliff_months + wlRound.turnId) * 30 days);
                if(wlRound.turnSold == wlRound.vesting_amount) {
                    wlRound.turnId += 1;
                    wlRound.turnSold = 0;
                }
            }
        }

        function convert_matic_invest_amount() public payable whenNotPaused returns(uint amount) {
            WhitelistRound storage wlRound = _whiteListRounds[_curRound];
            require(block.timestamp >= wlRound.startTime, "Presale is not yet started");
            require(block.timestamp <= wlRound.startTime + wlRound.duration, "Presale is already ended");
            // divide matic.decimals
            amount = msg.value.mul(lpinfo.updatePriceFromLP(lpaddress));
            return amount;
        }

        // amount decimals = 10 ** 10
        function invest(uint amount, uint8 id) public payable whenNotPaused returns(uint bomTokenAmount) {
            WhitelistRound storage wlRound = _whiteListRounds[_curRound];
            require(block.timestamp >= wlRound.startTime, "Presale is not yet started");
            require(block.timestamp <= wlRound.startTime + wlRound.duration, "Presale is already ended");
            // divide matic.decimals
            if(id==0) amount = msg.value.mul(lpinfo.updatePriceFromLP(lpaddress)).mul(getDecVal()).div(lpinfo.getDecVal()).div(10 ** matic.decimals()) ;

            require(amount >= softCap, "Amount should be greater than soft cap");
            require(amount <= hardCap, "Amount should be less than hard cap");

            require(id < 4, "Not Supported Token");

            uint bomtokenamount;

            bomtokenamount = amount.mul(10 ** bom.decimals()).div(wlRound.tokenPrice);
            require(bomtokenamount <= wlRound.amountRaised - wlRound.amountSold, "BOM Token Amount should be less than or equal to amountLeft");

            if (id == 0) {
                payable(address(masterWallet)).transfer(address(this).balance);
            }
            else if (id == 1) busd.safeTransferFrom(msg.sender, masterWallet, amount * 10 ** busd.decimals() / 10 ** _decimals);
            else if (id == 2) usdt.safeTransferFrom(msg.sender, masterWallet, amount * 10 ** usdt.decimals() / 10 ** _decimals);
            else if (id == 3) usdc.safeTransferFrom(msg.sender, masterWallet, amount * 10 ** usdc.decimals() / 10 ** _decimals);

            calcLockTime(msg.sender, bomtokenamount);
            balances[msg.sender] += bomtokenamount;
            emit Invested(msg.sender, amount, bomtokenamount);
            return bomtokenamount;
        }

        function getDecVal() internal view returns (uint256) {
            return 10 ** _decimals;
        }

        function getUnlockedAmount(address investor) whenNotPaused public view returns(uint) {
            uint _unlockedAmount = 0;
            for(uint i = 0; i < _whiteListRounds.length; i++) {
                WhitelistRound storage wlRound = _whiteListRounds[i];
                uint[] storage arr_lock_time = wlRound.lock_time[investor];
                uint[] storage arr_lock_amount = wlRound.lock_amount[investor];
                uint cnt = wlRound.lock_time[investor].length;
                for(uint j = 0; j<cnt; j++) {
                    if(block.timestamp >= arr_lock_time[j]) {
                        _unlockedAmount += arr_lock_amount[j];
                    }
                }
            }
            return _unlockedAmount;
        }

        function claim(uint amount) whenNotPaused public {
            require(getUnlockedAmount(_msgSender()) >= claimed[_msgSender()] + amount, "Not enough tokens to claim");
            claimed[_msgSender()] += amount;
            balances[_msgSender()] -= amount;
            // Transfer from masterWallet to investor
            bom.safeTransferFrom(masterWallet, msg.sender, amount);
            emit Distributed(_msgSender(), amount);
        }
        function claimAll() whenNotPaused public{
            uint _unlockedAmount = getUnlockedAmount(_msgSender());
            require(_unlockedAmount > claimed[_msgSender()], "Not enough tokens to claim");
            uint _claimAmount = _unlockedAmount - claimed[_msgSender()];
            claimed[_msgSender()] = _unlockedAmount;
            balances[_msgSender()] -= _claimAmount;
            // Transfer from masterWallet to investor
            bom.safeTransferFrom(masterWallet, msg.sender, _claimAmount);
            emit Distributed(_msgSender(), _claimAmount);
        }

        function updateMasterWallet(address _newAddress) external onlyOwner {
            require(_newAddress != address(0), "Cannot be zero address");
            masterWallet = _newAddress;
        }

        function setExchangePrice(uint newRate, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.tokenPrice = newRate;
        }

        function setStartTime(uint startTime, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.startTime = startTime;
        }

        function setRoundDuration(uint _duration, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.duration = _duration;
        }

        function setVestingAmount(uint amount, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.vesting_amount = amount;
        }

        function setCliffMonths(uint _cliff_months, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.cliff_months = _cliff_months;
        }

        function setInitUnlockAmount(uint _init_unlock_amount, uint roundid) external onlyOwner {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            wlRound.init_unlock_amount = _init_unlock_amount;
        }

        function getMaticPrice() external view returns(uint) {
            uint curPrice = lpinfo.getLatestPrice(lpaddress);
            return curPrice.mul(getDecVal()).div(lpinfo.getDecVal());
        }

        function getTokenPrice(uint roundid) public view returns(uint) {
            require(roundid < _whiteListRounds.length);
            WhitelistRound storage wlRound = _whiteListRounds[roundid];
            return wlRound.tokenPrice;
        }

        function setCurrentRound(uint roundid) public onlyOwner {
            require(roundid < _whiteListRounds.length);
            _curRound = roundid;
        }

        function withdraw() external payable onlyOwner {
            require(masterWallet != address(0), "Cannot be zero address");
            payable(masterWallet).transfer(address(this).balance);
        }

        function setLPAddress(address _address) external onlyOwner {
            require(_address != address(0), "Cannot be zero address");
            lpaddress = _address;
        }

        function setLPPriceInfo(address _address) external onlyOwner {
            require(_address != address(0), "Cannot be zero address");
            lpinfo = LPPrice(_address);
        }

        function setSoftCap(uint _softCap) external onlyOwner {
            require(hardCap > softCap, "Softcap should be less than hardcap");
            require(_softCap > 0, "Soft Cap should be greater than 0");
            softCap = _softCap;
        }
        function setHardCap(uint _hardCap) external onlyOwner {
            require(_hardCap > 0, "Hard Cap should be greater than 0");
            require(_hardCap > softCap, "Hardcap should be greater than softcap");
            hardCap = _hardCap;
        }
    }

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.7;
    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {

        function decimals() external view returns (uint8);
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
        function transfer(address recipient, uint256 amount) external returns (bool);

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
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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