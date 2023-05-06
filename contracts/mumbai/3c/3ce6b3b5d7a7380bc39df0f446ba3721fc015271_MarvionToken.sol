// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./Ownable.sol";

contract MarvionToken is ERC721Enumerable, IERC2981, Ownable {      
  mapping (uint256 => string) private Items;
   
    mapping (address => bool) private Admin;
    address[] private AdminAddress;

  
    string private ContractURI;
    string public DomainURI;
    string public MetadataURI;
    address public RoyaltyAddress;
    uint96 public RoyaltyPercentage; // *10
    

    modifier CheckMetadataAndDomain(){
        require(keccak256(abi.encodePacked(DomainURI)) != keccak256(abi.encodePacked("")), "The Domain URI is empty");
        
        require(keccak256(abi.encodePacked(MetadataURI)) != keccak256(abi.encodePacked("")), "The Metadata URI is empty");
        _;
    }

    modifier onlyAdmin(){
        require(Admin[msg.sender], "You are not permission");
        _;
    }

    constructor (string memory name, string memory symbol, uint96 royaltyPercentage, address royaltyAddress) ERC721(name, symbol){
        require(royaltyAddress != address(0));
        require(royaltyPercentage > 0);
        
        RoyaltyAddress = royaltyAddress;
        RoyaltyPercentage = royaltyPercentage;
     
        AdminAddress.push(msg.sender);

        Admin[msg.sender] = true;

    }
    
    event createItemsEvent(uint256 nftId, string uri, uint256 itemId, address owner, address royaltyAddress, uint96 royaltyPercentage);
    event addItemsToAdminListEvent(address[] walletAddresses);
    event removeItemsOnAdminListEvent(address [] walletAddresses);
  
    function createItems(uint256[] memory nftId, address owner) public CheckMetadataAndDomain onlyAdmin{ 
        require(nftId.length > 0, "The data is incorrect");
    
        for(uint256 i = 0; i < nftId.length; i++){
            uint256 newItemId = totalSupply();
            _safeMint(owner, newItemId);
    
            string memory metadata = string.concat(MetadataURI, Strings.toString(newItemId));
            Items[newItemId] = Strings.toString(newItemId);
            
            string memory fTokenURI = string.concat(DomainURI, metadata);
         
           emit createItemsEvent(nftId[i], fTokenURI, newItemId, owner, RoyaltyAddress, RoyaltyPercentage);
       }
    }
  

    function setApprovalForItems(address to, uint256[] memory tokenIds) public{
        require(tokenIds.length > 0, "The input data is incorrect");
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            require(_isApprovedOrOwner(msg.sender, tokenIds[i]), "You are not owner of item");

            _approve(to, tokenIds[i]);
        }
    }

    function transfers(address[] memory froms, address[] memory tos, uint256[] memory tokenIds) public{
        require(froms.length == tos.length, "The input data is incorrect");
        require(tokenIds.length == tos.length, "The input data is incorrect");

        for(uint256 i = 0; i < froms.length; i++){
            require(_isApprovedOrOwner(msg.sender, tokenIds[i]), "You are not owner of item");

            _transfer(froms[i], tos[i], tokenIds[i]);
        }
    }

  
    
    // Get Data
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No Token ID exists");

        return string.concat(DomainURI, MetadataURI, Items[tokenId]); 
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function nAdmin() public view returns (uint256){
        return AdminAddress.length;
    }

    function getAdminAddress(uint256 index) public view returns (address){
        address t = AdminAddress[index];
        if(Admin[t])
            return t;
        return address(0);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "No token ID exists");
        return (RoyaltyAddress, (salePrice * RoyaltyPercentage) / 1000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }



    // setting
    function setContractURI(string memory contractUri) public onlyOwner{
        ContractURI = contractUri;
    }

    function setDomainURI(string memory domainUri) public onlyOwner{
        DomainURI = domainUri;
    }

    function setMetadataURI(string memory metadataUri) public onlyOwner{
        MetadataURI = metadataUri;
    }

    function changeRoyaltyReceiver(address royaltyAddress) onlyOwner public{
        require(royaltyAddress != address(0));
        RoyaltyAddress = royaltyAddress;
    }

    function changeRoyaltyPercentage(uint96 royaltyPercentage) onlyOwner public{
        require(royaltyPercentage > 0);
        RoyaltyPercentage = royaltyPercentage;
    }

    // admin permission
    function addWalletToAdminList(address[] memory wallets) public onlyOwner{
         for(uint256 i = 0; i < wallets.length; i++){            
            require(!Admin[wallets[i]], "These Wallets are added");

            bool isAdded = false;
            for(uint256 j = 0; j < AdminAddress.length; j++){
                if(AdminAddress[j] == wallets[i]){
                    isAdded = true;
                    break;
                }
            }
            if(isAdded == false){
                AdminAddress.push(wallets[i]);
            }
            
            Admin[wallets[i]] = true;
         }    

        emit addItemsToAdminListEvent(wallets);
    }
    
    function removeWalletOnAdminList(address[] memory wallets) public onlyOwner{
        for(uint256 i = 0; i < wallets.length; i++){            
            require(Admin[wallets[i]], "These Wallets have not added");

            Admin[wallets[i]] = false;
         }    

        emit removeItemsOnAdminListEvent(wallets);
    }
}