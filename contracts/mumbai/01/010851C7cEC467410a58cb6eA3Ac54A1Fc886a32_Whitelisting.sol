// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";


contract Whitelisting is Ownable{

    //1 is for dontVerify
    //2 is for verify
    //3 is for verifyWithSmartContract
    //will denote the method for whitelisting in smart contract

    Ownable ownable;
    
    uint256 public identifier = 0;  // initially set to 0
    bool public registerUserEnabled = false;

    address public deployer;
    

    mapping (address => bool) public VerifyAddressForWhitelisting;  //for identifier 1
    mapping (address => bool) verifyAddress;  // for identifier 2

    //bytes32[] rootHashesForVerifyUsingContract; //for verifying with identifier 3
    mapping(bytes32 => bool) rootHashesForVerifyUsingContract;   //for verifying with identifier 3

    modifier moduleAccess(uint256 idType){
        require(identifier == idType, "Invalid identifier");
        _;
    }
   
    modifier onlyOwner() override {
        require(
        ownable.verifyOwner(msg.sender) == true || 
        verifyOwner(msg.sender) == true,
        "Caller is not the Owner." );
        _;
    }
    

    modifier onlyDeployer() {
        require(msg.sender == deployer, 
        "Caller in not deployer"
        );
        _;
    } 

    constructor() {
        deployer = msg.sender;
    }

    function setOwnable(address ownable_Address) public onlyDeployer{
        // require(msg.sender == deployer);
        ownable = Ownable(ownable_Address);
    }   

    //onlyOwner
    function setWhitelistType(uint256 identifierType) external onlyOwner{
        require (identifierType > 0 && identifierType <= 3, "wrong parameter passed");
        identifier = identifierType;
    }
    
    // Don't verify module start  - identifier 1
    function registerUser(address addr, uint256 id) external moduleAccess(id){
        require(registerUserEnabled == true, "registerUser is disabled.");
        require(VerifyAddressForWhitelisting[addr] = false, "User is already registered");
        VerifyAddressForWhitelisting[addr] = true;
    }
    
    function setRegisterUserEnabled() external onlyOwner{
        registerUserEnabled = !registerUserEnabled;
    }
    // Don't verify module end 

    

    //Verify module start   - identifier 2
    function addAddresses(bytes memory addresses, uint256 id) external moduleAccess(id) onlyOwner {
        address[] memory walletAddressesList = abi.decode(addresses, (address[]));
        for(uint i = 0; i < walletAddressesList.length; i++){
        verifyAddress[walletAddressesList[i]] = true;
        }
    }

    function statusOfAddress(address addr) external view returns(bool){
        return verifyAddress[addr];
    }
    //Verify module end


    //VerifyWithSmartContract module start - identifier 3

    function addRootHashForVerifyUsingContract(bytes32 newRootHash, uint256 id) external moduleAccess(id) onlyOwner {
        require(rootHashesForVerifyUsingContract[newRootHash] == false, "Root Hash is already in the list.");       
        rootHashesForVerifyUsingContract[newRootHash] = true;
    }

    function getRootHashesForVerifyUsingContract_status(bytes32 rootHash) public view returns(bool){
        return rootHashesForVerifyUsingContract[rootHash];
    }
    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// abstract contract Context {
   
// }

contract Ownable  {
    address private _owner;
    uint256 public totalOwners;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(address => bool) private owners;

    constructor() {
        _transferOwnership(_msgSender());
        owners[_msgSender()] = true;
        totalOwners++;
    }

     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // It will return the address who deploy the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySuperOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the super owner");
        _;
    }

    modifier onlyOwner() virtual {
        require(owners[_msgSender()] == true, "Ownable: caller is not the owner");
        _;
    }

  
    function transferOwnership(address newOwner) public virtual onlySuperOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function addOwner(address newOwner) public onlyOwner {
        require(owners[newOwner] == false, "This address have already owner rights.");
        owners[newOwner] = true;
        totalOwners++;
    }

    function removeOwner(address _Owner) public onlyOwner {
        require(owners[_Owner] == true, "This address have not any owner rights.");
        owners[_Owner] = false;
        totalOwners--;
    }

    function verifyOwner(address _ownerAddress) public view returns(bool){
        return owners[_ownerAddress];
    }
}