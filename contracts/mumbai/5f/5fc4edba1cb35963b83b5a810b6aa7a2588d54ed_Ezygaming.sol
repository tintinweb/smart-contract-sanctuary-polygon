// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

contract Ezygaming is ERC721Enumerable, Ownable, Pausable {
 
    using SafeMath for uint256;
    
    constructor() ERC721("Ezygaming", "EZY") {}

    struct Reveal{
        address owner;
        uint256 buyTime;
    }
    
    mapping (uint256 => Reveal) private tokenDetails;

    uint256 private maxSupply = 10000;

    uint256 private token_id = 0;

    uint256 private publicSaleStartDate;

    uint256 private publicSaleEndDate;

    uint256 private publicSalePrice;

    uint256 private revealTime = 172800;

    mapping(address => bool) private whitelistUsers;

    mapping(address => uint256) private ownedToken;

    event Mint(address user, uint256 count, uint256 amount, uint256 time);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function publicSaleMint(address _to ,uint256 _mintAmount) public payable whenNotPaused{
        require(publicSaleStartDate <= block.timestamp && publicSaleEndDate > block.timestamp, "Presale ended or not started yet");
        require(_mintAmount > 0, "No amount to mint");    
        require(totalSupply() <= maxSupply, "Supply limit reached!");        
        require(msg.value >= publicSalePrice * _mintAmount, "Wrong price!");  
        require(ownedToken[_to] <= 20, "You can't buy more tokens");      
        for (uint256 i = 0; i < _mintAmount; i++) {
            token_id++;
            Reveal memory revealInfo;
            revealInfo = Reveal({
                owner :  _to,
                buyTime : block.timestamp
            }); 
            tokenDetails[token_id] = revealInfo;
            _safeMint(_to, token_id);
        }
        emit Mint(_to, _mintAmount, msg.value, block.timestamp);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
   
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }  

    function setPublicSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function setPublicSaleTime(uint256 time) public onlyOwner {
        publicSaleStartDate = time;
    }

    function changeRevealTime(uint256 time) public onlyOwner{
        revealTime = time;
    } 

    function setPublicSaleEndTime(uint256 time) public onlyOwner {
        publicSaleEndDate = time;
    }

    function whitelist(address account) public onlyOwner {      
        whitelistUsers[account] = true;      
    }

    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);        
    }

    function removeWhitelistedUsers(address account) public onlyOwner {      
        whitelistUsers[account] = false;       
    }

    function getPublicSalePrice() public view returns (uint256) {
        return publicSalePrice;
    }


    function getPublicSaleTime() public view returns (uint256) {
        return publicSaleStartDate;
    }

    function getPublicSaleEndTime() public view returns (uint256) {
        return publicSaleEndDate;
    }

    function tokenOwner(address _user) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokenIds;
    }

    function isWhitelisted(address _user) public view returns (bool) {
       return whitelistUsers[_user];
    }

    function tokenURI(uint256 tokenId) public view  override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(block.timestamp < tokenDetails[tokenId].buyTime + revealTime){
            return "null";
        }else {
            return super.tokenURI(tokenId);
        }
    }

    function getTokenDetails(uint256 tokenId) public view returns (address, uint256){
        Reveal memory revealInf = tokenDetails[tokenId];  
        return (revealInf.owner, revealInf.buyTime);
    }
}