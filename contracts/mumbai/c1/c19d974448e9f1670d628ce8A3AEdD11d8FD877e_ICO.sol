// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    function burn(uint256 amount) external;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
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

contract ICO is Ownable {
    using SafeMath for uint256;

    IERC20 LRN_token;
    IERC20 LRNT_token;
    IERC20 WIS_token;
    uint256 public totalHardCap;
    address[] public allBuyerAddress;

    struct RoundTimeInfo {
        uint256 r1StartTime;
        uint256 r1EndTime;
        uint256 r2StartTime;
        uint256 r2EndTime;
        uint256 r3StartTime;
        uint256 r3EndTime;
    }
    RoundTimeInfo public roundTimeInfo;

    struct RoundHardCapInfo {
        uint256 r1HardCap;
        uint256 r2HardCap;
        uint256 r3HardCap;
    }
    RoundHardCapInfo public roundHardCapInfo;

    struct RoundTokenSaleInfo {
        uint256 r1SoldToken;
        uint256 r1TokenForSale;
        uint256 r2SoldToken;
        uint256 r2TokenForSale;
        uint256 r3SoldToken;
        uint256 r3TokenForSale;
    }
    RoundTokenSaleInfo public roundTokenSaleInfo;

    struct UserInfo {
        uint256 LRNTToken;
        uint256 bonusWISToken;
        uint256 claimedLRNToken;
        uint256 unclaimedLRNToken;
        uint256 lastClaimedAt;
        uint256 investBNBToken;
    }
    mapping(address => UserInfo) public userInfo;

    struct ICOInfo {
        uint256 raisedTotalBNBToken;
        uint256 soldLRNToken;
    }
    ICOInfo public iCOInfo;

    struct PreSale {
        uint256 presale1;
        uint256 presale2;
        uint256 presale3;
    }
    PreSale public preSale;

    struct StackInfo {
        uint256 stackedAt;
        uint256 unstackedAt;
        uint256 stackWISAmount;
        uint256 stackLRNAmount;
        uint256 rewardWISAmount;
        uint256 totalWISAmount;
        Stack stack;
        Month month;
    }
    mapping(address => StackInfo) public stackInfo;

    enum Airdrop {
        LRNT,
        LRN,
        WIS
    }

    enum Stack {
        WIS,
        WISLRN,
        LRN
    }

    enum Month {
        Six,
        Twelve
    }

    constructor(
        address _LRN_token,
        address _LRNT_token,
        address _WIS_token,
        uint256 _startingTime
    ) {
        require(
            _startingTime >= block.timestamp,
            "ICO start time should be equal or greater than current time"
        );

        LRN_token = IERC20(_LRN_token);
        LRNT_token = IERC20(_LRNT_token);
        WIS_token = IERC20(_WIS_token);

        totalHardCap = 2600000000 * 10 ** LRNT_token.decimals();

        roundTimeInfo.r1StartTime = _startingTime;
        roundTimeInfo.r1EndTime = roundTimeInfo.r1StartTime + (2 * 2629743) - 1;
        roundTimeInfo.r2StartTime = roundTimeInfo.r1EndTime + 1;
        roundTimeInfo.r2EndTime = roundTimeInfo.r2StartTime + (2 * 2629743) - 1;
        roundTimeInfo.r3StartTime = roundTimeInfo.r2EndTime + 1;
        roundTimeInfo.r3EndTime = roundTimeInfo.r3StartTime + (2 * 2629743) - 1;

        roundHardCapInfo.r1HardCap = 400000000 * 10 ** LRNT_token.decimals();
        roundHardCapInfo.r2HardCap = 800000000 * 10 ** LRNT_token.decimals();
        roundHardCapInfo.r3HardCap = 1400000000 * 10 ** LRNT_token.decimals();

        roundTokenSaleInfo.r1TokenForSale = roundHardCapInfo.r1HardCap;
        roundTokenSaleInfo.r2TokenForSale = roundHardCapInfo.r2HardCap;
        roundTokenSaleInfo.r3TokenForSale = roundHardCapInfo.r3HardCap;
    }

    //-------------------------------------Functions only Owner can call------------------------------------------------------

    //-------------------------------------Functions to update round sale timing----------------------------------------------

    //Function to update round 1 timing
    function updateRound1Time(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner returns (bool) {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        require(
            block.timestamp < roundTimeInfo.r1StartTime,
            "You can not change the time after round starts"
        );

        roundTimeInfo.r1StartTime = _startTime;
        roundTimeInfo.r1EndTime = _endTime;
        roundTimeInfo.r2StartTime = roundTimeInfo.r1EndTime + 1;
        roundTimeInfo.r2EndTime = roundTimeInfo.r2StartTime + (2 * 2629743);
        roundTimeInfo.r3StartTime = roundTimeInfo.r2EndTime + 1;
        roundTimeInfo.r3EndTime = roundTimeInfo.r3StartTime + (2 * 2629743);

        return true;
    }

    //Function to update round 2 timing
    function updateRound2Time(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner returns (bool) {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        require(
            block.timestamp < roundTimeInfo.r2StartTime,
            "You can not change the time after round starts"
        );

        roundTimeInfo.r1EndTime = block.timestamp;
        roundTimeInfo.r2StartTime = _startTime;
        roundTimeInfo.r2EndTime = _endTime;
        roundTimeInfo.r3StartTime = roundTimeInfo.r2EndTime + 1;
        roundTimeInfo.r3EndTime = roundTimeInfo.r3StartTime + (2 * 2629743);

        return true;
    }

    //Function to update round 3 timing
    function updateRound3Time(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner returns (bool) {
        require(
            _startTime < _endTime,
            "End Time should be greater than start time"
        );
        require(
            _endTime > block.timestamp,
            "End Time should be greater than Current Time"
        );

        require(
            block.timestamp < roundTimeInfo.r3StartTime,
            "You can not change the time after round starts"
        );

        roundTimeInfo.r2EndTime = block.timestamp;
        roundTimeInfo.r3StartTime = _startTime;
        roundTimeInfo.r3EndTime = _endTime;

        return true;
    }

    //----------------------------------------------------------------------------

    //function to update pre sale rate
    function presaleRate(uint256 _presaleRate) public onlyOwner returns (bool) {
        require(preSale.presale1 == 0, "Already set presale");
        uint256 presale1 = _presaleRate + (_presaleRate * 20) / 100;
        uint256 presale2 = presale1 + (presale1 * 20) / 100;
        uint256 presale3 = presale2 + (presale2 * 20) / 100;

        preSale = PreSale(presale1, presale2, presale3);
        return true;
    }

    //----------------------------------------------------------------------------

    function retrieveStuckedERC20Token(
        address _tokenAddr,
        uint256 _amount,
        address _toWallet
    ) public onlyOwner returns (bool) {
        IERC20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }

    function airDrop(
        Airdrop airdrop,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        if (airdrop == Airdrop.LRNT) {
            LRNT_token.transfer(_to, _amount);
        } else if (airdrop == Airdrop.LRN) {
            LRN_token.transfer(_to, _amount);
        } else if (airdrop == Airdrop.WIS) {
            WIS_token.transfer(_to, _amount);
        } else {
            require(false, "Please select correct option");
        }
    }

    //----------------------------------End of the functions only Owner can call-------------------------

    //---------------------------------------------------------------------------------------------------

    function round()
        public
        view
        returns (
            string memory _round,
            uint256 endTime,
            uint256 _hardcap,
            uint256 _soldToken,
            uint _presale
        )
    {
        uint currentTime = block.timestamp;
        if (
            currentTime >= roundTimeInfo.r1StartTime &&
            currentTime <= roundTimeInfo.r1EndTime
        ) {
            string memory Round = "Private A";
            return (
                Round,
                roundTimeInfo.r1EndTime,
                roundHardCapInfo.r1HardCap,
                roundTokenSaleInfo.r1SoldToken,
                preSale.presale1
            );
        } else if (
            currentTime >= roundTimeInfo.r2StartTime &&
            currentTime <= roundTimeInfo.r2EndTime
        ) {
            string memory Round = "Private B";
            return (
                Round,
                roundTimeInfo.r2EndTime,
                roundHardCapInfo.r2HardCap,
                roundTokenSaleInfo.r2SoldToken,
                preSale.presale2
            );
        } else if (
            currentTime >= roundTimeInfo.r3StartTime &&
            currentTime <= roundTimeInfo.r3EndTime
        ) {
            string memory Round = "Pre-Sale";
            return (
                Round,
                roundTimeInfo.r3EndTime,
                roundHardCapInfo.r3HardCap,
                roundTokenSaleInfo.r3SoldToken,
                preSale.presale3
            );
        } else {
            require(false, "Please check ICO time");
        }
    }

    function isICOOverRound1() public view returns (bool) {
        if (
            block.timestamp > roundTimeInfo.r1EndTime ||
            roundTokenSaleInfo.r1TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isICOOverRound2() public view returns (bool) {
        if (
            block.timestamp > roundTimeInfo.r2EndTime ||
            roundTokenSaleInfo.r2TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isICOOverRound3() public view returns (bool) {
        if (
            block.timestamp > roundTimeInfo.r3EndTime ||
            roundTokenSaleInfo.r3TokenForSale == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    //---------------------------------------------------------------------------------------------------

    function buy(uint256 _BNB) public payable returns (bool) {
        require(preSale.presale1 != 0, "There is no presale rate set");
        uint256 currentTime = block.timestamp;
        address currentInvestor = msg.sender;
        uint256 lrntToken;

        if (
            currentTime >= roundTimeInfo.r1StartTime &&
            currentTime <= roundTimeInfo.r1EndTime
        ) {
            lrntToken = ((_BNB) * 10000) / preSale.presale1;
            require(
                roundTokenSaleInfo.r1TokenForSale >= lrntToken,
                "Not enough token for sale in Private A round"
            );
            roundTokenSaleInfo.r1TokenForSale -= lrntToken;
            roundTokenSaleInfo.r1SoldToken += lrntToken;
        } else if (
            currentTime >= roundTimeInfo.r2StartTime &&
            currentTime <= roundTimeInfo.r2EndTime
        ) {
            lrntToken = ((_BNB) * 10000) / preSale.presale2;
            require(
                roundTokenSaleInfo.r2TokenForSale >= lrntToken,
                "Not enough token for sale in Private B round"
            );
            roundTokenSaleInfo.r2TokenForSale -= lrntToken;
            roundTokenSaleInfo.r2SoldToken += lrntToken;
        } else if (
            currentTime >= roundTimeInfo.r1StartTime &&
            currentTime <= roundTimeInfo.r1EndTime
        ) {
            lrntToken = ((_BNB) * 10000) / preSale.presale3;
            require(
                roundTokenSaleInfo.r3TokenForSale >= lrntToken,
                "Not enough token for sale in Pre-Sale round"
            );
            roundTokenSaleInfo.r3TokenForSale -= lrntToken;
            roundTokenSaleInfo.r3SoldToken += lrntToken;
        } else {
            require(false, "Please check ICO Time");
        }

        uint256 wisToken = (7 * lrntToken) / 100;

        payable(owner()).transfer(_BNB);
        LRNT_token.transfer(currentInvestor, lrntToken);
        WIS_token.transfer(currentInvestor, wisToken);

        if (userInfo[currentInvestor].LRNTToken == 0) {
            userInfo[currentInvestor] = UserInfo(
                lrntToken,
                wisToken,
                0,
                lrntToken,
                0,
                _BNB
            );
            allBuyerAddress.push(currentInvestor);
        } else {
            userInfo[currentInvestor].LRNTToken += lrntToken;
            userInfo[currentInvestor].bonusWISToken += wisToken;
            userInfo[currentInvestor].unclaimedLRNToken += lrntToken;
            userInfo[currentInvestor].investBNBToken += _BNB;
        }
        iCOInfo.raisedTotalBNBToken += _BNB;
        iCOInfo.soldLRNToken += lrntToken;

        return true;
    }

    function withdraw() public returns (bool) {
        UserInfo storage _user = userInfo[msg.sender];
        require(_user.LRNTToken != 0, "Oops you are not a buyer");
        require(
            block.timestamp > roundTimeInfo.r3EndTime,
            "Please wait for all ICO rounds to end"
        );
        require(
            _user.unclaimedLRNToken != 0,
            "You have already claimed all tokens"
        );
        require(
            _user.lastClaimedAt == 0 ||
                (block.timestamp - _user.lastClaimedAt) > 1 days,
            "Greylist for 1 day"
        );

        uint256 amount;
        uint256 _timeGap;

        if (block.timestamp > roundTimeInfo.r3EndTime + 200 days) {
            amount = _user.unclaimedLRNToken;
        } else {
            _timeGap =
                block.timestamp -
                (
                    _user.lastClaimedAt == 0
                        ? roundTimeInfo.r3EndTime
                        : _user.lastClaimedAt
                );
            uint256 _daysDiff;
            if (_user.lastClaimedAt == 0 && _daysDiff == 0) _daysDiff = 1;
            else _daysDiff += (_timeGap / 1 days);
            amount = (_user.LRNTToken * _daysDiff) / 200;
        }

        _user.claimedLRNToken += amount;
        _user.unclaimedLRNToken -= amount;
        _user.lastClaimedAt = block.timestamp;

        LRN_token.transfer(msg.sender, amount);
        LRNT_token.transferFrom(msg.sender, address(this), amount);
        LRNT_token.burn(amount);

        return true;
    }

    function stacking(Stack stack, Month month, uint256 _amount) public {
        require(stackInfo[msg.sender].stackedAt == 0, "Already a stack holder");
        uint256 unstackTime;
        uint256 WISReaward;
        uint256 totalWIS;

        if (stack == Stack.WIS) {
            if (month == Month.Six) {
                unstackTime = block.timestamp + (6 * 2629743);
                WISReaward = (_amount * 3) / 100;
                totalWIS = _amount + WISReaward;
            } else {
                unstackTime = block.timestamp + (12 * 2629743);
                WISReaward = (_amount * 7) / 100;
                totalWIS = _amount + WISReaward;
            }
            stackInfo[msg.sender] = StackInfo(
                block.timestamp,
                unstackTime,
                _amount,
                0,
                WISReaward,
                totalWIS,
                stack,
                month
            );
            WIS_token.transferFrom(msg.sender, address(this), _amount);
        } else if (stack == Stack.WISLRN) {
            if (month == Month.Six) {
                unstackTime = block.timestamp + (6 * 2629743);
                WISReaward = (_amount * 9) / 100;
                totalWIS = _amount + WISReaward;
            } else {
                unstackTime = block.timestamp + (12 * 2629743);
                WISReaward = (_amount * 186) / 1000;
                totalWIS = _amount + WISReaward;
            }
            stackInfo[msg.sender] = StackInfo(
                block.timestamp,
                unstackTime,
                _amount,
                0,
                WISReaward,
                totalWIS,
                stack,
                month
            );
            WIS_token.transferFrom(msg.sender, address(this), _amount);
            LRN_token.transferFrom(msg.sender, address(this), _amount);
        } else if (stack == Stack.LRN) {
            if (month == Month.Six) {
                unstackTime = block.timestamp + (6 * 2629743);
                WISReaward = (_amount * 3) / 100;
                totalWIS = WISReaward;
            } else {
                unstackTime = block.timestamp + (12 * 2629743);
                WISReaward = (_amount * 7) / 100;
                totalWIS = WISReaward;
            }
            stackInfo[msg.sender] = StackInfo(
                block.timestamp,
                unstackTime,
                0,
                _amount,
                WISReaward,
                totalWIS,
                stack,
                month
            );
            LRN_token.transferFrom(msg.sender, address(this), _amount);
        }
    }

    function unstacking() public returns (bool) {
        StackInfo storage _stack = stackInfo[msg.sender];
        require(_stack.stackedAt != 0, "You are not a stack holder");
        require(
            block.timestamp >= _stack.unstackedAt,
            "Please wait for stacking time to complete"
        );
        if (_stack.stackLRNAmount != 0) {
            LRN_token.transfer(msg.sender, _stack.stackLRNAmount);
        }
        WIS_token.transfer(msg.sender, _stack.totalWISAmount);
        delete stackInfo[msg.sender];
        return true;
    }
}

// 0x0DAe2b72Cf1Df2cECaF8Ee612662c79a53f7547B - Matic