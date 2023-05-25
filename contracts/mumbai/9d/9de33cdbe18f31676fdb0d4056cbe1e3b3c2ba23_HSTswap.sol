/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract HSTswap {
    using SafeMath for uint256;

    address public signer;
    address public nativeAddress = 0x5b321B410060743ae1d4961514C429be0887D2Cc;
    address public bnb = 0x0000000000000000000000000000000000000000;
    BEP20 public native = BEP20(nativeAddress);  // HST Coin
    
    struct Coins{
        string symbol;
        uint256 pp;
        uint256 sp;
        bool isExists;
        bool isNative;
    }

    mapping(address => Coins) public coins;

    event Swap(address buyer, string from, string to, uint256 famount, uint256 tamount);
    
   
    modifier onlySigner(){
        require(msg.sender == signer,"You are not authorized signer.");
        _;
    }

    modifier security{
        uint size;
        address sandbox = msg.sender;
        assembly  { size := extcodesize(sandbox) }
        require(size == 0,"Smart Contract detected.");
        _;
    }

    constructor() public {
        
        signer = msg.sender;

        coins[nativeAddress].symbol = "HST";
        coins[nativeAddress].pp = 120;
        coins[nativeAddress].sp = 110;
        coins[nativeAddress].isExists = true;
        coins[nativeAddress].isNative = true;

        coins[bnb].symbol = "BNB";
        coins[bnb].pp = 20;
        coins[bnb].sp = 10;
        coins[bnb].isExists = true;
        coins[bnb].isNative = false;
    
    }
    

    function swap(address _from, address _to, uint256 _amount) public security{
        require(coins[_from].isExists==true,"Invalid coin");
        require(coins[_to].isExists==true,"Invalid coin");
        uint256 scaledAmount = (coins[_to].isNative==true)?_amount.mul(coins[_from].pp).div(100):_amount.mul(coins[_from].sp).div(100);
        
        if(_to==bnb){
            require(scaledAmount<=address(this).balance,"Insufficient tokens!");
            BEP20(_from).transferFrom(msg.sender,address(this),_amount);
            msg.sender.transfer(scaledAmount);
        }
        else{
            require(scaledAmount<=BEP20(_to).balanceOf(address(this)),"Insufficient tokens!");
            if(_from==bnb){
                // transfer bnb to contract
            }
            else{
                BEP20(_from).transferFrom(msg.sender,address(this),_amount);
            }
            BEP20(_to).transferFrom(address(this),msg.sender,scaledAmount);
        }
        
        emit Swap(msg.sender, coins[_from].symbol, coins[_to].symbol, _amount.div(1e18), scaledAmount.div(1e18));
        
    }

    
    function setLocal(address _coin, uint256 _pp, uint _sp) external onlySigner security{
        require(coins[_coin].isExists==true,"Coin does not exists!");
        // overrides pp and sp only, not available for symbol, isExists and isNative.
        coins[_coin].pp = _pp;
        coins[_coin].sp = _sp;
    }

    function allowCoin(address _coin, string memory _sym, uint256 _pp, uint _sp) external onlySigner security{
        require(coins[_coin].isExists==false,"Coin already exists!");
        coins[_coin].pp = _pp;
        coins[_coin].sp = _sp;
        coins[_coin].symbol = _sym;
        coins[_coin].isExists = true;
        coins[_coin].isNative = false;
    }

    function sell(address payable buyer, address _coin, uint _amount) external onlySigner security{
        if(_coin==bnb){
            buyer.transfer(_amount);
        }
        else{
            BEP20(_coin).transfer(buyer, _amount);
        }
        
    }
   
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}