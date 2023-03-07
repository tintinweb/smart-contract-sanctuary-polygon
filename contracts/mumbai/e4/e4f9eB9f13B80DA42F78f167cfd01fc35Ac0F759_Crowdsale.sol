// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    IERC20 public token; 

    // wallet of funding
    address payable public  funding;

    uint256 public DirectCommission = 35; // 6%
    uint256 public minBuy = 1 ether; // 10 usd
    uint256 public maxBuy = 1000 ether * 1e6; // 1000 usd
    uint256 public totalBuy = 0; // in usd

    uint256 public tokenRate;

    struct investerStruct {
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
    mapping(address => investerStruct) public investers;

    uint256 profilId = 1000;
    struct userIndexModel {
        uint256 Id;
        address addr;
    }
    userIndexModel[] public index;

    bool public buying = true;

    event eventBuy(address account, uint256 amount);
    event eventSell(address account, uint256 amount);

    constructor(IERC20 _token, uint256 _rate, address _funding) {
        token = _token;
        address _root = msg.sender;
        funding = payable(_funding);
        tokenRate = _rate;

        investers[_root].id = profilId++;
        investers[_root].join_time = block.timestamp;

        userIndexModel memory idx = userIndexModel(investers[_root].id, _root);
        index.push(idx);

        buying = true;
    }

    /**
     * @dev Returns the amount of `POOL Tokens` held by the contract
     */
    function getReserve() public view returns (uint) {
        uint reserve = IERC20(token).balanceOf(address(this));
        return (reserve);
    }

    function buy(uint256 upline) public payable returns (uint256) {
        require(buying, "Crowdsale: active buy is disable");

        uint256 paidFee = 0;
        address invester = msg.sender;
        address _up;
        uint256 amount = msg.value;

        require(amount > minBuy, "Crowdsale: pool balance is low");

        uint reserved = getReserve();

        if (investers[invester].join_time > 0) {
            _up = investers[invester].upline;
        } else {
            _up = getUserAddress(upline);
        }

        uint256 amountOfToken = getAmountOfTokens(amount);
        require(
            token.balanceOf(address(this)) >= amountOfToken,
            "Crowdsale: contract balance is low"
        );
        require(
            reserved.sub(amountOfToken) > 100,
            "Crowdsale: pool balance is low"
        );
        token.transfer(invester, amountOfToken);

        if (investers[invester].join_time == 0) {
            investers[invester].upline = _up;
            investers[invester].id = profilId++;
            investers[invester].join_time = block.timestamp;
            investers[_up].structures++;
            userIndexModel memory idx = userIndexModel(
                investers[invester].id,
                invester
            );
            index.push(idx);
        }

        investers[invester].total_buy += amount;

        paidFee = amount.mul(DirectCommission).div(1000);
        payable(_up).transfer(paidFee);

        payable(funding).transfer(address(this).balance);

        totalBuy += amountOfToken;

        emit eventBuy(invester, amount);

        return amountOfToken;
    }

    function rate() public view returns (uint256) {
        return tokenRate;
    }

    function getAmountOfTokens(
        uint256 inputAmount
    ) public view returns (uint256) {
        return inputAmount.mul(rate());
    }

    function investor(
        address _addr
    )
        external
        view
        returns (uint256, uint256, uint256, uint256, address, uint256)
    {
        return (
            investers[_addr].id,
            investers[_addr].join_time,
            investers[_addr].total_buy,
            investers[_addr].structures,
            investers[_addr].upline,
            investers[_addr].bonuse
        );
    }

    function getUserAddress(uint256 _id) internal view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < index.length; i++) {
            if (index[i].Id == _id) {
                res = index[i].addr;
                break;
            }
        }
        return res;
    }

    function getUser(uint256 _id) external view returns (address) {
        address res = address(0);
        for (uint256 i = 0; i < index.length; i++) {
            if (index[i].Id == _id) {
                res = index[i].addr;
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
            uint256 totalInvesters,
            uint256 current_Rate
        )
    {
        total_Buy = totalBuy;
        totalInvesters = profilId;
        current_Rate = rate();
        return (total_Buy, totalInvesters, current_Rate);
    }

    function setBuying() public onlyOwner returns (bool) {
        buying = true;
        return true;
    }

    function setRate(uint256 newRate) public onlyOwner returns (bool) {
        tokenRate = newRate;
        return true;
    }

    function claimTokens(address _token) public {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(address(this), owner(), balance);
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