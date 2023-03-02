// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// decentraliz universal laboratory
import "./IERC20.sol";
import "./IInvestSystem.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TokenSale is Ownable {
    using SafeMath for uint256;

    // A very large multiplier means you can support many decimals
    uint256 public constant MULTIPLIER = 1e6;

    IERC20 public token0; // du
    IERC20 public token1; // usdt

    // wallet of developer
    address public developer;

    address public fund;
    address public dev;
    address public marketing;
    address public expenses;
    address public btcInvest;

    uint256 public fundPercent = 350;
    uint256 public devPercent = 250;
    uint256 public marketingPercent = 240;
    uint256 public expensesPercent = 160;
    uint256 public buyFeePercent = 30;

    uint256 public DirectCommission = 60; // 10%
    uint256 public minBuy = 1000000; // in usd
    uint256 public maxBuy = 100000000000; // in usd
    uint256 public totalBuy = 0; // in usd
    uint256 public totalSell = 0; // in usd

    uint256 public rate;

    struct userModel {
        uint256 id;
        uint256 join_time;
        uint256 total_buy;
        uint256 total_sell;
        address upline;
        uint256 bonuse;
        uint256 balance;
        uint256 lock_time;
        uint256 structures;
    }
    mapping(address => userModel) public investers;
    uint256 investerId = 1000;
    struct userIndexModel {
        uint256 id;
        address wallet;
    }
    userIndexModel[] public users;
    bool public isActiveBuy = true;
    bool public isActiveSell = true;

    // events: buy,sell

    event evBuy(uint256 amount, address account);
    event evSell(uint256 amount, address account);

    constructor(
        IERC20 _token,
        IERC20 _usdt,
        address _developer,
        address _dev,
        address _marketing,
        address _expenses,
        address _btcInvest
    ) {
        token0 = _token;
        token1 = _usdt;

        // add developer wallet
        investers[developer].id = investerId++;
        investers[developer].join_time = block.timestamp;

        // add to index
        userIndexModel memory idx = userIndexModel(
            investers[developer].id,
            developer
        );
        users.push(idx);

        developer = _developer;
        dev = _dev;
        marketing = _marketing;
        expenses = _expenses;
        btcInvest = _btcInvest;

        isActiveBuy = true;
        isActiveSell = true;

        
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param amount of token0(ico) sender like pay
    /// @return amount of token transfered to sender
    function buy(uint256 amount, uint256 upline) public returns (uint256) {
        require(isActiveBuy, "TokenSale: active buy is disable");

        uint256 paidFee = 0;
        address invester = msg.sender;
        address beneficiary = address(this);
        address _up;

        if (investers[invester].join_time > 0) {
            _up = investers[invester].upline;
        } else {
            _up = getUserAddress(upline);
        }

        // check allowance
        // require(
        //     token1.allowance(invester, beneficiary) >= amount,
        //     "TokenSale: token1 allowance not correct"
        // );
        token1.transferFrom(invester, beneficiary, amount);

        // check balance of USDT A from sender
        require(
            token1.balanceOf(invester) >= amount,
            "TokenSale: USD balance is low"
        );

        // calculation
        uint256 amountOfToken = token0Amount(amount); // token
        // balance of contract must be lower of required with current rate
        require(
            token0.balanceOf(beneficiary) >= amountOfToken,
            "TokenSale: contract balance is low"
        );

        // transfer token
        token0.transfer(invester, amountOfToken);

        // fund action
        // 0.5% send to developer
        uint256 partfeeAmount = amount.mul(5).div(1000);
        uint256 directAmount = amount.mul(DirectCommission).div(1000);

        if (investers[_up].join_time > 0) {
            investers[_up].bonuse += directAmount;
            if (_up != address(0)) {
                paidFee +=directAmount;
                token1.transfer(_up, directAmount);
            }
        }

        // transfer developer fee : 0.5%
        token1.transfer(developer, partfeeAmount);
        paidFee += partfeeAmount;

        // transfer btcinvest fee : 1%
        token1.transfer(btcInvest, partfeeAmount.mul(2));
        paidFee += partfeeAmount.mul(2);

        // transfer fund

        uint256 remainAmount = amount.sub(paidFee);

        // splite to action fund
        token1.transfer(dev, remainAmount.mul(devPercent).div(1000));
        token1.transfer(
            marketing,
            remainAmount.mul(marketingPercent).div(1000)
        );
        token1.transfer(expenses, remainAmount.mul(expensesPercent).div(1000));

        // 8. update invester ( deposit_amount , deposit_time)
        if (investers[invester].join_time == 0) {
            investers[invester].upline = _up;
            investers[invester].id = investerId++;
            investers[invester].join_time = block.timestamp;
            investers[_up].structures++;

            // add to index
            userIndexModel memory idx = userIndexModel(
                investers[invester].id,
                invester
            );

            users.push(idx);
        }

        investers[invester].lock_time = block.timestamp;
        investers[invester].total_buy += (amount).sub(partfeeAmount.mul(6));

        totalBuy += amountOfToken;

        // buy event
        emit evBuy(amount, invester);

        return amountOfToken;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param amount of token sender like pay
    /// @return amount of USDT transfered to sender
    function sell(uint256 amount) public returns (uint256) {
        require(isActiveSell, "active sell is disable");
        address sender = msg.sender;
        address beneficiary = address(this);

        // Step A : Before Transfer
        // check balance of token A from sender
        require(
            token0.balanceOf(sender) >= amount,
            "TokenSale: Token balance is low"
        );

        // check allowance
        require(
            token0.allowance(sender, beneficiary) >= amount,
            "TokenSale: Token allowance not correct"
        );

        // Step B : calculation
        uint256 amountOfUSDT = token0Amount(amount);
        // balance of contract must be lower of required with current rate
        require(
            token1.balanceOf(beneficiary) >= amountOfUSDT,
            "TokenSale: contract balance is low"
        );

        // Step C : transfer token
        token1.transfer(sender, amountOfUSDT);

        totalSell += amountOfUSDT;

        emit evSell(amount, sender);

        return amountOfUSDT;
    }

    function currentRate() public view returns (uint256) {
        uint256 bToken = token0.balanceOf(address(this));
        uint256 bUSDT = token1.balanceOf(address(this));

        return MULTIPLIER.mul(bUSDT).div(bToken);
    }

    // for sell token0
    function token0Amount(
        uint256 amount
    ) public view returns (uint256 tokenAMOUNT) {
        tokenAMOUNT = MULTIPLIER.mul(amount).div(currentRate()) ;
        return tokenAMOUNT;
    }

    // for buy token0
    function token1Amount(
        uint256 amount
    ) public view returns (uint256 tokenAMOUNT) {
        tokenAMOUNT = amount.mul(currentRate());
        return tokenAMOUNT;
    }

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256, uint256)
    {
        return (
            investers[_addr].id,
            investers[_addr].join_time,
            investers[_addr].total_buy,
            investers[_addr].structures,
            investers[_addr].upline,
            investers[_addr].bonuse,
            investers[_addr].balance
        );
    }

    function getUserAddress(uint256 _id) internal view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function getUser(uint256 _id) external view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                res = users[i].wallet;
                break;
            }
        }
        return res;
    }

    function info()
        external
        view
        returns (
            uint256 total_Buy,
            uint256 total_Sell,
            uint256 totalInvesters,
            uint256 balanceToken0,
            uint256 balanceToken1,
            uint256 current_Rate
        )
    {
        total_Buy = totalBuy;
        total_Sell = totalSell;
        totalInvesters = investerId;
        balanceToken0 = token0.balanceOf(address(this));
        balanceToken1 = token1.balanceOf(address(this));
        current_Rate = currentRate();
        return (
            total_Buy,
            total_Sell,
            totalInvesters,
            balanceToken0,
            balanceToken1,
            current_Rate
        );
    }


    // setIsActiveBuy
    function setActiveBuy() public onlyOwner returns(bool) {
        isActiveBuy = true;
        return true;
    }

    // setisActiveSell
      function setActiveSell() public onlyOwner returns(bool) {
        isActiveSell = true;
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// decentraliz universal laboratory
pragma solidity >=0.4.22 <0.9.0;


interface IInvestSystem {   

    function deposit(uint256 amount, uint256 upline) external;

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256, uint256);
    

    function getUserAddress(uint256 _id) external view returns (address);

    function getUser(uint256 _id) external view returns (address) ;

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256, // refundCounter
            address
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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