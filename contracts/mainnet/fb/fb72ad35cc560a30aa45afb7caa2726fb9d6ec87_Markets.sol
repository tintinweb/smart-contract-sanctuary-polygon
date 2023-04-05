/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

pragma solidity 0.5.0;

interface BitCereal {
    function decimals() external view returns(uint256);
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Markets {
    address owner;
    uint256 price;
    BitCereal bitCereal;
    uint256 tokenSold;

    event sold(address buyer, uint256 amount);

    constructor (uint256 _price, address _addressContract) public {
        owner = msg.sender;
        price = _price;
        bitCereal = BitCereal(_addressContract);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function buy() public payable {
        require(msg.value == mul(price, 2)); // Cobrar 2 matic por cada 100 tokens
        uint256 scaledAmount = 100 * (10 ** bitCereal.decimals());
        require(bitCereal.balanceOf(address(this)) >= scaledAmount);
        tokenSold += 100;
        require(bitCereal.transfer(msg.sender, scaledAmount));
        emit sold(msg.sender, 100);
    }

    function endsold() public onlyOwner {
        require(bitCereal.transfer(owner, bitCereal.balanceOf(address(this))));
        msg.sender.transfer(address(this).balance);
    }
}