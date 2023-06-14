/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// @title HST Swap
// @title Website https://swap.hsttoken.pro/
// @title Interface : Token Standard #20. https://github.com/ethereum/EIPs/issue

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
    address public nativeAddress = 0x99AcEf0A0284FA24C60f01d188EDC6Eb84424fd7; // Native coin address
    address public bnb = 0x0000000000000000000000000000000000000000; // Zero address used as BNB
    address public busd = 0xe36Bccd8093BcF3EdB2981d1b49CAe6B1ED2c357; // BUSD coin address
    BEP20 public native = BEP20(nativeAddress);  // Native coin on this contract
    
    address payable slipper1 = 0x1C62daf74Fd19Ac7eD8b013bD95c02933dA0B7C8;
    address payable slipper2 = 0x19826Ea42a927541a9c21682A109b073EeDa6F81;
    address payable slipper3 = 0xD2a821D113523BA400848D6062ED03a2134366EA;
    address payable slipper4 = 0xD4c1Fca98b551C65F50a3331F2581D75b840A57F;
    address payable slipper5 = 0x5fAC2FBC3eD6bb68AeF80310E83C3f26552dD5c4;

    uint8 slippageCharge = 2;

    struct Coins{
        string symbol;
        uint256 pp;
        uint256 sp;
        bool isExists;
        bool isNative;
    }

    mapping(address => Coins) public coins;

    event Swap(address buyer, string from, string to, uint256 famount, uint256 tamount);
    event Sell(address buyer, address coin, uint256 amount);
    
    // @dev Detects Authorized Signer.
    modifier onlySigner(){
        require(msg.sender == signer,"You are not authorized signer.");
        _;
    }

    // @dev Returns coin balance on this contract.
    function getBalanceSheet(address _coin) public view returns(uint256 bal){
        require(coins[_coin].isExists,"Invalid Coin!");
        if(_coin==bnb){
            bal = address(this).balance;
        }
        else{
            bal =  BEP20(_coin).balanceOf(address(this));
        }
        return bal;
    }

    // @dev Restricts unauthorized access by another contract.
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
        coins[nativeAddress].isExists = true;
        coins[nativeAddress].isNative = true;

        coins[bnb].symbol = "BNB";
        coins[bnb].pp = 1100;
        coins[bnb].sp = 900;
        coins[bnb].isExists = true;
        coins[bnb].isNative = false;

        coins[busd].symbol = "BUSD";
        coins[busd].pp = 8200;
        coins[busd].sp = 8400;
        coins[busd].isExists = true;
        coins[busd].isNative = false;
    
    }
    
    // @dev Swap coins only which are available to swap in this contract.
    function swap(address _from, address _to, uint256 _amount) public payable security{
        require(coins[_from].isExists==true,"Invalid coin");
        require(coins[_to].isExists==true,"Invalid coin");
        
        require(coins[_from].isNative==true && coins[_to].isNative==false || coins[_from].isNative==false && coins[_to].isNative==true,"Swapping native coin only.");
        uint256 scaledAmount = 0;
        uint256 slippageAmount = 0;
        if(coins[_to].isNative==true){
            scaledAmount = _amount.mul(coins[_from].pp).div(100);
            slippageAmount = _amount.mul((coins[_from].pp.div(100)).div((coins[busd].pp).div(100)));
        }
        else if(coins[_to].isNative==false){
            scaledAmount = _amount.div((coins[_to].sp).div(100));
            slippageAmount = _amount.div((coins[_to].sp.div(100)).div((coins[busd].sp).div(100)));
        }

        if(_to==bnb){
            require(scaledAmount<=address(this).balance,"Insufficient coins!");
            require(BEP20(_from).transferFrom(msg.sender,address(this),_amount));
            msg.sender.transfer(scaledAmount);
            slippage(slippageAmount.mul(slippageCharge).div(100));
        }
        else{
            require(scaledAmount<=BEP20(_to).balanceOf(address(this)),"Insufficient coins!");
            if(_from!=bnb){
                require(BEP20(_from).transferFrom(msg.sender,address(this),_amount));
            }
            
            BEP20(_to).transfer(msg.sender,scaledAmount);
            slippage(slippageAmount.mul(slippageCharge).div(100));
        }
        
        emit Swap(msg.sender, coins[_from].symbol, coins[_to].symbol, _amount.div(1e18), scaledAmount.div(1e18));
    }

    // @dev Slippage charge to slippers.
    function slippage(uint256 _amount) internal{
        uint256 _slip = _amount.div(5);
        BEP20(busd).transfer(slipper1,_slip);
        BEP20(busd).transfer(slipper2,_slip);
        BEP20(busd).transfer(slipper3,_slip);
        BEP20(busd).transfer(slipper4,_slip);
        BEP20(busd).transfer(slipper5,_slip);
        
    }

    // @dev Register new coin to swap on this contract
    function registerCoin(address _coin, string memory _sym, uint256 _pp, uint _sp) external onlySigner security{
        require(coins[_coin].isExists==false,"Coin already exists!");
        coins[_coin].pp = _pp;
        coins[_coin].sp = _sp;
        coins[_coin].symbol = _sym;
        coins[_coin].isExists = true;
        coins[_coin].isNative = false;
    }

    // @dev Overrides pp and sp only, not available for symbol, isExists and isNative.
    // @dev Not application for native coin.
    function setLocal(address _coin, uint256 _pp, uint _sp) external onlySigner security{
        require(coins[_coin].isExists==true && coins[_coin].isNative==false,"Either coin is native or coin does not exists!");
        coins[_coin].pp = _pp;
        coins[_coin].sp = _sp;
    }

    // @dev Settle coin to swap on this contract
    function coinSettlement(address _coin, bool action) external onlySigner security{
        require(coins[_coin].isNative==false,"Native coin settlement is not allowed.");
        coins[_coin].isExists = action;
    }

    // @dev Overrides Slippage on this contract
    function slippageSettlement(uint8 _slip) external onlySigner security{
        slippageCharge = _slip;
    }

    // @dev Sell coins directly to buyer instead of swapping
    function sell(address payable buyer, address _coin, uint _amount) external onlySigner security{
        if(_coin==bnb){
            buyer.transfer(_amount);
        }
        else{
            BEP20(_coin).transfer(buyer, _amount);
        }
        emit Sell(buyer, _coin, _amount);
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