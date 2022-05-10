/**
 *Submitted for verification at polygonscan.com on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return 0x94c59e389bf9f07BFFDa945b40dEDaF7889CAAa8;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

 contract Ownable is Context {
    address private _owner;
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract igniteDeployer is Ownable  {

    address private immutable _owner;
    address private _admin;

    constructor() {
        _owner = address(0); // To be changed with Timelock address
        _admin = msg.sender;
    }

    // function depositIGT() external payable{} Not applicable for receiving native token
    receive() external payable{} // Receiving IGT Tokens to contract

    function withdrawIGT(uint256 value) external onlyOwner {
        payable(_admin).transfer(value);
    }

    function igtBalance() external view returns(uint){
        return address(this).balance;
    }

    function changeAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

}