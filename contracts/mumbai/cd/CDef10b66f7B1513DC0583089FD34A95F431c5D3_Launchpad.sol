pragma solidity ^0.8.0;
 import "./Burnable.sol";
 import "./Mint&Burn.sol";
 import "./PausableMint.sol";
 import "./PausableMintBurn.sol";

import "./ILaunchPad2.sol";


pragma solidity ^0.8.0;





contract Launchpad  {
    address payable public admin;
    mapping (address=>uint256) public tatalTokensByOwner;
    mapping (address=>mapping(uint256=>address)) public TokenByIndexOfOwner;
    uint256 public totalSupply;
    uint256 public fee;
    address public UpgradedContract;
    event TokenCreated(address owner, address token);
    constructor(){
        admin=payable(msg.sender);
        fee=50000000000000000;    

    }
       function transferOwnership(address admin_)external{
        require(admin==msg.sender);
        admin=payable(admin_);

    }
    function setContract(address token_)public {
        require(admin==msg.sender);
        UpgradedContract=token_;

    }
    function setFee(uint256 fee_)external  {
        require(admin==msg.sender);
        fee=fee_;
    }
    function DeployPausableBurn(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals)payable public  returns (address){
        address newToken=ILaunchPad(UpgradedContract).DeployPausableBurn{value:msg.value}( name, symbol, totalSupply_, decimals);
        syncTheData(address(newToken));
        emit TokenCreated(msg.sender,newToken);
        return newToken;
    }
     function DeployPausableMintBurn(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals)payable public  returns (address){
        address newToken=ILaunchPad(UpgradedContract).DeployPausableMintBurn{value:msg.value}( name, symbol, totalSupply_, decimals);
        syncTheData(address(newToken));
        emit TokenCreated(msg.sender,newToken);
        return newToken;
    }
     
    function DeployERC20(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        
        ERC20 Contract = new ERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));
        return Contract;

    }
    function DeployBurnable(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        
        ERC20 Contract = new BurnableERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));

        return Contract;

    }
    function DeployMintable(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        
        ERC20 Contract = new MintableERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));
        return Contract;

    }
    function DeployMintBurn(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        
        ERC20 Contract = new MintBurnERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));
        return Contract;

    }
    function DeployPausable(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
        
        ERC20 Contract = new PausableERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));
        return Contract;

    }
    function DeployPausableMint(string calldata name, string calldata symbol,uint256 totalSupply_,uint8 decimals) payable public  returns (ERC20){
        require(msg.value>=fee);
       
        ERC20 Contract = new PausableMintERC20(name,symbol,totalSupply_,decimals);
        syncTheData(address(Contract));
        emit TokenCreated(msg.sender,address(Contract));
        return Contract;

    }

    
    function syncTheData(address Contract)internal{
        uint256 index=tatalTokensByOwner[msg.sender];
        totalSupply += 1;        
        TokenByIndexOfOwner[msg.sender][index]=Contract;
        tatalTokensByOwner[msg.sender]+=1;

    }
    function getAllFee()external{
        admin.transfer(address(this).balance);
    }


}