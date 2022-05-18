/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

//SPDX-License-Identifier: GPL-3.0
//Giuliano Neroni DEV

pragma solidity ^0.8.12;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;}
        return string(buffer);}
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";}
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;}
        return toHexString(value, length);}
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;}
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);}
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);}}

contract Ownable {
    address private _owner_1 = 0x330E5a355EfB830e6fD4d896FB4e4EE212c6835E;
    address private _owner_2 = 0x330E5a355EfB830e6fD4d896FB4e4EE212c6835E;
    function get_owner_1() public view returns (address) {
        return _owner_1;}
    function get_owner_2() public view returns (address) {
        return _owner_2;}
    modifier onlyOwner() {
        require(msg.sender == _owner_1 || msg.sender == _owner_2 , 'Not owner');
        _;}
    function set_owner_1(address _own) public onlyOwner {
    _owner_1 = _own;}
    function set_owner_2(address _own) public onlyOwner {
    _owner_2 = _own;}}

contract tx_mapping is Ownable{

    uint256 max_quantity = 10;

    struct tx_nft {
        uint256 qty_bought;
        uint256 qty_left;
        string hash_tx;
        string id_tx;
        string blockchain_id;
        string method;
        uint256 tx_done;}

    struct wallet_data {
        uint number_wallet;
        address address_wallet;
        string hash_tx;
        string blockchain_id;
        string qty_bought;
        string qty_pay;
        string method;}

    mapping(address => uint) private quantity;
    mapping(address => tx_nft) public balance;
    mapping (address => bool) public whitelisted;
    address[] private _whitelist;
    address[] private _excluded;

    uint tx_done;
    uint qty_bought;
    uint qty_left;
    uint tx_id;
    string tx_add;
    string tx_id_add;
    string tx_method_add;
    string blockchain_id_add;
    uint public total_tx;

    wallet_data []data;

    //Method -> Swappy
    //       -> Stripe

    function add_wallet(uint _tx_id, address address_wallet, string memory _hashtx, string memory _quantity, string memory _amount, string memory _method, string memory _blockchain_id) public {
	    wallet_data memory e = wallet_data(_tx_id, address_wallet, _hashtx, _quantity, _amount, _method, _blockchain_id); 
  	    data.push(e);}

    function get_list(uint _tx_id) public view returns(address, string memory, string memory, string memory, string memory, string memory) {
	    uint i;
	    for(i=0;i<data.length;i++){
  		    wallet_data memory e = data[i];
  		    if(e.number_wallet == _tx_id){
    			return(e.address_wallet, e.hash_tx, e.blockchain_id, e.qty_bought, e.qty_pay, e.method);}}}
    
    function purchase (address _addr, uint _quantity, string memory _hash_tx, string memory _blockchain_id, string memory _amount, string memory _method) public onlyOwner {
        quantity[_addr] = _quantity;
        count(_addr, _hash_tx, _blockchain_id, _method);
        tx_id += 1;
        add_wallet(tx_id, _addr, _hash_tx, _blockchain_id, Strings.toString(_quantity), _amount, _method);
        if(whitelisted[_addr] == false){
            whitelist(_addr);}}

    function count (address _addr, string memory _hash_tx, string memory _blockchain_id, string memory _method) private onlyOwner {
        tx_done = balance[_addr].tx_done;
        total_tx += 1;

        if(tx_done == 0){
            balance[_addr].hash_tx = _hash_tx;
            balance[_addr].blockchain_id = _blockchain_id;
            balance[_addr].qty_left = max_quantity;
            balance[_addr].qty_left -= quantity[_addr];
            balance[_addr].qty_bought = quantity[_addr];
            balance[_addr].id_tx = Strings.toString(total_tx);
            balance[_addr].method = _method;}

        if(tx_done > 0){
            tx_add = balance[_addr].hash_tx;
            tx_id_add = balance[_addr].id_tx;
            blockchain_id_add = balance[_addr].blockchain_id;
            tx_method_add = balance[_addr].method;
            balance[_addr].hash_tx = string(abi.encodePacked(tx_add, ";", _hash_tx));
            balance[_addr].blockchain_id = string(abi.encodePacked(blockchain_id_add, ";", _blockchain_id));
            balance[_addr].id_tx = string(abi.encodePacked(tx_id_add, ";", Strings.toString(total_tx)));
            balance[_addr].method = string(abi.encodePacked(tx_method_add, ";", _method));
            balance[_addr].qty_left -= quantity[_addr];
            balance[_addr].qty_bought += quantity[_addr];}

        balance[_addr].tx_done += 1;}
        
    function whitelist(address _addr) public onlyOwner() {
        require(!whitelisted[_addr], "Account is already Whitlisted");
        whitelisted[_addr] = true;
        _whitelist.push(_addr);}

    function blacklist_A_whitelisted(address _addr) external onlyOwner() {
        require(whitelisted[_addr], "Account is already Blacklisted");
        for (uint256 i = 0; i < _whitelist.length; i++) {
            if (_whitelist[i] == _addr) {
                _whitelist[i] = _excluded[_excluded.length - 1];
                whitelisted[_addr] = false;
                _whitelist.pop();
                break;}}}}