// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import './Interfaces.sol';
//import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './Interfaces.sol';
import './Ownable.sol';
import './Whitelisting.sol';


contract TraderTestinggg is Ownable, ERC721, ERC721Holder{

    using Strings for uint256;
    Whitelisting whitelisting;
    Ownable ownable;

    uint256 public totalMinted = 0;                 // Total Minted Supply

    uint256 public publicMinted = 0;                // Public Minted Supply 
    uint256 public giftMinted = 0;                  // Gift Minted Supply
    uint256 public airDropMinted = 0;               // AirDrop Minted Supply

    uint256 public publicMintLimit = 10000;         //  Public mint limit
    uint256 public giftMintLimit = 75;              //  Gift mint limit
    
    uint256 public giftMintId = 10001;
    uint256 public publicMintId = 1;

    uint256 public mintPrice = 1 * 10 ** 17;        // minting price 0.1 ETH
    uint256 public perTxQuantity = 20;
    uint256 public perWalletQuantity = 20;

    uint256 public mintedThroughStripe;

    address public custodialWallet;
    address public deployer; 

    bool public publicSaleIsActive = false;
    bool public privateSaleIsActive = false; 
    bool public isPaused = false;
    bool public isHalted = false;

    // metadata api after reveal
    string private baseUri;

    // metadata api before reveal
    string private notRevealedUri; 

    // for reveal NFT
    bool public revealed = false; 

    address[] private giftMintedAddresses;
    address[] private NFTBuyersAddresses;

    uint256 public whitelistType;


    mapping(address => bool) giftMintedAddressBool;
    mapping(address => bool) NFTBuyersAddressBool;

    //      UUID    =>       PaymentID=> tokenIDs
    mapping(bytes => mapping(bytes32 => uint256[])) private tokenIDwithUUID;
    mapping(address => uint256) public walletMinted;
    mapping(uint256 => bool) public lockedNFTs;    //for locking NFTs, if the user has revert his payment.
    mapping(bytes => uint256) public UUIDMinted;

    modifier isPause(){
        require(isPaused == false, "Token is Paused.");
        _;
    }

    modifier isHalt(){
        require(isHalted == false, "Token is Halted.");
        _;
    }

    modifier onlyCustodialWallet() {
        require(msg.sender == custodialWallet, "cannot call this function from unknown address");
        _;
    }

    modifier onlyOwner() override {

            if(address(ownable) != address(0)){
            require(
            ownable.verifyOwner(msg.sender) == true ||
            verifyOwner(msg.sender) == true,
            "Caller is not the Owner."
            );
            } 
            else{
            require(
            verifyOwner(msg.sender) == true,
            "Caller is not the Owner." );
            }
            _;
        }

    modifier onlyDeployer() {
        require(msg.sender == deployer, 
        "Caller in not deployer"
        );

        _;
    } 


    constructor(address _custodialWallet) ERC721("TraderSpirits", "TRSP"){
        custodialWallet = _custodialWallet;
        deployer = msg.sender;
    }

    function _msgSender() internal view override(Context, Ownable) virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view override(Context, Ownable) virtual returns (bytes calldata) {
        return msg.data;
    }

    function _setbaseURI(string memory _baseUri) external onlyOwner{
        baseUri = _baseUri;
    }

    function _setNotRevealURI(string memory _notRevealUri) external onlyOwner{
        notRevealedUri = _notRevealUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false && tokenId <= 10000){
          // string memory baseURI = _baseURI();
            return bytes(notRevealedUri).length > 0 ? string(abi.encodePacked(notRevealedUri)) : "";
        }
        else{
            return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString(),".json")) : "";
        } 
    }

    function setWhitelistContractAddress(address whitelistContractAddress) public onlyDeployer{
        whitelisting = Whitelisting(whitelistContractAddress);
    }


    function mintByUser(uint256 quantity, bytes32[] memory proof, bytes32 rootHash) public isPause isHalt payable{
        
        uint256 identifier = whitelisting.identifier();

        if(privateSaleIsActive == true){
          
        if(identifier == 1){
           require (whitelisting.VerifyAddressForWhitelisting(msg.sender) == true, 
           "User not whitelisted"
           );

        }   
        else if (identifier == 2){
            require(whitelisting.statusOfAddress(msg.sender) == true, 
            "User not whitelisted."
            );
        }
         
        else if(identifier == 3){
            require(whitelisting.getRootHashesForVerifyUsingContract_status(rootHash) == true, 
            "Root hash not found."
            );

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

            require(MerkleProof.verify(proof,rootHash, leaf), 
            "User not whitelisted"
            );
         }

        }
  
        else{
            require(publicSaleIsActive == true, "Public Sale is not Started");
            require(publicMinted + quantity <= publicMintLimit, "Max Limit To Total Sale");
        }
        
        require(quantity > 0 && quantity <= perTxQuantity, "Invalid Mint Quantity");
        require(walletMinted[msg.sender] + quantity <= perWalletQuantity, "Max NFT per wallet exceeded.");
        require( msg.value >= mintPrice * quantity, "Invalid Price To Mint");

        (bool success,) = ownable.owner().call{value: msg.value}("");

        if(!success) {
            revert("Payment Sending Failed");
        }
        else{
            uint256 count = quantity;
            while(count > 0) {
                if(!_exists(publicMintId) && (publicMintId < giftMintId || publicMintId >= (giftMintId+giftMintLimit))){
                    totalMinted++;
                    publicMinted++;
                    _safeMint(msg.sender, publicMintId);
                    publicMintId++;
                    count--;
                }else{
                    if(_exists(publicMintId)){
                        publicMintId++;
                    }else{
                        publicMintId+=giftMintLimit;
                    }
                }
            }

            if(NFTBuyersAddressBool[msg.sender] == false){
                NFTBuyersAddresses.push(msg.sender);
                NFTBuyersAddressBool[msg.sender] = true; 
            }
            walletMinted[msg.sender] += quantity;
        }
    }
    
 
    function mintThroughStripe(bytes memory UUID, bytes32 paymentID, address walletAddress, uint256 quantity) public isHalt isPause onlyCustodialWallet {
        require(privateSaleIsActive == true || publicSaleIsActive == true, "Sale has not been started yet.");
        require(quantity > 0 && quantity <= perTxQuantity, "Invalid Mint Quantity");
        require(UUIDMinted[UUID] + quantity <= perWalletQuantity, "Max NFT per UUID exceeded.");
        require(UUID.length != 0, "UUID can't be empty");
        require(getUUID_Data(UUID, paymentID).length == 0, "Payment Id already used");
        uint256 count =  quantity;

        address receiver;

        if(walletAddress == address(0)){
            receiver = custodialWallet;
        }else{
            receiver = walletAddress;
        }

        while(count > 0) {
            if(!_exists(publicMintId)){
                totalMinted++;
                publicMinted++;
                _safeMint(receiver, publicMintId);
                tokenIDwithUUID[UUID][paymentID].push(publicMintId);
                publicMintId++;
                count--;
            }else{
                publicMintId++;
            }
        }
        UUIDMinted[UUID] += quantity;
    }
 

    function claimNFT(bytes memory UUID, bytes memory paymentID)public isHalt isPause{
        require(UUID.length != 0, "UUID can't be Zero.");
        bytes32[] memory paymentIDsList = abi.decode(paymentID, (bytes32[]));

        uint i;

        for (i = 0; i < paymentIDsList.length; i++){

        require(tokenIDwithUUID[UUID][paymentIDsList[i]].length >= 1);

        uint totalTokens = tokenIDwithUUID[UUID][paymentIDsList[i]].length;
           
            for(uint x = 0; x < totalTokens; x++){
                _transfer(address(this), msg.sender, tokenIDwithUUID[UUID][paymentIDsList[i]][x]);
            }
            
            delete tokenIDwithUUID[UUID][paymentIDsList[i]];
        }
    }


    function setOwnable(address ownableAddr) public onlyDeployer {
        // require(msg.sender == deployer);
        ownable = Ownable(ownableAddr);
    }



    function lockNFTs(bytes memory tokenIDs) public onlyOwner{
        require(tokenIDs.length != 0, "Token Ids in bytes can't be zero.");
        uint256[] memory tokenIDsList = abi.decode(tokenIDs, (uint256[]));

        for(uint i = 0; i < tokenIDsList.length; i++){
        lockedNFTs[tokenIDsList[i]] = true;
        }
    }

    //overridden function for transfer
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(lockedNFTs[tokenId] = false, 
        "this NFT can't be transferred."
        );

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(lockedNFTs[tokenId] = false, 
        "this NFT can't be transferred."
        );
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(lockedNFTs[tokenId] = false, 
        "this NFT can't be transferred."
        );
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }


    function getUUID_Data(bytes memory UUID, bytes32 paymentId) public view returns(uint256[] memory) {
        return tokenIDwithUUID[UUID][paymentId];
    }

    function updateUUID(bytes memory UUID,bytes memory paymentID,  bytes memory newUUID) public onlyCustodialWallet returns(bool){
        // require(UUID[0] != 0 && newUUID.length != 0, "UUID can't be empty");
        require(UUID.length !=0 && newUUID.length != 0 , "UUID can't be empty");

        bytes32[] memory paymentIDsList = abi.decode(paymentID, (bytes32[]));
        
        for (uint i = 0; i < paymentIDsList.length; i++){
        uint256[] memory data = tokenIDwithUUID[UUID][paymentIDsList[i]]; 

        tokenIDwithUUID[newUUID][paymentIDsList[i]] = data;
        }

        return true;
    } 



    function setCustodialWallet(address newCustodialWallet) public onlyOwner{
        require(newCustodialWallet != address(0));
        custodialWallet = newCustodialWallet;
    }

    function reveal() public onlyOwner {
       revealed = !revealed;
    }
  

    function setSaleStatus() external onlyOwner {
        if(privateSaleIsActive == false){
            uint256 identifier = whitelisting.identifier();
            require(identifier > 0 && identifier <=3, 
            "Identifier not selected for the private Sale.");
        }
        publicSaleIsActive = privateSaleIsActive;
        privateSaleIsActive = !publicSaleIsActive;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }
    
    function setPauseStatus() public onlyOwner{
        isPaused = !isPaused;
    }

    function setHaltStatus() public onlyOwner{
        isHalted = !isHalted;
    }

    function setPublicMintLimit(uint256 _publicMintLimit) public onlyOwner{
        require(_publicMintLimit > 0, "You have passed wrong value.");
        publicMintLimit = _publicMintLimit;
    }

    function setGiftMintLimit(uint256 _giftMintLimit) public onlyOwner{
        require(_giftMintLimit > 0, "You have passed wrong value.");
        giftMintLimit = _giftMintLimit;
    }

    function setGiftMintId(uint256 _giftMintId) public onlyOwner{
        require(_giftMintId > 0, "You have passed wrong value.");
        giftMintId = _giftMintId;
    }

    function setPerTxQuantity(uint256 _perTxQuantity) public onlyOwner{
        require(_perTxQuantity > 0, "You have passed wrong value.");
        perTxQuantity = _perTxQuantity;
    }

    function setPerWalletQuantity(uint256 _perWalletQuantity) public onlyOwner{
        require(_perWalletQuantity > 0, "You have passed wrong value.");
        perWalletQuantity  = _perWalletQuantity;
    }

    function mintByOwner(uint256 quantity) public isHalt onlyOwner {
        require(publicSaleIsActive == true, "Public Sale is not Started");
        require(publicMinted + quantity <= publicMintLimit, "Max Limit To Total Sale");
        uint256 count = quantity; 
        while(count > 0) {
            if(!_exists(publicMintId)){
                totalMinted++;
                publicMinted++;
                _safeMint(msg.sender, publicMintId);
                publicMintId++;
                count--;
            }else{
                publicMintId++;
            }
        }
    }
    
       function giftMint(address _address, uint256 quantity) public isHalt onlyOwner{
        require((giftMinted + quantity) <= giftMintLimit, "You are exceeding gift mint limit.");
        uint256 count = quantity;
        while(count > 0){
            if(!_exists(giftMintId)){
                giftMinted++;
                totalMinted++;
                _safeMint(_address, giftMintId);
                giftMintId++;
                count--;
            }else{
                giftMintId++;
            }
        }
   
        if(giftMintedAddressBool[_address] == false){
                giftMintedAddresses.push(_address);
                giftMintedAddressBool[_address] = true; 
        }
    } 

    function airDropToken(address _address, uint256 _tokenID) public isHalt onlyOwner{
        require(_tokenID > 0 && _tokenID <= (publicMintLimit + giftMintLimit), "You have passed wrong value");
        airDropMinted++;
        totalMinted++;
        _safeMint(_address, _tokenID);
    }

    function totalSupply() public view returns(uint256) {
        return publicMintLimit;
    }

    function getGiftMintedAddresses() public view returns(address[] memory){
        return giftMintedAddresses;
    }
    
    function getNFTMintedAddresses() public view returns(address[] memory){
        return NFTBuyersAddresses;
    }
}