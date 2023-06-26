// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract NetliOF is Ownable {
    struct Content {
        address creator;
        uint256 price;
        uint256 date;
        string desc;
        string freeipfsurl;
        string paidipfsurl;
        uint256 category;
        uint256 contID;
    }
    struct Category {
        uint256 id;
        string name;
        string descr;
    }
    struct Purchased {
        uint256 contID;
        address buyer;
        uint256 date;
    }
    struct Creator {
        address creatorAddr;
        string name;
        string desc;
        string profilePicUrl;
        string coverPicUrl;
        string insta;
        string telegram;
        string twitter;
        string youtube;
    }
    Content[] _contents;
    Category[] _categories;
    Purchased[] _purchases;
    Creator[] _creators;
    mapping (uint256 => Content[]) _contentID;
    mapping (uint256 => Category[]) _catID;
    mapping (address => Purchased[]) _addrToPurchase;
    mapping (address => Content[]) _creatorToContent;
    mapping (address => uint256) public _howManyPerCreator;
    mapping (address => bool) public _isCreator;
    mapping (address => Creator) _addrToInfo;
    mapping (address => bool[]) _isHidden;
    uint256 public feePercentage = 12;
    uint256 public MAX_FEE = 12;


    address payable public balanceTwoAddress = payable(0x77d4321478234c729bDA5011722C85465BEd0917);
    uint256 catID = 0;
    uint256 contID = 0;

    function setFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= MAX_FEE, "Fee cannot exceed MAX_FEE value!");
        feePercentage = _newFeePercentage;
    }

    function setBalanceTwoAddress(address payable _newBalanceTwoAddress) public onlyOwner {
        balanceTwoAddress = _newBalanceTwoAddress;
    }
    function addCategory (string memory _name, string memory _desc) public onlyOwner {
        catID++;
        _catID[catID].push(Category(catID, _name, _desc));
        _categories.push(Category(catID, _name, _desc));
    }
    function addContent(uint256 _price, string memory _desc, string memory _url1, string memory _url2, uint256 _cat) public {
        require(_isCreator[msg.sender] == true, "You're not allowed to post");
        _contentID[contID].push(Content(msg.sender, _price, block.timestamp, _desc, _url1, _url2, _cat, contID));
        _contents.push(Content(msg.sender, _price, block.timestamp, _desc, _url1, _url2, _cat, contID));
        _creatorToContent[msg.sender].push(Content(msg.sender, _price, block.timestamp, _desc, _url1, _url2, _cat, contID));
        contID++;
        _howManyPerCreator[msg.sender] += 2;
    }
    function addCreator(
        address _creator, 
        string memory _name, 
        string memory _desc, 
        string memory _url1,
        string memory _url2,
        string memory _social1,
        string memory _social2,
        string memory _social3,
        string memory _social4) 
        public {
    require(_isCreator[msg.sender] == true, "You're not a Creator");
    _addrToInfo[msg.sender] =Creator(_creator, _name, _desc, _url1, _url2, _social1, _social2, _social3, _social4);
    _creators.push(Creator(_creator ,_name, _desc, _url1, _url2, _social1, _social2, _social3, _social4));
    }
    function enableCreator(address _creator) public onlyOwner {
        _isCreator[_creator] = true;
    }
    function removeCreator(address _creator) public onlyOwner {
    _isCreator[_creator] = false;
    }
    function purchase(uint256 _contID) external payable returns (string memory) {
        require (msg.value >= _contentID[_contID][0].price, "Insufficient Balance");
        uint256 count = 0;
        for(uint i = 0; i < _addrToPurchase[msg.sender].length; i++){
            if(_contID == _addrToPurchase[msg.sender][i].contID){
               count++;
            }}
            if(count == 0) {
                _addrToPurchase[msg.sender].push(Purchased(_contID, msg.sender, block.timestamp));
                _pay(_contentID[_contID][0].creator, msg.value);
                return "Content Bought succesfully!";
            } else {
                revert("You already own this content!");
            }
        }
    function retrieveContents() public view returns (Content[] memory) {
        return _contents;
    }
    function retrieveCategories() public view returns (Category[] memory) {
        return _categories;
    }
    function retrievePurchased() public view returns (Purchased[] memory) {
        return _purchases;
    }
    function retrieveCreators() public view returns(Creator[] memory) {
        return _creators;
    }
    function retrieveCreatorByAddress(address _creator) public view returns(Creator memory) {
        return _addrToInfo[_creator];
    }
    function retrievePurchaseByAddress(address _buyer) public view returns(Purchased[] memory) {
        return _addrToPurchase[_buyer];
    }
    function retrieveContentByID(uint256 _contID) public view returns (Content[] memory) {
        return _contentID[_contID];
    }
    function _pay(address _creator, uint256 _amount) internal {
        uint256 balanceOne = _amount * (100 - feePercentage) / 100;
        uint256 balanceTwo = _amount  * feePercentage / 100;
        ( bool transferOne, ) = payable(_creator).call{value: balanceOne}("");
        ( bool transferTwo, ) = balanceTwoAddress.call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");
    }

}