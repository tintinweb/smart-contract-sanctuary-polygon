// SPDX-License-Identifier: MIT
// decentraliz universal laboratory
pragma solidity >=0.4.22 <0.9.0;
import "./IERC20.sol";
import "./SafeMath.sol";

pragma experimental ABIEncoderV2;

contract DunilabInvest {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 decimal;

    // wallet of developer
    address public developer;

    // wallet of owner
    address public owner;

    uint256 public DirectCommission = 10; // 10%

    uint256 public minDeposit = 10000000; // in usd

    uint256 public total_deposit = 0; // in usd

    uint256 public deposit_fee = 3; // in %

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

    constructor(address _developer, address _owner, IERC20 _token) public {
        developer = _developer;
        owner = _owner;
        token = _token;

        // add developer wallet
        investers[developer].id = investerId++;
        investers[developer].join_time = block.timestamp;

        // add to index
        userIndexModel memory idx = userIndexModel(
            investers[developer].id,
            developer
        );

        users.push(idx);
    }

    modifier isOwner() {
        require(msg.sender == owner, "only owner can do it");
        _;
    }

    function deposit(uint256 amount, uint256 upline) external {
        address _up = getUserAddress(upline);
        _up = _up != address(0) ? _up : developer;

        // 1. check balance of token
        address invester = msg.sender;
        uint256 balance = token.balanceOf(invester);

        // 2. balance
        require(balance >= amount, "your balance is low");
        // require(invester != upline, "your balance is low");

        // 3. transfer incoming
        token.transferFrom(invester, address(this), amount);

        uint256 feeAmount = amount.mul(deposit_fee).div(100);
        uint256 directAmount = amount.mul(DirectCommission).div(100);

        // 4. bonuse : directsale get bonuse 10% USDC.e
        if (investers[_up].join_time > 0) {
            // for stop repeate one wallet
            if (investers[invester].upline != _up) {
                investers[_up].structures++;
            }
            if (_up != address(0)) {
                token.transfer(_up, directAmount);
            }
        } else {
            investers[invester].upline = developer;
            investers[_up].structures++;
            feeAmount += directAmount;
            directAmount = 0;
        }

        investers[_up].bonuse += directAmount;

        // 5. transfer commission fee
        token.transfer(developer, feeAmount);

        uint256 remainAmount = (amount).sub(directAmount).sub(feeAmount);
        token.transfer(owner, remainAmount);

        // 8. update invester ( deposit_amount , deposit_time)
        if (investers[invester].join_time == 0) {
            investers[invester].upline = _up;
            investers[invester].id = investerId++;
            investers[invester].join_time = block.timestamp;
            // add to index
            userIndexModel memory idx = userIndexModel(
                investers[invester].id,
                invester
            );

            users.push(idx);
        }

        investers[invester].lock_time = block.timestamp;
        investers[invester].total_deposit += (amount).sub(feeAmount);

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
            owner
        );
    }
}