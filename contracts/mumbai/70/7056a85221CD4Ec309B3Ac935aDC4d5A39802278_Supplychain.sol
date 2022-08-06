// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.9;
contract Supplychain {
    address owner;
   constructor() {
      owner = msg.sender;
   }
uint256 product_id=0;
struct Product{
    uint256 id;
    string name;
   // string price;
    string description;
    string manufacturing;
    uint256 timestamp;
    string imageuri;
}
struct Status{
    string location;
    uint256 timestamp;
    uint256 temp;
    uint256 humidity;
    uint256 p_id;
    uint256 total_quantity;
}
struct Data {
    uint256 temp;
    uint256 humidity;
    uint256 proid;
}
modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
Product[] public products_list;
Product private productInfo;
Status[] public productStatus;
Status private statusInfo;
Data[] public Data_list;
Data private DataInfo;
mapping(uint256 => Status[]) public product_Status;
mapping (uint256 => Product) public products;
mapping (uint256 => Data[]) public data;
mapping(uint256 => address)private proowner;
mapping(uint256 => address)private inter;
function AddProduct(
    string memory name,
    string memory description,
    string memory manufacturing,
    address intermediate,
    string memory uri) public payable
{
    productInfo=Product(product_id,name,description,manufacturing,block.timestamp,uri);
    products[product_id]=(productInfo);
    products_list.push(productInfo);
    proowner[product_id]=msg.sender;
    inter[product_id]=intermediate;
    product_id++;
}
function AddStatus( string memory location,
    uint256 temp,
    uint256 humidity,
    uint256 proid,
    uint256 total_quantity
) public payable {
    require(proowner[proid]==msg.sender || inter[proid]==msg.sender,'differnet user');
    statusInfo= Status(location,block.timestamp,temp,humidity,proid,total_quantity);
    product_Status[proid].push(statusInfo);
    productStatus.push(statusInfo);
}
function AddData( uint256 temp,
    uint256 humidity,
    uint256 proid) public payable{
    require(proowner[proid]==msg.sender || inter[proid]==msg.sender,'differnet user');
        DataInfo = Data(temp,humidity,proid);
        data[proid].push(DataInfo);
        Data_list.push(DataInfo);
        }
function getProductStatus(uint256 id) public view returns(Status[] memory){
    return product_Status[id];
}
function getProductData(uint256 id) public view returns(Data[] memory){
    return data[id];
}
function getProducts() public view returns(Product[] memory){
    return products_list ;
}
}