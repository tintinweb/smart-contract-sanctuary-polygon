/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  function checkIfPaused() public view returns(bool) {
      return paused;
  }
}

contract StringLib {
    function upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    function contains(string memory what, string memory where) pure internal returns(bool) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        if (whereBytes.length < whatBytes.length){
            return false;
        }

        bool found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                
                if (upper(whereBytes[i + j]) != upper(whatBytes[j])) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        return found;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

contract Unshoppable is Ownable, Pausable, StringLib {

    struct Listing{
        uint256 id;
        uint256 timestamp;
        uint256 quantity;
        string image;
        address seller;
        string title;
        string description;
        uint256 price;
        string[] tags;
        string encryptionKey;
    }

    struct Sale{
        uint256 id;
        uint256 listingId;
        uint256 timestamp;
        uint256 quantity;
        address buyer;
        string encryptedShipping;
    }

    using SafeMath for uint256;
    Listing[] public listings;
    Sale[] public sales;
    string[] public tags;
    address public charityWallet;
    string public ipfsPage;
    int16 public marketFees;
    int16 public chartiyFee;

    constructor(address _charityWallet, string memory _ipfsPage, int16 _marketFees, int16 _charitiyFee) {
        charityWallet = _charityWallet;
        ipfsPage = _ipfsPage;
        marketFees = _marketFees;
        chartiyFee = _charitiyFee;
    }

    function getListings() external view returns(Listing[] memory) {
        return listings;
    }

    function getSales() external view returns(Sale[] memory) {
        return sales;
    }

    function getIpfsPage() external view returns(string memory) {
        return ipfsPage;
    }

    function getMarketFees() external view returns(int16) {
        return marketFees;
    }

    function getChartityFee() external view returns(int16) {
        return chartiyFee;
    }

    function getChartityWallet() external view returns(address) {
        return charityWallet;
    }

    function getTags() external view returns(string[] memory) {
        return tags;
    }

    function getListingById(uint256 _id) external view returns(Listing memory) {
        return listings[_id];
    }

    function getListingsBySeller(address _seller) external view returns(Listing[] memory) {
        uint256 resultCounter = 0;

        for (uint256 i = 0; i < listings.length; i++) {
            if (listings[i].seller == _seller){
                resultCounter++;
            }
        }

        Listing[] memory result = new Listing[](resultCounter);
        uint256 counter = 0;

        for (uint256 i = 0; i < listings.length; i++) {
            if (listings[i].seller == _seller){
                result[counter] = listings[i];
                counter++;
            }
        }

        return result;
    }

    function getListingsByFilter(string memory _title, string memory _tag) external view returns(Listing[] memory) {
        uint256 resultCounter = 0;
        string memory tmpTag = toLower(_tag);

        if (bytes(_title).length == 0) {
            if (bytes(tmpTag).length == 0) {
                return listings;
            } else {
                for (uint256 i = 0; i < listings.length; i++) {
                    for(uint256 j = 0; j < listings[i].tags.length; j++) {
                        if (keccak256(abi.encodePacked(tmpTag)) == keccak256(abi.encodePacked(listings[i].tags[j]))) {
                            resultCounter++;
                            break;
                        }
                    }
                }
            }
        } else {
            if (bytes(tmpTag).length == 0) {
                for (uint256 i = 0; i < listings.length; i++) {
                    if (contains(_title, listings[i].title)){
                        resultCounter++;
                    }
                }
            } else {
                for (uint256 i = 0; i < listings.length; i++) {
                     if (contains(_title, listings[i].title)){
                        for(uint256 j = 0; j < listings[i].tags.length; j++) {
                            if (keccak256(abi.encodePacked(tmpTag)) == keccak256(abi.encodePacked(listings[i].tags[j]))) {
                                resultCounter++;
                                break;
                            }
                        }
                    }
                }
            }
        }

        Listing[] memory result = new Listing[](resultCounter);
        uint256 counter = 0;

        if (bytes(_title).length == 0) {
            if (bytes(tmpTag).length == 0) {
                return listings;
            } else {
                for (uint256 i = 0; i < listings.length; i++) {
                    for(uint256 j = 0; j < listings[i].tags.length; j++) {
                        if (keccak256(abi.encodePacked(tmpTag)) == keccak256(abi.encodePacked(listings[i].tags[j]))) {
                            result[counter] = listings[i];
                            counter++;
                            break;
                        }
                    }
                }
            }
        } else {
            if (bytes(tmpTag).length == 0) {
                for (uint256 i = 0; i < listings.length; i++) {
                    if (contains(_title, listings[i].title)){
                        result[counter] = listings[i];
                        counter++;
                    }
                }
            } else {
                for (uint256 i = 0; i < listings.length; i++) {
                     if (contains(_title, listings[i].title)){
                        for(uint256 j = 0; j < listings[i].tags.length; j++) {
                            if (keccak256(abi.encodePacked(tmpTag)) == keccak256(abi.encodePacked(listings[i].tags[j]))) {
                                result[counter] = listings[i];
                                counter++;
                                break;
                            }
                        }
                    }
                }
            }
        }

        return result;
    }

    function getSalesByListingId(uint256 _listingId) public view returns(Sale[] memory) {
        uint256 resultCounter = 0;

        for (uint256 i = 0; i < sales.length; i++) {
            if (sales[i].listingId == _listingId){
                resultCounter++;
            }
        }

        Sale[] memory result = new Sale[](resultCounter);
        uint256 counter = 0;

        for (uint256 i = 0; i < sales.length; i++) {
            if (sales[i].listingId == _listingId){
                result[counter] = sales[i];
                counter++;
            }
        }

        return result;
    }

    function getSalesBySeller(address _seller) external view returns(Sale[] memory) {
        uint256 resultCounter = 0;

        for (uint256 i = 0; i < listings.length; i++) {
            if (listings[i].seller == _seller){
                Sale[] memory tmpSaleCounter = getSalesByListingId(listings[i].id);
                resultCounter = resultCounter + tmpSaleCounter.length;
            }
        }

        Sale[] memory result = new Sale[](resultCounter);
        uint256 counter = 0;

        for (uint256 i = 0; i < listings.length; i++) {
            if (listings[i].seller == _seller){
                Sale[] memory tmpSales = getSalesByListingId(listings[i].id);
                for (uint256 j = 0; j < tmpSales.length; j++) {
                    result[counter] = tmpSales[j];
                    counter++;
                }
            }
        }

        return result;
    }

    function getSalesByBuyer(address _buyer) external view returns(Sale[] memory) {
        uint256 resultCounter = 0;

        for (uint256 i = 0; i < sales.length; i++) {
            if (sales[i].buyer == _buyer){
                resultCounter++;
            }
        }

        Sale[] memory result = new Sale[](resultCounter);
        uint256 counter = 0;

        for (uint256 i = 0; i < sales.length; i++) {
            if (sales[i].buyer == _buyer){
                result[counter] = sales[i];
                counter++;
            }
        }

        return result;
    }

    function setCharityWallet(address _chartityWallet) external onlyOwner {
        charityWallet = _chartityWallet;
    }

    function setChartiyFee(int16 _chartiyFee) external onlyOwner {
        chartiyFee = _chartiyFee;
    }

    function setIpfsPage(string memory _ipfsPage) external onlyOwner {
        ipfsPage = _ipfsPage;
    }

    function setMarketFees(int16 _marketFees) external onlyOwner  {
        marketFees = _marketFees;
    }

    function withdraw() external onlyOwner returns(bool) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance.");

        payable(charityWallet).transfer(balance.mul(uint256(int256(chartiyFee))).div(100));
        payable(owner()).transfer(balance.mul(uint256(int256(100 - chartiyFee)).div(100)));

        return true;
    }

    function buy(uint256 _id, uint256 _quantity, string memory _encryptedShipping) external payable whenNotPaused {
        require(listings[_id].quantity >= _quantity, "Quantity not available.");
        require(msg.value >= (listings[_id].price * _quantity), "Insufficient amount sent.");

        listings[_id].quantity = listings[_id].quantity - _quantity;
        _createSale(_id, block.timestamp, _quantity, msg.sender, _encryptedShipping);

        payable(listings[_id].seller).transfer(msg.value.mul(uint256(int256(100 - marketFees))).div(100));
    }

    function _createSale(uint256 _listingId, uint256 _timestamp, uint256 _quantity, address _buyer, string memory _encryptedShipping) internal {
        Sale memory sale = Sale(sales.length, _listingId, _timestamp, _quantity, _buyer, _encryptedShipping);
        sales.push(sale);
    }

    function createListing(string memory _image, string memory _title, string memory _description, uint256 _quantity, uint256 _price, string[] memory _tags, string memory _publicKey) external whenNotPaused {
        string[] memory tmpTags = new string[](_tags.length);
        for (uint256 i = 0; i < _tags.length; i++) {
            tmpTags[i] = toLower(_tags[i]);
        }

        for (uint256 i = 0; i < tmpTags.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < tags.length; j++) {
                if (keccak256(abi.encodePacked(tmpTags[i])) == keccak256(abi.encodePacked(tags[j]))) {
                    found = true;
                }
            }
            if (!found) {
                tags.push(tmpTags[i]);
            }
        }

        _createListing(block.timestamp, _quantity, _image, msg.sender, _title, _description, _price, tmpTags, _publicKey);
    }

    function _createListing(uint256 _timestamp, uint256 _quantity, string memory _image, address _seller, string memory _title, string memory _description, uint256 _price, string[] memory _tags, string memory _publicKey) internal {
        Listing memory listing = Listing(listings.length, _timestamp, _quantity, _image, _seller, _title, _description, _price, _tags, _publicKey);
        listings.push(listing);
    }

    function deleteListing(uint256 _id) external whenNotPaused {
       	require(listings.length >= _id, "Listing-ID is not valid.");
        require(listings[_id].seller == msg.sender, "Sender is not the seller.");

        _updateListing(_id, listings[_id].image, listings[_id].title, listings[_id].description, 0, listings[_id].price, listings[_id].tags);
    }

    function _updateListing(uint256 _id, string memory _image, string memory _title, string memory _description, uint256 _quantity, uint256 _price, string[] memory _tags) internal {
        listings[_id].image = _image;
        listings[_id].title = _title;
        listings[_id].description = _description;
        listings[_id].quantity = _quantity;
        listings[_id].price = _price;
        listings[_id].tags = _tags;
    }
}