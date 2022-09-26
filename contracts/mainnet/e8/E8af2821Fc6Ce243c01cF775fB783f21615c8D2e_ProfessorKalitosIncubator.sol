/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// SPDX-License-Identifier: MIT

/**
 *Suns Of DeFi: IBN5X - Prof. Kalito
*/
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//CORE
pragma solidity >=0.8.7;
contract ProfessorKalitosIncubator {
    //Security variabales
    uint256 private constant _NON_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    address owner;

    

    //Contract variables
    address somsContract;
    uint256 public totalIncubated;
    

    //Security Mods
    modifier isOwner{
        require(msg.sender == owner);
        _;
    }
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    } 

    modifier HasTransferApproval()
       {
           IERC721 tokenContract = IERC721(somsContract);
           require(tokenContract.isApprovedForAll(msg.sender, address(this)) == true, "Please approve Prof.Kalito's Incubator");
           _;
       }  



    mapping(address => uint256) hatchedAmount;

    event Deposited (address tokenAddress, uint256 tokenId, address user, uint256 hatched, uint256 date);

    constructor(address _MekaEggs){
       
        owner = msg.sender; 
        _status = _NON_ENTERED;
        somsContract = _MekaEggs;
        totalIncubated = 0;

    }

    function changeOwner(address newOwner) public isOwner returns(address){
        //emit OwnerSet(owner, newOwner);
        owner = newOwner;

        return owner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NON_ENTERED;
    }

    function incubatorDeposit(uint256 _id) public nonReentrant HasTransferApproval {
        IERC721 tokenContract = IERC721(somsContract);
        require(msg.sender == tokenContract.ownerOf(_id), "You are not the NFT owner");

        tokenContract.transferFrom(msg.sender, address(this), _id);

        totalIncubated+=1;
        hatchedAmount[msg.sender]+=1;

        emit Deposited (somsContract, _id, msg.sender, hatchedAmount[msg.sender], block.timestamp);

    }

    function myHatchNumber() public view returns(uint256){
        return hatchedAmount[msg.sender];
    }

    function Incubated() public view returns(uint256){
        return totalIncubated;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4)
    {
 
       return this.onERC721Received.selector;
    }

    function withdraw() public payable isOwner {
    
    // =============================================================================
    (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }




}