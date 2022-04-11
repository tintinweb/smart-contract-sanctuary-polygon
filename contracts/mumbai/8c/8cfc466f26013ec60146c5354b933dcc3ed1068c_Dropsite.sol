//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./ERC1155_Dropsite.sol"; 
import "./Strings.sol";
contract Dropsite is ERC1155_Dropsite  { 

    //NFT category
    // NFT Description & URL
    string  data ="";

    //NFTs distribution w.r.t Probabilities
    //Max probability of Diamond(id=0) = 0.5%
    //Max probability of Gold(id=1) = 10%
    //Max probability of Silver(id=2) = 85%
    uint8[20] private nums = [0,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2]; 
    
    uint TotalNFTsMinted;     //Total NFTs
    uint numOfCopies;         //A user can mint only 1 NFT
    
    //Initial Minting
    uint Diamond;            
    uint Gold;
    uint Silver; 

    //owner-NFT-ID Mapping
    //Won NFTs w.r.t Addresses
    struct nft_Owner{
        uint[] owned_Dropsite_NFTs;
    }
    mapping (address=>nft_Owner)  dropsite_NFT_Owner;
    
    //Check NFTs issued to an address
    function returnOwner(address addr) public view returns (uint[] memory){
        return dropsite_NFT_Owner[addr].owned_Dropsite_NFTs;
    }

    //payments Mapping
     mapping (address => uint) deposits;
  modifier OnlyOwner {
        require(_msgSender() == Owner, "Only NFT-ES Owner can Access");
        _;
    }

    //Pausing and activating the contract
    modifier contractIsNotPaused(){
        require (IsPaused == false, "Dropsite is not Opened Yet." );
        _;
    }
      bool public IsPaused = true;
    address payable public  Owner;
    string private _name;
    constructor (string memory name){
        _name = name;
        Owner = payable(msg.sender);

        TotalNFTsMinted=0;     //Total NFTs Minted
        numOfCopies=1;         //A user can mint only 1 NFT
        Diamond=0;            
        Gold=0;
        Silver=0;
    }
     
     //To Check issues NFTs Category Wise
     function checkMintedCategoryWise() public view OnlyOwner returns(uint,uint,uint){
         return (Diamond,Gold,Silver);
     }

     //To Check total Minted NFTs
    function checkTotalMinted() public view OnlyOwner returns(uint){
         return TotalNFTsMinted;
     }
     function stopDropsite() public OnlyOwner{
        require(IsPaused==false, "Dropsite is already Stopped");
        IsPaused=true;
    }

     function openDropsite() public OnlyOwner {
        require(IsPaused==true, "Dropsite is already Running");
        IsPaused=false;
    }
    
     //To WithDraw All Ammount from Contract to Owners Address or any other Address 
    function withDraw(address payable to) public payable OnlyOwner {
        uint Balance = address(this).balance;
        require(Balance > 0 wei, "Error! No Balance to withdraw"); 
        to.transfer(Balance);
    }  
    
    //To Check Contract Balance in Wei
      function ContractBalance() public view OnlyOwner returns (uint){
        return address(this).balance;
    }

    //Random Number to Select an item from nums Array(Probabilities)

    function random() internal view returns (uint) {
        // Returns 0-10
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 20;
    return randomnumber;
    }

    //random number will be generated which will be the index to nums array.
    //The number on that index will be considered as an nftID and will be alloted to the minter(user).
   function updateConditions() internal contractIsNotPaused returns(uint) {
       uint index = random();
        uint nftId = nums[index];

        // if nftID is 0, and less than 51 so 50 MAX - Diamond Category           
        if(nftId == 0 && Diamond < 50) {
             Diamond++;
            data = string(abi.encodePacked("Diamond_",Strings.toString(Diamond)));
            
            return nftId;

        // if nftID is 0 or 1 and Diamond is more than 150, it will go there in Gold Category
        } else if(nftId <= 1 && Gold < 100) {
            Gold++;
            data = string(abi.encodePacked("Gold_",Strings.toString(Gold)));
            return nftId;

        // if any of the above conditions are filled it will mint silver if enough silver available
        } else if(nftId <= 2 && Silver <= 850) {
            Silver++;
            data=data = string(abi.encodePacked("Silver_",Strings.toString(Silver)));
            
            return nftId;
        }
        else {
            
            //if nft ID is either 1 or 2, but Slots in Gold and Diamond are remaining, First Gold category will be filled then Diamond

            if(Gold < 100) {
                nftId = 1;
                Gold++;
                data = string(abi.encodePacked("Gold_",Strings.toString(Gold)));
                 
                return nftId;
            } else {
                nftId = 0;
                Diamond++;
                data = string(abi.encodePacked("Diamond_",Strings.toString(Diamond)));
                
                return nftId;
            }   
    }
   }

    //Random minting after Fiat Payments
    function FiatRandomMint(address user_addr) OnlyOwner contractIsNotPaused public returns (uint,string memory) {
     require(TotalNFTsMinted<1000, "Max Minting Limit reached");
   // we're assuming that random() returns only 0,1,2    
   uint nftId = updateConditions();
    _mint(user_addr, nftId, numOfCopies, data);
    TotalNFTsMinted++;
    dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
    return (nftId,string(data));
    }

    //MATIC Amount will be deposited  
    function depositAmount(address payee,uint amountToDeposit) internal {
        deposits[payee] += amountToDeposit;
    }
    
    //Random minting after Crypto Payments
    function CryptoRandomMint(address user_addr)  contractIsNotPaused public payable returns (uint,string memory) {
     require(TotalNFTsMinted<1000, "Max Minting Limit reached");
     require(msg.value == (25000000000000000000), "Balance must be 25 Matics");
   // nftId = random(); // we're assuming that random() returns only 0,1,2
   uint nftId = updateConditions();
    _mint(user_addr, nftId, numOfCopies, data);
    depositAmount(_msgSender(), msg.value);
    TotalNFTsMinted++;
    dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
    return (nftId,string(data));
    }
}