/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// SPDX-License-Identifier: MIT

/* 
 * Website           : https://jabal.io/  
 * Name              : JABAL
 * Symbol            : JBL
 * Smart Chain       : Fantom Chain (FTM20)
*/

pragma solidity 0.8.17;

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

/**
 * @dev Interface of the FTM20 standard as defined in the EIP.
 */
interface IFTM20 {
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

}



/**
 * @dev Interface for the optional metadata functions from the FTM20 standard.
 *
 * _Available since v4.1._
 */
interface IFTM20Metadata is IFTM20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
 * @dev Implementation of the {IFTM20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {FTM20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-FTM20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of FTM20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IFTM20-approve}.
 */
contract FTM20 is Context, IFTM20, IFTM20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {FTM20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IFTM20-balanceOf} and {IFTM20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev See {IFTM20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IFTM20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "FTM20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "FTM20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "FTM20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "FTM20: approve from the zero address");
        require(spender != address(0), "FTM20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
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


contract TestJab is FTM20, Ownable {
    using SafeMath for uint256;

    struct User {
        uint256 checkpoint;
        uint256 passiveWithdrawTime;
        uint256 totalInvested;
        uint256 totalTokenPurchase;
        address referrer;
        uint256[11] levels;
        uint256 withdrawn;
        uint256 bonus;
        uint256 totalBonus;
        uint256 payoutTo;
    }

    mapping(address => User) public users;

    address payable public creatorWallet;
    address payable public marketingWallet;
    uint256 public creatorFee = 20; // 2%
    uint256 public marketingFee = 50; // 5%
    uint256 public passiveIncome = 100; // 10%
    uint256 public levelFee = 230; // 23%
    uint256 public tokensToGet = 600; // 60%
    uint256 public creatorFeeCollected;
    uint256 public marketingFeeCollected;
    uint256 public tokenPriceIncremental_ = 0.00000001 ether;
    uint256 public tokenPriceInitial_ = 0.00000001 ether;
    uint256 public passiveIncomePoolTotalFTM;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 30 minutes;
    uint256 public INVEST_MIN_AMOUNT = 0.001 ether; // 1 FTM
    uint256 public totalInvested;
    uint256 public totalUsers;
    uint256 public totalBuyCount;
    uint256 public totalSellCount;
    uint256 private FTMDECIMAL = 18;
    uint256 constant internal magnitude = 2**64;
    uint256 public profitPerShare_;

    uint256[] public REFERRAL_PERCENTS = [90, 30, 20, 10, 10, 10, 10, 10, 10, 10, 20]; // 100 = 10%, 90 = 9%
    uint256[] public LEVEL_MINIMUM = [0, 0.25 ether, 0.4 ether, 0.6 ether, 0.8 ether, 1.0 ether, 1.2 ether, 1.4 ether, 1.6 ether, 1.8 ether, 2.1 ether]; // 100 = 10%, 90 = 9%


    event FeePayedIn(address indexed user, uint256 totalAmount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);

    constructor(address payable _creatorWallet, address payable _marketingWallet) FTM20("JABAL", "JBL") {
        creatorWallet = _creatorWallet;
        marketingWallet = _marketingWallet;
    }

    function buy(address referrer) external payable {
        
        require(msg.value >= INVEST_MIN_AMOUNT, "JABAL: Deposit value is too small");
        
        uint256 ftmAfterTax = msg.value.mul(tokensToGet).div(PERCENTS_DIVIDER);
        // 60% FTM Used to Buy Token
        uint256 tokenBrought = ethereumToTokens_(ftmAfterTax);
        
        // 40% FTM Used for Further Distribution 
        uint256 feeCreator = msg.value.mul(creatorFee).div(PERCENTS_DIVIDER);
        creatorWallet.transfer(feeCreator);
        emit FeePayedIn(msg.sender, feeCreator);

        uint256 feeMarketing = msg.value.mul(marketingFee).div(PERCENTS_DIVIDER);
        marketingWallet.transfer(feeMarketing);
        emit FeePayedIn(msg.sender, feeMarketing);

        
        User storage user = users[msg.sender];
        if (user.referrer == address(0)) {
            if (users[referrer].totalTokenPurchase > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
            address upline = user.referrer;
            for (uint256 i = 0; i < 11; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            uint256 totalInvest = user.totalInvested;

            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0) && totalInvest > LEVEL_MINIMUM[i]) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                    totalInvest = users[upline].totalInvested;
                } else break;
            }
        }

        if (user.totalInvested == 0) {
            totalUsers = totalUsers.add(1);
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }
        
        uint256 passiveAmount = msg.value.mul(passiveIncome).div(PERCENTS_DIVIDER);
        uint256 _fee = passiveAmount * magnitude;
        
        if(totalSupply() > 0){

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (passiveAmount * magnitude / (totalSupply()));

            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(tokenBrought * (passiveAmount * magnitude / (totalSupply()))));
        }else{
            _fee = 0;
        }

        uint256 _updatedPayouts = (uint256) ((profitPerShare_ * tokenBrought) - _fee);
        user.payoutTo += _updatedPayouts;

        user.totalInvested = user.totalInvested.add(msg.value);
        // ftmSupply = ftmSupply.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
        passiveIncomePoolTotalFTM = passiveIncomePoolTotalFTM.add(passiveAmount);
        totalBuyCount = totalBuyCount.add(1);

        user.totalTokenPurchase = user.totalTokenPurchase.add(tokenBrought);
        _mint(msg.sender, tokenBrought);

        emit NewDeposit(msg.sender, msg.value);
    }

    function sell(uint256 _amount) external {
        require(balanceOf(msg.sender)>0,"JABAL: You Dont have any Token to Sell");
        require(_amount<= balanceOf(msg.sender), "JABAL: Sell Amount Exceed Balance");
        uint256 totalToken = balanceOf(msg.sender);
        uint256 ftmAmount = tokensToEthereum_(_amount);
        uint256 deductionAmount;
        if(_amount < totalToken.mul(25).div(100)){
            deductionAmount = ftmAmount.mul(10).div(100);
        }else if(_amount >= totalToken.mul(25).div(100) && _amount < totalToken.mul(50).div(100)){
            deductionAmount = ftmAmount.mul(25).div(100);
        }else if(_amount >= totalToken.mul(50).div(100) && _amount <= totalToken.mul(100).div(100)){
            deductionAmount = ftmAmount.mul(50).div(100);
        }
        _burn(msg.sender, _amount);
        uint256 ftmRemaining = ftmAmount.sub(deductionAmount);
        uint256 ftmToRecieve = (ftmRemaining);

        User storage user = users[msg.sender];

        uint256 _updatedPayouts = (uint256) (profitPerShare_ * _amount + (deductionAmount * magnitude));
        if(_updatedPayouts > user.payoutTo){
            user.payoutTo -= _updatedPayouts;
        }else{
            user.payoutTo = 0;
        }

        // dividing by zero is a bad idea
        if (totalSupply() > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, ((deductionAmount/2) * magnitude) / totalSupply());
        }

        payable(creatorWallet).transfer(deductionAmount/2);
        payable(msg.sender).transfer(ftmToRecieve);
    }


    function withdraw()
        onlyhodler()
        public
    {
        User storage user = users[msg.sender];

        require(block.timestamp > user.passiveWithdrawTime.add(TIME_STEP));
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); 
        
        // update dividend tracker
        user.payoutTo +=  (uint256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += user.bonus;
        user.bonus = 0;
        user.passiveWithdrawTime = block.timestamp;
        
        payable(_customerAddress).transfer(_dividends);
        
    }

    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        
        if(totalSupply() == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            return _ethereum;
        }
    }

    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
       
        if(totalSupply() == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            return _ethereum;
        }
    }

    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        User storage user = users[msg.sender];
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + user.bonus : dividendsOf(_customerAddress) ;
    }
 
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    // only people with tokens
    modifier onlybelievers () {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyhodler() {
        require(myDividends(true) > 0);
        _;
    }

    function ethereumToTokens_(uint256 _ethereum)
        public
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(totalSupply()**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*totalSupply())
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(totalSupply())
        ;
  
        return _tokensReceived;
    }

     function tokensToEthereum_(uint256 _tokens)
        public
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (totalSupply() + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }
    
    function removeTestCoins() external onlyOwner {
        payable(creatorWallet).transfer(address(this).balance);
    }

    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        User storage user = users[_customerAddress];
        return (uint256) ((uint256)(profitPerShare_ * balanceOf(_customerAddress)) - user.payoutTo) / magnitude;
    }

}