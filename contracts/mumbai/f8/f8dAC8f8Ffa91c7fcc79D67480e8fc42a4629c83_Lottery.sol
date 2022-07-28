/**
 *Submitted for verification at polygonscan.com on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Lottery {

    struct LotteryInfo {
        address owner;
        uint256 betAmount;
        uint256 ranmdom;
        uint256 betTime;
    }

    address [] public player;
    uint public participants;	// 현재 베팅한 사람 수
    address public owner;
    uint256 public totalValueBet;

    IERC20Token private rewardToken;
    IERC20Token private betToken;

    mapping(address => LotteryInfo) public betOf;

    constructor(address btToken, address rwToken) {
        betToken = IERC20Token(btToken);
        rewardToken = IERC20Token(rwToken);
        owner = msg.sender;
    }

    event BetLottey(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueBet
    );
    event Winning(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );

    function randomNumber(uint256 _amount) public {
        require(
            betOf[msg.sender].betAmount == 0,
            "Already have a betting record"
        );
        // 최소 1 ERC20 토큰 배팅 가능
        // 1e18 = 1000000000000000000
        require(_amount >= 1e18, "Insufficient bet balance");

        uint randNonce = 0;

        betOf[msg.sender] = LotteryInfo(
            // 호출자
            msg.sender,
            // 배팅 수량
            _amount,
            // 난수 생성
            uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 100,
            // 호출 시간
            block.timestamp
        );
        // 계약 주소로 배팅 금액 transfer
        betToken.transferFrom(msg.sender, address(this), _amount);
        // 현재 배팅 된 금액 +
        totalValueBet = totalValueBet + _amount;
        // 배팅 인원 Count ++
        participants++;
        // 배팅 Events 등록
        emit BetLottey(msg.sender, _amount, block.timestamp, totalValueBet);
    }

    function closest2Random(string memory _random) public  onlyOwner returns(address) {
        // Contract Owner만 실행 가능
        require(msg.sender == owner, "Only the contract owner can execute");
        // 참여자가 두명보다 많아야 실행 가능
        require(participants >= 2, "Must have at least 2 participants");

    }

    modifier onlyOwner() {
        // Owner만 함수를 사용할 수 있음
        _;
    }
}