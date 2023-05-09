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

interface DepositableERC20 is IERC20 {
  function deposits() external payable;
}


contract vault {
    address public owner;

    ///0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa
    uint public totalSupply;


    IERC20 public immutable token;

    address public wethAddress = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;

    DepositableERC20 wethToken = DepositableERC20(wethAddress);

    
    mapping(address => uint) public balanceOf;

    event myVaultLog(string, uint256);

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    function getWethBalance() public view returns(uint) {
    return wethToken.balanceOf(address(this));
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

    receive() external payable {
    // accept ETH, do nothing as it would break the gas fee for a transaction
  }

  function wrapETH() public {
    require(msg.sender == owner, "Only the owner can convert ETH to WETH");
    uint ethBalance = address(this).balance;
    require(ethBalance > 0, "No ETH available to wrap");
    emit myVaultLog('wrapETH', ethBalance);
    wethToken.deposits{ value: ethBalance }();
  }
}