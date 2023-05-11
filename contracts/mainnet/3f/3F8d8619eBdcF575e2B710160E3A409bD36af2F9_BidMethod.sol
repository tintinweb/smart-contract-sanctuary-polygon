//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

contract BidMethod {
    struct tokenInfo {
        string cardName;
        uint count;
    }
    constructor() {
        
    }
    mapping(uint256 => tokenInfo) private _tokenInfo;
    address public _minter;
    modifier onlyOwner() {
        require(msg.sender == address(this), "Caller is not the Owner");
        _;
    }
    modifier onlyMinter() {
        require(msg.sender == _minter, "Caller is not the minter");
        _;
    }
    modifier onlyArbitrator() {
        require(msg.sender !=address(0), "Caller is not the arbitrator");
        _;
    }
    function setCards(string[] memory _cards,uint256[] memory _cardCounts,uint256[] memory _starTokens) public onlyOwner{}
    function ownerMint(address account,string memory cardName, uint256 amount) public onlyMinter{}
    function mintBidRights(uint256 starTokenId) public {}
    function mintBidRights(uint256[] memory starTokenIds) public {}
    function getTokenInfo(uint256 tokenId) public view returns (tokenInfo memory){return _tokenInfo[tokenId];}
    function getCardName(uint256 tokenId)public pure returns (string memory){return "tokenId";}
    function setMinter(address minter) external onlyOwner {_minter = minter;}
    function mintBidRights(address[] memory accounts,uint256[] memory starTokenIds) public onlyMinter{}
    function ownerMint(address account,string memory cardName, uint256 amount,string[] memory ids) public onlyMinter{}
    function stake() external payable {}
    function withdraw(address user,uint256 amount,uint256 fee) external onlyArbitrator {}
    function transferStake(uint256 amount) public {}
    function setArbitrator(address addr) public onlyOwner {}
    function setEffective(bool _effective) public onlyOwner {}   

}