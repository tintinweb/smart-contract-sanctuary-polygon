// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./EpigeonInterfaces_080.sol";

//----------------------------------------------------------------------------------------------------

contract NameAndPublicKeyDirectory is INameAndPublicKeyDirectory{
    
    mapping (address => string) internal addressToPublicKey;
    mapping (address => string) internal addressToUserName;
    mapping (string => address) internal userNameToAddress;
	mapping (address => address) internal userAvatarNFTContractToAddress;
	mapping (address => uint256) internal userAvatarTokenIdToAddress;
    mapping (address => mapping(address => string)) internal iv;
    
    Epigeon epigeonAddress;
    uint256 public uniqueNamePrice;
    
    constructor (){
        epigeonAddress = Epigeon(msg.sender);
    }
	
	function deleteUserName (string memory name) public {
        require(userNameToAddress[name] == msg.sender, "Name belongs to someone else");
        delete userNameToAddress[addressToUserName[msg.sender]];
        delete addressToUserName[msg.sender];
    }
    
    function getAddressForName (string memory name) public view returns (address owner){
        return userNameToAddress[name];
    }
	
	function getAvatarNFTAddress (address owner) public view returns (address nftcontract){
		if (userAvatarNFTContractToAddress[owner] != address(0)){
			if(INft(userAvatarNFTContractToAddress[owner]).ownerOf(userAvatarTokenIdToAddress[owner]) == owner)
				return userAvatarNFTContractToAddress[owner];
			else
				return address(0);
		}
		else
			return address(0);
    }
	
	function getAvatarTokenId (address owner) public view returns (uint256 id){
		if (userAvatarNFTContractToAddress[owner] != address(0)){
			if(INft(userAvatarNFTContractToAddress[owner]).ownerOf(userAvatarTokenIdToAddress[owner]) == owner)
				return userAvatarTokenIdToAddress[owner];
			else
				return 0;
		}
		else
			return 0;
    }
    
    function getPublicKeyForAddress (address owner) public view returns (string memory key){
        return addressToPublicKey[owner];
    }
    
    function getIv (address address1, address address2) public view returns (string memory _iv){
        return iv[address1][address2];
    }
    
    function getUserNameForAddress (address owner) public view returns (string memory name){
        return addressToUserName[owner];
    }
	
	function setAvatar (address nftcontract, uint256 tokenid) public {
		require(INft(nftcontract).ownerOf(tokenid) == msg.sender, "Not owner");
        userAvatarNFTContractToAddress[msg.sender] = nftcontract;
		userAvatarTokenIdToAddress[msg.sender] = tokenid;
    }
    
    function setIv (address address2, string memory _iv) public {
        iv[msg.sender][address2] = _iv;
    }
	
	function setPigeonIv (address pigeon, address address2, string memory _iv) public {
		require(ICryptoPigeon(pigeon).owner() == msg.sender || ICryptoPigeon(pigeon).toAddress() == msg.sender, "Only owner or addressee");
        iv[pigeon][address2] = _iv;
    }
    
    function setPublicKeyToAddress (string memory key) public {
        addressToPublicKey[msg.sender] = key;
    }
    
    function setUniqueNamePrice (uint256 price) public {
        require(msg.sender == epigeonAddress.owner(), "Only Epigeon owner");
        uniqueNamePrice = price;
    }

    function setUserNameToAddress (string memory name) public payable {
        require(userNameToAddress[name] == msg.sender || userNameToAddress[name] == address(0), "Name is already in use");
        require(msg.value >= uniqueNamePrice, "Not enough value");
        delete userNameToAddress[addressToUserName[msg.sender]];
        addressToUserName[msg.sender] = name;
        userNameToAddress[name] = msg.sender;
        payable(epigeonAddress.owner()).transfer(address(this).balance);
    }
    
    function transferUniqueName (address toAddress) public {
        addressToUserName[toAddress]= addressToUserName[msg.sender];
        userNameToAddress[addressToUserName[toAddress]] = toAddress;
		delete userNameToAddress[addressToUserName[msg.sender]];
        delete addressToUserName[msg.sender];
    }
}
//----------------------------------------------------------------------------------------------------

