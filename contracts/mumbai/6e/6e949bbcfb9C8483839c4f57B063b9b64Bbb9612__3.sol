/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

pragma solidity ^0.5.0;

contract MyFirstContract {
    string private name;
    uint private age;
    
    function setName(string memory newName) public {
        name = newName;
    }
    
    function getName() public view returns (string memory) {
        return name;
    }
    
    function setAge(uint newAge) public {
        age = newAge;
    }
    
    function getAge() public view returns (uint) {
        return age;
    }
}

pragma solidity ^0.5.0;

contract _1 
{
    int num1=15;
    
    function compute1 (int number1) internal view
    {
        num1*number1;
    }
}

pragma solidity ^0.5.0;

contract _2 is _1
{
    int num=-11;
    int overall;

    function compute2 (int number2) public 
    {
        overall=num%number2;
    }
}

pragma solidity ^0.5.0;

contract _3 is _2
{
    function compute3 () public view returns (int)
    {
        int divide=overall/3;
        return divide;
    }
}