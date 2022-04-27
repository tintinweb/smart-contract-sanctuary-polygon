// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./Applications.sol";
import "./IGoldToken.sol"; //cambiar el nombre
import "./IRoyalties.sol";
import "./IRefinery.sol";

interface tokenGoldDetails {
    function goldWeight(uint tokenId) external view returns(uint);
    function goldPurity(uint tokenId) external view returns(uint);
}

contract ArtWork is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, Applications {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    address OracleAUG;
    address OracleMATIC;
    address GOLD;
    address REFINERY;
    address ROYALTIES;

    struct TokenDetail {
        uint creationDate;
        string artWorkName;
        string ownerName;
        address creator;
        address owner;
        uint royalties;
        uint price;
    }


    mapping(uint=>TokenDetail) TokenDetails;
    mapping(uint=>uint) RefineryTokenSupport;
    mapping(uint=>bool) GoldSupportStatus;

    mapping(uint=>uint) tokenCounter;

    struct Curator {
        string docHash;
        uint creationDate;
    }
    mapping(uint=>Curator[]) Curators;
    

    uint private counterCollections;
    bool private safeTX=true;
    uint private _developerRoyalties = 10;
    string _imageUrl;

    constructor( address _OracleAUG, address _OracleMATIC, address _gold, address _refinery, address _royalties, string memory _setImageURL) ERC721("Art Work", "ARW") {
        pause(true);
        counterCollections=0; // first one
        OracleAUG = _OracleAUG;
        OracleMATIC = _OracleMATIC;
        GOLD = _gold;
        REFINERY = _refinery;
        ROYALTIES = _royalties;
        _imageUrl = _setImageURL;
        IERC721(GOLD).isApprovedForAll(address(this), GOLD);
        IERC721(REFINERY).isApprovedForAll(address(this), REFINERY);
    }

    function pause(bool val) public onlyOwner {
        val ? _pause() : _unpause();
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
   
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    function changeRoyalties(uint _tokenId,address[] memory _addresses, uint[] memory _royalties) public {
        require(TokenDetails[_tokenId].creator==msg.sender,string("You are not the creator"));
        uint _now = block.timestamp;
        uint _min = _now + 180 days;
        require(UserRoyalties(ROYALTIES).getRoyaltiesCreationDate(_tokenId)<_min,string("You must wait at least 180 days before changing royalties back"));
        UserRoyalties(ROYALTIES).createRoyalties(_addresses, _royalties, _tokenId);
    }    

    function createArtWork(string memory _ownerName, uint _price, address[] memory _addresses, uint[] memory _royalties, string memory _artWorkName) public {
        uint nextTokenId = _totalSupply();
        UserRoyalties(ROYALTIES).createRoyalties(_addresses, _royalties, nextTokenId);
        uint _totalRoyalties;
        for (uint i=0; i<_royalties.length; i++) {
            _totalRoyalties = _totalRoyalties+_royalties[i];
        }
        /*
            Precio en gwei. Tiene que venir en gwei, si no viene en gwei la cagan porque vale verga
            el artwork.
        */
        TokenDetails[nextTokenId] = TokenDetail({
            creationDate: uint(block.timestamp),
            artWorkName: string(_artWorkName),
            ownerName: string(_ownerName),
            creator: address(msg.sender),
            owner: address(msg.sender),
            royalties: uint(_totalRoyalties),
            price: uint(_price)
        });
        _tokenIdTracker.increment();
        _safeMint(msg.sender, nextTokenId);
        
    }
    function addGold(uint _tokenId, uint _refineryTokenId, uint _newArtWorkPrice) public {
        require(IERC721(REFINERY).ownerOf(_refineryTokenId)==msg.sender,string("Refinery Gold Sender must be the owner"));
        require(ownerOf(_tokenId)==msg.sender,string("ArtWork Sender must be the owner"));
        require(!GoldSupportStatus[_tokenId],string("The ArtWork already has a Refinery Gold Token"));
        IERC721(REFINERY).transferFrom(msg.sender,address(this),_refineryTokenId);
        RefineryTokenSupport[_tokenId]=_refineryTokenId;
        GoldSupportStatus[_tokenId]=true;
        if (_newArtWorkPrice>0) {
            TokenDetails[_tokenId].price=_newArtWorkPrice;
        }
    }
    function removeGold(uint _tokenId) public {
        require(ownerOf(_tokenId)==msg.sender,string("You are not the owner of this ArtWork"));
        require(GoldSupportStatus[_tokenId],string("The ArtWork does not have Gold Support"));
        GoldSupportStatus[_tokenId]=false;
        uint _refineryTokenId = RefineryTokenSupport[_tokenId];
        IERC721(REFINERY).transferFrom(address(this),msg.sender,_refineryTokenId);
        uint _goldPrice = RefineryDetails(REFINERY).averagePrice(_refineryTokenId);
        uint _artWorkPrice = TokenDetails[_tokenId].price;
        uint _newArtWorkPrice;
        _artWorkPrice > _goldPrice ? _newArtWorkPrice=_artWorkPrice.sub(_goldPrice) : _newArtWorkPrice = _artWorkPrice;
        TokenDetails[_tokenId].price = _artWorkPrice;
    }
    function changePriceCost(uint _tokenId, uint _newPrice) public view returns (uint) {
        uint _oldPrice = TokenDetails[_tokenId].price;
        uint _royalties = TokenDetails[_tokenId].royalties;
        uint256 _maticPrice = OracleInterface(OracleMATIC).getPrice();
        uint _totalToPay;
        if (_newPrice > _oldPrice) {
            uint _diffPrice = _newPrice.sub(_oldPrice);
            uint _percentPrice = _royalties.mul(_diffPrice);
            _percentPrice = supDivide(_percentPrice, 100, 18);
            _percentPrice = supDivide(_percentPrice, _maticPrice,18);
            return _percentPrice;
        }else{
            _totalToPay = 0;
        }
    }
    function changePrice(uint _tokenId, uint _newArtWorkPrice) public payable {
        require(ownerOf(_tokenId)==msg.sender,string("ArtWork must be the owner"));
        require(TokenDetails[_tokenId].owner==msg.sender,string("You need transfer the ArtWork under your name"));
        uint _oldPrice = TokenDetails[_tokenId].price;
        if (_newArtWorkPrice > _oldPrice) {
            uint _valueToTransfer;
            uint _amountToTransfer = changePriceCost(_tokenId,_newArtWorkPrice);
            uint _ownerSCroyalties = _developerRoyalties.mul(_amountToTransfer);
            _ownerSCroyalties = supDivide(_ownerSCroyalties, 100, 18);
            _amountToTransfer=_amountToTransfer.sub(_ownerSCroyalties); 
            
            require(msg.value==_amountToTransfer,string("Invalid Amount to pay Royalties"));
            (uint[] memory _royalties, address[] memory _addresses ) = UserRoyalties(ROYALTIES).getRoyalties(_tokenId);
            for (uint i=0; i<_addresses.length; i++) {
                //ya viene como gwei...
                _valueToTransfer = 0;
                _valueToTransfer = _royalties[i].mul(_amountToTransfer);
                _valueToTransfer = supDivide(_valueToTransfer,100,18);
                (bool sent, ) = _addresses[i].call{value: _amountToTransfer}("");
                /*
                    si fallta su parte que carajo hacemos
                */
            }
        }
        TokenDetails[_tokenId].price=_newArtWorkPrice;
    }
    function _transferCost(uint _tokenId, uint _price) internal view returns(uint) {
        //(uint[] memory _royalties, address[] memory _addresses ) = UserRoyalties(ROYALTIES).getRoyalties(_tokenId);
        //(uint[] memory _royalties, ) = UserRoyalties(ROYALTIES).getRoyalties(_tokenId);
        uint _royalties = TokenDetails[_tokenId].royalties;
        uint256 _maticPrice = OracleInterface(OracleMATIC).getPrice();
        uint _valueCost = _royalties.mul(_price);
        _valueCost = supDivide(_valueCost, 100, 18);
        _valueCost = supDivide(_valueCost, _maticPrice, 18);
        return _valueCost;
    }

    function transferCost(uint _tokenId, uint _price) public view returns(uint) {
        uint _artWorkActualPrice = TokenDetails[_tokenId].price;
        uint _usePrice;
        _artWorkActualPrice > _price ? _usePrice = _artWorkActualPrice : _usePrice = _price;
        uint _transferPrice = _transferCost(_tokenId, _usePrice);
        return _transferPrice;
    }
    
    function transferArtWorkOwner(uint _tokenId, string memory _name, uint _newPrice) public payable {
        require(ownerOf(_tokenId)==msg.sender,string("ArtWork must be the owner"));
        uint _basePrice;
        uint _usePrice;
        uint _actualPrice = TokenDetails[_tokenId].price;
        uint _valueToTransfer;
        /*
        Si le quiere bajar el precio se lo baja, pero la transferencia la paga por el valor actual
        */
        _newPrice > 0 ? _basePrice = _newPrice : _basePrice = TokenDetails[_tokenId].price;
        _actualPrice > _basePrice ? _usePrice = _actualPrice : _usePrice = _basePrice;
        uint _transferPrice = transferCost(_tokenId, _usePrice);

        require(msg.value==_transferPrice,string("Invalid amount to Pay Royalties"));
        TokenDetails[_tokenId].ownerName=_name;
        TokenDetails[_tokenId].price=_usePrice;
        TokenDetails[_tokenId].owner=msg.sender;
        uint _amountToTransfer;
        //Calculo Royalties con transferCost en _transferPrice
        uint _ownerSCroyalties = _transferPrice.mul(_developerRoyalties);
        _ownerSCroyalties = supDivide(_ownerSCroyalties, 100, 18);
        //Resto lo del owner que queda en el contrato
        _amountToTransfer = _transferPrice.sub(_ownerSCroyalties); 

        (uint[] memory _royalties, address[] memory _addresses ) = UserRoyalties(ROYALTIES).getRoyalties(_tokenId);
        for (uint i=0; i<_addresses.length; i++) {
            _valueToTransfer = 0;
            _valueToTransfer = _royalties[i].mul(_amountToTransfer);
            _valueToTransfer = supDivide(_valueToTransfer,100,18);
            (bool sent, ) = _addresses[i].call{value: _amountToTransfer}("");
            /*
                si fallta su parte que carajo hacemos
            */
        }
        TokenDetails[_tokenId].price=_newPrice;
    }
    
    
    function averagePurity(uint256 _tokenId) internal view returns (uint) {
        uint _totalPurity;
        uint _counter;
        for (uint256 i = 0; i<tokenCounter[_tokenId]; i++) {
            _totalPurity = tokenGoldDetails(GOLD).goldPurity(_tokenId)+_totalPurity;
            _counter++;
        }
        uint _averagePurity = _totalPurity.div(_counter);
        return _averagePurity;
    }
    
    function averagePrice(uint256 _tokenId) internal view returns (uint) {
        uint _totalPrice;
        uint _counter;
        uint256 _augPrice = OracleInterface(OracleAUG).getPrice();
        for (uint i = 0; i<tokenCounter[_tokenId]; i++) {
            _totalPrice = (_augPrice.mul(tokenGoldDetails(GOLD).goldWeight(i)))+_totalPrice;
            _counter++;
        }
        uint _averagePrice = _totalPrice.div(_counter);
        return _averagePrice;
    }

    function goldRefineryTokenTraits(uint256 _tokenId) external view returns (uint,uint) {
        return (averagePurity(_tokenId),averagePrice(_tokenId));
    }   
    function compiledAttributes (uint256 _tokenId) internal view returns (string memory) {
        string memory traits;
        uint _tokenPrice = TokenDetails[_tokenId].price.div(1**18);
        
        uint _goldPrice = RefineryDetails(REFINERY).averagePrice(RefineryTokenSupport[_tokenId]).div(1**18);
        traits =  string(abi.encodePacked(
            attributeForTypeAndValue("Creation Date", uint2str(TokenDetails[_tokenId].creationDate)),',',
            attributeForTypeAndValue("Owner Name", TokenDetails[_tokenId].ownerName),',',
            attributeForTypeAndValue("Estimated Price (USD)", uint2str(_tokenPrice)),',',
            attributeForTypeAndValue("Gold Support", goldSupport(GoldSupportStatus[_tokenId])),',',
            attributeForTypeAndValue("Gold Support Value (USD)", uint2str(_goldPrice)),',',
            attributeForTypeAndValue("Royalties (%)", uint2str(TokenDetails[_tokenId].royalties))
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
            '{"description":"',TokenDetails[tokenId].artWorkName,'",',
            '"image":"',_imageUrl,'/',uint2str(tokenId),'.jpg",',
            '"external_url":"http://www.elorodealito.com",',
            '"attributes":{',
                compiledAttributes(tokenId),
            '}}'
        ));
        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }
    function withdrawal() public onlyOwner {
        uint _balance = address(this).balance;
        (bool sent, ) = owner().call{value: _balance}("");
        require(sent, string("Failed to send Matic"));
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function setImageUrl(string memory _url) public onlyOwner {
        _imageUrl = _url;
    }
}