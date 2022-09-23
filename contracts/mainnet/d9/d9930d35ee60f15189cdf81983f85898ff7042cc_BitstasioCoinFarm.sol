/**
 *Submitted for verification at polygonscan.com on 2022-09-22
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

// File: contracts/farm/coin.sol



/**
 * Bitstasio Coin Farm revision 2
 * Application: https://app.bitstasio.com
 * - 6% automatic share burn on selling, incentivizes investment strategies & punishes TVL draining
 * - share burning also burns bits, decreasing supply - deflationary behavior
 * - 48 hours rewards cutoff
 * - referrals features have been removed
 * - lowered daily return
 * - uses send() instead of transfer() for eth transfers that should not be blocking
 */

pragma solidity ^0.8.17; // solhint-disable-line


contract BitstasioCoinFarm {
    using SafeMath for uint256;

    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;

    address public admin;
    address public marketing;
    address public influencer;
    address public dispatcher;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public ownedBits;
    mapping(address => uint256) public lastConvert;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public withdrawn;

    uint256 public marketBit;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint16 internal constant PERCENT_DIVIDER = 1e4;
    uint16 internal constant SHARES_TO_BURN = 600;

    // TOTAL DEPOSIT FEES: 5%
    uint256 public constant FEE_DEPOSIT_ADMIN = 150; // 1.50%
    uint256 public constant FEE_DEPOSIT_DISPATCHER = 100; // 1.00%
    uint256 public constant FEE_DEPOSIT_MARKETING = 150; // 1.50%
    uint256 public constant FEE_DEPOSIT_INFLUENCER = 100; // 1.00%

    // TOTAL WITHDRAW FEES: 10%
    uint256 public constant FEE_WITHDRAW_ADMIN = 250; // 2.50%
    uint256 public constant FEE_WITHDRAW_DISPATCHER = 150; // 1.50%
    uint256 public constant FEE_WITHDRAW_MARKETING = 400; // 4.00%
    uint256 public constant FEE_WITHDRAW_INFLUENCER = 200; // 2.00%

    uint256 public constant BIT_TO_CONVERT_1SHARE = 7776000;
    uint256 public constant DAILY_INTEREST = 1000; // 1.000% daily ROI

    constructor(
        address _influencer,
        address _marketing,
        address _dispatcher
    ) {
        admin = msg.sender;
        influencer = _influencer;
        marketing = _marketing;
        dispatcher = _dispatcher;
    }

    event BuyBits(address indexed from, uint256 amount, uint256 bitBought);
    event CompoundBits(
        address indexed from,
        uint256 bitUsed,
        uint256 sharesReceived
    );
    event SellBits(address indexed from, uint256 amount);
    event BurnShares(address indexed from, uint256 sharesBurned);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin restricted.");
        _;
    }

    function burnShares(uint256 amount) public {
        require(
            amount > 0 && amount <= shares[msg.sender],
            "Incorrect share amount."
        );

        uint256 balance = shares[msg.sender];
        uint256 bits_to_burn = balance.mul(_getBitToShare());

        if (marketBit - bits_to_burn > 0) {
            marketBit = marketBit.sub(bits_to_burn);
        }

        shares[DEAD] = shares[DEAD].add(amount);
        shares[msg.sender] = shares[msg.sender].sub(amount);

        emit BurnShares(msg.sender, amount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _getPercentage(uint256 value, uint256 percent)
        private
        pure
        returns (uint256)
    {
        return (value * percent) / PERCENT_DIVIDER;
    }

    function _getFeeDeposit(uint256 value) private returns (uint256) {
        uint256 feeAdmin = _getPercentage(value, FEE_DEPOSIT_ADMIN);
        uint256 feeMarketing = _getPercentage(value, FEE_DEPOSIT_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_DEPOSIT_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_DEPOSIT_INFLUENCER);

        payable(admin).send(feeAdmin);
        payable(dispatcher).send(feeDispatcher);
        payable(influencer).send(feeInfluencer);
        payable(marketing).send(feeMarketing);

        return value - feeAdmin - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeDepositSimple(uint256 value)
        private
        pure
        returns (uint256)
    {
        uint256 feeAdmin = _getPercentage(value, FEE_DEPOSIT_ADMIN);
        uint256 feeMarketing = _getPercentage(value, FEE_DEPOSIT_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_DEPOSIT_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_DEPOSIT_INFLUENCER);

        return value - feeAdmin - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeWithdraw(uint256 value) private returns (uint256) {
        uint256 feeAdmin = _getPercentage(value, FEE_WITHDRAW_ADMIN);
        uint256 feeMarketing = _getPercentage(value, FEE_WITHDRAW_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_WITHDRAW_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_WITHDRAW_INFLUENCER);

        payable(admin).send(feeAdmin);
        payable(dispatcher).send(feeDispatcher);
        payable(influencer).send(feeInfluencer);
        payable(marketing).send(feeMarketing);

        return value - feeAdmin - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getFeeWithdrawSimple(uint256 value)
        private
        pure
        returns (uint256)
    {
        uint256 feeAdmin = _getPercentage(value, FEE_WITHDRAW_ADMIN);
        uint256 feeMarketing = _getPercentage(value, FEE_WITHDRAW_MARKETING);
        uint256 feeDispatcher = _getPercentage(value, FEE_WITHDRAW_DISPATCHER);
        uint256 feeInfluencer = _getPercentage(value, FEE_WITHDRAW_INFLUENCER);

        return value - feeAdmin - feeMarketing - feeInfluencer - feeDispatcher;
    }

    function _getBitToShare() private pure returns (uint256) {
        return 7776e6 / DAILY_INTEREST;
    }

    function _getBitSinceLastConvert(address adr)
        private
        view
        returns (uint256)
    {
        uint256 secondsPassed = min(
            2 days,
            SafeMath.sub(block.timestamp, lastConvert[adr])
        );

        return SafeMath.mul(secondsPassed, shares[adr]);
    }

    function getBitToShare() external pure returns (uint256) {
        return _getBitToShare();
    }

    function seedMarket() public payable onlyAdmin {
        require(!initialized, "Already initialized.");
        require(marketBit == 0);
        initialized = true;
        marketBit = 108000000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getShares() public view returns (uint256) {
        return shares[msg.sender];
    }

    function getBits() public view returns (uint256) {
        return
            SafeMath.add(
                ownedBits[msg.sender],
                _getBitSinceLastConvert(msg.sender)
            );
    }

    function getLastConvert() public view returns (uint256) {
        return lastConvert[msg.sender];
    }

    function getBitSinceLastConvert(address adr)
        external
        view
        returns (uint256)
    {
        return _getBitSinceLastConvert(adr);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setDispatcher(address _dispatcher) external onlyAdmin {
        dispatcher = _dispatcher;
    }

    function setInfluencer(address _influencer) external onlyAdmin {
        influencer = _influencer;
    }

    function setMarketing(address _marketing) external onlyAdmin {
        marketing = _marketing;
    }

    function compoundBits() public {
        require(initialized, "Contract is not initialized yet.");

        uint256 bitUsed = getBits();

        uint256 newShares = bitUsed.div(_getBitToShare());
        shares[msg.sender] = shares[msg.sender].add(newShares);
        ownedBits[msg.sender] = 0;
        lastConvert[msg.sender] = block.timestamp;

        marketBit = marketBit.add(bitUsed.div(5));

        emit CompoundBits(msg.sender, bitUsed, newShares);
    }

    function sellBits() external {
        require(initialized, "Contract is not initialized yet.");

        uint256 sharesOwned = shares[msg.sender];

        require(sharesOwned > 0, "You must own shares to claim.");

        uint256 hasBit = getBits();
        uint256 bitValue = calculateBitSell(hasBit);
        uint256 fee = _getFeeWithdrawSimple(bitValue);
        uint256 sharesToBurn = (sharesOwned.mul(SHARES_TO_BURN)).div(
            PERCENT_DIVIDER
        );

        ownedBits[msg.sender] = 0;
        lastConvert[msg.sender] = block.timestamp;
        marketBit = marketBit.add(hasBit);
        withdrawn[msg.sender] += bitValue.sub(fee);

        if (sharesOwned >= 100) {
            burnShares(sharesToBurn); // burn 6% shares
        }

        fee = _getFeeWithdraw(bitValue);

        payable(msg.sender).transfer(bitValue.sub(fee));

        emit SellBits(msg.sender, bitValue);
    }

    function buyBits() external payable {
        require(msg.value > 0, "You need to enter an amount.");
        require(initialized, "Contract is not initialized yet.");

        uint256 bitBought = calculateBitBuy(
            msg.value,
            getBalance().sub(msg.value)
        );
        bitBought = bitBought.sub(_getFeeDepositSimple(bitBought));
        ownedBits[msg.sender] += bitBought;
        deposited[msg.sender] += _getFeeDepositSimple(msg.value);

        compoundBits();

        _getFeeDeposit(msg.value);

        emit BuyBits(msg.sender, msg.value, bitBought);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateBitSell(uint256 bit) public view returns (uint256) {
        return calculateTrade(bit, marketBit, getBalance());
    }

    function calculateBitBuy(uint256 token, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(token, contractBalance, marketBit);
    }

    function calculateBitBuySimple(uint256 eth) public view returns (uint256) {
        return calculateBitBuy(eth, getBalance());
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}
}