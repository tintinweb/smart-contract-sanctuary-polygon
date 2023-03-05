/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/* @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behaviour in high-level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with a custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with a custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with a custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// ERC20 token interface
interface IERC20 {
        
    // Total number of coins
    function totalSupply() external view returns (uint256);
    
    // Check the balance of the address
    function balanceOf(address account) external view returns (uint256);

    // Token transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens available for transfer
    function allowance(address owner, address spender) external view returns (uint256);

    // Approve the amount to be transferred
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer of the approved amount
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Entry in the event log about the transfer of funds
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Recording in the event log about the allowed transfer amount
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Contract providing accounting and management of staking
contract Staking {

    // Structure of tokens
    struct Token {
        // Name of the token
        string symbol;
        // Token contract address
        address token;
        // Decimals Token
        uint8 decimals;
        // Annual percentage rate
        uint16 apr;
        // Tariff validity period (day)
        uint256 lockout;
        // Duration of permanent blocking by tariff (day)
        uint256 permanentLockout;
        // Early withdrawal penalty. Dynamic (%)
        uint8 fineWithdraw;
        // Minimum allowed deposit
        uint256 minDeposit;
        // Token status, Staking allowed
        bool status;
        // Token interface
        IERC20 ERC20;
    }

    // Structure of deposits
    struct Deposit {
        // The name of the token on which the deposit is made
        string symbol;
        // Staking deposit amount
        uint256 amount;
        // Time of the perfect deposit
        uint256 timeStamp;
    }

    // Number of seconds in one day (86400)
    // uint256 secondsInDay = 86400;
    // or
    // depends on calculation in minutes or days
    // Number of seconds in one minute (60)
    uint256 secondsInDay = 60;

    // Affordable staking rates
    mapping (string => Token) public currentTarif;
    // Is staking at the moment
    mapping (string => uint256) public totalStaking;
    // Staking accounting
    mapping (address => mapping (string => Deposit)) public depositToken;

    // Native network Token
    string nativeToken = "MATIC";
    // Contract owner
    address public owner;
    // Distribution contract
    address public distribution = 0x09a24Fb2192616034453e4a19A81bdC4F55B2a21;
    // Acceptance of deposits
    bool public staking = true;

    // Event triggered by change of ownership contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Event triggered when funds are transferred from a contract
    event Stake(
        uint256 indexed timeStampNewStake,
        address indexed addresNewStake,
        uint256 indexed amountNewStake
    );

    // The event triggered a profit
    event WithdrawProfit(
        uint256 indexed timeStampNewStake,
        address indexed addresNewStake,
        uint256 indexed amountNewStake
    );

    // Event triggered pick up early with a fine and no profit
    event RemoveReverse(
        uint256 indexed timeStampNewStake,
        address indexed addresNewStake,
        uint256 indexed amountNewStake
    );

    // The modifier checks if the function caller is the owner of the contract
    modifier onlyOwner() {
        // Check whether the calling address is the owner of the contract
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Executed at contract initialization
    constructor() {
        // The owner of the contract is appointed
        owner = msg.sender;

        // Native network tarif
        addStakingTarif(
            nativeToken, // symbol: Name of the native Token
            0x0000000000000000000000000000000000000000, // token: The address field in the native token is not used (plug)
            18, // decimals: Decimals native Token
            24000, // apr: Annual percentage rate native Token
            10, // lockout: Tariff validity period (day or minutes) native Token
            5, // permanentLockout: Duration of permanent blocking by tariff (day or minutes) native Token
            20, // fineWithdraw: Early withdrawal penalty native Token
            10000000000000000 // minDeposit: Minimum allowed deposit (Wei) native Token - 0.01 MATIC
        );
    }

    // Change of ownership by contract
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(_newOwner);
    }

    // Immediate change of ownership by contract
    function _setOwner(address _newOwner) private {
        address _oldOwner = owner;
        owner = _newOwner;

        // Recording to the event log about the change of the contract owner
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    // Accepting deposits for staking
    function stakingContract(bool _trueOrFalse) public onlyOwner {
        // Change the status of deposits under the contract
        staking = _trueOrFalse;
    }

    // Compare strings
    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Add new staking tarif
    function addStakingTarif(
        string memory _symbol,
        address _token,
        uint8 _decimals,
        uint16 _apr,
        uint256 _lockout,
        uint256 _permanentLockout,
        uint8 _fineWithdraw,
        uint256 _minDeposit
        )
        public onlyOwner {

        // Check if there is a Token
        require(!_compareStrings(currentTarif[_symbol].symbol, _symbol), "Token already added");

        // ERC20 standard token 
        IERC20 ERC20;
        // ERC20 token interface is connected
        ERC20 = IERC20(_token);

        // Creating a New Token Structure
        Token memory newToken = Token(
            _symbol,
            _token,
            _decimals,
            _apr,
            (_lockout * secondsInDay),
            (_permanentLockout * secondsInDay),
            _fineWithdraw,
            _minDeposit,
            true,
            ERC20
            );

        // Adding a new Token structure to the array
        currentTarif[_symbol] = newToken;

        // Adding a staking counter
        totalStaking[_symbol] = 0;
    }

    // Edit staking tarif
    function editStakingTarif(
        string memory _symbol,
        address _token,
        uint8 _decimals,
        uint16 _apr,
        uint256 _lockout,
        uint256 _permanentLockout,
        uint8 _fineWithdraw,
        uint256 _minDeposit
        )
        public onlyOwner {

        // Check if there is a tariff
        require(_compareStrings(currentTarif[_symbol].symbol, _symbol), "Tariff does not exist");

        // ERC20 standard token 
        IERC20 ERC20;
        // ERC20 token interface is connected
        ERC20 = IERC20(_token);

        // Edit Token Structure
        Token memory newToken = Token(
            _symbol,
            _token,
            _decimals,
            _apr,
            (_lockout * secondsInDay),
            (_permanentLockout * secondsInDay),
            _fineWithdraw,
            _minDeposit,
            true,
            ERC20
            );

        // Edit Token structure to the array
        currentTarif[_symbol] = newToken;
    }

    function editStatusDepositTarif(string memory _symbol, bool _status) public onlyOwner {
        // Check if there is a tariff
        require(_compareStrings(currentTarif[_symbol].symbol, _symbol), "Tariff does not exist");

        // Edit Token Structure
        Token memory newToken = Token(
            _symbol,
            currentTarif[_symbol].token,
            currentTarif[_symbol].decimals,
            currentTarif[_symbol].apr,
            currentTarif[_symbol].lockout,
            currentTarif[_symbol].permanentLockout,
            currentTarif[_symbol].fineWithdraw,
            currentTarif[_symbol].minDeposit,
            _status,
            currentTarif[_symbol].ERC20
            );

        // Edit Token structure to the array
        currentTarif[_symbol] = newToken;
    }

    // Get information about the tariff
    function getTarif(string memory _symbol) public view returns(Token memory){
        return currentTarif[_symbol];
    }

    // Checking the balance of the ERC20 token on the contract
    function getBalance(string memory _symbol) public view returns (uint256) {
        if (_compareStrings(_symbol, nativeToken)){
            return address(this).balance;
        } else {
            return currentTarif[_symbol].ERC20.balanceOf(address(this));
        }
	}

    // Stacking Token
    function stake(string memory _symbol, uint256 _amount) public payable{
        // Check staking status
        require(currentTarif[_symbol].status, "Staking suspended");
        // Checking for a deposit
        require(depositToken[msg.sender][_symbol].amount == 0, "Deposit already made");
        // Check if there is a deposit token
        require(!_compareStrings(currentTarif[_symbol].symbol, ""), "No such token exists");
        // Check minimum deposit amount
        require(_amount >= currentTarif[_symbol].minDeposit, "Check minimum deposit amount");

        if (_compareStrings(_symbol, nativeToken)){
            // The transfer amount and the amount in the _amount field must match
            require(msg.value == _amount, "Amount entered incorrectly");

            // Transfer to a distribution contract
            payable(distribution).transfer(msg.value);
        } else {
            // Transferring Token to a contract for steaking
            currentTarif[_symbol].ERC20.transferFrom(address(msg.sender), address(this), _amount);
        }

        // Create a new deposit
        Deposit memory newDeposit = Deposit(_symbol, _amount, block.timestamp);
        depositToken[msg.sender][_symbol] = newDeposit;

        // We add the amount of the deposit to the total amount of deposits
        totalStaking[_symbol] += _amount;

        if (!_compareStrings(_symbol, nativeToken)){
            // Translation to distribution contract
            currentTarif[_symbol].ERC20.transfer(address(distribution), _amount);
        }

        // Recording in the event log about the transfer from the contract
        emit Stake(block.timestamp, address(msg.sender), _amount);
    }

    // Calculate the profit
    function calculateProfit(string memory _symbol, address _sender) public view returns (uint256) {
        uint256 _stakingTime;
        uint256 _multiplier;
        uint256 _aprResultMult;
        uint256 _profit;
        uint256 _total;
        uint256 _totalProfit;

        // Check whether a deposit has already been committed
        if (depositToken[_sender][_symbol].amount == 0){
            return 0;
        }

        _stakingTime = SafeMath.sub(block.timestamp, depositToken[_sender][_symbol].timeStamp);
        // Calculation accuracy
        _multiplier = 10 ** currentTarif[_symbol].decimals;

        if (_stakingTime > currentTarif[_symbol].lockout) {
            _stakingTime = currentTarif[_symbol].lockout;
        }

        _aprResultMult = SafeMath.div(SafeMath.mul(currentTarif[_symbol].apr, _multiplier), 365 days);
        _profit = SafeMath.div(
            SafeMath.mul(
                SafeMath.mul(_stakingTime, _multiplier),
                _aprResultMult
            ),
            _multiplier
        );
        _total = SafeMath.mul(SafeMath.div(depositToken[_sender][_symbol].amount, 100), _profit);
        _totalProfit = SafeMath.div(_total, _multiplier);

        return _totalProfit;
    }

    // Take the profit and the main deposit
    function withdrawProfit(string memory _symbol) public {

        // Tariff action
        uint256 _stakingTime;
        // The amount of the withdrawal taking into account the profit
        uint256 _totalWithdraw;

        // We check if there is a deposit
        require(
            depositToken[msg.sender][_symbol].amount > 0,
            "There is no deposit."
        );

        // Tariff action
        _stakingTime = SafeMath.sub(block.timestamp, depositToken[msg.sender][_symbol].timeStamp);

        // Check the fulfillment of the tariff conditions
        require( _stakingTime > currentTarif[_symbol].lockout, "Wait for the lock to complete");

        // The amount of the withdrawal taking into account the profit
        _totalWithdraw = SafeMath.add(calculateProfit(_symbol, msg.sender), depositToken[msg.sender][_symbol].amount);

        // Change accounting information
        // We add the amount of the deposit to the total amount of deposits
        totalStaking[_symbol] -= depositToken[msg.sender][_symbol].amount;

        // Clear a deposit
        Deposit memory clearDeposit = Deposit(_symbol, 0, 0);
        depositToken[msg.sender][_symbol] = clearDeposit;

        if (_compareStrings(_symbol, nativeToken)){
            // The withdrawal of funds to the client
            payable(msg.sender).transfer(_totalWithdraw);
        } else {
            // Transferring Token to a contract for withdraw profit
            currentTarif[_symbol].ERC20.transfer(address(msg.sender), _totalWithdraw);
        }
        // Recording in the event log about the transfer from the contract
        emit WithdrawProfit(block.timestamp, msg.sender, _totalWithdraw);
    }

        // Pick up the main deposit with the deduction of a fine and interest loss
    function removeReverse(string memory _symbol) public {

        // Tariff action
        uint256 _stakingTime;
        // Profit at the tariff
        uint256 _profit;
        // The amount of the withdrawal taking into account the profit
        uint256 _totalWithdraw;

        // We check if there is a deposit
        require(
            depositToken[msg.sender][_symbol].amount > 0,
            "There is no deposit."
        );

        // Tariff action
        _stakingTime = SafeMath.sub(block.timestamp, depositToken[msg.sender][_symbol].timeStamp);

        // Check the fulfillment of the tariff conditions
        require( _stakingTime < currentTarif[_symbol].lockout, "To take profit use withdrawProfit()");

        // Check if the time of mandatory blocking has expired
        require(
            _stakingTime > currentTarif[_symbol].permanentLockout,
            "Wait for the permanent lockout to complete"
        );

        // Check the conditions for mandatory blocking at the tariff
        if (_stakingTime > currentTarif[_symbol].lockout) {
            _profit = calculateProfit(_symbol, msg.sender);
        } else {
            _profit = 0;
        }

        // The amount of the withdrawal taking into account the profit
        _totalWithdraw = SafeMath.sub(
            SafeMath.add(_profit, depositToken[msg.sender][_symbol].amount),
            fine(_symbol, msg.sender)
        );

        // Change accounting information
        // We add the amount of the deposit to the total amount of deposits
        totalStaking[_symbol] -= depositToken[msg.sender][_symbol].amount;

        // Clear a deposit
        Deposit memory clearDeposit = Deposit(_symbol, 0, 0);
        depositToken[msg.sender][_symbol] = clearDeposit;

        if (_compareStrings(_symbol, nativeToken)){
            // The withdrawal of funds to the client
            payable(msg.sender).transfer(_totalWithdraw);
        } else {
            // Transferring Token to a contract for withdraw profit
            currentTarif[_symbol].ERC20.transfer(address(msg.sender), _totalWithdraw);
        }

        // Event triggered pick up early with a fine and no profit
        emit RemoveReverse(block.timestamp, msg.sender, _totalWithdraw);
    }

     // Count a fine
    function fine(string memory _symbol, address _address) public view returns (uint256) {

        uint256 _totalFine;
        uint256 _fineSec;
        uint256 _multiplier;
        uint256 _stakingTime;
        uint256 _fineWei;
        uint256 _timeFineSec;

        if (depositToken[_address][_symbol].amount == 0) {
            return 0;
        }

        _stakingTime = SafeMath.sub(block.timestamp, depositToken[_address][_symbol].timeStamp);

        if(_stakingTime > currentTarif[_symbol].lockout){
            return 0;
        }

        _totalFine = SafeMath.mul(SafeMath.div(depositToken[_address][_symbol].amount, 100), currentTarif[_symbol].fineWithdraw);
        // Calculation accuracy
        _multiplier = 10 ** currentTarif[_symbol].decimals;
        // Free lock time
        _timeFineSec = SafeMath.sub(currentTarif[_symbol].lockout, currentTarif[_symbol].permanentLockout);

        _fineSec = SafeMath.div(
            SafeMath.mul(_totalFine, _multiplier),
            _timeFineSec
        );

        if (_stakingTime > currentTarif[_symbol].permanentLockout) {
            _fineWei = SafeMath.div(
                SafeMath.mul(SafeMath.sub(currentTarif[_symbol].lockout, _stakingTime), _fineSec),
                _multiplier
            );
        } else {
            _fineWei = 0;
        }

        return _fineWei;
    }

    // Function allowing the acceptance of funds for the contract
    receive() external payable {
        require(msg.sender == distribution, "It is impossible to enroll");
    }
}