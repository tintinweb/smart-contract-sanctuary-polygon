// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
// decentraliz universal laboratory
import "./IERC20.sol";
import "./SafeMath.sol";

pragma experimental ABIEncoderV2;

contract InvestSystem {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 decimal;

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

    uint256 public DirectCommission = 115; // 10%
    uint256 public minDeposit = 1000000; // in usd
    uint256 public total_deposit = 0; // in usd
    uint256 public deposit_fee = 30; // in %3

    struct userModel {
        uint256 id;
        uint256 join_time;
        uint256 total_deposit;
        uint256 total_withdraw;
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

    event depositEvent(address account, uint256 amount);

    constructor(
        address _developer,
        address _fund,
        address _dev,
        address _marketing,
        address _expenses,
        address _btcInvest,
        IERC20 _token
    )  {
        developer = _developer;
        token = _token;

        // add developer wallet
        investers[developer].id = investerId++;
        investers[developer].join_time = block.timestamp;

        // add to index
        userIndexModel memory idx = userIndexModel(
            investers[developer].id,
            developer
        );

        fund = _fund;
        dev = _dev;
        marketing = _marketing;
        expenses = _expenses;
        btcInvest = _btcInvest;

        users.push(idx);
    }

    function deposit(uint256 amount, uint256 upline) external {
        address invester = msg.sender;
        address _up;

        if (investers[invester].join_time > 0) {
            // for stop repeate one wallet
            _up = investers[invester].upline;            
        }else {
            _up = getUserAddress(upline);
        }      

        require(investers[_up].join_time > 0, "upline not found");

        // 1. check balance of token
        uint256 balance = token.balanceOf(invester);

        // 2. balance
        require(balance >= amount, "your balance is low");        

        // 3. transfer incoming
        token.transferFrom(invester, address(this), amount);

        // 0.5% send to developer
        uint256 partfeeAmount = amount.mul(deposit_fee.div(6)).div(1000);

        uint256 directAmount = amount.mul(DirectCommission).div(1000);

        // 4. bonuse : directsale get bonuse 10% USDC.e
        if (investers[_up].join_time > 0) {
            // for stop repeate one wallet
            investers[_up].bonuse += directAmount;
            // pay 10% direct
            if (_up != address(0)) {
                token.transfer(_up, directAmount);
            }
        }

        // 5. transfer developer fee : 0.5%
        token.transfer(developer, partfeeAmount);

        // 6. transfer btcinvest fee : 1%
        token.transfer(btcInvest, partfeeAmount.mul(2));

        uint256 remainAmount = token.balanceOf(address(this));

        // splite to action fund
        token.transfer(fund, remainAmount.mul(fundPercent).div(1000));
        token.transfer(dev, remainAmount.mul(devPercent).div(1000));
        token.transfer(marketing, remainAmount.mul(marketingPercent).div(1000));
        token.transfer(expenses, remainAmount.mul(expensesPercent).div(1000));

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
        investers[invester].total_deposit += (amount).sub(partfeeAmount.mul(6));

        total_deposit += amount;

        emit depositEvent(invester, amount);
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
            investers[_addr].total_deposit,
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
            uint256,
            uint256,
            uint256,
            uint256, // refundCounter
            address
        )
    {
        return (
            total_deposit,
            investerId,
            token.balanceOf(address(this)),
            0,
            address(0)
        );
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