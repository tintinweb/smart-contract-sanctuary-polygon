/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/FirstAuction/iNRT.sol



pragma solidity ^0.8.0;



interface iNRT {

    event Issued(address account, uint256 amount);

    event Redeemed(address account, uint256 amount);



    function issue(address account, uint256 amount) external;



    function redeem(address account, uint256 amount) external;



    function balanceOf(address account) external view returns (uint256);



    function symbol() external view returns (string memory);



    function decimals() external view returns (uint256);



    function issuedSupply() external view returns (uint256);



    function outstandingSupply() external view returns (uint256);

}
// File: contracts/FirstAuction/FirstAuction.sol



pragma solidity ^0.8.0;





// *********************************

// Fair Launch pool

// *********************************



contract FirstAuction is Ownable {

    using SafeMath for uint256;



    // the token address the cash is raised in

    // assume decimals is 18

    address public investToken;

    // the token to be launched

    address public launchToken;

    // proceeds go to fundsRedeemer

    address public fundsRedeemer;

    // the certificate (token to be adquired)

    address public nrt;





    // fixed single price

    uint256 public price;

    // minimum amount

    uint256 public minInvest;

    // maximum cap

    uint256 public maxInvest;







    // the total amount in stables to be raised

    uint256 public totalRaiseCap;

    // how much was raised

    uint256 public totalRaised;

    // how much was issued

    uint256 public totalIssued;

    // how much was redeemed

    uint256 public totalRedeem;





    // start of the sale

    uint256 public startTime;

    // total duration

    uint256 public duration;

    // end of the sale    

    uint256 public endTime;





    // sale has started

    bool public saleEnabled;

    // redeem is possible

    bool public redeemEnabled;

    

    //uint256 public investDecimals;

    //uint256 public launchDecimals; 

    

    

    uint256 public numInvested;

    

    event SaleEnabled(bool enabled, uint256 time);

    event RedeemEnabled(bool enabled, uint256 time);

    event Invest(address investor, uint256 amount);

    event Redeem(address investor, uint256 amount);



    struct InvestorInfo {

        uint256 amountInvested; // Amount deposited by user

        bool claimed; // has claimed GNX

    }



    mapping(address => InvestorInfo) public investorInfoMap;

    

    constructor(

        address _investToken,

        uint256 _startTime,  

        uint256 _duration,  

        uint256 _price,

        uint256 _minInvest,

        uint256 _maxInvest,    

        uint256 _totalRaiseCap,

        address _fundsRedeemer,

        address _nrt        

    ) {

        investToken = _investToken;

        startTime = _startTime;

        duration = _duration;

        price = _price;

        minInvest = _minInvest;  

        maxInvest = _maxInvest; 

        totalRaiseCap = _totalRaiseCap;

        fundsRedeemer = _fundsRedeemer;

        nrt = _nrt;   





        endTime = startTime.add(duration);

    }



    function hasSaleEnded() public view returns (bool) {

        return block.timestamp > endTime;

    }



    

    // invest 

    function invest(uint256 investAmount) public {

        require(saleEnabled, "not enabled yet");

        require(block.timestamp >= startTime, "Sale not started yet");

        require(!hasSaleEnded(), "Sale finished");

        require(totalRaised.add(investAmount) <= totalRaiseCap, "over total raise");

        require(investAmount >= minInvest, "below minimum invest");



        InvestorInfo storage investor = investorInfoMap[msg.sender];



        require(investor.amountInvested.add(investAmount) <= maxInvest, "above maximum invest");      

        



        require(

            IERC20(investToken).transferFrom(

                msg.sender,

                address(this),

                investAmount

            ),

            "transfer failed"

        );

        

        

        uint256 issueAmount = investAmount.div(price);

        issueAmount = issueAmount.mul(1000000000000000000);



        iNRT(nrt).issue(msg.sender, issueAmount);



        

        totalRaised = totalRaised.add(investAmount);

        totalIssued = totalIssued.add(issueAmount);

        if (investor.amountInvested == 0){

            numInvested = numInvested.add(1);

        }

        investor.amountInvested = investor.amountInvested.add(investAmount);

        

        emit Invest(msg.sender, investAmount);

    }



    // redeem all tokens

    function redeem() public {        

        require(redeemEnabled, "redeem not enabled");

        uint256 redeemAmount = iNRT(nrt).balanceOf(msg.sender);

        require(redeemAmount > 0, "no amount issued");

        uint256 totalSupplyLaunchToken = IERC20(launchToken).balanceOf(address(this));

        require(totalSupplyLaunchToken >= redeemAmount, "Not enough balance for redeem");

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        require(!investor.claimed, "already claimed");

        require(

            IERC20(launchToken).transfer(

                msg.sender,

                redeemAmount

            ),

            "transfer failed"

        );



        iNRT(nrt).redeem(msg.sender, redeemAmount);



        totalRedeem = totalRedeem.add(redeemAmount);        

        emit Redeem(msg.sender, redeemAmount);

        investor.claimed = true;

    }



    // -- Admin functions --



    // define the launch token to be redeemed

    function setLaunchToken(address _launchToken) public onlyOwner {

        launchToken = _launchToken;

    }



    function depositLaunchtoken(uint256 amount) public onlyOwner {

        require(

            IERC20(launchToken).transferFrom(msg.sender, address(this), amount),

            "transfer failed"

        );

    }



    // withdraw in case some tokens were not redeemed

    function withdrawLaunchtoken(uint256 amount) public onlyOwner {

        require(

            IERC20(launchToken).transfer(msg.sender, amount),

            "transfer failed"

        );

    }



    // withdraw funds to fundsRedeemer

    function withdrawFundsRedeemer(uint256 amount) public onlyOwner {

        //uint256 b = ERC20(investToken).balanceOf(address(this));

        require(

            IERC20(investToken).transfer(fundsRedeemer, amount),

            "transfer failed"

        );

    }



    function enableSale() public onlyOwner {

        saleEnabled = true;

        emit SaleEnabled(true, block.timestamp);

    }



    function enableRedeem() public onlyOwner { 

        require(launchToken != address(0), "launch token not set");

        redeemEnabled = true;

        emit RedeemEnabled(true, block.timestamp);

    }



    function setNewFundsRedeemer(address _newfundsRedeemer) public onlyOwner {

        fundsRedeemer = _newfundsRedeemer;

    }

}