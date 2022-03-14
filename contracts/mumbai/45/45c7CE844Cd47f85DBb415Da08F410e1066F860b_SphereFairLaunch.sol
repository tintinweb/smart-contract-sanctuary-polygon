// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
import "./NRT.sol";
import "./libraries/ERC20.sol";
import "./libraries/OwnableBase.sol";
import "./libraries/SafeMath.sol";

////////////////////////////////////
//
//  Fair Price Launch Contract
//  Every gets the same price in the end
//  Users get issued a non-transferable token  and redeem for the final token
//
////////////////////////////////////
contract SphereFairLaunch is OwnableBase {
    using SafeMath for uint256;

    address public fundsRedeemer;
    // The token used for contributions
    address public investToken;

    // The Non-transferable token used for sale, redeemable for Mag
    NRT public redeemableToken;

    //Limits
    uint256 public maxInvestAllowed;
    uint256 public minInvestAllowed;
    uint256 public maxInvestRemovablePerPeriod;
    uint256 public maxGlobalInvestAllowed;
    uint256 public maxRedeemableToIssue;

    //totals
    uint256 public totalGlobalInvested;
    uint256 public totalGlobalIssued;
    uint256 public totalInvestors;

    //TIMES
    // The time that sale will begin
    uint256 public launchStartTime;
    // length of sale period
    uint256 public saleDuration;
    // launchStartTime.add(sale) durations
    uint256 public launchEndTime;
    //The delay required between investment removal
    uint256 public investRemovalDelay;
    //Prices
    uint256 public startingPrice;
    uint256 public finalPrice;

    //Token
    address public launchToken;

    //toggles
    // sale has started
    bool public saleEnabled;
    bool public saleEnded;
    bool public redeemEnabled;
    bool public finalized;

    //EVENTS
    event SaleEnabled(bool enabled, uint256 time);
    event SaleEnded(bool enabled, uint256 time);
    event RedeemEnabled(bool enabled, uint256 time);

    event Invest(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event RemoveInvestment(
        address investor,
        uint256 amount,
        uint256 totalInvested,
        uint256 price
    );
    event IssueNRT(address investor, uint256 amount);

    //Structs

    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    struct InvestorInfo {
        uint256 totalInvested;
        uint256 totalRedeemed;
        uint256 totalInvestableExchanged;
        Withdrawal[] withdrawHistory;
        bool hasClaimed;
    }

    mapping(address => InvestorInfo) public investorInfoMap;
    address[] public investorList;


    //@TODO: test more in-depth (february 6th)
    constructor(
        address _fundsRedeemer,
        address _investToken,
        uint256 _launchStartTime,
        uint256 _saleDuration,
        uint256 _investRemovalDelay,
        uint256 _maxInvestAllowed,
        uint256 _minInvestAllowed,
        uint256 _maxInvestRemovablePerPeriod,
        uint256 _maxGlobalInvestAllowed,
        uint256 _maxRedeemableToIssue,
        uint256 _startingPrice
        //address _redeemableToken
    ) {
        require(
            _launchStartTime > block.timestamp,
            "Start time must be in the future."
        );
        require(
            _minInvestAllowed >= 0,
            "Min invest amount must not be negative"
        );
        require(_startingPrice >= 0, "Starting price must not be negative");
        require(_fundsRedeemer != address(0), "fundsRedeemer address is not set.");

        fundsRedeemer = _fundsRedeemer;
        investToken = _investToken;
        //times
        launchStartTime = _launchStartTime;
        require(_saleDuration < 4 days, "duration too long");
        launchEndTime = _launchStartTime.add(_saleDuration);
        saleDuration = _saleDuration;
        investRemovalDelay = _investRemovalDelay;
        //limits
        maxInvestAllowed = _maxInvestAllowed;
        minInvestAllowed = _minInvestAllowed;
        maxGlobalInvestAllowed = _maxGlobalInvestAllowed;
        maxInvestRemovablePerPeriod = _maxInvestRemovablePerPeriod;
        maxRedeemableToIssue = _maxRedeemableToIssue;
        startingPrice = _startingPrice;
        //NRT is passed in as argument and this contract needs to be set as owner
        //redeemableToken = NRT(_redeemableToken);
        saleEnabled = false;
        redeemEnabled = false;
    }

    //User functions
    /**
    @dev Invests the specified amoount of investToken
     */
    function invest(uint256 amountToInvest) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(amountToInvest >= minInvestAllowed, "Invest amount too small");
        require(!hasSaleEnded(), "Sale period has ended");
        require(launchEndTime >= block.timestamp, "sale has ended");
        require(
            totalGlobalInvested.add(amountToInvest) <= maxGlobalInvestAllowed,
            "Maximum Investments reached"
        );

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(
            investor.totalInvested.add(amountToInvest) <= maxInvestAllowed,
            "Max individual investment reached"
        );
        //transact
        require(
            ERC20(investToken).transferFrom(
                msg.sender,
                address(this),
                amountToInvest
            ),
            "transfer failed"
        );
        if (investor.totalInvested == 0) {
            totalInvestors += 1;
            investorList.push(msg.sender);
        }
        investor.totalInvestableExchanged += amountToInvest;
        investor.totalInvested += amountToInvest;
        totalGlobalInvested += amountToInvest;
        //continuously updates finalPrice until the last contribution is made.
        finalPrice = currentPrice();
        emit Invest(
            msg.sender,
            amountToInvest,
            totalGlobalInvested,
            finalPrice
        );
    }

    /**
    @dev Returns the total amount withdrawn by the _address during the last hour
    **/

    function getLastPeriodWithdrawals(address _address)
    public
    view
    returns (uint256 totalWithdrawLastHour)
    {
        InvestorInfo storage investor = investorInfoMap[_address];

        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        for (uint256 i = 0; i < withdrawHistory.length; i++) {
            Withdrawal memory withdraw = withdrawHistory[i];
            if (withdraw.timestamp >= block.timestamp.sub(investRemovalDelay)) {
                totalWithdrawLastHour = totalWithdrawLastHour.add(
                    withdrawHistory[i].amount
                );
            }
        }
    }

    /**
    @dev Removes the specified amount from the users totalInvested balance and returns the amount of investTokens back to them
     */
    function removeInvestment(uint256 amountToRemove) public {
        require(saleEnabled, "Sale is not enabled yet");
        require(!saleEnded, "Sale ended");
        require(redeemEnabled != true, "Redeem already enabled");
        require(block.timestamp >= launchStartTime, "Sale has not started yet");
        require(block.timestamp < launchEndTime, "Sale has ended");
        require(
            totalGlobalInvested < maxGlobalInvestAllowed,
            "Maximum Investments reached, deposits/withdrawal are disabled"
        );

        InvestorInfo storage investor = investorInfoMap[msg.sender];

        //Two checks of funds to prevent over withdrawal
        require(
            amountToRemove <= investor.totalInvested,
            "Cannot Remove more than invested"
        );
        require(!investor.hasClaimed, "Already has claimed");

        //Make sure they can't withdraw too often.
        Withdrawal[] storage withdrawHistory = investor.withdrawHistory;
        uint256 authorizedWithdraw = maxInvestRemovablePerPeriod.sub(
            getLastPeriodWithdrawals(msg.sender)
        );
        require(
            amountToRemove <= authorizedWithdraw,
            "Max withdraw reached for this hour"
        );
        withdrawHistory.push(
            Withdrawal({timestamp: block.timestamp, amount: amountToRemove})
        );
        //transact
        investor.totalInvestableExchanged += amountToRemove;
        investor.totalInvested -= amountToRemove;
        totalGlobalInvested -= amountToRemove;
        require(
            ERC20(investToken).transferFrom(
                address(this),
                msg.sender,
                amountToRemove
            ),
            "transfer failed"
        );

        finalPrice = currentPrice();

        emit RemoveInvestment(
            msg.sender,
            amountToRemove,
            totalGlobalInvested,
            finalPrice
        );
    }

    function userIssueAmount(address _address) public view returns (uint256) {
        InvestorInfo storage investor = investorInfoMap[_address];

        return investor.totalInvested.mul(1e18).div(finalPrice);
    }

    /**
@dev Claims the SPHERE tokens equivalent to their contribution
     */
    function claimRedeemable() public {
        require(redeemEnabled, "redeem not enabled");
        require(launchToken != address(0), "launch token not set");

        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(!investor.hasClaimed, "Tokens already claimed");
        require(investor.totalInvested > 0, "No investment made");

        uint256 issueAmount = investor.totalInvested.mul(1e18);
        issueAmount = issueAmount.div(finalPrice);

        investor.hasClaimed = true;
        investor.totalRedeemed = issueAmount;
        totalGlobalIssued = totalGlobalIssued.add(issueAmount);


        require(
            ERC20(launchToken).transfer(
                msg.sender,
                    investor.totalRedeemed
            ),
            "transfer failed"
        );

        //redeemableToken.issue(msg.sender, issueAmount);
        emit IssueNRT(msg.sender, issueAmount);
    }

    //getters
    //calculates current price
    function currentPrice() public view returns (uint256) {
        uint256 price = computePrice();
        if (price <= startingPrice) {
            return startingPrice;
        } else {
            return price;
        }
    }

    function computePrice() public view returns (uint256) {
        return totalGlobalInvested.mul(1e18).div(maxRedeemableToIssue);
    }

    function hasSaleEnded() public view returns (bool) {
        return block.timestamp > launchStartTime.add(saleDuration);
    }

    //------ Owner Functions ------

    function enableSale() public onlyOwner {
        saleEnabled = true;
        emit SaleEnabled(true, block.timestamp);
    }

    function disableSale() public onlyOwner {
        saleEnded = true;
        emit SaleEnded(true, block.timestamp);
    }

    function enableRedeem() public onlyOwner {
        require(launchToken != address(0), "launch token not set");
        require(redeemEnabled != true, "already enabled");
        redeemEnabled = true;
        emit RedeemEnabled(true, block.timestamp);
    }

    function withdrawInvestablePool(address _address) public onlyOwner {
        require(redeemEnabled, "redeem not enabled");
        uint256 amount = ERC20(_address).balanceOf(address(this));
        ERC20(_address).transfer(fundsRedeemer, amount);
    }

    function changeStartTime(uint256 newTime) public onlyOwner {
        require(newTime > block.timestamp, "Start time must be in the future.");
        require(block.timestamp < launchStartTime, "Sale has already started");
        launchStartTime = newTime;
        //update endTime
        launchEndTime = newTime.add(saleDuration);
    }

    // define the launch token to be redeemed
    function setLaunchToken(address _launchToken) public onlyOwner {
        require(_launchToken != address(0), "address can not be set");
        launchToken = _launchToken;
    }


    // withdraw in case some tokens were not redeemed
    function withdrawLaunchtoken(address _address, uint256 amount) public onlyOwner {
        require(
            ERC20(_address).transfer(msg.sender, amount),
            "transfer failed"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./libraries/OwnableMulti.sol";
import "./libraries/SafeMath.sol";

//NRT is like a private stock
//can only be traded with the issuer who remains in control of the market
//until he opens the redemption window
contract NRT is OwnableMulti {
    uint256 private _issuedSupply;
    uint256 private _outstandingSupply;
    uint256 private _decimals;
    string private _symbol;

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    event Issued(address account, uint256 amount);
    event Redeemed(address account, uint256 amount);

    constructor(string memory __symbol, uint256 __decimals) {
        _symbol = __symbol;
        _decimals = __decimals;
        _issuedSupply = 0;
        _outstandingSupply = 0;
    }

    // Creates amount NRT and assigns them to account
    function issue(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");

        _issuedSupply = _issuedSupply.add(amount);
        _outstandingSupply = _outstandingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Issued(account, amount);
    }

    //redeem, caller handles transfer of created value
    function redeem(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");
        require(_balances[account] >= amount, "Insufficent balance");

        _balances[account] = _balances[account].sub(amount);
        _outstandingSupply = _outstandingSupply.sub(amount);

        emit Redeemed(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function issuedSupply() public view returns (uint256) {
        return _issuedSupply;
    }

    function outstandingSupply() public view returns (uint256) {
        return _outstandingSupply;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID =
    keccak256("ERC20Token");

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address(this), account_, ammount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.7.5;

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
abstract contract OwnableBase {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.7.5;

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
abstract contract OwnableMulti {
    mapping(address => bool) private _owners;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[msg.sender] = true;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function isOwner(address _address) public view virtual returns (bool) {
        return _owners[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owners[msg.sender], "Ownable: caller is not an owner");
        _;
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        _owners[_newOwner] = true;
    }
}