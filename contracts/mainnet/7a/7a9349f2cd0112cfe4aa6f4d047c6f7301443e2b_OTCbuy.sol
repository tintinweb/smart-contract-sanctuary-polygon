// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./getpriceToken.sol";

contract OTCbuy is Ownable, ReentrancyGuard, PriceInterface{
    // ============= VARIABLES ============

    // Contract address of the staked token
    IERC20 public immutable purchaseToken;

    bool private active;

    uint256 public minimum_buy=500*1e18;

    uint256 public Max_tokens_sold=1000000*1e18;

    uint256 public total_tokens_sold=0;

    mapping(address => bool) public whitelist;

    modifier isVaildReferer( address _ref ){
        require(whitelist[_ref]==true);
        _;
    }

    modifier isActive(  ){
        require( active == true );
        _;
    }

    modifier isInactive(  ){
        require( active == false );
        _;
    }

    event puchaseEvent( address indexed _buyer , address indexed _referer , uint256 _value);

    constructor(address _purchaseToken, address pairuniswap) PriceInterface(pairuniswap) {
        purchaseToken = IERC20(_purchaseToken);
        active=true;
    }

    function activate() onlyOwner isInactive public returns ( bool ) {
        active = true;
        return true;
    }

    function inactivate() onlyOwner isActive public returns ( bool ) {
        active = false;
        return true;
    }

    function getActive() public view returns(bool){
        return active;
    }

    function add_referer_whitelist(address[] memory listAdress) onlyOwner public returns (bool) {
        for(uint i=0;i<listAdress.length;i++){
            address referer=listAdress[i];
            whitelist[referer]=true;
        }
        return true;
    }

    function remove_referer_whitelist(address[] memory listAdress) onlyOwner public returns (bool) {
        for(uint i=0;i<listAdress.length;i++){
            address referer=listAdress[i];
            whitelist[referer]=false;
        }
        return true;
    }

    function change_minimum_buy(uint256 _minimum) onlyOwner public returns (bool) {
        minimum_buy=_minimum;
        return true;
    }

    function purchase(address _referer) isActive isVaildReferer( _referer ) payable public returns (bool)
    {
        require(msg.value>=minimum_buy,"Must respect the minimum purchase of MATIC");
        uint256 lastPriceToken=getTokenPrice();
        uint256 tokens=(msg.value*1e18)/lastPriceToken;

        require((tokens+total_tokens_sold)<=Max_tokens_sold,"Sold out");

        purchaseToken.transfer(msg.sender,tokens);
        total_tokens_sold=total_tokens_sold+tokens;

        payable(_referer).transfer(msg.value*15/100);
        payable(_owner).transfer(msg.value*85/100);
        
        emit puchaseEvent( msg.sender , _referer , msg.value);
        return true;
    }  

    function return_To_Owner(uint256 _amount)  external onlyOwner {
        purchaseToken.transfer(_owner, _amount);
    }

}