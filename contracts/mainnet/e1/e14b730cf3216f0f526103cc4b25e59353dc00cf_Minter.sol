/**
 *Submitted for verification at polygonscan.com on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ICAT {
    function mint(address _to) external returns (uint256);

    function upgrade(uint256 _tokenId) external;

    function totalSupply() external view returns (uint256);

}


contract Permission {
    address public owner;
    mapping(address => bool) public operators;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier onlyOperator(){
        require(operators[msg.sender], "Only Operator");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function addOperator(address _operator) public onlyOwner {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) public onlyOwner {
        operators[_operator] = false;
    }
}


contract Minter is Permission {
    using SafeMath for uint256;

    ICAT public icat;

    uint256 public basePrice = 500000000000000000;

    mapping(address => bool) public whiteListMinted;

    uint256 public freeThreshold = 500;

    uint256 public publicThreshold = 2000;



    constructor(address _cat) {
        icat = ICAT(_cat);
        owner = msg.sender;
        operators[address(msg.sender)] = true;
    }


    function changeIcat(address _cat) public onlyOwner {
        icat = ICAT(_cat);
    }

    function changeBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function changeFreeThreshold(uint256 _value) public onlyOwner {
        freeThreshold = _value;
    }

    function changePublicThreshold(uint256 _value) public onlyOwner {
        publicThreshold = _value;
    }

    function batchFreeMint(address[] memory _receivers) public onlyOperator {
        require(icat.totalSupply().add(_receivers.length) < freeThreshold, "Free mint count exceeded");
        for (uint i = 0; i < _receivers.length; i++) {
            icat.mint(_receivers[i]);
        }
    }

    function freeMint(address _to) public onlyOperator {
        require(icat.totalSupply() < freeThreshold, "Free mint count exceeded");
        icat.mint(_to);
    }


    function whiteListMint() public {
        require(icat.totalSupply() >= freeThreshold, "Not reach white list mint requirement");
        require(icat.totalSupply() < publicThreshold, "White list mint count exceeded");
        require(!whiteListMinted[msg.sender], "One white list address only once");
        icat.mint(msg.sender);
    }


    function publicMint() public payable {
        require(icat.totalSupply() >= publicThreshold, "Public mint not open yet");
        uint256 price = publicMintPrice();
        require(msg.value >= price, "Insufficient");
        if (msg.value.sub(price) > 0) {
            payable(msg.sender).transfer(msg.value.sub(price));
        }
        icat.mint(msg.sender);
    }

    function publicMintPrice() public view returns (uint256){
        uint256 totalSupply = icat.totalSupply();
        if (totalSupply < publicThreshold) {
            return basePrice;
        }
        return basePrice.mul(totalSupply.sub(publicThreshold).div(1000).add(1));
    }

    function transferEth(address payable _to) public onlyOwner {
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }
    }


}