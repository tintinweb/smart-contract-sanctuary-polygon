// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// vault should import the Ierc20 interface from openzeppelin
interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    // Other ERC20 functions
}


contract vault {

    IWETH public immutable weth;
    IERC20 public immutable token;
    
    address public owner;

    ///0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa
    uint public totalSupply;

    
    
    mapping(address => uint) public balanceOf;
    mapping(address => uint256) public ethBalances;

    event myVaultLog(string, uint256);

    constructor(address _token, address _weth) {
        token = IERC20(_token);
        weth = IWETH(_weth);
        owner = msg.sender;
    }

    function getWethBalance() public view returns(uint) {
    return weth.balanceOf(address(this));
  }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        /*
        a = amount
        B = balance of token before deposit
        T = total supply
        s = shares to mint

        (T + s) / T = (a + B) / B 

        s = aT / B
        */
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
        /*
        a = amount
        B = balance of token before withdraw
        T = total supply
        s = shares to burn

        (T - s) / T = (B - a) / B 

        a = sB / T
        */
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
    }

   

 function wrapEth() external payable {
    uint256 ethAmount = msg.value;
    require(ethAmount > 0, "No ETH to wrap");
    
    weth.deposit{value: ethAmount}();
}

    // Approve the contract to transfer WETH on behalf of the user
    function approveVault(uint256 amount) external  {
        weth.approve(address(this), amount);
    }

    // Unwrap WETH back to ETH
    function unwrapEth(uint256 amount) external  {
        require(amount > 0, "Invalid amount");
        weth.transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

     receive() external payable {

          ethBalances[msg.sender] += msg.value;
    // accept ETH, do nothing as it would break the gas fee for a transaction
  }


}