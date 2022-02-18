pragma solidity >=0.6.0 <0.9.0;
 
import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
 
contract FishToken is ERC1155, Ownable {
    using SafeMath for uint256;
 
    uint256 public immutable pricePerFish;
    uint256 public immutable maxFish;
    uint256 public totalSupply;
    bool public isSaleActive;
    
    address private immutable reserveAddress;
 
    constructor(address _reserveAddress) public ERC1155("Fish") {
        pricePerFish = 0.011 * 10 ** 18;
        maxFish = 1000;
        totalSupply = 1;
        reserveAddress = _reserveAddress;
    }
 
    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }
 
    function setURI(string memory URI) public onlyOwner {
        _setURI(URI);
    }
 
    function reserveFish(uint256 count) public onlyOwner {   
        require(totalSupply < 100);
        uint256 mintIndex = totalSupply;
        if (mintIndex < maxFish) {
            _mint(msg.sender, mintIndex, count, "");
            totalSupply ++;
        }
    }
 
    function mintFish(uint256 count) public payable {
        require(isSaleActive, "Sale is not active");
        require(totalSupply+1 <= maxFish, "Purchase would exceed max supply of Fish");
        require(pricePerFish == msg.value, "Ether value is not correct");
        require(count > 0, "Fish count should > 0");
        
        payable(owner()).transfer(msg.value);
 
        uint256 mintIndex = totalSupply;
        if (mintIndex < maxFish) {
            _mint(msg.sender, mintIndex, count, "");
            totalSupply ++;
        }
    }
}