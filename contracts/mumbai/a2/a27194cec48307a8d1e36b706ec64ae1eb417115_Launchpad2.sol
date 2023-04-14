pragma solidity ^0.8.0;

 import "./PausableMintBurn.sol";
pragma solidity ^0.8.0;
contract Launchpad2  {
    address payable public admin;
    uint256 public fee;
    constructor(){
        admin=payable(msg.sender); 
        fee=50000000000000000;  

    }
    function setFee(uint256 fee_)external  {
        require(admin==msg.sender);
        fee=fee_;
    }
    
    function DeployPausableBurn(string calldata name, string calldata symbol,uint256 totalSupply_,uint256 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);       
        ERC20 Contract = new PausableBurnERC20(name,symbol,totalSupply_,decimals);
        return Contract;

    }
    function DeployPausableMintBurn(string calldata name, string calldata symbol,uint256 totalSupply_,uint256 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        ERC20 Contract = new PausableMintBurnERC20(name,symbol,totalSupply_,decimals);
        return Contract;

    }
    function getAllFee()external{
        admin.transfer(address(this).balance);
    }
  


}