contract PigeonDestinationDirectory is IPigeonDestinationDirectory{
    
    address public epigeonAddress;
    
    mapping (address => address[]) internal toAddressToPigeon;
    mapping (address => uint256) internal pigeonToToAddressIndex;
    mapping (address => bool) internal pigeonToAddressExists;
    
    event PigeonSent(address toAddress);
    
    constructor (){
        epigeonAddress = msg.sender;
    }
    
    function changeToAddress(address newToAddress, address oldToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        require(pigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
        
        //Delete old to address
        address pigeonToRemove = address(pigeon);
        uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[address(pigeon)];
        uint256 lastIdIndex = toAddressToPigeon[oldToAddress].length - 1;
        if (toAddressToPigeon[oldToAddress][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = toAddressToPigeon[oldToAddress][lastIdIndex];
          toAddressToPigeon[oldToAddress][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
          pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
        }
        delete toAddressToPigeon[oldToAddress][lastIdIndex];
        toAddressToPigeon[oldToAddress].pop();
        
        //Push new to address
        toAddressToPigeon[newToAddress].push(address(pigeon));
        pigeonToToAddressIndex[address(pigeon)] = toAddressToPigeon[newToAddress].length-1;
        
        emit PigeonSent(newToAddress);
    }
    
    function deleteToAddress(address oldToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        
        //Delete old to address 
        address pigeonToRemove = address(pigeon);
        uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[address(pigeon)];
        uint256 lastIdIndex = toAddressToPigeon[oldToAddress].length - 1;
        if (toAddressToPigeon[oldToAddress][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = toAddressToPigeon[oldToAddress][lastIdIndex];
          toAddressToPigeon[oldToAddress][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
          pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
        }
        delete toAddressToPigeon[oldToAddress][lastIdIndex];
        toAddressToPigeon[oldToAddress].pop();
        
        pigeonToAddressExists[address(pigeon)] = false;
    }
    
    function deleteToAddressByEpigeon(address pigeon) public {
        require(epigeonAddress == msg.sender, "Available only for Epigeon Smart Contract");
        address pToAddress = ICryptoPigeon(pigeon).toAddress();
        address pigeonToRemove = pigeon;
        
        //Delete to address
        if (ICryptoPigeon(pigeon).hasFlown()){
            uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
            uint256 lastIdIndex = toAddressToPigeon[pToAddress].length - 1;
            if (toAddressToPigeon[pToAddress][lastIdIndex] != pigeonToRemove)
            {
              address alastPigeon = toAddressToPigeon[pToAddress][lastIdIndex];
              toAddressToPigeon[pToAddress][pigeonToToAddressIndex[pigeonToRemove]] = alastPigeon;
              pigeonToToAddressIndex[alastPigeon] = pigeonToRemoveIndex;
            }
            delete toAddressToPigeon[pToAddress][lastIdIndex];
            toAddressToPigeon[pToAddress].pop();
         }
         pigeonToAddressExists[pigeon] = false;
    }
    
    function pigeonSentToAddressByIndex(address toAddress, uint index) public view returns (address rpaddress){
        rpaddress = toAddressToPigeon[toAddress][index];
    }
    
    function pigeonsSentToAddressLenght(address toAddress) public view returns (uint256 length){
        length = toAddressToPigeon[toAddress].length;
    }
    
    function setToAddress(address newToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        
        //Push new to address
        require(pigeonToAddressExists[msg.sender] != true, "Pigeon already has recipient entry");
        toAddressToPigeon[newToAddress].push(address(pigeon));
        pigeonToToAddressIndex[address(pigeon)] = toAddressToPigeon[newToAddress].length-1;
        
        pigeonToAddressExists[address(pigeon)] = true;
        emit PigeonSent(newToAddress);
    }
    
    function _isPigeon (address sender) internal view returns (bool indeed){
        ICryptoPigeon pigeon = ICryptoPigeon(sender);
        return IEpigeon(epigeonAddress).validPigeon(sender, pigeon.owner());
    }
}
//----------------------------------------------------------------------------------------------------

contract Epigeon is IEpigeon{

    address public owner;
    string public egigeonURI;
    address private _nftContractAddress;

    INameAndPublicKeyDirectory private _nameAndKeyDirectory;
    IPigeonDestinationDirectory private _pigeonDestinations;

    uint256[] factoryIds;
    mapping (address => bool) disabledFactories;
    mapping (uint256 => address) factoryIdtoAddress;

    mapping (address => address[]) internal ownerToPigeon;
    mapping (address => uint256) internal pigeonToOwnerIndex;

    event PigeonCreated(ICryptoPigeon pigeon);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){ 
        owner = msg.sender;
        _nameAndKeyDirectory = new NameAndPublicKeyDirectory();
        _pigeonDestinations = new PigeonDestinationDirectory();
    }   

    function addFactory(address factoryAddress) public {
        require(msg.sender == owner, "Only owner");
        IPigeonFactory factory = IPigeonFactory(factoryAddress);
        require(factory.iAmFactory(), "Not a factory");
        require(factory.amIEpigeon(), "Not the factory's Epigeon");
        require(factoryIdtoAddress[factory.factoryId()] == address(0), "Existing Factory ID");
        factoryIds.push(factory.factoryId());
        factoryIdtoAddress[factory.factoryId()] = address(factory);
        disabledFactories[address(factory)] = false;
    }

    function burnPigeon(address pigeon) public {
        require((_nftContractAddress == msg.sender) || ((IEpigeonNFT(_nftContractAddress).isTokenizedPigeon(pigeon) == false) && (ICryptoPigeon(pigeon).owner() == msg.sender)), "Not authorized");
        address pOwner = ICryptoPigeon(pigeon).owner();
        address pigeonToRemove = pigeon;
        
        //Delete old owner address
        uint256 pigeonToRemoveIndex = pigeonToOwnerIndex[pigeon];
        uint256 lastIdIndex = ownerToPigeon[pOwner].length - 1;
        if (ownerToPigeon[pOwner][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = ownerToPigeon[pOwner][lastIdIndex];
          ownerToPigeon[pOwner][pigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
          pigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;       
        }
        delete ownerToPigeon[pOwner][lastIdIndex];
        ownerToPigeon[pOwner].pop();
         
        //Delete to address
        _pigeonDestinations.deleteToAddressByEpigeon(pigeon);
        
        //Burn contract too
        ICryptoPigeon(pigeon).burnPigeon();        
    }
    
    function createCryptoPigeon(uint256 factoryId) public payable returns (address pigeonAddress) {
        require(msg.value >= getPigeonPriceForFactory(factoryId), "Not enough value"); 
        return _createPigeon(msg.sender, factoryId);
    }
    
    function createCryptoPigeonByLatestFactory() public payable returns (address pigeonAddress) {
        require(msg.value >= getPigeonPriceForFactory(getLastFactoryId()), "Not enough value");
        return _createPigeon(msg.sender, getLastFactoryId());
    }
    
    function createCryptoPigeonForToken(address ERC20Token, uint256 factoryId) public returns (address pigeonAddress) {
        require(getPigeonTokenPriceForFactory(ERC20Token, factoryId) > 0, "Price for token not available");
        require(IERC20(ERC20Token).balanceOf(msg.sender) >= getPigeonTokenPriceForFactory(ERC20Token, factoryId), "Not enough balance");
        require(IERC20(ERC20Token).allowance(msg.sender, address(this)) >= getPigeonTokenPriceForFactory(ERC20Token, factoryId), "Not enough allowance");
        IERC20(ERC20Token).transferFrom(msg.sender, owner, getPigeonTokenPriceForFactory(ERC20Token, factoryId));
        return _createPigeon(msg.sender, factoryId);
    }
    
    function createCryptoPigeonNFT(address to, uint256 factoryId) public returns (address pigeonAddress) {
        require(_nftContractAddress == msg.sender, "Available only for the NFT contract");   
        return _createPigeon(to, factoryId);
    }
    
    function disableFactory(uint256 factoryId) public {
        require(msg.sender == owner, "Only owner");
        disabledFactories[factoryIdtoAddress[factoryId]] = true;
    }
    
    function enableFactory(uint256 factoryId) public {
        require(msg.sender == owner, "Only owner");
        require(factoryIdtoAddress[factoryId] != address(0));
        disabledFactories[factoryIdtoAddress[factoryId]] = false;
    }
    
    function getFactoryAddresstoId(uint256 id) public view returns (address factory){
        return factoryIdtoAddress[id];
    }
    
    function getFactoryCount() public view returns (uint256 count){
        return factoryIds.length;
    }
    
    function getIdforFactory(uint256 index) public view returns (uint256 id){
        return factoryIds[index];
    }
    
    function getLastFactoryId() public view returns (uint256 id){
        return factoryIds[factoryIds.length-1];
    }
    
    function getPigeonPriceForFactory(uint256 factoryId) public view returns (uint256 price){
        return IPigeonFactory(factoryIdtoAddress[factoryId]).mintingPrice();
    }
    
    function getPigeonTokenPriceForFactory(address ERC20Token, uint256 factoryId) public view returns (uint256 price){
        return IPigeonFactory(factoryIdtoAddress[factoryId]).getFactoryTokenPrice(ERC20Token);
    }
    
    function isFactoryDisabled(address factoryAddress) public view returns (bool disabled){
        return disabledFactories[factoryAddress];
    }
    
    function nameAndKeyDirectory() external view returns (INameAndPublicKeyDirectory directory){
        return _nameAndKeyDirectory;
    }
    
    function nftContractAddress() external view returns (address _nftcontract){
        return _nftContractAddress;
    }

    function payout() public {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }
    
    function pigeonDestinations() external view returns (IPigeonDestinationDirectory destinations){
        return _pigeonDestinations;
    }
    
    function pigeonsCountOfOwner(address pigeonOwner) public view returns (uint256 length){
        length = ownerToPigeon[pigeonOwner].length;
        return length;
    }
    
    function pigeonOfOwnerByIndex(address pigeonOwner, uint index) public view returns (address rpaddress){
        rpaddress = ownerToPigeon[pigeonOwner][index];
        return rpaddress;
    }
    
    function setNFTContractAddress(address nftContract) public { 
        require(owner == msg.sender, "Only owner");
        require(_nftContractAddress == address(0), "NFT contract already set");
        _nftContractAddress = nftContract;
    }
    
    function setUri(string memory uri) public {  
        require(owner == msg.sender, "Only owner");
        egigeonURI = uri;
    }
    
    function transferOwnership(address newOwner) public {    
        require(owner == msg.sender, "Only owner");
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        payable(owner).transfer(address(this).balance);
        owner = newOwner;
    }
    
    function transferPigeon(address from, address to, address pigeon) public {
    
        if (IEpigeonNFT(_nftContractAddress).isTokenizedPigeon(pigeon)) {
            require(_nftContractAddress == msg.sender, "Tokenized Pigeon can only be transferred by NFT contract");
        }
        else{
            require(ICryptoPigeon(pigeon).owner() == msg.sender || pigeon == msg.sender, "Only pigeon owner");
        }
        
        //Delete old owner address
        address pigeonToRemove = pigeon;
        uint256 pigeonToRemoveIndex = pigeonToOwnerIndex[pigeon];
        uint256 lastIdIndex = ownerToPigeon[from].length - 1;
        if (ownerToPigeon[from][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = ownerToPigeon[from][lastIdIndex];
          ownerToPigeon[from][pigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
          pigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;
          
        }
        delete ownerToPigeon[from][lastIdIndex];
        ownerToPigeon[from].pop();
        
        //Push new owner address
        ownerToPigeon[to].push(pigeon);
        pigeonToOwnerIndex[pigeon] = ownerToPigeon[to].length-1;
        
        //Delete old to address
        _pigeonDestinations.deleteToAddressByEpigeon(pigeon);
         
        //Transfer contract too
        ICryptoPigeon(pigeon).transferPigeon(to);
    }
    
    function validPigeon(address pigeon, address pigeonOwner) public view returns (bool valid){
        require(pigeon != address(0), "Null address");
        return ownerToPigeon[pigeonOwner][pigeonToOwnerIndex[pigeon]] == pigeon;
    }
    
    function _createPigeon(address to, uint256 factoryId) internal returns (address pigeonAddress) {
        require(isFactoryDisabled(factoryIdtoAddress[factoryId]) == false, "Factory is disabled");
        ICryptoPigeon pigeon = IPigeonFactory(factoryIdtoAddress[factoryId]).createCryptoPigeon( to);
        ownerToPigeon[to].push(address(pigeon));
        pigeonToOwnerIndex[address(pigeon)] = ownerToPigeon[to].length-1;
        emit PigeonCreated(pigeon);
        return address(pigeon);
    }
}