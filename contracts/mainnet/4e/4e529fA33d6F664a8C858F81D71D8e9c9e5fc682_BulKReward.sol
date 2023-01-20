/**
 *Submitted for verification at polygonscan.com on 2023-01-20
*/

pragma  solidity >=0.4.22 <0.9.0;
// SPDX-License-Identifier: Unlicensed
interface IERC20 {
function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract  BulKReward  is  Context ,Ownable {
    uint256 public  DetlaG=10000000000000000000000000;
    uint public _decimal=3;
    address[]  wad; // store as an array
    IERC20 _token;
    event _comments (string  buy, uint256 value);
    address payable public   _marker;
       constructor(address Token )   {
        _token = IERC20(Token);
        _marker=payable(msg.sender);
        
    }
     function toDecimal(uint dec) external  onlyOwner
    {
       _decimal=dec;
    }

    function UpdateDeltaGA(uint256 dt) external onlyOwner
     {
       DetlaG=dt;
     }

 

    /* WithDraw Token - Working*/
    function selfWithdrawToken(address _tokenContract, uint256 _amount) external  onlyOwner 
    {
        IERC20 tokenContract = IERC20(_tokenContract);
        require(_tokenContract != address(this), "Self withdraw");
        uint256 TakeAmnt=_amount*(10**_decimal);
        tokenContract.approve(address(this), TakeAmnt);
        tokenContract.transferFrom(address(this), _marker, TakeAmnt);
   }

  

   receive() external payable {}
 
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
         require(_tokenContract != address(this), "Self withdraw");
        tokenContract.transfer(msg.sender, _amount);
    }
    
       
    event comments (string comments ,uint256 value);
    event addreComments(string comments ,address value);
    //Bulk Rewards 
      function airDrop(uint256 amount) onlyOwner public returns (bool) {
      
       uint256   amountVal = amount*1000;
       uint256 addressCount = wad.length;
       uint256 tokenBalance=_token.balanceOf(address(this));
       uint256 totalWantSendToken = addressCount*amountVal;
       require(totalWantSendToken <= tokenBalance, "Total amount must be less than your total token amount.");
         for (uint256 i = 0; i < addressCount; i++) 
         {
            address sendAddress = wad[i];
             emit addreComments("sendAddress",sendAddress);
             _token.transfer(sendAddress, amountVal);
         }
    return true;
     }
     
    
     function _GetBalanceOFContract() external view returns(uint) {
        return _token.balanceOf(address(this));
    }
    
    
    function setStore(address[] memory _wad) public {
        wad = _wad;
    }

    function displayALlArrayElemnts() public view  returns(address[] memory){
        return wad;
    }

 function removeSingleAdress(uint index) public {
        delete wad[index]; 
    }
    

    function addRewardHolder() payable public    {

 
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         

         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);


        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        
         wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        wad.push(0x411E88B5EF404a2CE57A4801da33Deb91cCF53E7);
        
    }
    
}