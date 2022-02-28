// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract LazyDuck is ERC721,ERC721Enumerable,Ownable{
    string public baseURI;
    uint256 public MAX_QUANTITY = 2000;
    uint256 private mintDiscountPrice = 0.01 * 10**18;
    uint256 private mintNonalPrice = 0.05 * 10**18;
    uint256 public activityMustQuantity = 4;
    address public activityContract;

    constructor(string memory _baseInitURI,address _activityContract) ERC721("Lazy Duck", "LD") {
            baseURI=_baseInitURI;
            activityContract=_activityContract;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function discountMint(
        address caster
    ) public payable {
        require(totalSupply() < MAX_QUANTITY,"The casting quantity has been completed");
        require(msg.value >= mintDiscountPrice, "You must pay enough to complete the minting");
        require(checkRequirement(),"You don't meet the casting conditions");
        uint256 tokenId = totalSupply()+1;
        _safeMint(caster,tokenId);
    }

    function mint(
        address caster
    ) public payable {
        require(totalSupply() < MAX_QUANTITY,"The casting quantity has been completed");
        require(msg.value >= mintNonalPrice, "You must pay enough to complete the minting");
        uint256 tokenId = totalSupply()+1;
        _safeMint(caster,tokenId);
    }

    function onlyOwnerMint(address caster) public onlyOwner{
        require(totalSupply() < MAX_QUANTITY,"The casting quantity has been completed");
        uint256 tokenId = totalSupply()+1;
        _safeMint(caster,tokenId);
    }

    event callmessage(bytes4,uint256);
    function checkRequirement() private returns(bool){
        bytes4 method = bytes4(keccak256("balanceOf(address)"));
        (bool success,bytes memory data) =address(activityContract).call(abi.encodeWithSelector(method,msg.sender));
        if(success){
            uint256 quantity = abi.decode(data,(uint256));
            emit callmessage(method,quantity);
            return quantity>=activityMustQuantity;
        }else{
            return false;
        }
    }

    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawToAddress(address recipient) external onlyOwner{
        Address.sendValue(payable(recipient), address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setMaxQuantity(uint256 _quantity)public onlyOwner{
        MAX_QUANTITY = _quantity;
    }

    function setActivityContract(address _contractAddress) public onlyOwner{
        activityContract = _contractAddress;
    }
    
    function setMustQuantity(uint256 _mustQuantity) public onlyOwner{
        activityMustQuantity = _mustQuantity;
    }
}