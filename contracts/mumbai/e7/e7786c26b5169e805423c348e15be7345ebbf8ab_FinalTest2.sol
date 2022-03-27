// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Blocklist.sol";
import "./ERC20Pausable.sol";

contract FinalTest2 is ERC20, Pausable, Ownable, ERC20Burnable, ERC20Blocklist{
    
    struct Frozen{
        uint256 amount;
        uint until;
    }
    
    mapping(address => Frozen[]) private frozenTokens;
    
    constructor() ERC20("FinalTest2", "FT2") {}
    
    modifier checkFrozenBalance(address account, uint256 amount){
        uint256 frozenBalance = frozenBalanceOf(account);
        uint256 balance = balanceOf(account);
        unchecked {
            require( balance - frozenBalance >= amount, "Attention: The amount you want to transfer is frozen");
        }
        _;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
    
    function mint(address _to, uint256 _amount) external onlyOwner{
        _mint(_to, _amount);
    }
    
    function setWalletRegister(address Wallet, string memory _RegOrUnReg) public payable {
         require(msg.value >= PriceOfRegister);
          require(Wallet == _msgSender());
            WalletRegisterStatus[Wallet] = _RegOrUnReg;
    }

   function setPriceOfRegister(uint256 _PriceOfRegisterSet) public onlyOwner {
      PriceOfRegister = _PriceOfRegisterSet;
    }
    function Details(string memory _newWebSite, string memory _newSourceIPFS, string memory _newAvailableInBlockchain) public onlyOwner {
       WebSite = _newWebSite;
       SourceIPFS = _newSourceIPFS;
       AvailableInBlockchain = _newAvailableInBlockchain;
    }
    function SetNotifications(string memory _newNotifications) public onlyOwner {
        Notifications = _newNotifications;
    }   
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
 }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override preventBlockedAccount checkFrozenBalance(sender, amount) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
    
    function approve(address spender, uint256 amount) public virtual override preventBlockedAccount returns (bool) {
        return super.approve(spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override preventBlockedAccount checkFrozenBalance(_msgSender(), amount) returns (bool) {
        return super.transfer(recipient, amount);
    }
    
    
    function mintAndFreeze(address _to, uint256 _amount, uint _until) external onlyOwner{
        require(_until > block.timestamp, "_until param should be greater than current block.timestamp");
        Frozen memory _frozen = Frozen(_amount, _until);
        frozenTokens[_to].push(_frozen);
        _mint(_to, _amount);
    }
    
    function frozenBalanceOf(address _account) public view returns(uint256){
        if(frozenTokens[_account].length < 1){
            return 0;
        }
        uint256 totalFrozen = 0;
        for(uint i = 0; i < frozenTokens[_account].length; i++){
            Frozen memory frozen = frozenTokens[_account][i];
            if(frozen.until >= block.timestamp){
                totalFrozen += frozen.amount;
            }
        }
        return totalFrozen;
    }
    
    function currentBlockTimestamp() public view returns(uint){
        return block.timestamp;
    }
}