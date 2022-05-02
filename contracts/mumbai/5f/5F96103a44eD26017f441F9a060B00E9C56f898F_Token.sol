// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";

contract Token is ERC20, ERC20Burnable, Ownable,Pausable  {
    constructor(string memory tokenName,string memory tokenSymbol) 
        ERC20(tokenName, tokenSymbol)  {}  
   

    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        _mint(to, amount);
    } 

    function burn(uint256 amount) public override virtual whenNotPaused {
        ERC20Burnable.burn(amount);
    }
    
    function burnFrom(address account, uint256 amount) public override virtual whenNotPaused   {
        ERC20Burnable.burnFrom(account, amount);
    }

    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
       
        return ERC20.transfer(to,amount);
    }

    function transferFrom(address from,address to,uint256 amount) public virtual override whenNotPaused returns (bool) {
        return ERC20.transferFrom(from,to,amount);
    }

    function approve(address spender, uint256 amount)public virtual override whenNotPaused returns (bool){
        return ERC20.approve(spender,amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue)public virtual override whenNotPaused returns (bool){
        return ERC20.increaseAllowance(spender,addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return ERC20.decreaseAllowance(spender,subtractedValue);
    }
    function pause() public onlyOwner{
       _pause();
    }
    
    function unpause() public onlyOwner{
       _unpause();
    }  
}

contract WrapEth is Ownable{
    Token public wraptoken;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);   
    event Refund(address _sendto,uint256 _amount);
    event SetNewToken(Token _newtoken,Token oldtoken);
    constructor(Token _token){
        require(address(_token) != address(0));
        wraptoken = _token;
    }
    receive() payable external {      
        require(msg.value > 0,"Must sent more than zero Eth.");
        require(wraptoken.owner() == address(this),"Must transfer Owner to this contact");
        wraptoken.mint(msg.sender, msg.value);
        emit TransferReceived(msg.sender, msg.value);
    }
    function refund()public{
        uint256 token_amount = wraptoken.allowance(msg.sender, address(this));
        require(token_amount > 0,"Not enough funds alowance by this contract.");
        wraptoken.burnFrom(msg.sender, token_amount);
        payable(msg.sender).transfer(token_amount);
        emit Refund(msg.sender, token_amount);
    }

    function transferTokenOwner(address _owner) public onlyOwner{
        wraptoken.transferOwnership(_owner);
    }

    function setNewToken(Token token)public onlyOwner{
        require(address(token) != address(0));
        Token oldtoken = wraptoken;
        wraptoken = token;
        token.transferOwnership(address(this));
        emit SetNewToken(token,oldtoken);
    }
}