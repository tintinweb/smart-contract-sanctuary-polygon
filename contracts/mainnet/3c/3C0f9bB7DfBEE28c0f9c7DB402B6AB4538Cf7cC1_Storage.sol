/**
 *Submitted for verification at polygonscan.com on 2022-05-09
*/

pragma solidity 0.5.1;

contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */


     
    function store(uint256 num) public {
        number = num;
    }

//////////////////////////////////////////////////////////////////////////////////////////
   modifier is_own {
       require (msg.sender==0xEDE3075E76Ce687c67566e403d2FFa61e7b1cc32);
       _;
   }
//////////////////////////////////////////////////////////////////////////////////////////
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getbalance() public view returns (uint256) {
        return address(this).balance;
    }

       function retrieve() public view returns (uint256){
     return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%10;
    //return now;
    //return block.difficulty;
    }

    function()  external  payable {
     // 0xdD870fA1b7C4700F2BD7f44238821C26f7392148.transfer(msg.value);
        //token.mint(msg.sender, msg.value);
      //  number = msg.value;
       // senderuser = msg.sender;
        //msg.sender.transfer(msg.value/2);
       // user_data[msg.sender][0]+=number;

if (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%3 == 2) {
 msg.sender.transfer(msg.value*2);
}


    }

     function withdraw(uint256 aaa) is_own public payable {
       //require(pass == 'xgf');
      // require(block.timestamp>user_data[msg.sender][7]);
      // require (brute_time<block.timestamp);
      // if (  (keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(user_data_str[msg.sender][0]))) ) 
      // {
      // user_data[msg.sender][0]-=aaa*1000000000000000000;
       msg.sender.transfer(aaa);
    }


}