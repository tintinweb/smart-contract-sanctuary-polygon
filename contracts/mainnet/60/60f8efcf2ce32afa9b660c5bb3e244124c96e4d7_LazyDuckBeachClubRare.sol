// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract LazyDuckBeachClubRare is ERC721Enumerable,Ownable{
    string public baseURI;
    uint256 public MAX_QUANTITY = 2000;
    uint256 private mintPrice = 200 *10**18;
    uint256 public activityMustQuantity = 4;
    address public activityContract;

    constructor(string memory _baseInitURI,address _activityContract) ERC721("Lazy Duck Beach Club Rare", "LDBC Rare") {
            baseURI=_baseInitURI;
            activityContract=_activityContract;
    }

    function discountMint(
        address caster,
        uint256 amount
    ) public payable {
        require(totalSupply() + amount <= MAX_QUANTITY, "Will exceed maximum supply");
        require(msg.value >=  (mintPrice/10) * amount, "You must pay enough to complete the minting");
        require(checkRequirement(),"You don't meet the casting conditions");
       _internalMint(caster,amount);
    }

    function mint(
        address caster,
        uint256 amount,
        uint256 discount
    ) public payable {
        require(discount >= 5 ,"The parameter you passed in is invalid");
        require(totalSupply() + amount <= MAX_QUANTITY, "Will exceed maximum supply");
        require(msg.value >= (mintPrice * discount / 10) * amount, "You must pay enough to complete the minting");
        _internalMint(caster,amount);
    }

    function onlyOwnerMint(address caster, uint256 amount) public onlyOwner{
        require(totalSupply() + amount <= MAX_QUANTITY, "Will exceed maximum supply");
        _internalMint(caster,amount);
    }

    function _internalMint(address to,uint256 amount)private {
        uint256 _currentId = totalSupply();
           for (uint256 i = 1; i <= amount; i++) {
             _currentId++;
            _safeMint(to, _currentId);
        }
    }


    function checkRequirement() private returns(bool){
        bytes4 method = bytes4(keccak256("balanceOf(address)"));
        (bool success,bytes memory data) =address(activityContract).call(abi.encodeWithSelector(method,msg.sender));
        if(success){
            uint256 quantity = abi.decode(data,(uint256));
            return quantity>=activityMustQuantity;
        }else{
            return false;
        }
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