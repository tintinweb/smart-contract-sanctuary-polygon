pragma solidity 0.8.9;

//import "hardhat/console.sol";
import "./ERC1155.sol";
import "./INiftnityTicket.sol";

contract NiftinityTicket is ERC1155, INiftnityTicket {

    address public platformOwner;
    uint public nextTokenId = 0;

    // token => creator
    mapping(uint256 => address) public creators;

    // token => tokenSupply
    mapping(uint256 => uint256) public tokenSupply;


    // token => Metadata
    mapping(uint256 => string) public publicMetadataURLs;

    // token => Metadata
    mapping(uint256 => string) private privateMetadataURLs;


    constructor(){
        platformOwner = msg.sender;
    }

    function getNextTokenId() external override view returns (uint){
        return nextTokenId;
    }


    function mintTickets(
        address creator,
        uint amount,
        string calldata publicMetadataURL,
        string calldata privateMetadataURL) override external returns (uint) {

        require(creator == tx.origin, "CREATOR MUST BE EQUAL TO TX.ORIGIN");
        require(this.isApprovedForAll(creator, address(this)), "CREATOR DID NOT APPROVE NIFTINITY TO MANAGE TICKETS ON THEIR BEHALF");

        uint tokenId = nextTokenId;
        nextTokenId = nextTokenId + 1;

        creators[tokenId] = creator;
        tokenSupply[tokenId] = amount;
        balances[tokenId][creator] = amount;
        publicMetadataURLs[tokenId] = publicMetadataURL;
        privateMetadataURLs[tokenId] = privateMetadataURL;

        return tokenId;
    }

    function claimAccess(address requestor, uint ticketId) public view virtual returns (string memory) {
        require(this.balanceOf(requestor, ticketId) > 0, 'REQUESTOR DOES NOT HAVE ACCESS TO SECRET TICKET DATA');
        return privateMetadataURLs[ticketId];
    }

    function numTokens() public view virtual returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return nextTokenId;
    }

}