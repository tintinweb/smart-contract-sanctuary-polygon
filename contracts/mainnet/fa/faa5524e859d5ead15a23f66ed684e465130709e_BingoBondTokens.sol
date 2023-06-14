/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

/**
 宾果零和博弈合约地址：0xa3cF335faAc9f7a3E900C4d1a7aB82C841922313
BINGO/MATIC-LP合约地址：0x3f4cEd266ca0f84EEAfb317Adee5E2Da17F7DE8d
*/
//SPDX-License-Identifier: MIT
pragma solidity >= 0.6.9;

library TransferHelper {
    
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
    
    function safeTransferETH(address to, uint256 value) internal {
        // solium-disable-next-line
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH(HT/BNB)_TRANSFER_FAILED");
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint);
}

contract BingoBondTokens {
    
    string public name     = "BingoBondTokens";
    string public symbol   = "BBT";
    uint8  public decimals = 6;
    
    address public BINGO_MATIC_LP;
    address public _OWNER_;
    mapping(address => uint256) public balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint256 public totalSupply;
    
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    
    constructor(address _BINGO_MATIC_LP, address _OWNER) public {
        BINGO_MATIC_LP = _BINGO_MATIC_LP;
        _OWNER_ = _OWNER;
    }
    
    function BingoTotalDeposit() public view returns (uint) {
        return IERC20(BINGO_MATIC_LP).balanceOf(address(this));
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public returns (bool) {
        return transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool)
    {
        require(balanceOf[from] >= value);

        if (from != msg.sender && allowance[from][msg.sender] != uint(-1)) {
            require(allowance[from][msg.sender] >= value);
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
        return true;
    }
    
    function deposit(uint256 payAmount) public returns (uint256 recevieAmount) {
        require(payAmount > 0, "Invalid Pay Amount");
        TransferHelper.safeTransferFrom(BINGO_MATIC_LP, msg.sender, address(this), payAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender] + payAmount;
        totalSupply += payAmount;
        recevieAmount = payAmount;
        emit Deposit(msg.sender, payAmount);
        emit Transfer(address(0), msg.sender, payAmount);
    }
    
    function withdraw(uint256 withdrawAmount) public returns (uint256 recevieAmount) {
        require(withdrawAmount > 0, "Invalid Pay Amount");
        require(withdrawAmount <= balanceOf[msg.sender], "Insufficient balance");
        balanceOf[msg.sender] = balanceOf[msg.sender] - withdrawAmount;
        TransferHelper.safeTransfer(BINGO_MATIC_LP, msg.sender, withdrawAmount);
        recevieAmount = withdrawAmount;
        totalSupply -= withdrawAmount;
        emit Withdrawal(msg.sender, withdrawAmount);
        emit Transfer(msg.sender, address(0), withdrawAmount);
    }
    
    function recoverOther(address payable token) public {
        require(msg.sender == _OWNER_, "Invalid Owner");
        require(token !=BINGO_MATIC_LP && token != address(this), "Invalid token");
        if(token == address(0)) {
            TransferHelper.safeTransferETH(_OWNER_, address(this).balance);
        } else {
            TransferHelper.safeTransfer(token, _OWNER_, IERC20(token).balanceOf(address(this)));
        }
    }
}