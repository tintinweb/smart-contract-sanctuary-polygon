// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

//       🍄🍄🍄 ≋The≋ ≋Moody≋ ≋Item≋ ≋Shop≋ 🍄🍄🍄

contract MoodyMushroomsItemShop is ERC1155, Ownable {
    using Strings for uint256;
    
    struct Stake {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
    
    string private baseURI;

    mapping(uint256 => bool) public validItems;

    string public constant C____ = "     ,---.    ";
    string public constant _O___ = "    ' ,~, `   ";
    string public constant __I__ = "   ( ( ..) )  ";
    string public constant ___N_ = "    . ( ) .   ";
    string public constant ____S = "     `---'    ";
 
    event SetBaseURI(string indexed _baseURI);

    //######      item codes       ######
    //###### 0-199   - Accessories ######
    //###### 200-399 - Backgrounds ######
    //###### 400-599 - Spots       ######
    //###### 600-799 - Costumes    ######
    //###### 800-999 - Moods       ######

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validItems[0] = true;
        validItems[1] = true;
        validItems[69] = true;
        validItems[200] = true;
        validItems[400] = true;
        validItems[420] = true;
        validItems[600] = true;
        validItems[800] = true;
        validItems[999] = true;
        emit SetBaseURI(baseURI);
    }

    
    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }


    function burnItem(uint256 typeId, address burnTokenAddress) external
    {
        _burn(burnTokenAddress, typeId, 1);
    }

    // DM ImEmmy in discord, tell him you're a zombie coming to snack on his brain
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId) public view override returns (string memory)
    {
        require(
            validItems[typeId],
            "URI requested for invalid item type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI , typeId.toString()))
                : baseURI;
    }

    // map staker address to stake details
    mapping(address => Stake) public stakes;

    // map staker to total staking time 
    mapping(address => uint256) public stakingTime;    

    
    function stake(uint256 _tokenId, uint256 _amount) public {
        stakes[msg.sender] = Stake(_tokenId, _amount, block.timestamp); 
        safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "0x00");
    } 

    function unstake() public {
        safeTransferFrom(address(this), msg.sender, stakes[msg.sender].tokenId, stakes[msg.sender].amount, "0x00");
        stakingTime[msg.sender] += (block.timestamp - stakes[msg.sender].timestamp);
        delete stakes[msg.sender];
    }      

     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}