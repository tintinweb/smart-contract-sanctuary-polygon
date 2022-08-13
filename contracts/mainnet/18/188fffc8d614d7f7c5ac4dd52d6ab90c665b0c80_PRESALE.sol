/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract PRESALE {
    
    IERC20 public token;

    bool public paused; 

    address public owner;

    uint256 public perDollarPrice;  //in decimals

    uint256 public UsdtoMatic; //one usd to matic

    mapping (address => mapping (address => bool)) public referral;

    modifier onlyOwner {
        require(owner == msg.sender,"Caller must be Ownable!!");
        _;
    }

    constructor(uint256 _price,address _presaleToken , uint _perUsdtomatic){
        owner = msg.sender;
        perDollarPrice = _price;
        token = IERC20(_presaleToken);
        UsdtoMatic = _perUsdtomatic;
    }

    //5% referral directly go to user account

    function ikeBalance(address _user) public view returns(uint){
        return token.balanceOf(_user);
    }

    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function remainingToken() public view returns(uint){
        return token.balanceOf(address(this));
    }

    //per dollar price in decimals
    function setTokenPrice(uint _price) public onlyOwner{
        perDollarPrice = _price;
    }

    //per dollar price in decimals of bnb
    function setMaticPrice(uint _price) public onlyOwner{
        UsdtoMatic = _price;
    }

    function setPause(bool _value) public onlyOwner{
        paused = _value;
    }

    function setToken(address _token) public onlyOwner{
        token = IERC20(_token);
    }

    function buyFromNative(address ref) public payable {

        require(!paused,"Presale is Paused!!");

        uint check = 1;   

        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){}
        else{
            referral[msg.sender][ref] = true;
            check = 2;
        }

        uint value = msg.value;

        uint equaltousd = value / UsdtoMatic;

        uint multiplier = perDollarPrice  * equaltousd;

        token.transfer(msg.sender,multiplier);

        if(check == 2){
            uint per5 = ( value * 5 ) / 100;
            uint per95 = ( value * 95 ) / 100;
            payable(ref).transfer(per5);
            payable(owner).transfer(per95);
        }
        else{
            payable(owner).transfer(value);
        }

    }

    function RescueFunds() public onlyOwner {
        payable(msg.sender).transfer( address(this).balance );
    }

    function RescueTokens(IERC20 _add,uint _amount,address _recipient) public onlyOwner{
        _add.transfer(_recipient,_amount);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

}