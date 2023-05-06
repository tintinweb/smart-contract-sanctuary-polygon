// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./Ownable.sol";

contract MarvionToken is ERC721Enumerable, IERC2981, Ownable {   
    struct IAsset{
        uint256 ItemTotal;
        uint256 ItemMinted;
        uint256 PricePerToken;
        bool IsActivated;
    }

    enum saleState{PrivateSale, PublicSale}
    
    IAsset private Asset;
    mapping (uint256 => string) private Items;
   
    mapping (address => bool) private Admin;
    address[] private AdminAddress;

    mapping (address => bool) public IsWhitelist;
    mapping (address => uint256) public DOTMintedNumber;
    address[] private WhiteListAddress;


  
    string private ContractURI;
    string public DomainURI;
    string public MetadataURI;

    saleState public SaleState;

    address payable public ReceiveAddress;
    uint256 public MaximumDOTPerWallet;

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

        SaleState = saleState.PrivateSale;

        ReceiveAddress = payable(msg.sender);

        MaximumDOTPerWallet = 3;
    }
    
    event createItemsEvent(uint256 nftId, string uri, uint256 itemId, address owner, address royaltyAddress, uint96 royaltyPercentage);
    event claimItemEvent(string uri, uint256 itemId, address owner, address royaltyAddress, uint96 royaltyPercentage);
    event payForDOTEvent (address from, address to, uint256 totalPrice);
    event addItemsToWhiteListEvent(address[] walletAddresses);
    event removeItemsOnWhiteListEvent(address [] walletAddresses);
    event addItemsToAdminListEvent(address[] walletAddresses);
    event removeItemsOnAdminListEvent(address [] walletAddresses);
    event updateAssetDataEvent (uint256 itemTotal, uint256 pricePerToken, bool isActivated);
    event changeSaleStatusEvent (saleState saleStatus);


    function createItems(uint256[] memory nftId, address owner) public CheckMetadataAndDomain onlyAdmin{ 
        require(nftId.length > 0, "The data is incorrect");
        require(Asset.IsActivated, "Asset is unavailable");

        for(uint256 i = 0; i < nftId.length; i++){
            uint256 newItemId = totalSupply();
            _safeMint(owner, newItemId);
    
            string memory metadata = string.concat(MetadataURI, Strings.toString(newItemId));
            Items[newItemId] = metadata;
            
            string memory fTokenURI = string.concat(DomainURI, metadata);
         
            Asset.ItemMinted ++;

            emit createItemsEvent(nftId[i], fTokenURI, newItemId, owner, RoyaltyAddress, RoyaltyPercentage);
       }
    }

    function claim(uint256 quantity) payable public CheckMetadataAndDomain {
        require (ReceiveAddress != address(0), "The reveive wallet is incorrect");    
        require (quantity > 0, "The input data is incorrect");

        require (Asset.IsActivated, "The Asset is not active");
        require ((Asset.ItemTotal - Asset.ItemMinted) >= quantity, "The claim left is unavailable");
   

        if(SaleState == saleState.PrivateSale){
            bool isWhiteList = IsWhitelist[msg.sender];
                
            require (isWhiteList, "You are not permission");

            uint256 dotMintedNumber = DOTMintedNumber[msg.sender];
            require(dotMintedNumber < MaximumDOTPerWallet, "You have minted more than the allowed amount");
            
            _mintAsset(quantity);     

            _payout(quantity);

            DOTMintedNumber[msg.sender] += quantity;            
        }
        else if(SaleState == saleState.PublicSale){                  
            _mintAsset(quantity);  

            _payout(quantity);

            DOTMintedNumber[msg.sender] += quantity;           
        }
    }  
     

    function _payout(uint256 quantity) private {
        uint256 totalPrice = Asset.PricePerToken * quantity;
        require(msg.value >= totalPrice, "Insufficient payment amount");
        ReceiveAddress.transfer(msg.value);
    
        emit payForDOTEvent(msg.sender, ReceiveAddress, totalPrice);
    }


     function _mintAsset(uint256 quantity) private {                     
        for(uint256 i = 0; i < quantity; i++){
            uint256 newItemId = totalSupply();
            _safeMint(msg.sender, newItemId);
    
            string memory metadata = string.concat(MetadataURI, Strings.toString(newItemId));
            Items[newItemId] = metadata;
            
            Asset.ItemMinted ++;           

            string memory fTokenURI = string.concat(DomainURI, metadata);
            
            emit claimItemEvent(fTokenURI, newItemId, msg.sender, RoyaltyAddress, RoyaltyPercentage);
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

        return string.concat(DomainURI, Items[tokenId]); 
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function getAssetInformation() public view returns (IAsset memory) {
        return Asset;
    }

    function nWhiteListWallet() public view returns (uint256){
        return WhiteListAddress.length;
    }

   function getWalletOnWhiteList(uint256 index) public view returns (address, bool){
        address wlAddress = WhiteListAddress[index];

        bool isWhiteList = IsWhitelist[wlAddress];
     
        return (wlAddress, isWhiteList);
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

    function setReceiveAddress(address payable receiveAddress) public onlyOwner{
        ReceiveAddress = receiveAddress;
    }

     function setMaximumDOTPerWallet(uint256 maximumDOTPerWallet) public onlyOwner{
        MaximumDOTPerWallet = maximumDOTPerWallet;
    }

    function changeRoyaltyReceiver(address royaltyAddress) onlyOwner public{
        require(royaltyAddress != address(0));
        RoyaltyAddress = royaltyAddress;
    }

    function changeRoyaltyPercentage(uint96 royaltyPercentage) onlyOwner public{
        require(royaltyPercentage > 0);
        RoyaltyPercentage = royaltyPercentage;
    }


    // whitelist
    function addWalletToWhiteList(address[] memory wallets) public onlyAdmin{
        for(uint256 i = 0; i < wallets.length; i++){
            require(!IsWhitelist[wallets[i]], "These Wallets are added");
        
            IsWhitelist[wallets[i]] = true;     

            bool isAdded = false;
            for(uint256 j = 0; j < WhiteListAddress.length; j++){
                if(WhiteListAddress[j] == wallets[i]){
                    isAdded = true;
                    break;
                }
            }

            if(isAdded == false){
                WhiteListAddress.push(wallets[i]);
            }
         }    

        emit addItemsToWhiteListEvent(wallets);
    }

    function removeWalletOnWhiteList(address[] memory wallets) public onlyAdmin{
        for(uint256 i = 0; i < wallets.length; i++){                     
            require(IsWhitelist[wallets[i]], "These Wallets have not added");

            IsWhitelist[wallets[i]] = false;            
         }    

        emit removeItemsOnWhiteListEvent(wallets);
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


    // setting sale
    function changeSaleStatus(saleState state) public onlyAdmin{
        SaleState = state;

        emit changeSaleStatusEvent(SaleState);
    }


    function updateAssetData (uint256 _itemTotal,  uint256 _pricePerToken, bool _isActivated) public onlyAdmin{
        IAsset storage assetData = Asset;
    
        if(assetData.ItemTotal != _itemTotal) 
            assetData.ItemTotal = _itemTotal;

        if(assetData.PricePerToken != _pricePerToken)
            assetData.PricePerToken = _pricePerToken;

        if(assetData.IsActivated != _isActivated)
            assetData.IsActivated = _isActivated;

        emit updateAssetDataEvent(assetData.ItemTotal, assetData.PricePerToken, assetData.IsActivated); 
    }
}