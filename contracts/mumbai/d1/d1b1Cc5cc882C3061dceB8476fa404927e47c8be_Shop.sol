pragma solidity >=0.4.22 <0.9.0;

import "./Token.sol";

contract Shop {

  struct Product { // Tables
    string name;
    string imgPath;
    uint256 price;
    uint256 quantity;
    address seller;
  }

  event AddressProduct(uint256 pid, address seller, uint256 timestamp); // CRUD
  event BuyProduct(uint256 pid, address buyer, uint256 timestamp); // CRUD

  mapping(uint256 => Product) products; // query Tables Product
  mapping(uint256 => address[]) buying; // query address

  Token token;

  constructor (address _tokenAddress) public {
    token = Token(_tokenAddress);
  }

  function addProduct (
    string memory _name,
    string memory _imgPath,
    uint256 _price,
    uint256 _quantity,
    uint256 _pid,
    uint256 timestamp
  ) public {

    products[_pid] = Product({
      name: _name,
      imgPath: _imgPath,
      price: _price,
      quantity: _quantity,
      seller: msg.sender
    });

    emit AddressProduct(_pid, msg.sender, timestamp);

  }

  function getProduct(uint256 _pid) public view returns (
    string memory,
    uint256,
    uint256,
    string memory,
    address
  ) {

    Product memory product = products[_pid];

    return (
      product.name,
      product.price,
      product.quantity,
      product.imgPath,
      product.seller
    );

  }

  function buyProduct(uint256 _pid, uint256 _timestamp) public {

      require( products[_pid].quantity > 0, "Product is sold out");
      // expect 0

      Product storage product = products[_pid];
      // Storage หมายถึงตัวแปรที่ถูกจัดเก็บอย่างถาวรบน blokchain Memory หมายถึงตัวแปรที่ถูกจัดเก็บชั่วคราว

      address _buyer = msg.sender;
      token.transfer(_buyer, product.seller, product.price);

      product.quantity -= 1;
      buying[_pid].push(_buyer);
      emit BuyProduct(_pid, _buyer, _timestamp);

  }



}

pragma solidity >=0.4.22 <0.9.0;

contract Token {

  mapping (address => uint256) public balanceOf;

  constructor (uint256 initialSupply) public {
    balanceOf[msg.sender] = initialSupply;
  }

  function transfer(address _from, 
  address _to, 
  uint256 _value) public returns (bool success) {

    require(balanceOf[_from] >= _value); // Check if the sender balanceOf _from

    require(balanceOf[_to] + _value >= balanceOf[_to]); // Check balanceOf _to 

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    return true;

  }
  
}