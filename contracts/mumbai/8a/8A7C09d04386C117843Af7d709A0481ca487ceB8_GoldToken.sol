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
import "./IGoldToken.sol";
import "./IERC20.sol";
import {goldStructs} from "./GoldTokenLib.sol";

contract GoldToken is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable, Applications {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using goldStructs for *;

    Counters.Counter private _tokenIdTracker;

    string public baseTokenURI;

    address OracleAUG;
    
    //Produccion
    //address private constant USDCContract = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    //Testing
    address private constant USDCContract = 0x848Edb98Dc408A7A3247CE327638Dd5B60a1cEbb;
    //uint _maintenanceDays = 5475;
    uint _maintenanceDays = 1;
    uint public CCBalance;

    mapping(uint=>goldStructs.GoldCollection) public GoldCollections;
    uint private counterCollections;
    
    mapping(uint=>goldStructs.GoldTokenDetail) public GoldTokenDetails;
    mapping(address=>bool) admin;
    bool private safeReedem=true;

    event CreateGold(uint256 indexed id);

    constructor( address _OracleAUG) ERC721("GoldToken", "GTK") {
        pause(true);
        counterCollections=0; // first one
        OracleAUG = _OracleAUG;
        IERC20(USDCContract).approve(address( this), 1000000000000 ether);
    }

    function pause(bool val) public onlyOwner {
        val ? _pause() : _unpause();
    }

    function modifyAdmin(address _new) public onlyOwner {
        admin[_new] ? admin[_new]=false : admin[_new]=true;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    function currentSupply(uint256 _collectionId) public view returns (uint256) {
        return GoldCollections[_collectionId].qtyAvailable;
    }
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count, uint256 _collection) public whenNotPaused {
        require(currentSupply(_collection)>=_count,string("Insufficient Gold in Stock"));
        require(_collection < counterCollections,string("The Gold collection does not exists"));
        uint256 _lastAUGUpdate = OracleInterface(OracleAUG).getLastUpdate();
        require((block.timestamp-_lastAUGUpdate)<3600,string("Error in AUG Oracle Price"));
        require(GoldCollections[_collection].onSale,string("The Gold Collection is not on sale"));
        uint256[] memory checkMintPrice = mintPrice(_count,_collection);
        uint256 totalUSDToPay = checkMintPrice[2];
        require(IERC20(USDCContract).balanceOf(msg.sender)>=totalUSDToPay,string("Insufficients funds"));
        bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), totalUSDToPay);
        require(_transferStatus,string("Transfer Failed"));
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        GoldTokenDetails[id] = goldStructs.GoldTokenDetail({
            creationDate: uint(block.timestamp),
            weight: uint(_count),
            owner: address(_to),
            collectionId: uint (_collection),
            active: bool(true)
        });
        _safeMint(_to, id);
        GoldCollections[_collection].qtyAvailable=GoldCollections[_collection].qtyAvailable-_count;
        emit CreateGold(id);
    }
    function mintCC(address _to, uint256 _count, uint256 _collection) public whenNotPaused {
        require(admin[msg.sender],string("You are not an admin"));
        require(currentSupply(_collection)>=_count,string("Insufficient Gold in Stock"));
        require(_collection < counterCollections,string("The Gold collection does not exists"));
        require(GoldCollections[_collection].onSale,string("The Gold Collection is not on sale"));
        uint256[] memory checkMintPrice = mintPrice(_count,_collection);
        uint256 totalUSDToPay = checkMintPrice[2];
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        GoldTokenDetails[id] = goldStructs.GoldTokenDetail({
            creationDate: uint(block.timestamp),
            weight: uint(_count),
            owner: address(_to),
            collectionId: uint (_collection),
            active: bool(true)
        });
        _safeMint(_to, id);
        GoldCollections[_collection].qtyAvailable=GoldCollections[_collection].qtyAvailable-_count;
        CCBalance=CCBalance+totalUSDToPay;
        emit CreateGold(id);
    }
    function depositCCBalance(uint _amount, bool deposit) public {
        require(_amount<=CCBalance,string("Amount to send must be <= to CCBalance"));
        if (deposit) {
            require(IERC20(USDCContract).balanceOf(msg.sender)>=_amount,string("Insufficients funds"));
            bool _transferStatus = IERC20(USDCContract).transferFrom(msg.sender, address(this), _amount);
            require(_transferStatus,string("Transfer Failed"));
        }
        CCBalance=CCBalance-_amount;
    }
    /*
    function calculateMaintenance (uint _cantidad, uint _days) public view returns(uint256[] memory) {
        return MaintenancePrice(OracleMaintenance).calculateMaintenance(_cantidad,_days);
    }
    */
    function price(uint256 _count, uint256 _purity) public view returns (uint256) {
        uint256 _augPrice = OracleInterface(OracleAUG).getPrice();
        _augPrice = _augPrice.mul(_purity);
        _augPrice = _augPrice.div(10000);
        uint256 _ePrice = _augPrice.mul(_count);
        return _ePrice; //devuelve dolares del valor del gramo / pureza
    }
    function gramPrice() external view returns (uint) {
        uint256 _gramPrice = OracleInterface(OracleAUG).getPrice();
        return _gramPrice;
    }
    function mintPrice(uint256 _count,uint256 _collectionId) public view returns(uint256[] memory) {
        uint256 _lastAUGUpdate = OracleInterface(OracleAUG).getLastUpdate();
        require((block.timestamp-_lastAUGUpdate)<3600,string("Error in AUG Oracle Price"));
        require(_collectionId<counterCollections,string("The gold collection does not exists"));
        
        uint256 _purity = GoldCollections[_collectionId].purity;
        uint256 totalAugPrice = price(_count,_purity); //dolares
        
        //uint256[] memory _maintPrices = calculateMaintenance(_count,_maintenanceDays); // 15 yers = 5475
        uint256 totalUSDMaintenance = 0;
        uint256 totalUSDGold = totalAugPrice; //supDivide(totalAugPrice,1,18);
        uint256 totalUSDToPay = totalUSDGold+totalUSDMaintenance;
        uint256[] memory devPrices = new uint256[](3);
        devPrices[0]=totalUSDGold;
        devPrices[1]=totalUSDMaintenance;
        devPrices[2]=totalUSDToPay;
        return devPrices;
    }
    
    
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
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
    function compiledAttributes (uint256 _tokenId) internal view returns (string memory) {
        string memory traits;
        
        traits =  string(abi.encodePacked(
            attributeForTypeAndValue("Creation Date", uint2str(GoldTokenDetails[_tokenId].creationDate)),',',
            attributeForTypeAndValue("Weight (grs)", uint2str(GoldTokenDetails[_tokenId].weight)),',',
            attributeForTypeAndValue("Estimated Price (USD)", uint2str(price(GoldTokenDetails[_tokenId].weight,GoldCollections[GoldTokenDetails[_tokenId].collectionId].purity).div(1**18))),',',
            attributeForTypeAndValue("CollectionId", uint2str(GoldTokenDetails[_tokenId].collectionId)),',',
            attributeForTypeAndValue("Purity (%)", uint2str(GoldCollections[GoldTokenDetails[_tokenId].collectionId].purity/100)),',',
            attributeForTypeAndValue("EntireCollection", isEntireCollection(GoldTokenDetails[_tokenId].weight, GoldCollections[GoldTokenDetails[_tokenId].collectionId].weight))
        ));
        return string(abi.encodePacked(
            '[',
            traits,
            ']'
        ));
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory imageToken = getImageType(GoldTokenDetails[tokenId].weight);
        string memory metadata = string(abi.encodePacked(
            '{"name":"Gold NFT"',',',
            '"description":"Gold NFT Token"',',',
            '"image":"',imageToken,'"',',',
            '"external_url":"http://www.elorodealito.com"',',',
            '"attributes":',
                compiledAttributes(tokenId),
            '}'
        ));
        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }
    //Creo un nuevo Item de Oro para vender
    function createCollection(uint _weight,string memory _name,uint _purity) public onlyOwner {
        require(_weight>0,string("Invalid Weight"));
        require(_purity>=5000 && _purity<=10000,string("Invalid Purity"));
        require(keccak256(abi.encodePacked(_name))!=keccak256(abi.encodePacked("")),string("Invalid Collection Name"));
        GoldCollections[counterCollections] = goldStructs.GoldCollection ({
            creationDate: uint(block.timestamp),
            weight: uint(_weight),
            name: string(_name),
            purity: uint(_purity),
            qtyAvailable: uint(_weight),
            onSale: bool(true)
        });
        counterCollections++;
    }
    function pauseUnPauseCollection(uint _collectionId) public onlyOwner {
        require(_collectionId < counterCollections,string("Collection does not exists"));
        bool _collectionStatus = GoldCollections[_collectionId].onSale;
        _collectionStatus ? GoldCollections[_collectionId].onSale=false : GoldCollections[_collectionId].onSale=true;
    }
    
    //Muestro solamente el ID de la coleccion de Oro disponible para vender
    function showAvailbleGoldCollections() external view returns(uint[] memory) {
        uint256 j=0;
        uint[] memory availCollections = new uint[](counterCollections);
        for (uint256 i = 0; i<counterCollections; i++) {
            //Primero , esta a la venta ? true or false
            if (GoldCollections[i].onSale) {
                //Segundo, si esta a la venta, queda algo para vender ?
                if (GoldCollections[i].qtyAvailable>0) {
                    availCollections[j]=i;
                    j++;
                }
            }
        }
        return availCollections;
    }

    function withdrawal() external onlyOwner {
        uint _available = IERC20(USDCContract).balanceOf(address(this));
        bool _transferStatus = IERC20(USDCContract).transferFrom(address(this), owner(), _available);
        require(_transferStatus,string("Failed to Send"));
    }
    /*
        External Query Functions
    */
    function goldWeight(uint _tokenId) external view returns (uint) {
        uint _weight = GoldTokenDetails[_tokenId].weight;
        return _weight;
    }
    function goldPurity(uint _tokenId) external view returns (uint) {
        uint _collectionId = GoldTokenDetails[_tokenId].collectionId;
        uint _purity = GoldCollections[_collectionId].purity;
        return _purity;
    }
    function collectionWeight(uint _tokenId) external view returns (uint) {
        uint _collectionId = GoldTokenDetails[_tokenId].collectionId;
        uint _collectionWeight = GoldCollections[_collectionId].weight;
        return _collectionWeight;
    }
    function collectionName(uint _tokenId) external view returns (string memory) {
        uint _collectionId = GoldTokenDetails[_tokenId].collectionId;
        string memory _collectionName = GoldCollections[_collectionId].name;
        return _collectionName;
    }

    function reedemPartial(uint _tokenId) external whenNotPaused {
        require(admin[msg.sender],string("You are not an admin"));
        uint _collectionId = GoldTokenDetails[_tokenId].collectionId;
        uint _weight = GoldTokenDetails[_tokenId].weight;
        GoldCollections[_collectionId].qtyAvailable=GoldCollections[_collectionId].qtyAvailable+_weight;
    }
}