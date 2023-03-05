// SPDX-License-Identifier: MIT
pragma solidity  >=0.4.22 <0.9.0;
import "./f_Mycoin.sol";
//import "./Owner.sol";

contract WrapEth is Owner{
    Mycoin public wraptoken;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);   
    event Refund(address _sendto,uint256 _amount);
    event SetNewToken(Mycoin _newtoken,Mycoin oldtoken);

    constructor( Mycoin  _token){
        require(address(_token) != address(0));
        wraptoken = _token;        
    }
    receive() payable external {      
        require(msg.value > 0,"Must sent more than zero Eth.");
        require(wraptoken.getOwner() == address(this),"Must transfer Owner to this contact");
        wraptoken.mint(msg.sender, msg.value);
        emit TransferReceived(msg.sender, msg.value);
    }
    function refund()public{
        uint256 token_amount = wraptoken.allowance(msg.sender, address(this));
        require(token_amount > 0,"Not enough funds alowance by this contract.");
        wraptoken.burn(msg.sender, token_amount);
        payable(msg.sender).transfer(token_amount);
        emit Refund(msg.sender, token_amount);
    }

    function transferTokenOwner(address _owner) public isOwner{
        wraptoken.changeOwner(_owner);
    }

    function setNewToken(Mycoin token)public isOwner{
        require(address(token) != address(0));
        Mycoin oldtoken = wraptoken;
        wraptoken = token;
        token.changeOwner(address(this));
        oldtoken.changeOwner(msg.sender);
        emit SetNewToken(token,oldtoken);
    }
}