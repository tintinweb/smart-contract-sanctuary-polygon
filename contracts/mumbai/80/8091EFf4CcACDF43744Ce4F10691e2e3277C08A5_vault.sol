/**
 *Submitted for verification at polygonscan.com on 2022-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// ERC20 Interface 정의
interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract vault {
    // 구조체는 여러 변수를 그룹화할 수 있는 사용자 지정 데이터 형식
    struct VaultInfo {
        address owner;
        uint256 lockedAmount;
        uint256 lockTime;
    }

    IERC20Token private vaultToken;
    // Read 전용
    address public owner;
    // Read 전용
    uint256 public totalValueLocked;

    // address가 키가 되는 쌍의 mapping
    mapping(address => VaultInfo) public lockOf;

    // Event 등록
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );

    // 생성자는 생성자 키워드 를 사용하여 선언된 특수 함수
    // 선택적 함수이며 계약의 상태 변수를 초기화하는 데 사용
    constructor(address vt) {
        vaultToken = IERC20Token(vt);
        owner = msg.sender;
    }

    // 연결 된 Token의 balance 조회
    function balanceOf() public view virtual returns (uint256) {
        return vaultToken.balanceOf(msg.sender);
    }

    function lock(uint256 _amount, uint256 _lockPeriod) public {
        // 호출자의 lock amount가 0이 아니라면 에러 리턴
        require(
            lockOf[msg.sender].lockedAmount == 0,
            "You have already staked"
        );
        // 1e18 = 1000000000000000000 && 입력 수량이 1e18보다 같거나 크지 않으면 에러 리턴
        require(_amount >= 1e18, "You cannot stake nothing");
        lockOf[msg.sender] = VaultInfo(
            msg.sender,
            // 입력 받은 수량
            _amount,
            // 현재 시간 + 입력 받은 unix timestamp 값
            block.timestamp + _lockPeriod
        );
        // 1. 호출자 2. 계약 주소 3. 입력 수량
        vaultToken.transferFrom(msg.sender, address(this), _amount);
        totalValueLocked = totalValueLocked + _amount;
        emit Deposit(msg.sender, _amount, block.timestamp, totalValueLocked);
    }
    
    function withdraw() public {
        // 호출자의 lock amount가 0보다 크지 않으면 에러 리턴
        require(
            lockOf[msg.sender].lockedAmount > 0,
            "You are not staking anything"
        );
        // 호출자의 lock timestamp가 현재 block timestamp보다 같거나 크지 않으면 에러 리턴
        require(
            block.timestamp >= lockOf[msg.sender].lockTime,
            "Assets are still locked"
        );
        vaultToken.transfer(msg.sender, lockOf[msg.sender].lockedAmount);
        totalValueLocked = totalValueLocked - lockOf[msg.sender].lockedAmount;
        emit Withdraw(
            msg.sender,
            lockOf[msg.sender].lockedAmount,
            block.timestamp,
            totalValueLocked
        );
        lockOf[msg.sender].lockedAmount = 0;
    }

    event tokenWithdrawalComplete(address indexed user, uint256 amount);

    // 전체 출금 기능
    function withDrawAll() public {
        // Contract Owner만 실행 가능
        require(owner == msg.sender, "Only the contract owner can execute");
        require(lockOf[msg.sender].lockedAmount > 0, "User doesnt has funds on this vault");
        uint256 amount = lockOf[msg.sender].lockedAmount;
        require(vaultToken.transfer(msg.sender, amount), "the transfer failed");
        lockOf[msg.sender].lockedAmount = 0;
        emit tokenWithdrawalComplete(msg.sender, amount);
    }
}