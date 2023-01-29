/**
 *Submitted for verification at polygonscan.com on 2023-01-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Introducer is Ownable {
    mapping(address => uint256) uplinesCode;
    mapping(address => uint256) myCode;
    mapping(uint256 => address) code2address;

    uint256 public code;

    constructor() {
        code = 1000;
        uplinesCode[msg.sender] = code;
        code2address[code] = msg.sender;
        myCode[msg.sender] = code;
    }

    event Code(uint256 MyCode);

    function register(uint256 _upline) public {
        code++;
        require(myCode[msg.sender] == 0, "Already registered");
        myCode[msg.sender] = code;
        code2address[code] = msg.sender;
        uplinesCode[msg.sender] = _upline;
        emit Code(code);
    }

    function viewMyCode() public view returns (uint256) {
        return myCode[msg.sender];
    }

    function viewMyUplinesCode() public view returns (uint256) {
        return uplinesCode[msg.sender];
    }

    function viewMyUplinesAddress() public view returns (address) {
        return code2address[viewMyUplinesCode()];
    }

    uint256 introducerReward100x;

    function setIntroducerReward(uint256 _100x) public {
        introducerReward100x = _100x;
    }
}


contract Guess3 is Ownable, Introducer{

    event Guessing(uint256 Result, string Outcome, uint256 Amount);
    event Lucky(uint256 Guess1,uint256 Guess2,uint256 Guess3);
    string outcome;

    uint256 randNonce;
    uint256 public result;
    uint256 public result1;
    uint256 public result2;
    uint256 public result3;
    uint256[] public results;
    
    
    // Defining a function to generate a random number
    function randMod() internal returns(uint256){
        // increase nonce
        randNonce++;
        result = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10;
        result1 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+10))) % 10;
        result2 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+11))) % 10;
        result3 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce+12))) % 10;
        return result;
    }
    
    function viewResult() public view returns(uint256 Result) {
        return (result);
    }
    uint8 bonus;
    
    function guessNumber(uint8 _number, uint8 _number2,uint8 _number3) public payable returns(uint256 Result)  {
        require(msg.value>0, " Nill");
        uint256 amount;
        randMod();
        bonus = uint8(result*10);
        if(_number == result || _number2 == result || _number3 == result){
            outcome = " Hooray!! You Won";
           amount = msg.value*(100+bonus)/100;
           payable(msg.sender).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            amount =0;
        }
        results.push(result);
        if(results.length>10){
          _remove(0);
        }

    
        emit Guessing(result,outcome,amount);
        return(result);
    }
    function luckyDip() public payable returns(uint,uint,uint,uint){
        require(msg.value>0, " Nill");
        uint256 amount;
        randMod();
        bonus = uint8(result*10);
        if(result1 == result || result2 == result || result3 == result){
            outcome = " Hooray!! You Won";
           amount = msg.value*(100+bonus)/100;
           payable(msg.sender).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            amount = 0;
        }
        results.push(result);
        if(results.length>10){
          _remove(0);
        }

    
        emit Guessing(result,outcome,amount);
        emit Lucky(result1,result2,result3);
        return(result,result1,result2,result3);
    }
    function _remove(uint8 _num) internal {
        for (uint8 i=_num; i<results.length-1;i++){
            results[i] = results[i+1];
        }
        results.pop();
    }
    function countResult() public view returns(uint8,uint8,uint8,uint8,uint8) {
        uint8 evenResult;
        uint8 oddResult;
        uint8 firstGroup;
        uint8 secondGroup;
        uint8 thirdGroup;

        for(uint i=0; i<results.length;i++){
            if(results[i] == 0 || results[i] == 1 ||results[i] == 2 ||results[i] == 3) {
                firstGroup++;
            }else if (results[i] == 4 || results[i] == 5 ||results[i] == 6){
                secondGroup++;
            }else {
                thirdGroup++;
            }
            if(results[i] == 0 || results[i] == 2 ||results[i] == 4 ||results[i] == 6 ||results[i] == 8){
                evenResult++;
            }else{
                oddResult++;
            }    
        }

        return (firstGroup,secondGroup,thirdGroup,evenResult,oddResult);
    }
    
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        uint256 contractBalance = address(this).balance;

        _withdraw(owner(), contractBalance );
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}