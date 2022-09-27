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
import "./IERC20.sol";

contract ArtWork_Vertical is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, Applications {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    address OracleAUG;
    address GOLD;
    uint ownerTAX = 3;
    //Produccion
    //address private constant USDCContract = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    //Testing
    address private constant USDCContract = 0x848Edb98Dc408A7A3247CE327638Dd5B60a1cEbb;

    struct TokenDetail {
        uint creationDate;
        string artWorkName;
        string ownerName;
        address creator;
        address owner;
        uint price;
        uint goldTokens;
    }

    mapping(uint=>mapping(uint=>uint)) tokenIdOwner;
    mapping(uint=>uint) tokenCounter;

    mapping(uint=>TokenDetail) TokenDetails;
    mapping(uint=>bool) GoldSupportStatus;
    mapping(uint=>bool) FirstTransferFreeOfCharge;

    struct Curator {
        string docHash;
        uint creationDate;
    }
    mapping(uint=>Curator[]) Curators;
   
    uint private counterCollections;
    bool private safeTX=true;
    uint private _developerRoyalties = 10;
    mapping(address=>bool) public admin;
    string _imageUrl;

    constructor( address _OracleAUG, address _gold, string memory _setImageURL) ERC721("Art Work Vertical", "VER") {
        pause(true);
        counterCollections=0; // first one
        OracleAUG = _OracleAUG;
        GOLD = _gold;
        _imageUrl = _setImageURL;
        IERC721(GOLD).isApprovedForAll(address(this), GOLD);
        IERC20(USDCContract).approve(address(this), 1000000000000 ether);
    }
    function pause(bool val) public onlyOwner {
        val ? _pause() : _unpause();
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
    function ViewGoldSupport(uint _tokenId) external view returns(bool) {
        return GoldSupportStatus[_tokenId];
    }
    function changeOnwerTAX(uint _newOwnerTAX) public onlyOwner {
        require(_newOwnerTAX<7,string("Owner TAX must be lower than 7%"));
        ownerTAX = _newOwnerTAX;
    }
    function withdrawal() public onlyOwner {
        uint _amountUSDC = IERC20(USDCContract).balanceOf(address(this));
        IERC20(USDCContract).transferFrom(address(this), owner(), _amountUSDC);
    }







    function createArtWork(string memory _ownerName, uint _price, string memory _artWorkName) public  {
        require(admin[msg.sender],string("Only admin can create new ArtWorks"));
        uint nextTokenId = _totalSupply();
        
        /*
            Precio en gwei. Tiene que venir en gwei, si no viene en gwei la cagan porque vale verga
            el artwork.
            Separar los valores de la Obra de Arte y del Respaldo del Oro
        */
        TokenDetails[nextTokenId] = TokenDetail({
            creationDate: uint(block.timestamp),
            artWorkName: string(_artWorkName),
            ownerName: string(_ownerName),
            creator: address(msg.sender),
            owner: address(msg.sender),
            price: uint(_price),
            goldTokens: uint(0)
        });
        _tokenIdTracker.increment();
        _safeMint(msg.sender, nextTokenId);
        FirstTransferFreeOfCharge[nextTokenId]=true;
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
        uint[] memory _returnValues = new uint256[](4);
        _returnValues[0] = _goldFinalPrice;
        _returnValues[1] = _goldFinalTAX;
        _returnValues[2] = _realWeight;
        _returnValues[3] = _realPurity;
        return _returnValues;
    }

    function addGold(uint[] memory _goldTokenId, uint _tokenId) public {
        require(ownerOf(_tokenId)==msg.sender,string("ArtWork Sender must be the owner"));
        for (uint i=0; i<_goldTokenId.length; i++) {
            require(IERC721(GOLD).ownerOf(_goldTokenId[i])==msg.sender,string("You are not the Gold Token Owner"));
        }
        uint[] memory _goldDataValues = calculateGoldPriceAndTAX(_goldTokenId);

        require(IERC20(USDCContract).balanceOf(msg.sender)>=_goldDataValues[1],string("Incomplete Balance"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _goldDataValues[0]);
        require(_transferStatus,string("Transfer Failed"));
        for (uint x=0; x<_goldTokenId.length; x++) {
            IERC721(GOLD).transferFrom(msg.sender, address(this), _goldTokenId[x]);
            tokenIdOwner[_tokenId][tokenCounter[_tokenId]]=_goldTokenId[x];
            tokenCounter[_tokenId]++;
        }
        TokenDetails[_tokenId].goldTokens=_goldTokenId.length;
        GoldSupportStatus[_tokenId]=true;
    }
    function removeGold(uint _tokenId) public {
        require(ownerOf(_tokenId)==msg.sender,string("You are not the owner of this ArtWork"));
        require(GoldSupportStatus[_tokenId],string("The Art Work does not have Gold Support"));
        GoldSupportStatus[_tokenId]=false;
        for (uint i=0; i<tokenCounter[_tokenId]; i++) {
            IERC721(GOLD).transferFrom(address(this), msg.sender, tokenIdOwner[_tokenId][i]);
        }
        TokenDetails[_tokenId].goldTokens=0;
        tokenCounter[_tokenId]=0;
    }

    function changeArtWorkPrice(uint _tokenId, uint _newPrice) public {
        require(ownerOf(_tokenId)==msg.sender,string("ArtWork must be the owner"));
        require(TokenDetails[_tokenId].owner==msg.sender,string("You need transfer the ArtWork under your name"));
        uint _oldPrice = TokenDetails[_tokenId].price;
        uint minValue;
        if (GoldSupportStatus[_tokenId]) {
            uint256[] memory _goldTokens = new uint256[](tokenCounter[_tokenId]);
            uint _counter;
            for (uint i=0; i<tokenCounter[_tokenId];i++) {
                _goldTokens[_counter]=tokenIdOwner[_tokenId][i];
                _counter++;
            }
            uint[] memory _goldValues = calculateGoldPriceAndTAX(_goldTokens);
            minValue = _goldValues[0]; // Gold Value!
            minValue = minValue.mul(2); // Double 
            require(_newPrice>minValue,string("The Art Work Value is invalid"));
        }else{
            minValue = _oldPrice.div(2); // Hasta el 50%
        }
        if (_newPrice>_oldPrice) {
            uint _royaltiesToPay = _newPrice-_oldPrice;
            uint _totalAmountToPayOwner = ownerTAX.mul(_royaltiesToPay);
            _totalAmountToPayOwner = _totalAmountToPayOwner.div(100);

            if (_totalAmountToPayOwner>0) {
                require(IERC20(USDCContract).balanceOf(msg.sender)>=_totalAmountToPayOwner,string("Insufficients funds"));
                bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _totalAmountToPayOwner);
                require(_transferStatus,string("Transfer Failed"));
            }

            TokenDetails[_tokenId].price=_newPrice;
        }else{
            TokenDetails[_tokenId].price=_newPrice;
        }
    }


    function _calculateTransferCost(uint _tokenId) internal view returns (uint) {
        uint _artWorkValue = TokenDetails[_tokenId].price;
        uint _totalAmountToPayOwner = ownerTAX.mul(_artWorkValue);
        _totalAmountToPayOwner = _totalAmountToPayOwner.div(100);
        return _totalAmountToPayOwner;
    }
    function calculateTransferCost(uint _tokenId) external view returns (uint) {
        return _calculateTransferCost(_tokenId);
    }

    function transferArtWorkFromOwner(uint _tokenId, string memory _name, address _newOwnerAddress) public {
        require(admin[msg.sender],string("Only admin can create new ArtWorks"));
        require(ownerOf(_tokenId)==msg.sender,string("Admin must have the Art Work Token"));
        require(FirstTransferFreeOfCharge[_tokenId],string("Only one free transfer is allowed"));
        TokenDetails[_tokenId].ownerName=_name;
        TokenDetails[_tokenId].owner=_newOwnerAddress; //Ojo con esto porque lo puede poner mal y tiene que volver a pagar para corregirlo
        IERC721(GOLD).transferFrom(address(this), _newOwnerAddress, _tokenId);
        FirstTransferFreeOfCharge[_tokenId]=false;
    }

    function transferArtWorkOwner(uint _tokenId, string memory _name, address _newOwnerAddress) public {
        require(ownerOf(_tokenId)==msg.sender,string("Art Worker must be the owner"));
        uint _transferCost = _calculateTransferCost(_tokenId);
        require(IERC20(USDCContract).balanceOf(msg.sender)>=_transferCost,string("Insufficients funds"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _transferCost);
        require(_transferStatus,string("Transfer Failed"));
        TokenDetails[_tokenId].ownerName=_name;
        TokenDetails[_tokenId].owner=_newOwnerAddress; //Ojo con esto porque lo puede poner mal y tiene que volver a pagar para corregirlo
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
    function compiledAttributes (uint256 _tokenId) internal view returns (string memory) {
        string memory traits;
        uint _tokenPrice = TokenDetails[_tokenId].price.div(1**18);
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
        traits =  string(abi.encodePacked(
            attributeForTypeAndValue("Creation Date", uint2str(TokenDetails[_tokenId].creationDate)),',',
            attributeForTypeAndValue("Owner Name", TokenDetails[_tokenId].ownerName),',',
            attributeForTypeAndValue("Estimated Price (USD)", uint2str(_tokenPrice)),',',
            attributeForTypeAndValue("Gold Support Value (USD)", uint2str(_goldPrice)),',',
            
            attributeForTypeAndValue("Royalties (%)", uint2str(0))
        ));
        return string(abi.encodePacked(
            '[',
            traits,
            ']'
        ));
    }
      
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        /*
        Cambiado el valor de name
        revisar bien el nombre que va a ir
        6 de julio de 2022
        */
        string memory metadata = string(abi.encodePacked(
            '{"name":"Art Work NFT",',
            '"description":"',TokenDetails[tokenId].artWorkName,'",',
            '"image":"',_imageUrl,'/',uint2str(tokenId),'.jpg",',
            '"external_url":"http://www.elorodealito.com",',
            '"attributes":',
                compiledAttributes(tokenId),
            '}'
        ));
        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
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