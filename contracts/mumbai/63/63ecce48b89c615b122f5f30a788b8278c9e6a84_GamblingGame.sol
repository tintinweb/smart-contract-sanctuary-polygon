/**
 *Submitted for verification at polygonscan.com on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Giao diện của token RVND
interface IRVND {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GamblingGame {
    // Biến lưu trữ số tiền cược tối thiểu
    uint public minBet = 1000; // 1000 RVND
    
    // Biến lưu trữ số tiền trong hợp đồng
    uint public balance;
    
    // Biến lưu trữ số người chơi
    uint public numPlayers;
    
    // Biến lưu trữ địa chỉ của token RVND
    address public rvndAddress;
    
    // Biến lưu trữ giao diện của token RVND
    IRVND public rvnd;
    
    // Cấu trúc lưu trữ thông tin của mỗi người chơi
    struct Player {
        address payable addr; // Địa chỉ của người chơi
        uint betAmount; // Số tiền cược
        bool betChoice; // Lựa chọn của người chơi: true là đầu, false là đuôi
    }
    
    // Mảng lưu trữ danh sách người chơi
    Player[] public players;
    
    // Sự kiện được phát ra khi có người chơi tham gia
    event PlayerJoined(address indexed player, uint betAmount, bool betChoice);
    
    // Sự kiện được phát ra khi có kết quả xổ số
    event LotteryResult(bool result, address[] winners, uint reward);
    
    // Hàm khởi tạo hợp đồng với tham số là địa chỉ của token RVND
    constructor(address _rvndAddress) {
        balance = 0;
        numPlayers = 0;
        rvndAddress = _rvndAddress;
        rvnd = IRVND(rvndAddress); // Khởi tạo giao diện của token RVND
    }
    
    // Hàm cho phép người chơi tham gia trò chơi với số tiền cược và lựa chọn của họ
    function joinGame(bool _betChoice) public {
        // Kiểm tra số tiền cược phải lớn hơn hoặc bằng số tiền cược tối thiểu
        require(rvnd.balanceOf(msg.sender) >= minBet, "Bet amount must be greater than or equal to minimum bet");
        
        // Kiểm tra số tiền trong hợp đồng phải đủ để thanh toán cho tất cả người chơi nếu họ thắng
        require(balance >= (numPlayers + 1) * minBet * 95 / 100, "Contract balance is not enough to pay for all players");
        
        // Chuyển số tiền cược từ người chơi đến hợp đồng bằng hàm transferFrom của token RVND
        require(rvnd.transferFrom(msg.sender, address(this), minBet), "Transfer failed");
        
        // Tạo một người chơi mới với địa chỉ, số tiền cược và lựa chọn của người gửi
        Player memory newPlayer = Player(payable(msg.sender), minBet, _betChoice);
        
        // Thêm người chơi mới vào mảng người chơi
        players.push(newPlayer);
        
        // Cập nhật số tiền trong hợp đồng và số người chơi
        balance += minBet;
        numPlayers++;
        
        // Phát ra sự kiện người chơi tham gia
        emit PlayerJoined(msg.sender, minBet, _betChoice);
    }
    
    // Hàm cho phép chủ sở hữu hợp đồng thực hiện xổ số
    function runLottery() public {
        // Kiểm tra số người chơi phải lớn hơn 0
        require(numPlayers > 0, "No players in the game");
        
        // Tạo một số ngẫu nhiên từ 0 đến 1 dựa trên số khối hiện tại
        uint random = uint(keccak256(abi.encodePacked(block.number))) % 2;
        
        // Chuyển số ngẫu nhiên thành kết quả xổ số: true là đầu, false là đuôi
        bool lotteryResult = random == 1;
        
        // Tạo một mảng để lưu trữ danh sách người thắng
        address[] memory winners;
        
        // Duyệt qua mảng người chơi để tìm ra những người có lựa chọn trùng với kết quả xổ số
        for (uint i = 0; i < numPlayers; i++) {
            if (players[i].betChoice == lotteryResult) {
            }
        }
        
        // Tính toán phần thưởng cho mỗi người thắng bằng cách chia đều số tiền trong hợp đồng cho số người thắng
        uint reward = balance / winners.length;
        
        // Duyệt qua mảng người thắng để gửi phần thưởng cho họ bằng hàm transfer của token RVND
        for (uint i = 0; i < winners.length; i++) {
            // Gửi phần thưởng cho người thắng
            require(rvnd.transfer(winners[i], reward), "Transfer failed");
            
            // Trừ đi số tiền trong hợp đồng
            balance -= reward;
        }
        
        // Phát ra sự kiện kết quả xổ số
        emit LotteryResult(lotteryResult, winners, reward);
        
        // Xóa mảng người chơi và đặt lại số người chơi về 0
        delete players;
        numPlayers = 0;
    }
}