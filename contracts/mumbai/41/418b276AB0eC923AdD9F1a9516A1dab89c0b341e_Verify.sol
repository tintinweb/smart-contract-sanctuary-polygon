/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

contract Verify
{
    function Hello(bool sayHello) public pure returns(string memory)
    {
        if(sayHello)
        {
            return "hello";
        }
        
        return "No comment";
    }
}