/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

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


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IQuiz {
    function isAdmin(address _sender) external view returns (bool);
}

contract LotteryPool {
    using SafeMath for uint256;
    address public owner;
    mapping(address => bool) public operators;
    IQuiz public quiz;

    mapping(uint256 => address[]) private remainLotteryInductees;
    mapping(uint256 => mapping(uint256 => address[])) private lotteryResults;

    constructor(address _operator){
        owner = msg.sender;
        operators[msg.sender] = true;
        operators[_operator] = true;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    modifier onlyAdmin(address _sender){
        bool isAdmin = quiz.isAdmin(_sender);
        require(isAdmin, "Only Admin");
        _;
    }

    modifier newLottery(uint256 _lotteryId){
        require(!lotteries[_lotteryId].exist, "exist lottery");
        _;
    }

    modifier notOverLottery(uint256 _lotteryId){
        require(lotteries[_lotteryId].exist, "not exist lottery");
        require(!lotteries[_lotteryId].over, "over lottery");
        _;
    }


    struct Lottery {
        IERC20 token;
        uint256 amount;
        uint256[] fixedNum;
        uint256[] proportionNum;
        bool isEth;
        bool over;
        bool exist;
    }

    mapping(uint256 => Lottery) public lotteries;

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addOperator(address _newOperator) public onlyOwner {
        operators[_newOperator] = true;
    }

    function changeQuiz(address _newQuiz) public onlyOwner {
        quiz = IQuiz(_newQuiz);
        operators[_newQuiz] = true;
    }

    function addLotteryInductees(uint256 _lotteryId, address[] memory _inductees) public onlyOperator {
        if (!lotteries[_lotteryId].exist) {
            return;
        }
        require(!lotteries[_lotteryId].over, "lottery is over");
        if (remainLotteryInductees[_lotteryId].length == 0) {
            remainLotteryInductees[_lotteryId] = _inductees;
        } else {
            for (uint256 i = 0; i < _inductees.length; i++) {
                remainLotteryInductees[_lotteryId].push(_inductees[i]);
            }
        }
    }

    function erc20Lottery(IERC20 _token, uint256 _amount, address[] memory _receivers) public onlyOperator {
        _erc20Lottery(_token, _amount, _receivers);
    }

    function _erc20Lottery(IERC20 _token, uint256 _amount, address[] memory _receivers) internal {
        if (_receivers.length == 0) {
            return;
        }
        require(_token.balanceOf(address(this)) >= _amount, "token remain not enough");
        uint256 singleAmount = _amount.div(_receivers.length);
        for (uint i = 0; i < _receivers.length; i++) {
            _token.transfer(_receivers[i], singleAmount);
        }
    }

    function ethLottery(uint256 _amount, address[] memory _receivers) public onlyOperator {
        _ethLottery(_amount, _receivers);
    }

    function _ethLottery(uint256 _amount, address[] memory _receivers) internal {
        if (_receivers.length == 0) {
            return;
        }
        require(address(this).balance >= _amount, "eth not enough");
        uint256 singleAmount = _amount.div(_receivers.length);
        for (uint i = 0; i < _receivers.length; i++) {
            payable(_receivers[i]).transfer(singleAmount);
        }
    }

    function createLottery(uint256 _lotteryId, IERC20 _rewardToken, uint256[] memory _fixedNum, uint256[] memory _proportionNum, uint256 _amount) public newLottery(_lotteryId)
    onlyAdmin(msg.sender) {
        require(_amount > 0, "amount should be greater than zero");
        _rewardToken.transferFrom(msg.sender, address(this), _amount);
        lotteries[_lotteryId] = Lottery(_rewardToken, _amount, _fixedNum, _proportionNum, false, false, true);
    }

    function createEthLottery(uint256 _lotteryId, uint256[] memory _fixedNum, uint256[] memory _proportionNum, uint256 _amount) public payable newLottery(_lotteryId)
    onlyAdmin(msg.sender) {
        require(_amount > 0, "amount should be greater than zero");
        require(msg.value >= _amount, "amount should be greater amount");
        lotteries[_lotteryId] = Lottery(IERC20(address(0)), _amount, _fixedNum, _proportionNum, true, false, true);
    }


    function drawALottery(uint256 _lotteryId) public onlyOperator {
        if (!lotteries[_lotteryId].exist) {
            return;
        }
        require(!lotteries[_lotteryId].over, "lottery is over");
        lotteries[_lotteryId].over = true;
        if (lotteries[_lotteryId].fixedNum.length > 0) {
            for (uint i = 0; i < lotteries[_lotteryId].fixedNum.length; i++) {
                _drawALotteryByIndex(_lotteryId, i, true);
            }
        }

        if (lotteries[_lotteryId].proportionNum.length > 0) {
            for (uint i = 0; i < lotteries[_lotteryId].proportionNum.length; i++) {
                _drawALotteryByIndex(_lotteryId, i, false);
            }
        }
    }

    function drawALotteryByIndex(uint256 _lotteryId, uint256 _index) public onlyOperator {
        if (!lotteries[_lotteryId].exist) {
            return;
        }
        lotteries[_lotteryId].over = true;
        if (lotteries[_lotteryId].fixedNum.length > 0) {
            _drawALotteryByIndex(_lotteryId, _index, true);
        }
        if (lotteries[_lotteryId].proportionNum.length > 0) {
            _drawALotteryByIndex(_lotteryId, _index, false);
        }
    }

    function _drawALotteryByIndex(uint256 _lotteryId, uint256 _index, bool isFixNum) internal {
        uint256 lotteryNum = 0;
        if (isFixNum) {
            require(_index <= lotteries[_lotteryId].fixedNum.length, "lottery index out of bounds");
            require(remainLotteryInductees[_lotteryId].length >= lotteries[_lotteryId].fixedNum[_index], "the number of the inductees is smaller than lottery configuration");
            lotteryNum = lotteries[_lotteryId].fixedNum[_index];

        } else {
            require(_index <= lotteries[_lotteryId].proportionNum.length, "lottery index out of bounds");
            uint256 proportion = lotteries[_lotteryId].proportionNum[_index];
            if (proportion > 0) {
                if (proportion >= 100) {
                    proportion = 100;
                }
                lotteryNum = remainLotteryInductees[_lotteryId].length.mul(proportion).div(100);
                if (lotteryNum == 0) {
                    lotteryNum = 1;
                }
            }
        }

        if (lotteryNum == 0) {
            return;
        }

        for (uint256 i = 0; i < lotteryNum; i++) {
            uint256 inducteeNum = remainLotteryInductees[_lotteryId].length;
            uint256 latestInducteeIndex = inducteeNum - 1;

            uint256 winnerIndex = _randomNumber(inducteeNum, i);

            lotteryResults[_lotteryId][_index].push(remainLotteryInductees[_lotteryId][winnerIndex]);

            if (winnerIndex != latestInducteeIndex) {
                remainLotteryInductees[_lotteryId][winnerIndex] = remainLotteryInductees[_lotteryId][latestInducteeIndex];
            }
            remainLotteryInductees[_lotteryId].pop();
        }

        if (lotteries[_lotteryId].isEth) {
            _ethLottery(lotteries[_lotteryId].amount, lotteryResults[_lotteryId][_index]);
        } else {
            _erc20Lottery(lotteries[_lotteryId].token, lotteries[_lotteryId].amount, lotteryResults[_lotteryId][_index]);
        }
    }

    function getLotteryResults(uint256 _lotteryId, uint256 _index) public view returns (address[] memory){
        require(lotteries[_lotteryId].exist, "not exist lottery");
        require(lotteries[_lotteryId].over, "not over lottery");
        return lotteryResults[_lotteryId][_index];
    }

    function _randomNumber(uint256 _scope, uint256 _salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encode(abi.encodePacked(block.timestamp, block.difficulty), _salt))) % _scope;
    }

}