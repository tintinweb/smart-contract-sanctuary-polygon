// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./Applications.sol";
import "./IERC20.sol";
import "./IGoldToken.sol";

contract ArtWorkToken is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, Applications {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address OracleAUG;
    address GOLD;

    //Prod.
    address private constant USDCContract = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    //Testing
    //address private constant USDCContract = 0x848Edb98Dc408A7A3247CE327638Dd5B60a1cEbb;

    struct royalties {
        address royaltyAddress;
        uint royaltyAmount;
    }
    mapping(uint=>royalties) Royalties;

    struct TokenDetail {
        uint creationDate;
        string artWorkName;
        string ownerName;
        address creator;
        address owner;
        uint royalties;
        uint price;
        uint goldTokens;
    }
    mapping(uint=>TokenDetail) public TokenDetails;

    mapping(uint=>mapping(uint=>uint)) tokenIdOwner;
    mapping(uint=>uint) tokenCounter;

    mapping(uint=>bool) GoldSupportStatus;
    mapping(uint=>bool) FirstTransferFreeOfCharge;

    uint private counterCollections;
    bool private safeTX=true;

    mapping(uint=>bool) public NftLocked;

    mapping(address=>bool) public admin;
    string _imageUrl;
    string _certificateUrl;
    string _externalUrl;

    // Def. values
    address galleryArtAddress;
    uint public galleryArtTAX = 1;
    uint public galleryArtFIXED = 10 ether;
    uint public ownerTAX = 1;
    uint public ownerFIXED = 100 ether;

    constructor( address _OracleAUG, address _Gold, string memory _setImageURL, string memory _setCertificateUrl, string memory _setExternalUrl, address _galleryArtAddress) ERC721("Art Work Token", "AWT") {
        OracleAUG = _OracleAUG;
        GOLD = _Gold;
        _imageUrl = _setImageURL;
        galleryArtAddress = _galleryArtAddress;
        _certificateUrl = _setCertificateUrl;
        _externalUrl = _setExternalUrl;
        IERC20(USDCContract).approve(address( this), 10000000000000000000000000000000000000 ether);
    }

    function addAdmin(address _new) public onlyOwner {
        require(!admin[_new],string("Already an Admin"));
        admin[_new] = true;
    }
    function removeAdmin(address _new) public onlyOwner {
        require(admin[_new],string("Not an Admin"));
        admin[_new] = true;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
   
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    
    function createArtWork (string memory _ownerName, uint _price, uint _royaltyAmount, address _royaltyAddress, string memory _artWorkName) public whenNotPaused {
        require(admin[msg.sender],string("createArtWork: You are not a Gallery Admin"));
        uint nextTokenId = _totalSupply();
        TokenDetails[nextTokenId] = TokenDetail({
            creationDate: uint(block.timestamp),
            artWorkName: string(_artWorkName),
            ownerName: string(_ownerName),
            creator: address(msg.sender),
            owner: address(msg.sender),
            royalties: uint(_royaltyAmount),
            price: uint(_price),
            goldTokens: uint(0)
        });
        Royalties[nextTokenId] = royalties({
            royaltyAddress: address(_royaltyAddress),
            royaltyAmount: uint(_royaltyAmount)
        });
        _tokenIdTracker.increment();
        _safeMint(msg.sender, nextTokenId);
    }

    function changeOwnerCosts(uint _tokenId) public view returns(uint[] memory)  {
        uint _artWorkPrice;
        uint _percentArtistRoyalties;
        uint _artistRoyalties;
        _percentArtistRoyalties = Royalties[_tokenId].royaltyAmount;
        _artWorkPrice = TokenDetails[_tokenId].price;
        uint _percentArtGalery = (_artWorkPrice.mul(galleryArtTAX)).div(100);
        uint _percentOwner = (_artWorkPrice.mul(ownerTAX)).div(100);
        _artistRoyalties = (_artWorkPrice.mul(_percentArtistRoyalties)).div(100);
        uint _subTotalCosts;
        _subTotalCosts = _subTotalCosts.add(galleryArtFIXED);
        _subTotalCosts = _subTotalCosts.add(ownerFIXED);
        _subTotalCosts = _subTotalCosts.add(_percentArtGalery);
        _subTotalCosts = _subTotalCosts.add(_percentOwner);
        _subTotalCosts = _subTotalCosts.add(_artistRoyalties);

        uint[] memory _returnValues = new uint256[](6);
        _returnValues[0] = _subTotalCosts; // Total
        _returnValues[1] = ownerFIXED; // Owner Fijo
        _returnValues[2] = _percentOwner; // Owner Porcentaje
        _returnValues[3] = galleryArtFIXED; // Galeria Fijo
        _returnValues[4] = _percentArtGalery; // Galeria Porcentaje
        _returnValues[5] = _artistRoyalties; // Artist Porcentaje
        return _returnValues;
    }

    function changeOwnerAndTransfer (uint _tokenId, string memory _newOwner, bool _transfer, address _newOwnerAddress) public whenNotPaused {
        require(ownerOf(_tokenId)==msg.sender,string("changeOwnerAndTransfer: You are not the Owner Token"));
        require(keccak256(abi.encodePacked(_newOwner))!=keccak256(abi.encodePacked("")),string("changeOwnerAndTransfer: Invalid Owner Name"));
        
        uint _artGalleryAmount;
        uint[] memory _royaltiesAndTaxes;
        _royaltiesAndTaxes = changeOwnerCosts(_tokenId);
        _artGalleryAmount = _royaltiesAndTaxes[3].add(_royaltiesAndTaxes[4]);
    
        require(IERC20(USDCContract).balanceOf(msg.sender)>=_royaltiesAndTaxes[0],string("changeOwnerAndTransfer: Insufficients Tokens in your Wallet"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _royaltiesAndTaxes[0]);
        require(_transferStatus,string("changeOwnerAndTransfer: Error sending Tokens"));
        IERC20(USDCContract).transferFrom(address(this), galleryArtAddress, _artGalleryAmount);
        IERC20(USDCContract).transferFrom(address(this), Royalties[_tokenId].royaltyAddress, _royaltiesAndTaxes[5]);
        TokenDetails[_tokenId].ownerName=_newOwner;
        TokenDetails[_tokenId].owner=_newOwnerAddress;
        //¿Hay que transferirlo?
        if (_transfer) transferFrom(msg.sender, _newOwnerAddress, _tokenId);
    }

    function safeTransferArtWork(uint _tokenId) public {
        require(ownerOf(_tokenId)==msg.sender,string("safeTransferArtWork: You are not the Owner Token"));
        require(ownerOf(_tokenId)!=TokenDetails[_tokenId].owner,string("safeTransferArtWork: Sending From and To are the same address"));
        transferFrom(msg.sender,TokenDetails[_tokenId].owner, _tokenId);
    }

    function calculateGoldPriceAndTAX(uint[] memory _goldTokenId) public view returns(uint[] memory) {
        uint _weight;
        uint _purity;
        for (uint i=0; i<_goldTokenId.length; i++) {
            _weight=_weight+GoldData(GOLD).goldWeight(_goldTokenId[i]);
            _purity=_purity+GoldData(GOLD).goldPurity(_goldTokenId[i]);
        }
        uint _realPurity = _purity.div(_goldTokenId.length);
        uint _realWeight = _weight;
        uint _lastGoldUpdate = OracleInterface(OracleAUG).getLastUpdate();
        require(_lastGoldUpdate>block.timestamp-3600,string("Oracle Gold Price Problems"));
        uint _gramGoldPrice = OracleInterface(OracleAUG).getPrice();
        uint _goldPartialPrice = _gramGoldPrice.mul(_realWeight);
        uint _goldFinalPrice = _realPurity.mul(_goldPartialPrice);
        _goldFinalPrice=_goldFinalPrice.div(10000); //100.00
        uint _goldFinalTAX=_goldFinalPrice.mul(ownerTAX);
        _goldFinalTAX=_goldFinalTAX.div(100);
        _goldFinalTAX=_goldFinalTAX.add(ownerFIXED);
        uint[] memory _returnValues = new uint256[](4);
        _returnValues[0] = _goldFinalPrice;
        _returnValues[1] = _goldFinalTAX;
        _returnValues[2] = _realWeight;
        _returnValues[3] = _realPurity;
        return _returnValues;
    }

    function addGold(uint[] memory _goldTokenId, uint _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId)==msg.sender,string("addGold: Not the Token owner"));
        for (uint i=0; i<_goldTokenId.length; i++) {
            //Controlo uno x uno que sea el dueño
            require(IERC721(GOLD).ownerOf(_goldTokenId[i])==msg.sender,string("You are not the Gold Token Owner"));
        }
        uint[] memory _goldDataValues = calculateGoldPriceAndTAX(_goldTokenId);
        require(IERC20(USDCContract).balanceOf(msg.sender)>=_goldDataValues[1],string("Incomplete Balance"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _goldDataValues[1]);
        require(_transferStatus,string("Transfer Failed"));
        for (uint x=0; x<_goldTokenId.length; x++) {
            IERC721(GOLD).transferFrom(msg.sender, address(this), _goldTokenId[x]);
            tokenIdOwner[_tokenId][tokenCounter[_tokenId]]=_goldTokenId[x];
            tokenCounter[_tokenId]++;
        }
        TokenDetails[_tokenId].goldTokens=_goldTokenId.length;
        GoldSupportStatus[_tokenId]=true;
    }

    function removeGold(uint _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId)==msg.sender,string("addGold: Not the Token owner"));
        require(GoldSupportStatus[_tokenId],string("addGold: The Art Work does not have Gold Support"));
        require(IERC20(USDCContract).balanceOf(msg.sender)>=ownerFIXED,string("addGold: Incomplete Balance"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), ownerFIXED);
        require(_transferStatus,string("Transfer Failed"));
        GoldSupportStatus[_tokenId]=false;
        for (uint i=0; i<tokenCounter[_tokenId]; i++) {
            IERC721(GOLD).transferFrom(address(this), msg.sender, tokenIdOwner[_tokenId][i]);
        }
        TokenDetails[_tokenId].goldTokens=0;
        tokenCounter[_tokenId]=0;
    }

    function changePriceCost(uint _tokenId, uint _newAmount) public view returns(uint[] memory) {
        uint _actualAmount = TokenDetails[_tokenId].price;
        uint _diffAmount;
        uint _subTotal;
        if (_newAmount<=_actualAmount) {
            _diffAmount = 0;
        }else{
            _diffAmount = _newAmount-_actualAmount;
        }
        //Owner
        uint _ownerFIXED = ownerFIXED;
        uint _ownerTAX = (ownerTAX.mul(_diffAmount)).div(100);
        //Art Gallery
        uint _galleryArtFIXED = galleryArtFIXED;
        uint _galleryArtTAX = (galleryArtTAX.mul(_diffAmount)).div(100);
        //Artist 

        // Correccion de esto que era el porcentaje y se sumaba como unidad
        //uint _artistRoyalties = Royalties[_tokenId].royaltyAmount;
        uint _artistRoyalties = Royalties[_tokenId].royaltyAmount;
        _artistRoyalties = _artistRoyalties.mul(_diffAmount);
        _artistRoyalties = _artistRoyalties.div(100);
        
        _subTotal = _ownerFIXED.add(_ownerTAX);
        _subTotal = _subTotal.add(_galleryArtFIXED);
        _subTotal = _subTotal.add(_galleryArtTAX);
        _subTotal = _subTotal.add(_artistRoyalties);

        uint[] memory _returnValues = new uint256[](4);
        _returnValues[0] = _ownerFIXED.add(_ownerTAX);
        _returnValues[1] = _galleryArtFIXED.add(_galleryArtTAX);
        _returnValues[2] = _artistRoyalties;
        _returnValues[3] = _subTotal;
        return _returnValues;
    }

    function changePrice(uint _tokenId, uint _newPrice) public whenNotPaused {
        require(ownerOf(_tokenId)==msg.sender,string("changePrice: Not the Token Owner"));
        require(_newPrice>=1 ether, string("changePrice: Price must be at least $1"));
        uint[] memory _taxes;
        _taxes = changePriceCost(_tokenId, _newPrice);
        require(IERC20(USDCContract).balanceOf(msg.sender)>=_taxes[3],string("changePrice: Insufficient Tokens to pay the fees"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _taxes[3]);
        require(_transferStatus,string("changePrice: Failed paying the fees"));
        IERC20(USDCContract).transferFrom(address(this), galleryArtAddress, _taxes[1]);
        IERC20(USDCContract).transferFrom(address(this), Royalties[_tokenId].royaltyAddress, _taxes[2]);
        TokenDetails[_tokenId].price=_newPrice;
    }

    function detailGoldSupport(uint _tokenId) public view returns (uint[] memory) {
        uint256[] memory _goldTokens = new uint256[](tokenCounter[_tokenId]);
        uint _counter;
        for (uint i=0; i<tokenCounter[_tokenId];i++) {
            _goldTokens[_counter]=tokenIdOwner[_tokenId][i];
            _counter++;
        }
        uint[] memory _goldValues = calculateGoldPriceAndTAX(_goldTokens);
        return _goldValues;
    }

    function goldTokenDeposited(uint _tokenId) public view returns (uint[] memory) {
        uint256[] memory _goldTokens = new uint256[](tokenCounter[_tokenId]);
        uint _counter;
        for (uint i=0; i<tokenCounter[_tokenId];i++) {
            _goldTokens[_counter]=tokenIdOwner[_tokenId][i];
            _counter++;
        }
        return _goldTokens;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function compiledAttributes (uint256 _tokenId) internal view returns (string memory) {
        string memory traits;
        uint _tokenPrice = TokenDetails[_tokenId].price.div(1**6);
        uint _goldPrice;
        uint[] memory _goldTokDetails;
        uint _totalPrice;
        if (GoldSupportStatus[_tokenId]) {
            _goldTokDetails = detailGoldSupport(_tokenId);
            _goldPrice = _goldTokDetails[0];
            _totalPrice = _goldTokDetails[0]+_tokenPrice;
        }else{
            _goldPrice = 0;
            _totalPrice = _tokenPrice;
        }
        string memory _certificateAddress;
        _certificateAddress = string.concat(_certificateUrl,"/","?tokenId=",uint2str(_tokenId));
        /*
        _certificateAddress = string.concat(_certificateUrl,"/");
        _certificateAddress = string.concat(_certificateAddress,"?tokenId=");
        _certificateAddress = string.concat(_certificateAddress,uint2str(_tokenId));
        */
        
        traits =  string(abi.encodePacked(
            attributeForTypeAndValue("Creation Date", uint2str(TokenDetails[_tokenId].creationDate)),',',
            attributeForTypeAndValue("Owner Name", TokenDetails[_tokenId].ownerName),',',
            attributeForTypeAndValue("Estimated Price (USD)", uint2str(_tokenPrice)),',',
            attributeForTypeAndValue("Gold Support Value (USD)", uint2str(_goldPrice)),',',
            attributeForTypeAndValue("Data Json URL", _certificateAddress)
        ));
        return string(abi.encodePacked(
            '[',
            traits,
            ']'
        ));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory metadata = string(abi.encodePacked(
            '{"name":"Art Work NFT",',
            '"description":"',TokenDetails[tokenId].artWorkName,'",',
            '"image":"',_imageUrl,'/',uint2str(tokenId),'.jpg",',
            '"external_url":"',_externalUrl,'",',
            '"attributes":',
                compiledAttributes(tokenId),
            '}'
        ));
        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }

    function setImageUrl(string memory _url) public onlyOwner {
        _imageUrl = _url;
    }
    
    function setCertificateUrl(string memory _url) public onlyOwner {
        _certificateUrl = _url;
    }

    function changeExternalUrl(string memory _newExternalUrl) public onlyOwner {
        _externalUrl=_newExternalUrl;
    }

    function withdrawal() public onlyOwner {
        uint _amountUSDC = IERC20(USDCContract).balanceOf(address(this));
        IERC20(USDCContract).transferFrom(address(this), owner(), _amountUSDC);
    }

    function changeGalleryRoyalties(uint _galleryArtTAX, uint _galleryArtFIXED) public onlyOwner {
        require(_galleryArtTAX<=3,string("changeGalleryRoyalties: Max 3%"));
        require(_galleryArtFIXED<=1000 ether, string("Fixed Royalties up to $1000 per transaction"));
        galleryArtTAX = _galleryArtTAX;
        galleryArtFIXED = _galleryArtFIXED;
    }

    function changeGalleryRoyaltiesAddress(address _newGalleryAddress) public onlyOwner {
        galleryArtAddress = _newGalleryAddress;
    }

    function changeOwnerRoyalties(uint _ownerTAX, uint _ownerFIXED) public onlyOwner {
        require(_ownerTAX<=3,string("changeGalleryRoyalties: Max 3%"));
        require(_ownerFIXED<=1000 ether, string("Fixed Royalties up to $1000 per transaction"));
        ownerTAX = _ownerTAX;
        ownerFIXED = _ownerFIXED;
    }

    function changeArtistRoyalties(uint _tokenId, uint _newArtistRoyalties, address _newArtistAddress) public whenNotPaused {
        require(admin[msg.sender],string("changeArtistRoyalties: You are not a Gallery Admin"));
        require(_newArtistRoyalties<=3,string("changeArtistRoyalties: From 0% to 3%"));
        Royalties[_tokenId].royaltyAmount=_newArtistRoyalties;
        Royalties[_tokenId].royaltyAddress=_newArtistAddress;
        TokenDetails[_tokenId].royalties=_newArtistRoyalties;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) whenNotPaused {
        require(!NftLocked[tokenId],string("Your Token is Locked!"));
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function lockToken(uint _tokenId) public onlyOwner {
        NftLocked[_tokenId]=true;
    }

    function unLockToken(uint _tokenId) public onlyOwner {
        NftLocked[_tokenId]=false;
    }

    function changeAugOracle(address _newOracle) public onlyOwner {
        OracleAUG = _newOracle;
    }
}