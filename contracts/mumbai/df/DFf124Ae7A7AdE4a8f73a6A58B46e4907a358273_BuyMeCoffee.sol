//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract BuyMeCoffee {

    address payable private _owner;

    event NewOneIsBuyingMeCoffe(string _title, string _message, address indexed _sender, uint256 _cost, uint256 _timestamp);
    uint256 public totalCoffe;
    
    struct Coffee {
        string  _title;
        string  _message;
        address _sender;
        uint256 _amount;
        uint256 _timestamp; 
    }

    Coffee[] public coffee;
    
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Initializes the contract setting the deployer as the initial owner and payable.
    */
      function initialize() public {
        _owner = payable(msg.sender);
        totalCoffe = 0;
    }

    /**
    * @dev Buy me Coffee function.
    */
    function buyMeCoffee(string memory _title, string memory _message) public payable {
        uint256 cost = 0.001 ether;
        require(msg.value >= cost, "You must send at least 0.001 ETH");
        (bool success,) = _owner.call{value: msg.value}(""); // send ETH to the owner
        require(success, "Failed to send Ether");
        coffee.push(Coffee(_title, _message, msg.sender, msg.value, block.timestamp));
        totalCoffe += 1;
        emit NewOneIsBuyingMeCoffe(_title, _message, msg.sender, msg.value, block.timestamp);
    }


    function getAllCoffee() public view returns(Coffee[] memory) {
        return coffee;
    }

    function getTotalCoffe() public view returns (uint256) {
		return coffee.length;
	}


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}